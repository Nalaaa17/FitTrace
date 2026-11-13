/// Supported running and fallback sport types from FIT sessions (PRD §4.1).
enum SportType {
  run(1, 'Run'),
  trailRun(2, 'Trail Run'),
  treadmill(3, 'Treadmill'),
  other(4, 'Other');

  const SportType(this.code, this.label);

  final int code;
  final String label;

  static SportType fromCode(int code) {
    return SportType.values.firstWhere(
      (value) => value.code == code,
      orElse: () => SportType.other,
    );
  }
}

/// Origin of an imported or synced activity record (PRD §4.1).
enum ActivitySource {
  garminSync('garminSync'),
  manualImport('manualImport');

  const ActivitySource(this.storageKey);

  final String storageKey;

  static ActivitySource fromStorageKey(String key) {
    return ActivitySource.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => ActivitySource.manualImport,
    );
  }
}

/// Sync and parse lifecycle state shown in the activity feed (PRD M1-09, §7).
enum SyncStatus {
  synced('synced'),
  localOnly('localOnly'),
  failed('failed'),
  parseFailed('parseFailed');

  const SyncStatus(this.storageKey);

  final String storageKey;

  static SyncStatus fromStorageKey(String key) {
    return SyncStatus.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => SyncStatus.localOnly,
    );
  }
}

/// GPS signal integrity status after coordinate and spike filtering (PRD §7).
enum GpsQuality {
  good('good'),
  degraded('degraded'),
  none('none');

  const GpsQuality(this.storageKey);

  final String storageKey;

  static GpsQuality fromStorageKey(String key) {
    return GpsQuality.values.firstWhere(
      (value) => value.storageKey == key,
      orElse: () => GpsQuality.none,
    );
  }
}

