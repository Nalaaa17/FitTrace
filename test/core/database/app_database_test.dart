import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';

ParsedActivity _sampleActivity({
  int? garminActivityId,
  String title = 'Easy 5K',
  double distanceMeters = 5000,
  int movingSec = 1500,
}) {
  final start = DateTime.utc(2026, 11, 12, 0, 0);
  return ParsedActivity(
    garminActivityId: garminActivityId,
    title: title,
    sportType: SportType.run,
    startTimeUtc: start,
    utcOffsetSeconds: 7 * 3600,
    durationTotalSec: movingSec + 20,
    durationMovingSec: movingSec,
    distanceMeters: distanceMeters,
    avgPaceSecPerKm: movingSec / (distanceMeters / 1000.0),
    avgHeartRate: 152,
    maxHeartRate: 171,
    avgCadence: 174,
    totalElevationGainM: 35,
    totalElevationLossM: 32,
    caloriesKcal: 320,
    isIndoor: false,
    hasGpsTrack: true,
    gpsQuality: GpsQuality.good,
    splitPacesSecPerKm: const <int>[300, 300, 300, 300, 300],
    zoneDurationsSec: const <int>[60, 400, 700, 280, 60],
    trackPoints: <ParsedTrackPoint>[
      ParsedTrackPoint(
        timestampUtc: start,
        latitudeDeg: -6.2,
        longitudeDeg: 106.8,
        altitudeM: 12,
        speedMps: 3.3,
        distanceMeters: 0,
        heartRateBpm: 135,
        cadenceRpm: 170,
        hrZone: 2,
      ),
      ParsedTrackPoint(
        timestampUtc: start.add(const Duration(seconds: 300)),
        latitudeDeg: -6.208,
        longitudeDeg: 106.805,
        altitudeM: 15,
        speedMps: 3.35,
        distanceMeters: 1000,
        heartRateBpm: 154,
        cadenceRpm: 174,
        hrZone: 3,
      ),
    ],
    lapSplits: const <ParsedLapSplit>[
      ParsedLapSplit(
        splitIndex: 0,
        distanceMeters: 1000,
        durationSec: 300,
        avgPaceSecPerKm: 300,
        avgHeartRate: 145,
        avgCadence: 172,
        elevationDeltaM: 3,
      ),
    ],
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase schema & CRUD', () {
    test('seeds singleton preferences with ADR-003 defaults', () async {
      final prefs = await db.getPreferences();

      expect(prefs.id, 1);
      expect(prefs.themeMode, 'dark');
      expect(prefs.unitSystem, 'metric');
      expect(prefs.backgroundSyncEnabled, isTrue);
      expect(prefs.backgroundSyncWifiOnly, isFalse);
      expect(prefs.backgroundSyncRequireCharging, isFalse);
      expect(prefs.hrZoneThresholds, const <int>[60, 70, 80, 90]);
    });

    test('validates schema v2 custom unique indexes and foreign keys', () async {
      expect(db.schemaVersion, 2);

      final fkRow = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(fkRow.data.values.first, 1);

      final indexRows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name IN ('idx_activities_garmin_id_unique', 'idx_best_efforts_act_dist');",
          )
          .get();
      expect(indexRows, hasLength(2));
    });

    test('allows multiple manual imports with null garminActivityId', () async {
      final id1 = await db.insertParsedActivity(
        parsed: _sampleActivity(garminActivityId: null, title: 'Manual 1'),
        source: ActivitySource.manualImport,
        syncStatus: SyncStatus.localOnly,
        fitFileHash: 'hash_manual_1',
      );
      final id2 = await db.insertParsedActivity(
        parsed: _sampleActivity(garminActivityId: null, title: 'Manual 2'),
        source: ActivitySource.manualImport,
        syncStatus: SyncStatus.localOnly,
        fitFileHash: 'hash_manual_2',
      );

      expect(id1, isPositive);
      expect(id2, greaterThan(id1));
    });

    test('rejects duplicate non-null garminActivityId', () async {
      await db.insertParsedActivity(
        parsed: _sampleActivity(garminActivityId: 987654321),
        source: ActivitySource.garminSync,
        syncStatus: SyncStatus.synced,
        fitFileHash: 'hash_garmin_1',
      );

      expect(
        () => db.insertParsedActivity(
          parsed: _sampleActivity(garminActivityId: 987654321),
          source: ActivitySource.garminSync,
          syncStatus: SyncStatus.synced,
          fitFileHash: 'hash_garmin_2',
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('inserts and cascade-deletes trackpoints and lap splits', () async {
      final activityId = await db.insertParsedActivity(
        parsed: _sampleActivity(garminActivityId: 555),
        source: ActivitySource.garminSync,
        syncStatus: SyncStatus.synced,
        fitFileHash: 'hash_555',
      );

      final pointsBefore = await db.getTrackPointsForActivity(activityId);
      final splitsBefore = await db.getLapSplitsForActivity(activityId);
      expect(pointsBefore, hasLength(2));
      expect(splitsBefore, hasLength(1));

      final deleted = await db.deleteActivityById(activityId);
      expect(deleted, 1);

      final pointsAfter = await db.getTrackPointsForActivity(activityId);
      final splitsAfter = await db.getLapSplitsForActivity(activityId);
      expect(pointsAfter, isEmpty);
      expect(splitsAfter, isEmpty);
    });

    test('aggregates distance, moving time, and pace in SQLite', () async {
      await db.insertParsedActivity(
        parsed: _sampleActivity(
          garminActivityId: 1,
          distanceMeters: 5000,
          movingSec: 1500,
        ),
        source: ActivitySource.garminSync,
        syncStatus: SyncStatus.synced,
        fitFileHash: 'h1',
      );
      await db.insertParsedActivity(
        parsed: _sampleActivity(
          garminActivityId: 2,
          distanceMeters: 10000,
          movingSec: 3300,
        ),
        source: ActivitySource.garminSync,
        syncStatus: SyncStatus.synced,
        fitFileHash: 'h2',
      );

      final stats = await db.getAggregateStats();
      expect(stats.activityCount, 2);
      expect(stats.totalDistanceMeters, 15000);
      expect(stats.totalMovingDurationSec, 4800);
      expect(stats.avgPaceSecPerKm, closeTo(320.0, 0.01));
    });

    test('updates user preferences singleton', () async {
      await db.updatePreferences(
        const UserPreferencesTableCompanion(
          themeMode: Value('light'),
          backgroundSyncWifiOnly: Value(true),
        ),
      );

      final prefs = await db.getPreferences();
      expect(prefs.themeMode, 'light');
      expect(prefs.backgroundSyncWifiOnly, isTrue);
    });
  });
}

