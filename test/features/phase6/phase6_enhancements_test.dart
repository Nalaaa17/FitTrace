import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/backup/application/backup_providers.dart';
import 'package:fit_trace/features/backup/data/backup_reminder_service.dart';
import 'package:fit_trace/features/backup/data/backup_restore_service.dart';
import 'package:fit_trace/features/backup/data/csv_export_service.dart';
import 'package:fit_trace/features/feed/data/thumbnail_cache_service.dart';
import 'package:fit_trace/features/feed/presentation/feed_screen.dart';
import 'package:fit_trace/features/garmin_sync/application/garmin_sync_engine.dart';
import 'package:fit_trace/features/garmin_sync/application/garmin_sync_providers.dart';
import 'package:fit_trace/features/garmin_sync/data/background_sync_scheduler.dart';
import 'package:fit_trace/features/garmin_sync/data/secure_cookie_store.dart';
import 'package:fit_trace/features/garmin_sync/data/webview_cookie_extractor.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_connect_client.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session_refresher.dart';
import 'package:fit_trace/features/import/application/import_providers.dart';
import 'package:fit_trace/features/import/data/fit_archive_storage.dart';
import 'package:fit_trace/features/import/data/fit_import_pipeline.dart';
import 'package:fit_trace/features/stats/application/stats_providers.dart';
import 'package:fit_trace/features/stats/presentation/stats_screen.dart';
import 'package:fit_trace/features/story_share/data/story_image_cache_service.dart';
import 'package:fit_trace/features/story_share/domain/story_template_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';

Uint8List _encodeFitRun({
  required DateTime startUtc,
  required int distanceMeters,
  required int durationSec,
  int heartRate = 154,
}) {
  final builder = FitFileBuilder(autoDefine: true);
  builder.add(
    FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.garmin.value
      ..timeCreated = startUtc.millisecondsSinceEpoch,
  );

  const steps = 60;
  final stepSec = durationSec / steps;
  final stepDist = distanceMeters / steps;
  final speed = distanceMeters / durationSec;

  for (var i = 0; i <= steps; i++) {
    final t = startUtc.add(Duration(milliseconds: (i * stepSec * 1000).round()));
    final dist = i * stepDist;
    builder.add(
      RecordMessage()
        ..timestamp = t.millisecondsSinceEpoch
        ..distance = dist
        ..enhancedSpeed = speed
        ..enhancedAltitude = 15.0 + (i % 5)
        ..cadence = 88
        ..heartRate = heartRate
        ..positionLat = -6.2000 + dist / 111111.0
        ..positionLong = 106.8000,
    );
  }

  builder.add(
    SessionMessage()
      ..timestamp = startUtc.add(Duration(seconds: durationSec)).millisecondsSinceEpoch
      ..startTime = startUtc.millisecondsSinceEpoch
      ..sport = Sport.running
      ..subSport = SubSport.street
      ..totalElapsedTime = durationSec.toDouble()
      ..totalTimerTime = durationSec.toDouble()
      ..totalDistance = distanceMeters.toDouble()
      ..totalCalories = 420,
  );

  return builder.build().toBytes();
}

class _IncrementalFakeClient implements GarminConnectClient {
  List<GarminActivitySummary> activities = <GarminActivitySummary>[];
  final Map<int, Uint8List> payloads = <int, Uint8List>{};
  final List<int> downloadedIds = <int>[];

  @override
  Future<SessionProbeResult> probeSession() async =>
      const SessionProbeResult(status: ProbeStatus.valid, statusCode: 200);

  @override
  Future<List<GarminActivitySummary>> fetchActivitiesPage({
    required int start,
    int limit = 50,
  }) async {
    if (start >= activities.length) return const <GarminActivitySummary>[];
    final end = (start + limit).clamp(0, activities.length);
    return activities.sublist(start, end);
  }

  @override
  Stream<List<int>> downloadFitStream(int garminActivityId) async* {
    downloadedIds.add(garminActivityId);
    yield payloads[garminActivityId]!;
  }
}

