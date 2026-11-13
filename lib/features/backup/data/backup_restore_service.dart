import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../feed/data/thumbnail_cache_service.dart';
import '../../garmin_sync/data/secure_cookie_store.dart';
import '../../garmin_sync/data/webview_cookie_extractor.dart';
import '../../import/data/fit_archive_storage.dart';
import '../../story_share/data/story_image_cache_service.dart';

typedef BackupProgressCallback = void Function(String stage, double progress);

class BackupRestoreSummary {
  const BackupRestoreSummary({
    required this.restoredActivities,
    required this.skippedDuplicates,
    required this.restoredTrackPoints,
    required this.restoredArchives,
  });

  final int restoredActivities;
  final int skippedDuplicates;
  final int restoredTrackPoints;
  final int restoredArchives;
}

class LocalStorageStats {
  const LocalStorageStats({
    required this.activityCount,
    required this.trackPointCount,
    required this.fitArchiveCount,
    required this.totalStorageBytes,
    this.sqliteDbBytes = 0,
  });

  final int activityCount;
  final int trackPointCount;
  final int fitArchiveCount;
  final int totalStorageBytes;
  final int sqliteDbBytes;
}

class CompactDatabaseResult {
  const CompactDatabaseResult({
    required this.beforeBytes,
    required this.afterBytes,
  });

  final int beforeBytes;
  final int afterBytes;

  int get savedBytes => beforeBytes > afterBytes ? beforeBytes - afterBytes : 0;
}

/// Manages full offline ZIP backup (`backup.json` + `trackpoints.bin` + `fit_archives/`),
/// validated deduplicated restore, local storage telemetry, and double-confirm
/// factory reset (`PRD M5-02`..`M5-05`, `NFR-02`).
class BackupRestoreService {
  BackupRestoreService({
    required this.db,
    required this.archiveStorage,
    required this.thumbnailCache,
    required this.storyCache,
    required this.cookieStore,
    required this.cookieExtractor,
    Future<Directory> Function()? appDocumentsResolver,
    Future<Directory> Function()? appCacheResolver,
  })  : _appDocumentsResolver =
            appDocumentsResolver ?? getApplicationDocumentsDirectory,
        _appCacheResolver = appCacheResolver ?? getApplicationCacheDirectory;

  static const int currentSchemaVersion = 2;
  static const int _tpMagic0 = 0x46; // F
  static const int _tpMagic1 = 0x54; // T
  static const int _tpMagic2 = 0x54; // T
  static const int _tpMagic3 = 0x50; // P
  static const int _tpBinaryVersion = 2;
  static const int _tpHeaderBytes = 10;
  static const int _tpRecordBytesV1 = 45;
  static const int _tpRecordBytesV2 = 53;
  static const int _tpRecordBytes = _tpRecordBytesV2;

  final AppDatabase db;
  final FitArchiveStorage archiveStorage;
  final ThumbnailCacheService thumbnailCache;
  final StoryImageCacheService storyCache;
  final SecureCookieStore cookieStore;
  final WebViewCookieExtractor cookieExtractor;
  final Future<Directory> Function() _appDocumentsResolver;
  final Future<Directory> Function() _appCacheResolver;

  /// Creates an encrypted-cookie-free ZIP archive containing:
  /// - `backup.json` (metadata, lap splits, non-secret preferences)
  /// - `trackpoints.bin` (compact 45-byte little-endian binary stream)
  /// - `fit_archives/*.fit.gz` (retained original compressed blobs)
  Future<Uint8List> buildFullBackupZip({
    BackupProgressCallback? onProgress,
    DateTime? exportedAtUtc,
  }) async {
    final nowUtc = (exportedAtUtc ?? DateTime.now()).toUtc();
    onProgress?.call('Membaca aktivitas & preferensi...', 0.1);

    final prefs = await db.getPreferences();
    final activityRows = await db.select(db.activities).get();
    final splitRows = await db.select(db.lapSplits).get();
    final effortRows = await db.select(db.activityBestEfforts).get();
    final presetRows = await db.select(db.storyPresets).get();

    final totalTpRow = await db
        .customSelect('SELECT COUNT(*) AS c FROM track_points;')
        .getSingle();
    final totalTrackPoints = totalTpRow.read<int>('c');

    final splitsByActivity = <int, List<LapSplitRecord>>{};
    for (final s in splitRows) {
      (splitsByActivity[s.activityId] ??= <LapSplitRecord>[]).add(s);
    }
    final effortsByActivity = <int, List<BestEffortRecord>>{};
    for (final e in effortRows) {
      (effortsByActivity[e.activityId] ??= <BestEffortRecord>[]).add(e);
    }

    onProgress?.call('Mengemas trackpoints biner ($totalTrackPoints)...', 0.35);
    final tpBytes = await _encodeTrackPointsBinaryChunked(totalTrackPoints);

    onProgress?.call('Mengumpulkan arsip .fit.gz...', 0.60);
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('trackpoints.bin', tpBytes));

