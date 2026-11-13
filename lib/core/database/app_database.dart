import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Aggregated summary metrics computed directly in SQLite (PRD M3-07, ADR-001).
class ActivityAggregateStats {
  const ActivityAggregateStats({
    required this.activityCount,
    required this.totalDistanceMeters,
    required this.totalMovingDurationSec,
    required this.avgPaceSecPerKm,
  });

  final int activityCount;
  final double totalDistanceMeters;
  final int totalMovingDurationSec;
  final double avgPaceSecPerKm;
}

/// All-time Personal Record entry for a standard distance (`PRD M2-10`).
class BestEffortPrRecord {
  const BestEffortPrRecord({
    required this.distanceKey,
    required this.activityId,
    required this.activityTitle,
    required this.startTimeUtc,
    required this.utcOffsetSeconds,
    required this.targetDistanceMeters,
    required this.durationSec,
    required this.paceSecPerKm,
  });

  final String distanceKey;
  final int activityId;
  final String activityTitle;
  final DateTime startTimeUtc;
  final int utcOffsetSeconds;
  final double targetDistanceMeters;
  final int durationSec;
  final double paceSecPerKm;
}

/// Filter criteria for the paginated activity feed (PRD M3-02, M3-08).
class ActivityFeedFilter {
  const ActivityFeedFilter({
    this.startDateUtc,
    this.endDateUtc,
    this.sportTypeCode,
    this.sourceKey,
    this.searchQuery,
  });

  final DateTime? startDateUtc;
  final DateTime? endDateUtc;
  final int? sportTypeCode;
  final String? sourceKey;
  final String? searchQuery;

  bool get isEmpty =>
      startDateUtc == null &&
      endDateUtc == null &&
      sportTypeCode == null &&
      sourceKey == null &&
      (searchQuery == null || searchQuery!.trim().isEmpty);

  ActivityFeedFilter copyWith({
    DateTime? Function()? startDateUtc,
    DateTime? Function()? endDateUtc,
    int? Function()? sportTypeCode,
    String? Function()? sourceKey,
    String? Function()? searchQuery,
  }) {
    return ActivityFeedFilter(
      startDateUtc: startDateUtc != null ? startDateUtc() : this.startDateUtc,
      endDateUtc: endDateUtc != null ? endDateUtc() : this.endDateUtc,
      sportTypeCode:
          sportTypeCode != null ? sportTypeCode() : this.sportTypeCode,
      sourceKey: sourceKey != null ? sourceKey() : this.sourceKey,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityFeedFilter &&
          other.startDateUtc == startDateUtc &&
          other.endDateUtc == endDateUtc &&
          other.sportTypeCode == sportTypeCode &&
          other.sourceKey == sourceKey &&
          other.searchQuery == searchQuery;

  @override
  int get hashCode => Object.hash(
        startDateUtc,
        endDateUtc,
        sportTypeCode,
        sourceKey,
        searchQuery,
      );
}

@DriftDatabase(
  tables: <Type>[
    Activities,
    TrackPoints,
    LapSplits,
    UserPreferencesTable,
    ActivityBestEfforts,
    StoryPresets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory or custom executor constructor used for automated unit tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _ensureCustomIndexes();
          await _seedDefaultPreferences();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await _addColumnIfMissing(
              table: 'activities',
              column: 'has_custom_title',
              definition: 'INTEGER NOT NULL DEFAULT 0',
            );
            await m.createTable(activityBestEfforts);
            await m.createTable(storyPresets);
            await _addColumnIfMissing(
              table: 'user_preferences',
              column: 'background_sync_interval_minutes',
              definition: 'INTEGER NOT NULL DEFAULT 15',
            );
            await _addColumnIfMissing(
              table: 'user_preferences',
              column: 'backup_reminder_enabled',
              definition: 'INTEGER NOT NULL DEFAULT 1',
            );
            await _addColumnIfMissing(
              table: 'user_preferences',
              column: 'last_backup_reminder_at',
              definition: 'INTEGER',
            );
          }
          await _ensureCustomIndexes();
          await _seedDefaultPreferences();
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await _ensureCustomIndexes();
          await _seedDefaultPreferences();
        },
      );