class _NoopRefresher implements GarminSessionRefresher {
  @override
  Future<RefreshOutcome> attemptSilentRefresh() async =>
      RefreshOutcome.expiredOrLoginRequired;
}

class _MemoryKvStore implements SecureKeyValueStore {
  final Map<String, String> _map = <String, String>{};
  @override
  Future<void> delete(String key) async => _map.remove(key);
  @override
  Future<String?> read(String key) async => _map[key];
  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

class _NoopCookieExtractor implements WebViewCookieExtractor {
  @override
  Future<void> clearAllWebViewCookies() async {}

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

class _RecordingNotificationDispatcher implements LocalNotificationDispatcher {
  int count = 0;
  @override
  Future<void> showMonthlyBackupReminder({
    required String title,
    required String body,
  }) async {
    count++;
  }
}

class _NoopBackgroundSyncScheduler implements BackgroundSyncScheduler {
  @override
  Future<void> applySchedule(BackgroundSyncScheduleConfig config) async {}
}

void main() {
  group('Phase 6 Background Sync & Incremental Sync (M1-10, M1-11, ADR-003)', () {
    test('BackgroundSyncScheduleConfig uses ADR-003 cellular+non-charging defaults & clamps <15m', () {
      final now = DateTime.utc(2026, 11, 12);
      final defaultPrefs = UserPreference(
        id: 1,
        garminLoggedIn: true,
        lastSyncAt: now,
        lastActivityStartTime: null,
        birthDate: null,
        hrMaxManual: null,
        hrZoneThresholds: const <int>[60, 70, 80, 90],
        themeMode: 'dark',
        unitSystem: 'metric',
        weeklyMonthlyToggle: 'weekly',
        watermarkEnabled: true,
        defaultTemplateId: 'routeGlow',
        backgroundSyncEnabled: true,
        backgroundSyncWifiOnly: false,
        backgroundSyncRequireCharging: false,
        backgroundSyncIntervalMinutes: 5, // Below Android 15m minimum
        onboardingCompleted: true,
        lastBackupAt: null,
        backupReminderEnabled: true,
        lastBackupReminderAt: null,
      );

      final cfg = BackgroundSyncScheduleConfig.fromPreferences(defaultPrefs);
      expect(cfg.enabled, isTrue);
      expect(cfg.intervalMinutes, 15);
      expect(cfg.wifiOnly, isFalse);
      expect(cfg.requireCharging, isFalse);
      expect(cfg.androidNetworkType, 'CONNECTED');

      final saverPrefs = defaultPrefs.copyWith(
        backgroundSyncWifiOnly: true,
        backgroundSyncRequireCharging: true,
        backgroundSyncIntervalMinutes: 60,
      );
      final saverCfg = BackgroundSyncScheduleConfig.fromPreferences(saverPrefs);
      expect(saverCfg.androidNetworkType, 'UNMETERED');
      expect(saverCfg.requireCharging, isTrue);
      expect(saverCfg.intervalMinutes, 60);
    });

    test('Incremental sync fetches only startTime > lastActivityStartTime - 24h and preserves custom title', () async {
      final tempDir = await Directory.systemTemp.createTemp('fittrace_p6_sync_');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final anchor = DateTime.utc(2026, 11, 10, 8, 0);
        await db.updatePreferences(
          UserPreferencesTableCompanion(
            garminLoggedIn: const Value(true),
            lastActivityStartTime: Value(anchor),
          ),
        );

        // 1) Old activity strictly before anchor - 24h (Nov 8) -> MUST NOT download.
        // 2) Overlap window activity within 24h (Nov 9 12:00) -> MUST download.
        // 3) New activity after anchor (Nov 11 06:00) -> MUST download.
        final oldId = 101;
        final windowId = 102;
        final newId = 103;

        final fitOld = _encodeFitRun(
          startUtc: DateTime.utc(2026, 11, 8, 6, 0),
          distanceMeters: 5000,
          durationSec: 1500,
        );
        final fitWindow = _encodeFitRun(
          startUtc: DateTime.utc(2026, 11, 9, 12, 0),
          distanceMeters: 5000,
          durationSec: 1400,
        );
        final fitNew = _encodeFitRun(
          startUtc: DateTime.utc(2026, 11, 11, 6, 0),
          distanceMeters: 10000,
          durationSec: 2700,
        );

        // Pre-insert windowId locally and rename it locally; Garmin re-sync must preserve custom title.
        final preParsed = const GarminFitParserEngine().parseFitBytes(
          fitWindow,
          hrZoneConfig: HrZoneConfig.resolve(),
          garminActivityId: windowId,
          fallbackTitle: 'Original Garmin Name',
        );
        final localId = await db.insertParsedActivity(
          parsed: preParsed,
          source: ActivitySource.garminSync,
          syncStatus: SyncStatus.synced,
          fitFileHash: 'old_hash_trigger_update',
        );
        await db.renameActivity(
          activityId: localId,
          newTitle: 'Custom Race Name',
        );

        final client = _IncrementalFakeClient()
          ..activities = <GarminActivitySummary>[
            GarminActivitySummary(
              activityId: newId,
              activityName: 'New 10K',
              startTimeUtc: DateTime.utc(2026, 11, 11, 6, 0),
              sportType: SportType.run,
            ),
            GarminActivitySummary(
              activityId: windowId,
              activityName: 'Garmin Overwrite Attempt',
              startTimeUtc: DateTime.utc(2026, 11, 9, 12, 0),
              updatedAtUtc: DateTime.now().toUtc().add(
                const Duration(minutes: 5),
              ),
              sportType: SportType.run,
            ),
            GarminActivitySummary(
              activityId: oldId,
              activityName: 'Too Old Outside 24h',
              startTimeUtc: DateTime.utc(2026, 11, 8, 6, 0),
              sportType: SportType.run,
            ),
          ]
          ..payloads[oldId] = fitOld
          ..payloads[windowId] = fitWindow
          ..payloads[newId] = fitNew;

        final pipeline = FitImportPipeline(
          db: db,
          archiveStorage: FitArchiveStorage(rootDirectoryResolver: () async => tempDir),
          tempDirectory: tempDir,
        );
        final engine = GarminSyncEngine(
          db: db,
          client: client,
          refresher: _NoopRefresher(),
          importPipeline: pipeline,
        );

        final result = await engine.syncNow();
        expect(result.importedCount, 1); // newId
        expect(result.updatedCount, 1); // windowId re-downloaded
        expect(result.skippedCount, 1); // oldId skipped before download
        expect(client.downloadedIds.contains(oldId), isFalse);
        expect(client.downloadedIds.contains(newId), isTrue);

        final refreshedWindowRow = await db.getActivityById(localId);
        expect(refreshedWindowRow!.title, 'Custom Race Name');
        expect(refreshedWindowRow.hasCustomTitle, isTrue);
      } finally {
        await db.close();
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('Phase 6 Analytics, Story Presets, Backup Reminder & CSV (M2-10..M5-06)', () {
    test('Best Effort PRs, Consistency Heatmap, Story Preset JSON & CSV Export work end-to-end', () async {
      final tempDir = await Directory.systemTemp.createTemp('fittrace_p6_data_');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final day1 = DateTime.utc(2026, 11, 10, 6, 0);
        final day2 = DateTime.utc(2026, 11, 11, 6, 0);
        final day3 = DateTime.utc(2026, 11, 12, 6, 0);

        final p1 = const GarminFitParserEngine().parseFitBytes(
          _encodeFitRun(startUtc: day1, distanceMeters: 5200, durationSec: 1560),
          hrZoneConfig: HrZoneConfig.resolve(),
          fallbackTitle: 'Morning "Easy", Run',
        );
        final p2 = const GarminFitParserEngine().parseFitBytes(
          _encodeFitRun(startUtc: day2, distanceMeters: 10100, durationSec: 2500),
          hrZoneConfig: HrZoneConfig.resolve(),
          fallbackTitle: 'Fast 10K Tempo',
        );
        final p3 = const GarminFitParserEngine().parseFitBytes(
          _encodeFitRun(startUtc: day3, distanceMeters: 5050, durationSec: 1600),
          hrZoneConfig: HrZoneConfig.resolve(),
          fallbackTitle: 'Recovery 5K',
        );

        await db.insertParsedActivity(
          parsed: p1,
          source: ActivitySource.manualImport,
          syncStatus: SyncStatus.localOnly,
          fitFileHash: 'h1',
        );
        final id2 = await db.insertParsedActivity(
          parsed: p2,
          source: ActivitySource.manualImport,
          syncStatus: SyncStatus.localOnly,
          fitFileHash: 'h2',
        );
        await db.insertParsedActivity(
          parsed: p3,
          source: ActivitySource.manualImport,
          syncStatus: SyncStatus.localOnly,
          fitFileHash: 'h3',
        );

        // M2-10 PR detection across multiple activities.
        final prs = await db.getAllTimeBestEffortPrs();
        expect(prs['5k']?.activityId, id2); // 10K tempo was fastest per-km -> faster 5K split!
        expect(prs['10k']?.activityId, id2);

        // M3-09 Streak heatmap across 3 consecutive local days.
        final rows = await db.getValidActivitiesSince(
          DateTime.utc(2026, 11, 1),
        );
        final heatmap = ConsistencyHeatmapData.fromActivities(
          activities: rows,
          todayLocal: DateTime(2026, 11, 12),
        );
        expect(heatmap.currentStreakDays, 3);
        expect(heatmap.longestStreakDays, 3);
        expect(heatmap.activeDaysCount, 3);

        // M4-09 Story preset save + deserialize.
        const customCfg = StoryEditorConfig(
          templateId: StoryTemplateId.minimalist,
          minimalistDark: false,
          stickerOffset: Offset(12, -24),
          stickerScale: 1.25,
          showWatermark: false,
          alignment: StoryTextAlignment.center,
        );
        final presetId = await db.saveStoryPreset(
          name: 'Clean Center Light',
          configJson: customCfg.toLayoutJsonString(),
        );
        final presets = await db.select(db.storyPresets).get();
        expect(presets.single.id, presetId);
        final restoredCfg =
            StoryEditorConfig.fromLayoutJsonString(presets.single.configJson);
        expect(restoredCfg.templateId, StoryTemplateId.minimalist);
        expect(restoredCfg.minimalistDark, isFalse);
        expect(restoredCfg.stickerOffset, const Offset(12, -24));
        expect(restoredCfg.showWatermark, isFalse);
        expect(restoredCfg.alignment, StoryTextAlignment.center);

        // Phase 6 CSV export + quote/comma RFC-4180 escaping.
        final csvPayload =
            await CsvExportService(db: db).buildActivitiesCsv(
          exportedAtLocal: DateTime(2026, 11, 12),
        );
        expect(csvPayload.rowCount, 3);
        final csvText = utf8.decode(csvPayload.bytes);
        expect(csvText, contains('"Morning ""Easy"", Run"'));
        expect(csvText, contains('Fast 10K Tempo'));

        // M5-05 VACUUM & M5-06 Monthly backup reminder.
        final backupService = BackupRestoreService(
          db: db,
          archiveStorage: FitArchiveStorage(rootDirectoryResolver: () async => tempDir),
          thumbnailCache: ThumbnailCacheService(
            cacheDirectoryResolver: () async => tempDir,
          ),
          storyCache: StoryImageCacheService(
            cacheDirectoryResolver: () async => tempDir,
          ),
          cookieStore: SecureCookieStore(_MemoryKvStore()),
          cookieExtractor: _NoopCookieExtractor(),
          appDocumentsResolver: () async => tempDir,
          appCacheResolver: () async => tempDir,
        );
        final compactRes = await backupService.compactDatabase();
        expect(compactRes.beforeBytes, greaterThanOrEqualTo(0));

        await db.updatePreferences(
          UserPreferencesTableCompanion(
            lastBackupAt: Value(DateTime.utc(2026, 9, 1)),
          ),
        );
        final notif = _RecordingNotificationDispatcher();
        final reminderService = BackupReminderService(
          db: db,
          notificationDispatcher: notif,
          nowUtc: () => DateTime.utc(2026, 11, 12),
        );
        final due = await reminderService.checkAndNotifyIfDue();
        expect(due.isDue, isTrue);
        expect(due.daysSinceBackup, greaterThan(30));
        expect(notif.count, 1);

        await reminderService.snoozeReminder();
        final snoozed = await reminderService.checkAndNotifyIfDue();
        expect(snoozed.isDue, isFalse);
      } finally {
        await db.close();
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      }
    });

    test('Feed search filter, activity rename, and PR/VDOT/Heatmap analytics work end-to-end', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        await db.updatePreferences(
          const UserPreferencesTableCompanion(onboardingCompleted: Value(true)),
        );
        final parsed1 = const GarminFitParserEngine().parseFitBytes(
          _encodeFitRun(
            startUtc: DateTime.utc(2026, 11, 11, 5, 0),
            distanceMeters: 5200,
            durationSec: 1350,
          ),
          hrZoneConfig: HrZoneConfig.resolve(),
          fallbackTitle: 'Senayan Speed 5K',
        );
        final parsed2 = const GarminFitParserEngine().parseFitBytes(
          _encodeFitRun(
            startUtc: DateTime.utc(2026, 11, 12, 5, 0),
            distanceMeters: 6000,
            durationSec: 2100,
          ),
          hrZoneConfig: HrZoneConfig.resolve(),
          fallbackTitle: 'Monas Easy Jog',
        );
        final id1 = await db.insertParsedActivity(
          parsed: parsed1,
          source: ActivitySource.manualImport,
          syncStatus: SyncStatus.localOnly,
          fitFileHash: 'ui_h1',
        );
        final id2 = await db.insertParsedActivity(
          parsed: parsed2,
          source: ActivitySource.manualImport,
          syncStatus: SyncStatus.localOnly,
          fitFileHash: 'ui_h2',
        );

        // M3-08: Feed search filter in SQLite
        final searchSenayan = await db.fetchFeedActivities(
          filter: const ActivityFeedFilter(searchQuery: 'Senayan'),
          limit: 10,
          offset: 0,
        );
        expect(searchSenayan.map((a) => a.title), contains('Senayan Speed 5K'));
        expect(searchSenayan.map((a) => a.title), isNot(contains('Monas Easy Jog')));

        // M3-08: Activity local rename preserves custom title
        await db.renameActivity(activityId: id1, newTitle: 'GBK Tempo Evening');
        final renamed = await db.getActivityById(id1);
        expect(renamed?.title, 'GBK Tempo Evening');
        expect(renamed?.hasCustomTitle, isTrue);

        // M2-10: Best efforts detected for 5K run
        final prs = await db.getAllTimeBestEffortPrs();
        expect(prs.containsKey('5k'), isTrue);
        expect(prs['5k']!.activityId, id1);

        // M2-11: VO2max predictor
        final vdot = VdotPredictor.computeVdot(
          distanceMeters: 5000,
          durationSec: prs['5k']!.durationSec,
        );
        expect(vdot, isNotNull);
        expect(vdot!, greaterThan(40.0));
        final predictions = const VdotPredictor().predictRaces(vdot);
        expect(predictions, isNotEmpty);
        expect(predictions.first.predictedDurationSec, greaterThan(0));

        // M3-09: 20-week heatmap consistency stats
        final sinceUtc = DateTime.utc(2026, 11, 12).subtract(const Duration(days: 140));
        final heatmapActivities = await db.getValidActivitiesSince(sinceUtc);
        final heatmap = ConsistencyHeatmapData.fromActivities(
          activities: heatmapActivities,
          weekColumns: 20,
          todayLocal: DateTime(2026, 11, 12),
        );
        expect(heatmap.weeks.length, 20);
        expect(heatmap.activeDaysCount, 2);
      } finally {
        await db.close();
      }
    });
  });
}
