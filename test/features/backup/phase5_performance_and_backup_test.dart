import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/core/error/app_failure.dart';
import 'package:fit_trace/core/utils/unit_formatter.dart';
import 'package:fit_trace/features/activity_detail/application/activity_detail_providers.dart';
import 'package:fit_trace/features/activity_detail/presentation/widgets/cached_osm_tile_provider.dart';
import 'package:fit_trace/features/backup/application/backup_providers.dart';
import 'package:fit_trace/features/backup/data/backup_restore_service.dart';
import 'package:fit_trace/features/backup/data/fit_export_service.dart';
import 'package:fit_trace/features/feed/data/thumbnail_cache_service.dart';
import 'package:fit_trace/features/garmin_sync/application/garmin_sync_providers.dart';
import 'package:fit_trace/features/garmin_sync/data/secure_cookie_store.dart';
import 'package:fit_trace/features/garmin_sync/data/webview_cookie_extractor.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session.dart';
import 'package:fit_trace/features/import/application/import_providers.dart';
import 'package:fit_trace/features/import/data/fit_archive_storage.dart';
import 'package:fit_trace/features/settings/presentation/settings_screen.dart';
import 'package:fit_trace/features/story_share/application/story_share_providers.dart';
import 'package:fit_trace/features/story_share/data/story_image_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;

class _NoOpCookieExtractor implements WebViewCookieExtractor {
  bool cleared = false;

  @override
  Future<void> clearAllWebViewCookies() async {
    cleared = true;
  }

  @override
  Future<GarminSessionBundle> extractGarminSession({
    Future<String?> Function()? jsCookieFallback,
  }) async {
    return GarminSessionBundle(
      cookies: const <String, GarminCookieEntry>{},
      capturedAtUtc: DateTime.now().toUtc(),
    );
  }
}

ParsedActivity _sampleParsedRun({
  int? garminActivityId,
  required String title,
  required DateTime startUtc,
  int points = 40,
}) {
  final track = List<ParsedTrackPoint>.generate(points, (i) {
    return ParsedTrackPoint(
      timestampUtc: startUtc.add(Duration(seconds: i * 10)),
      latitudeDeg: -6.2000 + i * 0.0003,
      longitudeDeg: 106.8000 + (i % 5) * 0.00004,
      altitudeM: 25.0 + i * 0.25,
      speedMps: 3.35 + (i % 4) * 0.1,
      distanceMeters: (i * 34).round(),
      heartRateBpm: 146 + (i % 18),
      cadenceRpm: 88,
      hrZone: 3,
    );
  });

  return ParsedActivity(
    garminActivityId: garminActivityId,
    title: title,
    sportType: SportType.run,
    startTimeUtc: startUtc,
    utcOffsetSeconds: 25200,
    durationTotalSec: (points - 1) * 10,
    durationMovingSec: (points - 1) * 10,
    distanceMeters: ((points - 1) * 34).toDouble(),
    avgPaceSecPerKm: 294.1,
    avgHeartRate: 154,
    maxHeartRate: 164,
    avgCadence: 88,
    totalElevationGainM: 9.75,
    totalElevationLossM: 0,
    caloriesKcal: 110,
    isIndoor: false,
    hasGpsTrack: true,
    gpsQuality: GpsQuality.good,
    splitPacesSecPerKm: const <int>[294],
    zoneDurationsSec: const <int>[0, 20, 250, 120, 0],
    trackPoints: track,
    lapSplits: <ParsedLapSplit>[
      ParsedLapSplit(
        splitIndex: 0,
        distanceMeters: ((points - 1) * 34).toDouble(),
        durationSec: (points - 1) * 10,
        avgPaceSecPerKm: 294.1,
        elevationDeltaM: 9.75,
        avgHeartRate: 154,
        avgCadence: 88,
      ),
    ],
  );
}