  Future<void> _addColumnIfMissing({
    required String table,
    required String column,
    required String definition,
  }) async {
    final rows = await customSelect('PRAGMA table_info($table);').get();
    final exists = rows.any((row) => row.read<String>('name') == column);
    if (!exists) {
      await customStatement(
        'ALTER TABLE $table ADD COLUMN $column $definition;',
      );
    }
  }

  Future<void> _ensureCustomIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_activities_garmin_id_unique '
      'ON activities (garmin_activity_id) '
      'WHERE garmin_activity_id IS NOT NULL;',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_best_efforts_act_dist '
      'ON activity_best_efforts (activity_id, distance_key);',
    );
  }

  Future<void> _seedDefaultPreferences() async {
    await into(userPreferencesTable).insert(
      UserPreferencesTableCompanion.insert(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Persists an activity along with all trackpoints and splits in a single
  /// atomic SQLite transaction (PRD §2.3 step 4).
  Future<int> insertParsedActivity({
    required ParsedActivity parsed,
    required ActivitySource source,
    required SyncStatus syncStatus,
    required String fitFileHash,
    String? originalFitPath,
  }) {
    final now = DateTime.now().toUtc();
    return transaction(() async {
      final activityId = await into(activities).insert(
        ActivitiesCompanion.insert(
          garminActivityId: Value(parsed.garminActivityId),
          title: parsed.title,
          sportType: parsed.sportType.code,
          startTimeUtc: parsed.startTimeUtc.toUtc(),
          utcOffsetSeconds: parsed.utcOffsetSeconds,
          durationTotalSec: parsed.durationTotalSec,
          durationMovingSec: parsed.durationMovingSec,
          distanceMeters: parsed.distanceMeters,
          avgPaceSecPerKm: parsed.avgPaceSecPerKm,
          avgHeartRate: Value(parsed.avgHeartRate),
          maxHeartRate: Value(parsed.maxHeartRate),
          avgCadence: Value(parsed.avgCadence),
          totalElevationGainM: parsed.totalElevationGainM,
          totalElevationLossM: parsed.totalElevationLossM,
          caloriesKcal: parsed.caloriesKcal,
          isIndoor: Value(parsed.isIndoor),
          hasGpsTrack: Value(parsed.hasGpsTrack),
          gpsQuality: Value(parsed.gpsQuality.storageKey),
          source: source.storageKey,
          syncStatus: syncStatus.storageKey,
          originalFitPath: Value(originalFitPath),
          fitFileHash: fitFileHash,
          splitPacesSecPerKm: parsed.splitPacesSecPerKm,
          zoneDurationsSec: parsed.zoneDurationsSec,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _insertChildren(activityId: activityId, parsed: parsed);
      return activityId;
    });
  }

  /// Replaces an existing activity (used for retry parse or Garmin re-sync)
  /// along with its trackpoints and lap splits in one atomic transaction.
  ///
  /// Locally customized titles (`hasCustomTitle == true`) are preserved (PRD M3-08).
  Future<int> replaceParsedActivity({
    required int existingActivityId,
    required ParsedActivity parsed,
    required ActivitySource source,
    required SyncStatus syncStatus,
    required String fitFileHash,
    String? originalFitPath,
  }) {
    final now = DateTime.now().toUtc();
    return transaction(() async {
      final existingRow = await getActivityById(existingActivityId);
      final keepCustomTitle = existingRow?.hasCustomTitle ?? false;

      await (delete(trackPoints)
            ..where((t) => t.activityId.equals(existingActivityId)))
          .go();
      await (delete(lapSplits)
            ..where((t) => t.activityId.equals(existingActivityId)))
          .go();
      await (delete(activityBestEfforts)
            ..where((t) => t.activityId.equals(existingActivityId)))
          .go();

      await (update(activities)
            ..where((t) => t.id.equals(existingActivityId)))
          .write(
        ActivitiesCompanion(
          garminActivityId: Value(parsed.garminActivityId),
          title: Value(
            keepCustomTitle ? existingRow!.title : parsed.title,
          ),
          sportType: Value(parsed.sportType.code),
          startTimeUtc: Value(parsed.startTimeUtc.toUtc()),
          utcOffsetSeconds: Value(parsed.utcOffsetSeconds),
          durationTotalSec: Value(parsed.durationTotalSec),
          durationMovingSec: Value(parsed.durationMovingSec),
          distanceMeters: Value(parsed.distanceMeters),
          avgPaceSecPerKm: Value(parsed.avgPaceSecPerKm),
          avgHeartRate: Value(parsed.avgHeartRate),
          maxHeartRate: Value(parsed.maxHeartRate),
          avgCadence: Value(parsed.avgCadence),
          totalElevationGainM: Value(parsed.totalElevationGainM),
          totalElevationLossM: Value(parsed.totalElevationLossM),
          caloriesKcal: Value(parsed.caloriesKcal),
          isIndoor: Value(parsed.isIndoor),
          hasGpsTrack: Value(parsed.hasGpsTrack),
          gpsQuality: Value(parsed.gpsQuality.storageKey),
          source: Value(source.storageKey),
          syncStatus: Value(syncStatus.storageKey),
          originalFitPath: Value(originalFitPath),
          fitFileHash: Value(fitFileHash),
          splitPacesSecPerKm: Value(parsed.splitPacesSecPerKm),
          zoneDurationsSec: Value(parsed.zoneDurationsSec),
          updatedAt: Value(now),
        ),
      );

      await _insertChildren(
        activityId: existingActivityId,
        parsed: parsed,
      );
      return existingActivityId;
    });
  }

  /// Inserts a placeholder record when a FIT file fails CRC/parsing (§7)
  /// so batch imports are never blocked and users can retry or delete it.
  Future<int> insertFailedParseActivity({
    required String title,
    required ActivitySource source,
    required String fitFileHash,
    int? garminActivityId,
    String? originalFitPath,
  }) {
    final now = DateTime.now().toUtc();
    return into(activities).insert(
      ActivitiesCompanion.insert(
        garminActivityId: Value(garminActivityId),
        title: title,
        sportType: SportType.other.code,
        startTimeUtc: now,
        utcOffsetSeconds: now.timeZoneOffset.inSeconds,
        durationTotalSec: 0,
        durationMovingSec: 0,
        distanceMeters: 0,
        avgPaceSecPerKm: 0,
        totalElevationGainM: 0,
        totalElevationLossM: 0,
        caloriesKcal: 0,
        isIndoor: const Value(true),
        hasGpsTrack: const Value(false),
        gpsQuality: Value(GpsQuality.none.storageKey),
        source: source.storageKey,
        syncStatus: SyncStatus.parseFailed.storageKey,
        originalFitPath: Value(originalFitPath),
        fitFileHash: fitFileHash,
        splitPacesSecPerKm: const <int>[],
        zoneDurationsSec: const <int>[0, 0, 0, 0, 0],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _insertChildren({
    required int activityId,
    required ParsedActivity parsed,
  }) async {
    if (parsed.trackPoints.isNotEmpty) {
      await batch((b) {
        b.insertAll(
          trackPoints,
          parsed.trackPoints.map(
            (pt) => TrackPointsCompanion.insert(
              activityId: activityId,
              timestampUtc: pt.timestampUtc.toUtc(),
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

    if (parsed.lapSplits.isNotEmpty) {
      await batch((b) {
        b.insertAll(
          lapSplits,
          parsed.lapSplits.map(
            (split) => LapSplitsCompanion.insert(
              activityId: activityId,
              splitIndex: split.splitIndex,
              distanceMeters: split.distanceMeters,
              durationSec: split.durationSec,
              avgPaceSecPerKm: split.avgPaceSecPerKm,
              avgHeartRate: Value(split.avgHeartRate),
              avgCadence: Value(split.avgCadence),
              elevationDeltaM: split.elevationDeltaM,
            ),
          ),
        );
      });
    }

    if (parsed.bestEfforts.isNotEmpty) {
      await _insertBestEfforts(
        activityId: activityId,
        efforts: parsed.bestEfforts,
      );
    }
  }

  Future<void> _insertBestEfforts({
    required int activityId,
    required List<BestEffortSegment> efforts,
  }) async {
    if (efforts.isEmpty) return;
    await batch((b) {
      b.insertAll(
        activityBestEfforts,
        efforts.map(
          (e) => ActivityBestEffortsCompanion.insert(
            activityId: activityId,
            distanceKey: e.distance.storageKey,
            targetDistanceMeters: e.distance.distanceMeters,
            durationSec: e.durationSec,
            paceSecPerKm: e.paceSecPerKm,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<ActivityRecord?> getActivityById(int activityId) {
    return (select(activities)..where((t) => t.id.equals(activityId)))
        .getSingleOrNull();
  }

  Stream<ActivityRecord?> watchActivityById(int activityId) {
    return (select(activities)..where((t) => t.id.equals(activityId)))
        .watchSingleOrNull();
  }

  Future<ActivityRecord?> findByGarminActivityId(int garminActivityId) {
    return (select(activities)
          ..where((t) => t.garminActivityId.equals(garminActivityId)))
        .getSingleOrNull();
  }

  Future<ActivityRecord?> findByFitFileHash(String fitFileHash) {
    return (select(activities)..where((t) => t.fitFileHash.equals(fitFileHash)))
        .getSingleOrNull();
  }

  Future<List<ActivityRecord>> fetchFeedActivities({
    ActivityFeedFilter filter = const ActivityFeedFilter(),
    int limit = 30,
    int offset = 0,
  }) {
    final query = select(activities);
    query.where((t) {
      Expression<bool> expr = const Constant(true);
      if (filter.startDateUtc != null) {
        expr = expr &
            t.startTimeUtc.isBiggerOrEqualValue(filter.startDateUtc!.toUtc());
      }
      if (filter.endDateUtc != null) {
        expr = expr &
            t.startTimeUtc.isSmallerOrEqualValue(filter.endDateUtc!.toUtc());
      }
      if (filter.sportTypeCode != null) {
        expr = expr & t.sportType.equals(filter.sportTypeCode!);
      }
      if (filter.sourceKey != null) {
        expr = expr & t.source.equals(filter.sourceKey!);
      }
      final search = filter.searchQuery?.trim();
      if (search != null && search.isNotEmpty) {
        expr = expr & t.title.lower().contains(search.toLowerCase());
      }
      return expr;
    });
    query
      ..orderBy(<OrderingTerm Function(Activities)>[
        (t) => OrderingTerm.desc(t.startTimeUtc),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limit, offset: offset);
    return query.get();
  }

  /// Renames an activity locally and marks `hasCustomTitle = true` so Garmin
  /// re-syncs do not overwrite the user's title (PRD M3-08).
  Future<void> renameActivity({
    required int activityId,
    required String newTitle,
  }) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return (update(activities)..where((t) => t.id.equals(activityId))).write(
      ActivitiesCompanion(
        title: Value(trimmed),
        hasCustomTitle: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Emits whenever rows in `activities` are inserted, updated, or deleted.
  Stream<int> watchActivitiesMutationTick() {
    return customSelect(
      'SELECT COUNT(*) AS cnt, COALESCE(MAX(id), 0) AS max_id, '
      'COALESCE(MAX(updated_at), 0) AS max_upd FROM activities;',
      readsFrom: <ResultSetImplementation<HasResultSet, dynamic>>{activities},
    ).watchSingle().map(
          (row) => Object.hash(
            row.read<int>('cnt'),
            row.read<int>('max_id'),
            row.read<int>('max_upd'),
          ),
        );
  }

  /// Attaches a Garmin activity ID onto a previously imported local record
  /// whose SHA-256 matches, preventing duplicate feed rows (PRD M1-05).
  Future<void> linkGarminActivityId({
    required int activityId,
    required int garminActivityId,
    required ActivitySource source,
    required SyncStatus syncStatus,
  }) {
    return (update(activities)..where((t) => t.id.equals(activityId))).write(
      ActivitiesCompanion(
        garminActivityId: Value(garminActivityId),
        source: Value(source.storageKey),
        syncStatus: Value(syncStatus.storageKey),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Records or refreshes a placeholder when downloading `.FIT` from Garmin
  /// fails after retries (`syncFailed`, PRD M1-07). Valid synced rows are preserved.
  Future<int> upsertSyncFailedActivity({
    required int garminActivityId,
    required String title,
    SportType sportType = SportType.run,
    DateTime? startTimeUtc,
    int utcOffsetSeconds = 0,
    double distanceMeters = 0,
    int durationTotalSec = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await findByGarminActivityId(garminActivityId);
    if (existing != null) {
      if (SyncStatus.fromStorageKey(existing.syncStatus) == SyncStatus.synced) {
        return existing.id;
      }
      await (update(activities)..where((t) => t.id.equals(existing.id))).write(
        ActivitiesCompanion(
          title: Value(title),
          syncStatus: Value(SyncStatus.failed.storageKey),
          updatedAt: Value(now),
        ),
      );
      return existing.id;
    }

    final effectiveStart = (startTimeUtc ?? now).toUtc();
    return into(activities).insert(
      ActivitiesCompanion.insert(
        garminActivityId: Value(garminActivityId),
        title: title,
        sportType: sportType.code,
        startTimeUtc: effectiveStart,
        utcOffsetSeconds: utcOffsetSeconds,
        durationTotalSec: durationTotalSec,
        durationMovingSec: durationTotalSec,
        distanceMeters: distanceMeters,
        avgPaceSecPerKm: 0,
        totalElevationGainM: 0,
        totalElevationLossM: 0,
        caloriesKcal: 0,
        isIndoor: Value(sportType == SportType.treadmill),
        hasGpsTrack: const Value(false),
        gpsQuality: Value(GpsQuality.none.storageKey),
        source: ActivitySource.garminSync.storageKey,
        syncStatus: SyncStatus.failed.storageKey,
        fitFileHash: '',
        splitPacesSecPerKm: const <int>[],
        zoneDurationsSec: const <int>[0, 0, 0, 0, 0],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> clearOriginalFitPath(int activityId) {
    return (update(activities)..where((t) => t.id.equals(activityId))).write(
      const ActivitiesCompanion(originalFitPath: Value(null)),
    );
  }

  Stream<List<ActivityRecord>> watchFeedActivities({
    int limit = 30,
    int offset = 0,
  }) {
    return (select(activities)
          ..orderBy(<OrderingTerm Function(Activities)>[
            (t) => OrderingTerm.desc(t.startTimeUtc),
          ])
          ..limit(limit, offset: offset))
        .watch();
  }

  Future<List<TrackPointRecord>> getTrackPointsForActivity(
    int activityId, {
    int? limit,
    int offset = 0,
  }) {
    final query = select(trackPoints)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy(<OrderingTerm Function(TrackPoints)>[
        (t) => OrderingTerm.asc(t.timestampUtc),
      ]);
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    return query.get();
  }

  Future<List<LapSplitRecord>> getLapSplitsForActivity(int activityId) {
    return (select(lapSplits)
          ..where((t) => t.activityId.equals(activityId))
          ..orderBy(<OrderingTerm Function(LapSplits)>[
            (t) => OrderingTerm.asc(t.splitIndex),
          ]))
        .get();
  }

  /// Deletes an activity; cascades to `track_points` and `lap_splits`.
  Future<int> deleteActivityById(int activityId) {
    return (delete(activities)..where((t) => t.id.equals(activityId))).go();
  }

  Future<UserPreference> getPreferences() async {
    await _seedDefaultPreferences();
    return (select(userPreferencesTable)..where((t) => t.id.equals(1)))
        .getSingle();
  }

  Stream<UserPreference> watchPreferences() {
    return (select(userPreferencesTable)..where((t) => t.id.equals(1)))
        .watchSingle();
  }

  Future<void> updatePreferences(UserPreferencesTableCompanion companion) {
    return (update(userPreferencesTable)..where((t) => t.id.equals(1)))
        .write(companion);
  }

  Future<ActivityAggregateStats> getAggregateStats({
    DateTime? sinceUtc,
  }) async {
    final whereClause = sinceUtc == null
        ? "WHERE sync_status NOT IN ('parseFailed', 'failed')"
        : "WHERE sync_status NOT IN ('parseFailed', 'failed') AND start_time_utc >= ?1";
    final variables = sinceUtc == null
        ? const <Variable<Object>>[]
        : <Variable<Object>>[Variable.withDateTime(sinceUtc.toUtc())];

    final row = await customSelect(
      'SELECT '
      'COUNT(*) AS activity_count, '
      'COALESCE(SUM(distance_meters), 0.0) AS total_distance, '
      'COALESCE(SUM(duration_moving_sec), 0) AS total_moving_sec '
      'FROM activities $whereClause;',
      variables: variables,
      readsFrom: <ResultSetImplementation<HasResultSet, dynamic>>{activities},
    ).getSingle();

    final count = row.read<int>('activity_count');
    final distanceMeters = row.read<double>('total_distance');
    final movingSec = row.read<int>('total_moving_sec');
    final avgPace = distanceMeters > 0
        ? movingSec / (distanceMeters / 1000.0)
        : 0.0;

    return ActivityAggregateStats(
      activityCount: count,
      totalDistanceMeters: distanceMeters,
      totalMovingDurationSec: movingSec,
      avgPaceSecPerKm: avgPace,
    );
  }

  /// Fetches detected 5K/10K/HM/FM best efforts for a single activity (`M2-10`).
  Future<List<BestEffortRecord>> getBestEffortsForActivity(int activityId) {
    return (select(activityBestEfforts)
          ..where((t) => t.activityId.equals(activityId))
          ..orderBy(<OrderingTerm Function(ActivityBestEfforts)>[
            (t) => OrderingTerm.asc(t.targetDistanceMeters),
          ]))
        .get();
  }

  /// Fetches all-time fastest PR record per standard distance (`5k`, `10k`, `hm`, `fm`).
  Future<Map<String, BestEffortPrRecord>> getAllTimeBestEffortPrs() async {
    final rows = await customSelect(
      'SELECT be.distance_key, be.activity_id, be.target_distance_meters, '
      'be.duration_sec, be.pace_sec_per_km, a.title, a.start_time_utc, a.utc_offset_seconds '
      'FROM activity_best_efforts be '
      'INNER JOIN activities a ON a.id = be.activity_id '
      "WHERE a.sync_status NOT IN ('parseFailed', 'failed') "
      'ORDER BY be.duration_sec ASC, a.start_time_utc ASC;',
      readsFrom: <ResultSetImplementation<HasResultSet, dynamic>>{
        activityBestEfforts,
        activities,
      },
    ).get();

    final prs = <String, BestEffortPrRecord>{};
    for (final row in rows) {
      final key = row.read<String>('distance_key');
      if (prs.containsKey(key)) continue;
      prs[key] = BestEffortPrRecord(
        distanceKey: key,
        activityId: row.read<int>('activity_id'),
        activityTitle: row.read<String>('title'),
        startTimeUtc: row.read<DateTime>('start_time_utc'),
        utcOffsetSeconds: row.read<int>('utc_offset_seconds'),
        targetDistanceMeters: row.read<double>('target_distance_meters'),
        durationSec: row.read<int>('duration_sec'),
        paceSecPerKm: row.read<double>('pace_sec_per_km'),
      );
    }
    return prs;
  }

  /// Backfills Best Effort rows for legacy v1 activities >= 5 km without entries.
  Future<int> backfillMissingBestEfforts() async {
    final missingRows = await customSelect(
      'SELECT id, distance_meters, duration_moving_sec FROM activities '
      'WHERE distance_meters >= 5000.0 '
      "AND sync_status NOT IN ('parseFailed', 'failed') "
      'AND NOT EXISTS ('
      '  SELECT 1 FROM activity_best_efforts be WHERE be.activity_id = activities.id'
      ') '
      'LIMIT 25;',
      readsFrom: <ResultSetImplementation<HasResultSet, dynamic>>{
        activities,
        activityBestEfforts,
      },
    ).get();

    if (missingRows.isEmpty) return 0;

    const calculator = BestEffortCalculator();
    var updatedCount = 0;
    for (final row in missingRows) {
      final actId = row.read<int>('id');
      final distM = row.read<double>('distance_meters');
      final movingSec = row.read<int>('duration_moving_sec');
      final tps = await getTrackPointsForActivity(actId);
      final parsedPoints = tps
          .map(
            (pt) => ParsedTrackPoint(
              timestampUtc: pt.timestampUtc,
              latitudeDeg: pt.latitudeDeg,
              longitudeDeg: pt.longitudeDeg,
              altitudeM: pt.altitudeM,
              speedMps: pt.speedMps,
              distanceMeters: pt.distanceMeters,
              heartRateBpm: pt.heartRateBpm,
              cadenceRpm: pt.cadenceRpm,
              hrZone: pt.hrZone,
            ),
          )
          .toList(growable: false);
      final detected = calculator.detect(
        trackPoints: parsedPoints,
        summaryDistanceMeters: distM,
        summaryMovingDurationSec: movingSec,
      );
      if (detected.isNotEmpty) {
        await _insertBestEfforts(activityId: actId, efforts: detected);
        updatedCount++;
      }
    }
    return updatedCount;
  }

  /// Fetches eligible running samples (`>= 1.5 km`) for VDOT / VO2max estimation (`M2-11`).
  Future<List<PerformanceSample>> getVdotPerformanceSamples({
    int limit = 25,
  }) async {
    final samples = <PerformanceSample>[];
    final prs = await getAllTimeBestEffortPrs();
    for (final pr in prs.values) {
      samples.add(
        PerformanceSample(
          title: '${pr.activityTitle} (${BestEffortDistance.fromStorageKey(pr.distanceKey)?.label ?? pr.distanceKey})',
          distanceMeters: pr.targetDistanceMeters,
          durationSec: pr.durationSec,
        ),
      );
    }

    final recentRuns = await (select(activities)
          ..where(
            (t) =>
                t.distanceMeters.isBiggerOrEqualValue(
                  VdotPredictor.minDistanceMeters,
                ) &
                t.durationMovingSec.isBiggerThanValue(0) &
                t.syncStatus.isNotIn(const <String>['parseFailed', 'failed']),
          )
          ..orderBy(<OrderingTerm Function(Activities)>[
            (t) => OrderingTerm.asc(t.avgPaceSecPerKm),
            (t) => OrderingTerm.desc(t.startTimeUtc),
          ])
          ..limit(limit))
        .get();

    for (final act in recentRuns) {
      samples.add(
        PerformanceSample(
          title: act.title,
          distanceMeters: act.distanceMeters,
          durationSec: act.durationMovingSec,
        ),
      );
    }
    return samples;
  }

  /// Fetches valid activities since `sinceUtc` ordered chronologically for calendar streak heatmap (`M3-09`).
  Future<List<ActivityRecord>> getValidActivitiesSince(DateTime sinceUtc) {
    return (select(activities)
          ..where(
            (t) =>
                t.startTimeUtc.isBiggerOrEqualValue(sinceUtc.toUtc()) &
                t.syncStatus.isNotIn(const <String>['parseFailed', 'failed']),
          )
          ..orderBy(<OrderingTerm Function(Activities)>[
            (t) => OrderingTerm.asc(t.startTimeUtc),
          ]))
        .get();
  }

  /// Fetches all valid activities ordered newest-first for CSV export (Phase 6).
  Future<List<ActivityRecord>> getAllValidActivitiesForExport() {
    return (select(activities)
          ..where(
            (t) => t.syncStatus.isNotIn(const <String>['parseFailed', 'failed']),
          )
          ..orderBy(<OrderingTerm Function(Activities)>[
            (t) => OrderingTerm.desc(t.startTimeUtc),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Watches saved custom Instagram Story layout presets (`PRD M4-09`).
  Stream<List<StoryPresetRecord>> watchStoryPresets() {
    return (select(storyPresets)
          ..orderBy(<OrderingTerm Function(StoryPresets)>[
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Future<int> saveStoryPreset({
    required String name,
    required String configJson,
  }) {
    final now = DateTime.now().toUtc();
    return into(storyPresets).insert(
      StoryPresetsCompanion.insert(
        name: name.trim(),
        configJson: configJson,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<int> deleteStoryPreset(int presetId) {
    return (delete(storyPresets)..where((t) => t.id.equals(presetId))).go();
  }

  /// Reclaims unused SQLite pages (`VACUUM`, PRD M5-05).
  Future<void> vacuumDatabase() => customStatement('VACUUM;');
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fittrace.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