    final includedArchiveNames = <String>{};
    for (final act in activityRows) {
      final path = act.originalFitPath;
      if (path == null || path.isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final base = p.basename(path);
      if (includedArchiveNames.add(base)) {
        final rawGz = await file.readAsBytes();
        archive.addFile(ArchiveFile.bytes('fit_archives/$base', rawGz));
      }
    }

    // Security (NFR-02): strictly omit garminLoggedIn, lastSyncAt, and all credentials.
    final backupJson = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'appVersion': '1.1.0',
      'exportedAtUtc': nowUtc.toIso8601String(),
      'preferences': <String, dynamic>{
        'birthDate': prefs.birthDate?.toUtc().toIso8601String(),
        'hrMaxManual': prefs.hrMaxManual,
        'hrZoneThresholds': prefs.hrZoneThresholds,
        'themeMode': prefs.themeMode,
        'unitSystem': prefs.unitSystem,
        'weeklyMonthlyToggle': prefs.weeklyMonthlyToggle,
        'watermarkEnabled': prefs.watermarkEnabled,
        'defaultTemplateId': prefs.defaultTemplateId,
        'backgroundSyncEnabled': prefs.backgroundSyncEnabled,
        'backgroundSyncWifiOnly': prefs.backgroundSyncWifiOnly,
        'backgroundSyncRequireCharging': prefs.backgroundSyncRequireCharging,
        'backgroundSyncIntervalMinutes': prefs.backgroundSyncIntervalMinutes,
        'backupReminderEnabled': prefs.backupReminderEnabled,
      },
      'storyPresets': presetRows
          .map(
            (pRow) => <String, dynamic>{
              'name': pRow.name,
              'configJson': pRow.configJson,
              'createdAt': pRow.createdAt.toUtc().toIso8601String(),
              'updatedAt': pRow.updatedAt.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
      'activities': activityRows.map((a) {
        final splits = splitsByActivity[a.id] ?? const <LapSplitRecord>[];
        final efforts = effortsByActivity[a.id] ?? const <BestEffortRecord>[];
        final archiveName = (a.originalFitPath != null &&
                a.originalFitPath!.isNotEmpty &&
                includedArchiveNames.contains(p.basename(a.originalFitPath!)))
            ? p.basename(a.originalFitPath!)
            : null;
        return <String, dynamic>{
          'backupId': a.id,
          'garminActivityId': a.garminActivityId,
          'title': a.title,
          'hasCustomTitle': a.hasCustomTitle,
          'sportType': a.sportType,
          'startTimeUtc': a.startTimeUtc.toUtc().toIso8601String(),
          'utcOffsetSeconds': a.utcOffsetSeconds,
          'durationTotalSec': a.durationTotalSec,
          'durationMovingSec': a.durationMovingSec,
          'distanceMeters': a.distanceMeters,
          'avgPaceSecPerKm': a.avgPaceSecPerKm,
          'avgHeartRate': a.avgHeartRate,
          'maxHeartRate': a.maxHeartRate,
          'avgCadence': a.avgCadence,
          'totalElevationGainM': a.totalElevationGainM,
          'totalElevationLossM': a.totalElevationLossM,
          'caloriesKcal': a.caloriesKcal,
          'isIndoor': a.isIndoor,
          'hasGpsTrack': a.hasGpsTrack,
          'gpsQuality': a.gpsQuality,
          'source': a.source,
          'syncStatus': a.syncStatus,
          'fitFileHash': a.fitFileHash,
          'fitArchiveFileName': archiveName,
          'splitPacesSecPerKm': a.splitPacesSecPerKm,
          'zoneDurationsSec': a.zoneDurationsSec,
          'createdAt': a.createdAt.toUtc().toIso8601String(),
          'updatedAt': a.updatedAt.toUtc().toIso8601String(),
          'lapSplits': splits
              .map(
                (s) => <String, dynamic>{
                  'splitIndex': s.splitIndex,
                  'distanceMeters': s.distanceMeters,
                  'durationSec': s.durationSec,
                  'avgPaceSecPerKm': s.avgPaceSecPerKm,
                  'avgHeartRate': s.avgHeartRate,
                  'avgCadence': s.avgCadence,
                  'elevationDeltaM': s.elevationDeltaM,
                },
              )
              .toList(growable: false),
          'bestEfforts': efforts
              .map(
                (e) => <String, dynamic>{
                  'distanceKey': e.distanceKey,
                  'targetDistanceMeters': e.targetDistanceMeters,
                  'durationSec': e.durationSec,
                  'paceSecPerKm': e.paceSecPerKm,
                },
              )
              .toList(growable: false),
        };
      }).toList(growable: false),
    };

    onProgress?.call('Mengompresi arsip ZIP...', 0.85);
    final jsonBytes = utf8.encode(jsonEncode(backupJson));
    archive.addFile(ArchiveFile.bytes('backup.json', jsonBytes));
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    await db.updatePreferences(
      UserPreferencesTableCompanion(lastBackupAt: Value(nowUtc)),
    );
    onProgress?.call('Backup selesai.', 1.0);
    return zipBytes;
  }

  /// Validates ZIP backup schema & binary layout, then merges activities atomically
  /// inside a single transaction skipping any existing `garminActivityId` or SHA-256 (`M5-03`).
  Future<BackupRestoreSummary> restoreFromZipBytes(
    Uint8List zipBytes, {
    BackupProgressCallback? onProgress,
  }) async {
    onProgress?.call('Membaca & memvalidasi arsip ZIP...', 0.10);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } on Object catch (error) {
      throw DatabaseFailure('File backup ZIP korup atau tidak valid.', error);
    }

    ArchiveFile? jsonEntry;
    ArchiveFile? tpEntry;
    final fitEntries = <String, Uint8List>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (file.name == 'backup.json') {
        jsonEntry = file;
      } else if (file.name == 'trackpoints.bin') {
        tpEntry = file;
      } else if (file.name.startsWith('fit_archives/') &&
          file.name.endsWith('.fit.gz')) {
        final safeBase = p.basename(file.name);
        if (safeBase.isNotEmpty && safeBase.endsWith('.fit.gz')) {
          fitEntries[safeBase] = file.readBytes() ?? Uint8List(0);
        }
      }
    }

