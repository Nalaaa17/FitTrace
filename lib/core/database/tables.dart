import 'package:drift/drift.dart';

import 'converters.dart';

/// Running shoes table for tracking mileage and wear (`PRD Shoe Tracking`).
@DataClassName('ShoeRecord')
class Shoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brand => text().withDefault(const Constant(''))();
  RealColumn get maxDistanceKm => real().withDefault(const Constant(600.0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isRetired => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Running activities table (PRD §4.1, ADR-001, ADR-002).
///
/// Uniqueness of non-null `garminActivityId` is enforced via partial unique index
/// `idx_activities_garmin_id_unique` created in `AppDatabase.migration`.
@TableIndex(name: 'idx_activities_start_time', columns: {#startTimeUtc})
@TableIndex(name: 'idx_activities_fit_hash', columns: {#fitFileHash})
@DataClassName('ActivityRecord')
class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nullable for manual `.FIT` imports without a Garmin Connect activity ID.
  IntColumn get garminActivityId => integer().nullable()();

  TextColumn get title => text()();
  IntColumn get sportType => integer()();
  DateTimeColumn get startTimeUtc => dateTime()();
  IntColumn get utcOffsetSeconds => integer()();
  IntColumn get durationTotalSec => integer()();
  IntColumn get durationMovingSec => integer()();
  RealColumn get distanceMeters => real()();
  RealColumn get avgPaceSecPerKm => real()();
  RealColumn get avgHeartRate => real().nullable()();
  RealColumn get maxHeartRate => real().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get totalElevationGainM => real()();
  RealColumn get totalElevationLossM => real()();
  IntColumn get caloriesKcal => integer()();

  BoolColumn get isIndoor => boolean().withDefault(const Constant(false))();
  BoolColumn get hasGpsTrack => boolean().withDefault(const Constant(false))();
  TextColumn get gpsQuality => text().withDefault(const Constant('good'))();
  TextColumn get source => text()();
  TextColumn get syncStatus => text()();
  TextColumn get originalFitPath => text().nullable()();
  TextColumn get fitFileHash => text()();

  TextColumn get splitPacesSecPerKm =>
      text().map(const IntListConverter())();
  TextColumn get zoneDurationsSec => text().map(const IntListConverter())();

  /// Marks titles renamed locally by the user so Garmin re-syncs keep them (M3-08).
  BoolColumn get hasCustomTitle =>
      boolean().withDefault(const Constant(false))();

  IntColumn get shoeId => integer().nullable().references(
        Shoes,
        #id,
        onDelete: KeyAction.setNull,
      )();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Time-series trackpoints linked to an activity (PRD §4.2, ADR-001).
@TableIndex(
  name: 'idx_track_points_activity_ts',
  columns: {#activityId, #timestampUtc},
)
@DataClassName('TrackPointRecord')
class TrackPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId => integer().references(
        Activities,
        #id,
        onDelete: KeyAction.cascade,
      )();

  DateTimeColumn get timestampUtc => dateTime()();
  RealColumn get latitudeDeg => real()();
  RealColumn get longitudeDeg => real()();
  RealColumn get altitudeM => real()();
  RealColumn get speedMps => real()();
  IntColumn get heartRateBpm => integer().nullable()();
  IntColumn get cadenceRpm => integer().nullable()();
  IntColumn get distanceMeters => integer()();
  IntColumn get hrZone => integer().nullable()();
}

/// Per-kilometer split rows linked to an activity (PRD §4.3).
@TableIndex(
  name: 'idx_lap_splits_activity_idx',
  columns: {#activityId, #splitIndex},
)
@DataClassName('LapSplitRecord')
class LapSplits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId => integer().references(
        Activities,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get splitIndex => integer()();
  RealColumn get distanceMeters => real()();
  IntColumn get durationSec => integer()();
  RealColumn get avgPaceSecPerKm => real()();
  RealColumn get avgHeartRate => real().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get elevationDeltaM => real()();
}

/// Singleton user preferences table (id = 1) matching PRD §4.4 & ADR-003.
@DataClassName('UserPreference')
class UserPreferencesTable extends Table {
  @override
  String get tableName => 'user_preferences';

  IntColumn get id => integer()();

  BoolColumn get garminLoggedIn =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get lastActivityStartTime => dateTime().nullable()();

  DateTimeColumn get birthDate => dateTime().nullable()();
  IntColumn get hrMaxManual => integer().nullable()();
  TextColumn get hrZoneThresholds => text()
      .map(const IntListConverter())
      .withDefault(const Constant('[60,70,80,90]'))();

  TextColumn get themeMode => text().withDefault(const Constant('dark'))();
  TextColumn get unitSystem => text().withDefault(const Constant('metric'))();
  TextColumn get weeklyMonthlyToggle =>
      text().withDefault(const Constant('weekly'))();

  BoolColumn get watermarkEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get defaultTemplateId =>
      text().withDefault(const Constant('routeGlow'))();

  // ADR-003: Background sync allows cellular & non-charging by default.
  BoolColumn get backgroundSyncEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get backgroundSyncWifiOnly =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get backgroundSyncRequireCharging =>
      boolean().withDefault(const Constant(false))();
  IntColumn get backgroundSyncIntervalMinutes =>
      integer().withDefault(const Constant(15))();

  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
  BoolColumn get backupReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastBackupReminderAt => dateTime().nullable()();
  RealColumn get weeklyTargetKm =>
      real().withDefault(const Constant(30.0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Persisted Best Effort segments (5K, 10K, HM, FM) per activity (`PRD M2-10`).
@TableIndex(
  name: 'idx_best_efforts_dist_dur',
  columns: {#distanceKey, #durationSec},
)
@DataClassName('BestEffortRecord')
class ActivityBestEfforts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId => integer().references(
        Activities,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get distanceKey => text()();
  RealColumn get targetDistanceMeters => real()();
  IntColumn get durationSec => integer()();
  RealColumn get paceSecPerKm => real()();
}

/// User-defined reusable Story Card layout presets (`PRD M4-09`).
@DataClassName('StoryPresetRecord')
class StoryPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get configJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