void main() {
  group('Marathon 42K Performance & Tile LRU (NFR-01, NFR-03)', () {
    test('processes 45,000 marathon trackpoints into <=1000 chart pts & <=42 split segments across 3 Douglas-Peucker zoom buckets', () {
      const n = 45000;
      final transfers = List<RawDetailPointTransfer>.generate(n, (i) {
        final progress = i / (n - 1);
        final dist = (progress * 42195).round();
        // Smooth marathon bend + mild 0.3m jitter.
        final lat = -6.2000 + progress * 0.28 + math.sin(progress * 6) * 0.02;
        final lng = 106.8000 + math.cos(progress * 4) * 0.04;
        return RawDetailPointTransfer(
          lat: lat,
          lng: lng,
          alt: 12.0 + math.sin(progress * 20) * 8.0,
          speed: 3.1 + (i % 7) * 0.15,
          hr: 145 + (i % 25),
          dist: dist,
        );
      });

      final sw = Stopwatch()..start();
      final geometry = prepareDetailGeometrySync(raw: transfers, hasGps: true);
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(2000));
      expect(geometry.chartPoints.length, lessThanOrEqualTo(1000));

      final overviewSegs = geometry.segmentsByZoom[MapZoomBucket.overview]!;
      final citySegs = geometry.segmentsByZoom[MapZoomBucket.city]!;
      final streetSegs = geometry.segmentsByZoom[MapZoomBucket.street]!;

      expect(overviewSegs.length, lessThanOrEqualTo(42));
      expect(citySegs.length, lessThanOrEqualTo(42));
      expect(streetSegs.length, lessThanOrEqualTo(42));

      final overviewVertices =
          overviewSegs.fold<int>(0, (sum, s) => sum + s.points.length);
      final streetVertices =
          streetSegs.fold<int>(0, (sum, s) => sum + s.points.length);
      expect(overviewVertices, lessThan(n ~/ 10));
      expect(streetVertices, greaterThanOrEqualTo(overviewVertices));
    });

    test('CachedOsmTileProvider pruneLruCache evicts oldest tiles below maxCacheBytes', () async {
      final tempDir = await Directory.systemTemp.createTemp('fittrace_tile_lru_');
      try {
        final tileDir = Directory(p.join(tempDir.path, 'osm_tiles'));
        await tileDir.create(recursive: true);

        final oldTile = File(p.join(tileDir.path, '12_1_1.png'));
        final midTile = File(p.join(tileDir.path, '12_1_2.png'));
        final newTile = File(p.join(tileDir.path, '12_1_3.png'));

        await oldTile.writeAsBytes(Uint8List(250));
        await midTile.writeAsBytes(Uint8List(250));
        await newTile.writeAsBytes(Uint8List(250));

        final now = DateTime.now();
        await oldTile.setLastModified(now.subtract(const Duration(hours: 5)));
        await midTile.setLastModified(now.subtract(const Duration(hours: 2)));
        await newTile.setLastModified(now);

        final provider = CachedOsmTileProvider(
          cacheDirectoryResolver: () async => tempDir,
          maxCacheBytes: 520,
          offlineOnly: true,
        );
        await provider.pruneLruCache();

        expect(await oldTile.exists(), isFalse);
        expect(await midTile.exists(), isTrue);
        expect(await newTile.exists(), isTrue);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('FitExportService & BackupRestoreService (M5-01..M5-03)', () {
    late Directory docsDir;
    late Directory cacheDir;
    late AppDatabase db;
    late FitArchiveStorage archives;
    late SecureCookieStore cookieStore;
    late _NoOpCookieExtractor cookieExtractor;
    late BackupRestoreService backupService;

    setUp(() async {
      docsDir = await Directory.systemTemp.createTemp('fittrace_bkp_docs_');
      cacheDir = await Directory.systemTemp.createTemp('fittrace_bkp_cache_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.getPreferences();
      archives = FitArchiveStorage(
        rootDirectoryResolver: () async => Directory(p.join(docsDir.path, 'fit_archives')),
      );
      cookieStore = SecureCookieStore(InMemorySecureKeyValueStore());
      cookieExtractor = _NoOpCookieExtractor();
      backupService = BackupRestoreService(
        db: db,
        archiveStorage: archives,
        thumbnailCache: ThumbnailCacheService(cacheDirectoryResolver: () async => cacheDir),
        storyCache: StoryImageCacheService(cacheDirectoryResolver: () async => cacheDir),
        cookieStore: cookieStore,
        cookieExtractor: cookieExtractor,
        appDocumentsResolver: () async => docsDir,
        appCacheResolver: () async => cacheDir,
      );
    });

    tearDown(() async {
      await db.close();
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
      if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
    });

    test('exports regenerated .FIT when .fit.gz archive is pruned and exports original when archived', () async {
      final parsed = _sampleParsedRun(
        garminActivityId: 8801,
        title: 'Aged Marathon Session',
        startUtc: DateTime.utc(2026, 9, 1, 5, 30),
        points: 25,
      );
      final encodedOriginal = const GarminFitEncoder().encodeActivity(parsed);
      final archivedPath = await archives.saveArchive(
        fitFileHash: 'hash_archived_8801',
        rawFitBytes: encodedOriginal,
      );

      final archivedId = await db.insertParsedActivity(
        parsed: parsed,
        source: ActivitySource.garminSync,
        syncStatus: SyncStatus.synced,
        fitFileHash: 'hash_archived_8801',
        originalFitPath: archivedPath,
      );
      final agedId = await db.insertParsedActivity(
        parsed: _sampleParsedRun(
          garminActivityId: 8802,
          title: 'Pruned Run >30d',
          startUtc: DateTime.utc(2026, 7, 1, 5, 30),
          points: 20,
        ),
        source: ActivitySource.manualImport,
        syncStatus: SyncStatus.localOnly,
        fitFileHash: 'hash_pruned_8802',
        originalFitPath: null,
      );

      final exporter = FitExportService(db: db, archiveStorage: archives);
      final fromArchive = await exporter.buildFitBytes(archivedId);
      expect(fromArchive.isRegenerated, isFalse);
      expect(fromArchive.bytes, encodedOriginal);

      final regenerated = await exporter.buildFitBytes(agedId);
      expect(regenerated.isRegenerated, isTrue);

      final reparsed = const GarminFitParserEngine().parseFitBytes(
        regenerated.bytes,
        hrZoneConfig: HrZoneConfig.resolve(),
        fallbackTitle: 'Pruned Run >30d',
      );
      expect(reparsed.trackPoints.length, 20);
      expect(reparsed.utcOffsetSeconds, 25200);
    });

    test('full ZIP backup excludes credentials and restores losslessly without duplicates', () async {
      // Save sensitive cookie that must NEVER appear inside backup ZIP.
      await cookieStore.saveSession(
        GarminSessionBundle(
          cookies: const <String, GarminCookieEntry>{
            'SESSIONID': GarminCookieEntry(
              name: 'SESSIONID',
              value: 'secretCookieTokenXYZ',
            ),
          },
          capturedAtUtc: DateTime.utc(2026, 11, 10),
        ),
      );
      await db.updatePreferences(
        const UserPreferencesTableCompanion(
          garminLoggedIn: Value(true),
          hrMaxManual: Value(194),
          unitSystem: Value('imperial'),
        ),
      );

      final parsed = _sampleParsedRun(
        garminActivityId: 70001,
        title: 'Monas Morning Loop',
        startUtc: DateTime.utc(2026, 11, 10, 6, 0),
        points: 60,
      );
      final fitBytes = const GarminFitEncoder().encodeActivity(parsed);
      final gzPath = await archives.saveArchive(
        fitFileHash: 'hash_70001',
        rawFitBytes: fitBytes,
      );
      await db.insertParsedActivity(
        parsed: parsed,
        source: ActivitySource.garminSync,
        syncStatus: SyncStatus.synced,
        fitFileHash: 'hash_70001',
        originalFitPath: gzPath,
      );

      final zipBytes = await backupService.buildFullBackupZip();
      final decodedZip = ZipDecoder().decodeBytes(zipBytes);
      final names = decodedZip.files.map((f) => f.name).toSet();
      expect(names, containsAll(<String>['backup.json', 'trackpoints.bin']));
      expect(names.any((n) => n.startsWith('fit_archives/')), isTrue);

      // Security NFR-02 check: no cookie/token anywhere in backup JSON.
      final jsonStr = utf8.decode(
        decodedZip.files.firstWhere((f) => f.name == 'backup.json').readBytes()!,
      );
      expect(jsonStr, isNot(contains('secretCookieTokenXYZ')));
      expect(jsonStr, isNot(contains('SESSIONID')));
      expect(jsonStr, isNot(contains('garminLoggedIn')));

      // Reject tampered schema version cleanly.
      final tamperedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      tamperedJson['schemaVersion'] = 99;
      final badArchive = Archive()
        ..addFile(ArchiveFile.bytes('backup.json', utf8.encode(jsonEncode(tamperedJson))))
        ..addFile(
          ArchiveFile.bytes(
            'trackpoints.bin',
            decodedZip.files.firstWhere((f) => f.name == 'trackpoints.bin').readBytes()!,
          ),
        );
      await expectLater(
        backupService.restoreFromZipBytes(Uint8List.fromList(ZipEncoder().encode(badArchive))),
        throwsA(isA<DatabaseFailure>()),
      );

      // Restore into fresh DB preserves everything & omits garminLoggedIn.
      final targetDocs = await Directory.systemTemp.createTemp('fittrace_restore_docs_');
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await targetDb.getPreferences();
        final targetArchives = FitArchiveStorage(
          rootDirectoryResolver: () async =>
              Directory(p.join(targetDocs.path, 'fit_archives')),
        );
        final targetService = BackupRestoreService(
          db: targetDb,
          archiveStorage: targetArchives,
          thumbnailCache: ThumbnailCacheService(cacheDirectoryResolver: () async => cacheDir),
          storyCache: StoryImageCacheService(cacheDirectoryResolver: () async => cacheDir),
          cookieStore: SecureCookieStore(InMemorySecureKeyValueStore()),
          cookieExtractor: cookieExtractor,
          appDocumentsResolver: () async => targetDocs,
          appCacheResolver: () async => cacheDir,
        );

        final firstRestore = await targetService.restoreFromZipBytes(zipBytes);
        expect(firstRestore.restoredActivities, 1);
        expect(firstRestore.skippedDuplicates, 0);
        expect(firstRestore.restoredTrackPoints, 60);
        expect(firstRestore.restoredArchives, 1);

        final restoredAct = await targetDb.findByGarminActivityId(70001);
        expect(restoredAct, isNotNull);
        expect(restoredAct!.title, 'Monas Morning Loop');
        expect((await targetDb.getTrackPointsForActivity(restoredAct.id)).length, 60);
        expect((await targetDb.getLapSplitsForActivity(restoredAct.id)).length, 1);
        expect(await targetArchives.readArchive(restoredAct.originalFitPath), fitBytes);

        final targetPrefs = await targetDb.getPreferences();
        expect(targetPrefs.hrMaxManual, 194);
        expect(targetPrefs.unitSystem, 'imperial');
        expect(targetPrefs.garminLoggedIn, isFalse);

        // Second restore of same ZIP merges without creating duplicates.
        final secondRestore = await targetService.restoreFromZipBytes(zipBytes);
        expect(secondRestore.restoredActivities, 0);
        expect(secondRestore.skippedDuplicates, 1);
        expect((await targetDb.fetchFeedActivities()).length, 1);
      } finally {
        await targetDb.close();
        if (await targetDocs.exists()) await targetDocs.delete(recursive: true);
      }
    });
  });

  group('UnitFormatter & SettingsScreen UI', () {
    test('converts metric & imperial distances, pace, and elevation consistently', () {
      expect(UnitFormatter.formatDistanceValue(5000, 'metric'), '5.00');
      expect(UnitFormatter.distanceUnitLabel('metric', upperCase: true), 'KM');
      expect(UnitFormatter.formatPaceWithUnit(300, 'metric'), "5'00\"/km");

      expect(UnitFormatter.formatDistanceValue(1609.344, 'imperial'), '1.00');
      expect(UnitFormatter.distanceUnitLabel('imperial', upperCase: true), 'MI');
      expect(UnitFormatter.formatPaceWithUnit(300, 'imperial'), "8'03\"/mi");
      expect(UnitFormatter.formatElevation(100, 'imperial', signed: true), '+328 ft');
    });

    testWidgets(
      'SettingsScreen configures HRmax, privacy sheet, and executes double-confirm Factory Reset',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final kvStore = InMemorySecureKeyValueStore();
        final cookieExtractor = _NoOpCookieExtractor();
        late Directory tempDir;

        try {
          await tester.runAsync(() async {
            tempDir = await Directory.systemTemp.createTemp('fittrace_settings_');
            await db.getPreferences();
            await db.insertParsedActivity(
              parsed: _sampleParsedRun(
                garminActivityId: 3030,
                title: 'Temp Run For Reset',
                startUtc: DateTime.utc(2026, 11, 12, 6, 0),
                points: 10,
              ),
              source: ActivitySource.garminSync,
              syncStatus: SyncStatus.synced,
              fitFileHash: 'hash_reset_3030',
            );
            await SecureCookieStore(kvStore).saveSession(
              GarminSessionBundle(
                cookies: const <String, GarminCookieEntry>{
                  'SESSIONID': GarminCookieEntry(name: 'SESSIONID', value: 'x'),
                },
                capturedAtUtc: DateTime.now().toUtc(),
              ),
            );
          });

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWithValue(db),
                secureKeyValueStoreProvider.overrideWithValue(kvStore),
                webViewCookieExtractorProvider.overrideWithValue(cookieExtractor),
                fitArchiveStorageProvider.overrideWithValue(
                  FitArchiveStorage(
                    rootDirectoryResolver: () async =>
                        Directory(p.join(tempDir.path, 'fit_archives')),
                  ),
                ),
                thumbnailCacheServiceProvider.overrideWithValue(
                  ThumbnailCacheService(cacheDirectoryResolver: () async => tempDir),
                ),
                storyImageCacheServiceProvider.overrideWithValue(
                  StoryImageCacheService(cacheDirectoryResolver: () async => tempDir),
                ),
                backupRestoreServiceProvider.overrideWith(
                  (ref) => BackupRestoreService(
                    db: db,
                    archiveStorage: ref.watch(fitArchiveStorageProvider),
                    thumbnailCache: ref.watch(thumbnailCacheServiceProvider),
                    storyCache: ref.watch(storyImageCacheServiceProvider),
                    cookieStore: ref.watch(secureCookieStoreProvider),
                    cookieExtractor: cookieExtractor,
                    appDocumentsResolver: () async => tempDir,
                    appCacheResolver: () async => tempDir,
                  ),
                ),
              ],
              child: const FitTraceApp(home: SettingsScreen()),
            ),
          );
          await tester.pumpAndSettle();

          // Switch distance unit to MI.
          await tester.tap(find.text('MI'));
          await tester.pumpAndSettle();
          expect((await db.getPreferences()).unitSystem, 'imperial');

          // Scroll to HRmax section & configure manual HRmax = 195.
          await tester.scrollUntilVisible(
            find.text('HRmax Aktif'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('HRmax Aktif'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('HRmax Aktif'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).last, '195');
          await tester.tap(find.text('Simpan'));
          await tester.pumpAndSettle();
          expect(find.text('195 bpm (Manual)'), findsOneWidget);

          // Scroll to Privacy Policy & open sheet.
          await tester.scrollUntilVisible(
            find.text('Kebijakan Privasi (100% Local-Only)'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.text('Kebijakan Privasi (100% Local-Only)'),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kebijakan Privasi (100% Local-Only)'));
          await tester.pumpAndSettle();
          expect(
            find.text('KEBIJAKAN PRIVASI — 100% LOCAL-ONLY'),
            findsOneWidget,
          );
          await tester.tap(find.text('Tutup'));
          await tester.pumpAndSettle();

          // Execute double-confirm Factory Reset.
          await tester.scrollUntilVisible(
            find.text('Factory Reset Lokal'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text('Factory Reset Lokal'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Factory Reset Lokal'));
          await tester.pumpAndSettle();
          expect(find.text('Factory Reset Lokal?'), findsOneWidget);
          await tester.tap(find.text('Lanjutkan'));
          await tester.pumpAndSettle();

          expect(find.text('Konfirmasi Terakhir'), findsOneWidget);
          await tester.enterText(find.byType(TextField).last, 'RESET');
          await tester.tap(find.text('Hapus Permanen'));
          await tester.pumpAndSettle();

          expect((await db.fetchFeedActivities()).isEmpty, isTrue);
          expect(
            await SecureCookieStore(kvStore).loadSession(),
            isNull,
          );
          expect(cookieExtractor.cleared, isTrue);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(Duration.zero);
          await tester.runAsync(() async {
            await db.close();
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          });
        }
      },
    );
  });
}