    if (jsonEntry == null || tpEntry == null) {
      throw const DatabaseFailure(
        'Backup tidak valid: `backup.json` atau `trackpoints.bin` tidak ditemukan.',
      );
    }

    final Map<String, dynamic> decodedJson;
    try {
      final rawStr = utf8.decode(jsonEntry.readBytes() ?? Uint8List(0));
      final parsed = jsonDecode(rawStr);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Root JSON bukan object.');
      }
      decodedJson = parsed;
    } on Object catch (error) {
      throw DatabaseFailure('Metadata `backup.json` tidak dapat dibaca.', error);
    }

    final schemaVersion = decodedJson['schemaVersion'];
    if (schemaVersion is! int || schemaVersion > currentSchemaVersion || schemaVersion < 1) {
      throw DatabaseFailure(
        'Versi skema backup ($schemaVersion) tidak didukung oleh versi aplikasi ini.',
      );
    }

    final tpMap = _decodeTrackPointsBinary(tpEntry.readBytes() ?? Uint8List(0));

    onProgress?.call('Memulihkan arsip .FIT...', 0.45);
    final docsDir = await _appDocumentsResolver();
    final archiveDir = Directory(p.join(docsDir.path, 'fit_archives'));
    if (!await archiveDir.exists()) {
      await archiveDir.create(recursive: true);
    }

    final restoredArchivePaths = <String, String>{};
    for (final entry in fitEntries.entries) {
      if (entry.value.isEmpty) continue;
      final dest = File(p.join(archiveDir.path, entry.key));
      if (!await dest.exists()) {
        await dest.writeAsBytes(entry.value, flush: true);
      }
      restoredArchivePaths[entry.key] = dest.path;
    }

    onProgress?.call('Menyimpan aktivitas ke SQLite (transaksi tunggal)...', 0.70);
    final rawActivities =
        decodedJson['activities'] as List<dynamic>? ?? const <dynamic>[];

    var restoredActivities = 0;
    var skippedDuplicates = 0;
    var restoredTrackPoints = 0;

    await db.transaction(() async {
      for (final rawAct in rawActivities) {
        if (rawAct is! Map<String, dynamic>) continue;
        final garminId = rawAct['garminActivityId'] as int?;
        final fitHash = (rawAct['fitFileHash'] as String?) ?? '';

        if (garminId != null && await db.findByGarminActivityId(garminId) != null) {
          skippedDuplicates++;
          continue;
        }
        if (fitHash.isNotEmpty && await db.findByFitFileHash(fitHash) != null) {
          skippedDuplicates++;
          continue;
        }

        final backupId = rawAct['backupId'] as int? ?? -1;
        final archiveName = rawAct['fitArchiveFileName'] as String?;
        final localFitPath =
            archiveName != null ? restoredArchivePaths[archiveName] : null;

        final newActivityId = await db.into(db.activities).insert(
          ActivitiesCompanion.insert(
            garminActivityId: Value(garminId),
            title: (rawAct['title'] as String?) ?? 'Restored Run',
            sportType: (rawAct['sportType'] as int?) ?? 1,
            startTimeUtc: DateTime.parse(rawAct['startTimeUtc'] as String).toUtc(),
            utcOffsetSeconds: (rawAct['utcOffsetSeconds'] as int?) ?? 0,
            durationTotalSec: (rawAct['durationTotalSec'] as int?) ?? 0,
            durationMovingSec: (rawAct['durationMovingSec'] as int?) ?? 0,
            distanceMeters:
                ((rawAct['distanceMeters'] as num?) ?? 0).toDouble(),
            avgPaceSecPerKm:
                ((rawAct['avgPaceSecPerKm'] as num?) ?? 0).toDouble(),
            avgHeartRate: Value((rawAct['avgHeartRate'] as num?)?.toDouble()),
            maxHeartRate: Value((rawAct['maxHeartRate'] as num?)?.toDouble()),
            avgCadence: Value((rawAct['avgCadence'] as num?)?.toDouble()),
            totalElevationGainM:
                ((rawAct['totalElevationGainM'] as num?) ?? 0).toDouble(),
            totalElevationLossM:
                ((rawAct['totalElevationLossM'] as num?) ?? 0).toDouble(),
            caloriesKcal: (rawAct['caloriesKcal'] as int?) ?? 0,
            isIndoor: Value((rawAct['isIndoor'] as bool?) ?? false),
            hasGpsTrack: Value((rawAct['hasGpsTrack'] as bool?) ?? false),
            gpsQuality: Value((rawAct['gpsQuality'] as String?) ?? 'good'),
            source: (rawAct['source'] as String?) ?? 'manualImport',
            syncStatus: (rawAct['syncStatus'] as String?) ?? 'localOnly',
            originalFitPath: Value(localFitPath),
            fitFileHash: fitHash,
            splitPacesSecPerKm: (rawAct['splitPacesSecPerKm'] as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList(growable: false) ??
                const <int>[],
            zoneDurationsSec: (rawAct['zoneDurationsSec'] as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList(growable: false) ??
                const <int>[0, 0, 0, 0, 0],
            hasCustomTitle: Value((rawAct['hasCustomTitle'] as bool?) ?? false),
            createdAt: DateTime.parse(rawAct['createdAt'] as String).toUtc(),
            updatedAt: DateTime.parse(rawAct['updatedAt'] as String).toUtc(),
          ),
        );

        final rawSplits =
            rawAct['lapSplits'] as List<dynamic>? ?? const <dynamic>[];
        if (rawSplits.isNotEmpty) {
          await db.batch((b) {
            b.insertAll(
              db.lapSplits,
              rawSplits.whereType<Map<String, dynamic>>().map(
                    (s) => LapSplitsCompanion.insert(
                      activityId: newActivityId,
                      splitIndex: (s['splitIndex'] as num).toInt(),
                      distanceMeters: (s['distanceMeters'] as num).toDouble(),
                      durationSec: (s['durationSec'] as num).toInt(),
                      avgPaceSecPerKm:
                          (s['avgPaceSecPerKm'] as num).toDouble(),
                      avgHeartRate: Value(
                        (s['avgHeartRate'] as num?)?.toDouble(),
                      ),
                      avgCadence: Value((s['avgCadence'] as num?)?.toDouble()),
                      elevationDeltaM:
                          ((s['elevationDeltaM'] as num?) ?? 0).toDouble(),
                    ),
                  ),
            );
          });
        }

        final rawEfforts =
            rawAct['bestEfforts'] as List<dynamic>? ?? const <dynamic>[];
        if (rawEfforts.isNotEmpty) {
          await db.batch((b) {
            b.insertAll(
              db.activityBestEfforts,
              rawEfforts.whereType<Map<String, dynamic>>().map(
                    (e) => ActivityBestEffortsCompanion.insert(
                      activityId: newActivityId,
                      distanceKey: e['distanceKey'] as String,
                      targetDistanceMeters:
                          (e['targetDistanceMeters'] as num).toDouble(),
                      durationSec: (e['durationSec'] as num).toInt(),
                      paceSecPerKm: (e['paceSecPerKm'] as num).toDouble(),
                    ),
                  ),
              mode: InsertMode.insertOrReplace,
            );
          });
        }

        final pts = tpMap[backupId] ?? const <_PackedTrackPoint>[];
        if (pts.isNotEmpty) {
          const tpBatchSize = 1000;
          for (var i = 0; i < pts.length; i += tpBatchSize) {
            final end =
                (i + tpBatchSize < pts.length) ? i + tpBatchSize : pts.length;
            final slice = pts.sublist(i, end);
            await db.batch((b) {
              b.insertAll(
                db.trackPoints,
                slice.map(
                  (pt) => TrackPointsCompanion.insert(
                    activityId: newActivityId,
                    timestampUtc: DateTime.fromMillisecondsSinceEpoch(
                      pt.timestampMsUtc,
                      isUtc: true,
                    ),
                    latitudeDeg: pt.latitudeDeg,
                    longitudeDeg: pt.longitudeDeg,
                    altitudeM: pt.altitudeM,
                    speedMps: pt.speedMps,
                    heartRateBpm: Value(pt.heartRateBpm),
                    cadenceRpm: Value(pt.cadenceRpm),
                    distanceMeters: pt.distanceMeters,
                    hrZone: Value(pt.hrZone),
                  ),
                ),
              );
            });
          }
          restoredTrackPoints += pts.length;
        }

        restoredActivities++;
      }

      final rawPrefs = decodedJson['preferences'];
      if (rawPrefs is Map<String, dynamic>) {
        final birthRaw = rawPrefs['birthDate'] as String?;
        final thresholds = (rawPrefs['hrZoneThresholds'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(growable: false);
        await db.updatePreferences(
          UserPreferencesTableCompanion(
            birthDate: Value(
              birthRaw != null ? DateTime.tryParse(birthRaw)?.toUtc() : null,
            ),
            hrMaxManual: Value(rawPrefs['hrMaxManual'] as int?),
            hrZoneThresholds:
                thresholds != null && thresholds.length == 4
                    ? Value(thresholds)
                    : const Value.absent(),
            themeMode: rawPrefs['themeMode'] is String
                ? Value(rawPrefs['themeMode'] as String)
                : const Value.absent(),
            unitSystem: rawPrefs['unitSystem'] is String
                ? Value(rawPrefs['unitSystem'] as String)
                : const Value.absent(),
            weeklyMonthlyToggle: rawPrefs['weeklyMonthlyToggle'] is String
                ? Value(rawPrefs['weeklyMonthlyToggle'] as String)
                : const Value.absent(),
            watermarkEnabled: rawPrefs['watermarkEnabled'] is bool
                ? Value(rawPrefs['watermarkEnabled'] as bool)
                : const Value.absent(),
            defaultTemplateId: rawPrefs['defaultTemplateId'] is String
                ? Value(rawPrefs['defaultTemplateId'] as String)
                : const Value.absent(),
            backgroundSyncEnabled: rawPrefs['backgroundSyncEnabled'] is bool
                ? Value(rawPrefs['backgroundSyncEnabled'] as bool)
                : const Value.absent(),
            backgroundSyncWifiOnly: rawPrefs['backgroundSyncWifiOnly'] is bool
                ? Value(rawPrefs['backgroundSyncWifiOnly'] as bool)
                : const Value.absent(),
            backgroundSyncRequireCharging:
                rawPrefs['backgroundSyncRequireCharging'] is bool
                    ? Value(rawPrefs['backgroundSyncRequireCharging'] as bool)
                    : const Value.absent(),
            backgroundSyncIntervalMinutes:
                rawPrefs['backgroundSyncIntervalMinutes'] is int
                    ? Value(rawPrefs['backgroundSyncIntervalMinutes'] as int)
                    : const Value.absent(),
            backupReminderEnabled: rawPrefs['backupReminderEnabled'] is bool
                ? Value(rawPrefs['backupReminderEnabled'] as bool)
                : const Value.absent(),
          ),
        );
      }

      final rawPresets =
          decodedJson['storyPresets'] as List<dynamic>? ?? const <dynamic>[];
      if (rawPresets.isNotEmpty) {
        final existingPresets = await db.select(db.storyPresets).get();
        final existingNames = existingPresets.map((e) => e.name).toSet();
        for (final rawPreset in rawPresets.whereType<Map<String, dynamic>>()) {
          final name = (rawPreset['name'] as String?)?.trim() ?? '';
          final configJson = rawPreset['configJson'] as String? ?? '';
          if (name.isEmpty ||
              configJson.isEmpty ||
              existingNames.contains(name)) {
            continue;
          }
          existingNames.add(name);
          await db.into(db.storyPresets).insert(
            StoryPresetsCompanion.insert(
              name: name,
              configJson: configJson,
              createdAt: DateTime.tryParse(
                        rawPreset['createdAt'] as String? ?? '',
                      )?.toUtc() ??
                  DateTime.now().toUtc(),
              updatedAt: DateTime.tryParse(
                        rawPreset['updatedAt'] as String? ?? '',
                      )?.toUtc() ??
                  DateTime.now().toUtc(),
            ),
          );
        }
      }
    });

    // Backfill best efforts if restored from a v1 backup without precomputed efforts.
    await db.backfillMissingBestEfforts();

    onProgress?.call('Restore selesai.', 1.0);
    return BackupRestoreSummary(
      restoredActivities: restoredActivities,
      skippedDuplicates: skippedDuplicates,
      restoredTrackPoints: restoredTrackPoints,
      restoredArchives: restoredArchivePaths.length,
    );
  }

  /// Reports SQLite row counts & approximate disk footprint (`M5-05`).
  Future<LocalStorageStats> getStorageStats() async {
    final actCountRow = await db
        .customSelect('SELECT COUNT(*) AS c FROM activities;')
        .getSingle();
    final tpCountRow = await db
        .customSelect('SELECT COUNT(*) AS c FROM track_points;')
        .getSingle();

    var totalBytes = 0;
    var sqliteDbBytes = 0;
    var fitArchiveCount = 0;

    try {
      final docsDir = await _appDocumentsResolver();
      final sqliteFile = File(p.join(docsDir.path, 'fittrace.sqlite'));
      if (await sqliteFile.exists()) {
        sqliteDbBytes = await sqliteFile.length();
        totalBytes += sqliteDbBytes;
      }
      final archivesDir = Directory(p.join(docsDir.path, 'fit_archives'));
      if (await archivesDir.exists()) {
        await for (final entity in archivesDir.list(followLinks: false)) {
          if (entity is File && entity.path.endsWith('.fit.gz')) {
            fitArchiveCount++;
            totalBytes += await entity.length();
          }
        }
      }
    } on Object catch (e) {
      AppLogger.warn('BackupRestore', 'Failed inspecting documents dir', e);
    }

    try {
      final cacheDir = await _appCacheResolver();
      for (final folder in const <String>['osm_tiles', 'thumbnails', 'story_cache']) {
        final sub = Directory(p.join(cacheDir.path, folder));
        if (await sub.exists()) {
          await for (final entity in sub.list(followLinks: false)) {
            if (entity is File) {
              totalBytes += await entity.length();
            }
          }
        }
      }
    } on Object catch (e) {
      AppLogger.warn('BackupRestore', 'Failed inspecting cache dir', e);
    }

    return LocalStorageStats(
      activityCount: actCountRow.read<int>('c'),
      trackPointCount: tpCountRow.read<int>('c'),
      fitArchiveCount: fitArchiveCount,
      totalStorageBytes: totalBytes,
      sqliteDbBytes: sqliteDbBytes,
    );
  }

  /// Compacts SQLite database pages using `VACUUM` (`PRD M5-05`).
  Future<CompactDatabaseResult> compactDatabase() async {
    Future<int> readSqliteBytes() async {
      try {
        final docsDir = await _appDocumentsResolver();
        final sqliteFile = File(p.join(docsDir.path, 'fittrace.sqlite'));
        if (await sqliteFile.exists()) {
          return await sqliteFile.length();
        }
      } on Object {
        // Test environment / in-memory DB.
      }
      return 0;
    }

    final before = await readSqliteBytes();
    await db.vacuumDatabase();
    final after = await readSqliteBytes();
    AppLogger.info(
      'BackupRestore',
      'Database compacted via VACUUM ($before -> $after bytes)',
    );
    return CompactDatabaseResult(beforeBytes: before, afterBytes: after);
  }

  /// Clears OpenStreetMap tile cache without touching activities or sqlite DB.
  Future<int> clearTileCache() async {
    var totalFreed = 0;
    try {
      final cacheDir = await _appCacheResolver();
      final tileDir = Directory(p.join(cacheDir.path, 'osm_tiles'));
      if (await tileDir.exists()) {
        await for (final entity in tileDir.list(followLinks: false)) {
          if (entity is File) {
            totalFreed += await entity.length();
            await entity.delete();
          }
        }
      }
      AppLogger.info(
        'BackupRestore',
        'OSM tile cache cleared ($totalFreed bytes freed)',
      );
    } on Object catch (e) {
      AppLogger.warn('BackupRestore', 'Failed clearing OSM tile cache', e);
    }
    return totalFreed;
  }

  /// Erases all local activities, caches, archives, preferences, and Garmin cookies (`M5-04`).
  Future<void> factoryResetAllData() async {
    await db.transaction(() async {
      await db.delete(db.activityBestEfforts).go();
      await db.delete(db.trackPoints).go();
      await db.delete(db.lapSplits).go();
      await db.delete(db.activities).go();
      await db.delete(db.storyPresets).go();
      await db.delete(db.userPreferencesTable).go();
      await db.into(db.userPreferencesTable).insert(
            UserPreferencesTableCompanion.insert(
              id: const Value(1),
              onboardingCompleted: const Value(true),
            ),
          );
    });

    await cookieStore.clearSession();
    await cookieExtractor.clearAllWebViewCookies();

    try {
      final docsDir = await _appDocumentsResolver();
      final archiveDir = Directory(p.join(docsDir.path, 'fit_archives'));
      if (await archiveDir.exists()) {
        await archiveDir.delete(recursive: true);
      }
    } on Object catch (e) {
      AppLogger.warn('FactoryReset', 'Failed clearing fit_archives', e);
    }

    try {
      final cacheDir = await _appCacheResolver();
      for (final folder in const <String>['osm_tiles', 'thumbnails', 'story_cache']) {
        final dir = Directory(p.join(cacheDir.path, folder));
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } on Object catch (e) {
      AppLogger.warn('FactoryReset', 'Failed clearing cache folders', e);
    }
  }

  Future<Uint8List> _encodeTrackPointsBinaryChunked(int totalCount) async {
    final totalBytes = _tpHeaderBytes + totalCount * _tpRecordBytes;
    final byteData = ByteData(totalBytes);
    byteData.setUint8(0, _tpMagic0);
    byteData.setUint8(1, _tpMagic1);
    byteData.setUint8(2, _tpMagic2);
    byteData.setUint8(3, _tpMagic3);
    byteData.setUint16(4, _tpBinaryVersion, Endian.little);
    byteData.setUint32(6, totalCount, Endian.little);

    if (totalCount == 0) {
      return byteData.buffer.asUint8List();
    }

    const chunkSize = 2500;
    var lastId = 0;
    var writeOffset = _tpHeaderBytes;
    var processed = 0;

    while (processed < totalCount) {
      final chunk = await (db.select(db.trackPoints)
            ..where((t) => t.id.isBiggerThanValue(lastId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(chunkSize))
          .get();

      if (chunk.isEmpty) break;

      for (final pt in chunk) {
        byteData.setInt32(writeOffset, pt.activityId, Endian.little);
        byteData.setInt64(
          writeOffset + 4,
          pt.timestampUtc.toUtc().millisecondsSinceEpoch,
          Endian.little,
        );
        byteData.setFloat64(writeOffset + 12, pt.latitudeDeg, Endian.little);
        byteData.setFloat64(writeOffset + 20, pt.longitudeDeg, Endian.little);
        byteData.setFloat64(writeOffset + 28, pt.altitudeM, Endian.little);
        byteData.setFloat64(writeOffset + 36, pt.speedMps, Endian.little);
        byteData.setInt16(
          writeOffset + 44,
          pt.heartRateBpm ?? -1,
          Endian.little,
        );
        byteData.setInt16(
          writeOffset + 46,
          pt.cadenceRpm ?? -1,
          Endian.little,
        );
        byteData.setInt32(writeOffset + 48, pt.distanceMeters, Endian.little);
        byteData.setInt8(writeOffset + 52, pt.hrZone ?? -1);
        writeOffset += _tpRecordBytes;
      }

      lastId = chunk.last.id;
      processed += chunk.length;
    }

    return byteData.buffer.asUint8List();
  }


  static Map<int, List<_PackedTrackPoint>> _decodeTrackPointsBinary(
    Uint8List bytes,
  ) {
    if (bytes.length < _tpHeaderBytes) {
      throw const DatabaseFailure('Format `trackpoints.bin` terlalu pendek.');
    }
    final data = ByteData.sublistView(bytes);
    if (data.getUint8(0) != _tpMagic0 ||
        data.getUint8(1) != _tpMagic1 ||
        data.getUint8(2) != _tpMagic2 ||
        data.getUint8(3) != _tpMagic3) {
      throw const DatabaseFailure('Header magic `trackpoints.bin` tidak valid.');
    }
    final version = data.getUint16(4, Endian.little);
    if (version != 1 && version != 2) {
      throw DatabaseFailure('Versi biner `trackpoints.bin` ($version) tidak didukung.');
    }
    final count = data.getUint32(6, Endian.little);
    final recordBytes = version == 1 ? _tpRecordBytesV1 : _tpRecordBytesV2;
    final expectedLen = _tpHeaderBytes + count * recordBytes;
    if (bytes.length != expectedLen) {
      throw const DatabaseFailure('Ukuran `trackpoints.bin` korup atau terpotong.');
    }

    final grouped = <int, List<_PackedTrackPoint>>{};
    var offset = _tpHeaderBytes;
    for (var i = 0; i < count; i++) {
      final actId = data.getInt32(offset, Endian.little);
      final tsMs = data.getInt64(offset + 4, Endian.little);
      final lat = data.getFloat64(offset + 12, Endian.little);
      final lng = data.getFloat64(offset + 20, Endian.little);
      final double alt;
      final double speed;
      final int hrRaw;
      final int cadRaw;
      final int dist;
      final int zoneRaw;

      if (version == 1) {
        alt = data.getFloat32(offset + 28, Endian.little);
        speed = data.getFloat32(offset + 32, Endian.little);
        hrRaw = data.getInt16(offset + 36, Endian.little);
        cadRaw = data.getInt16(offset + 38, Endian.little);
        dist = data.getInt32(offset + 40, Endian.little);
        zoneRaw = data.getInt8(offset + 44);
      } else {
        alt = data.getFloat64(offset + 28, Endian.little);
        speed = data.getFloat64(offset + 36, Endian.little);
        hrRaw = data.getInt16(offset + 44, Endian.little);
        cadRaw = data.getInt16(offset + 46, Endian.little);
        dist = data.getInt32(offset + 48, Endian.little);
        zoneRaw = data.getInt8(offset + 52);
      }

      (grouped[actId] ??= <_PackedTrackPoint>[]).add(
        _PackedTrackPoint(
          timestampMsUtc: tsMs,
          latitudeDeg: lat,
          longitudeDeg: lng,
          altitudeM: alt,
          speedMps: speed,
          heartRateBpm: hrRaw >= 0 ? hrRaw : null,
          cadenceRpm: cadRaw >= 0 ? cadRaw : null,
          distanceMeters: dist,
          hrZone: zoneRaw >= 0 ? zoneRaw : null,
        ),
      );
      offset += recordBytes;
    }

    return grouped;
  }
}

class _PackedTrackPoint {
  const _PackedTrackPoint({
    required this.timestampMsUtc,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.altitudeM,
    required this.speedMps,
    required this.heartRateBpm,
    required this.cadenceRpm,
    required this.distanceMeters,
    required this.hrZone,
  });

  final int timestampMsUtc;
  final double latitudeDeg;
  final double longitudeDeg;
  final double altitudeM;
  final double speedMps;
  final int? heartRateBpm;
  final int? cadenceRpm;
  final int distanceMeters;
  final int? hrZone;
}

