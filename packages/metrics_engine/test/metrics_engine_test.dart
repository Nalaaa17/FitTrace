import 'package:metrics_engine/metrics_engine.dart';
import 'package:test/test.dart';

void main() {
  group('HrZoneConfig', () {
    test('uses manual HRmax when provided', () {
      final config = HrZoneConfig.resolve(
        hrMaxManual: 186,
        birthDate: DateTime.utc(1990, 5, 10),
      );

      expect(config.hrMaxBpm, 186);
      expect(config.isEstimated, isFalse);
      expect(config.zoneForHeartRate(100), 1);
      expect(config.zoneForHeartRate(170), 5);
    });

    test('computes 220 - age when birthDate is provided', () {
      final config = HrZoneConfig.resolve(
        birthDate: DateTime.utc(1996, 11, 20),
        referenceDate: DateTime.utc(2026, 11, 12),
      );

      // Birthday hasn't passed yet in 2026 -> age 29 -> HRmax 191.
      expect(config.hrMaxBpm, 191);
      expect(config.isEstimated, isTrue);
    });

    test('falls back to 190 bpm when profile is unset', () {
      final config = HrZoneConfig.resolve();

      expect(config.hrMaxBpm, HrZoneConfig.defaultFallbackHrMax);
      expect(config.isEstimated, isTrue);
      expect(config.zoneForHeartRate(113), 1);
      expect(config.zoneForHeartRate(114), 2);
      expect(config.zoneForHeartRate(133), 3);
      expect(config.zoneForHeartRate(152), 4);
      expect(config.zoneForHeartRate(171), 5);
    });
  });

  group('SportType & ParsedActivity', () {
    test('maps enum codes and storage keys safely', () {
      expect(SportType.fromCode(2), SportType.trailRun);
      expect(SportType.fromCode(99), SportType.other);
      expect(
        ActivitySource.fromStorageKey('garminSync'),
        ActivitySource.garminSync,
      );
      expect(
        ActivitySource.fromStorageKey('unknown'),
        ActivitySource.manualImport,
      );
      expect(SyncStatus.fromStorageKey('parseFailed'), SyncStatus.parseFailed);
      expect(SyncStatus.fromStorageKey('unknown'), SyncStatus.localOnly);
      expect(GpsQuality.fromStorageKey('degraded'), GpsQuality.degraded);
      expect(GpsQuality.fromStorageKey('unknown'), GpsQuality.none);
      expect(
        const FitParseException('bad crc').toString(),
        'FitParseException: bad crc',
      );

      final activity = ParsedActivity(
        title: 'Morning Tempo',
        sportType: SportType.run,
        startTimeUtc: DateTime.utc(2026, 11, 12, 0, 30),
        utcOffsetSeconds: 7 * 3600,
        durationTotalSec: 1800,
        durationMovingSec: 1780,
        distanceMeters: 5000,
        avgPaceSecPerKm: 356,
        totalElevationGainM: 22,
        totalElevationLossM: 20,
        caloriesKcal: 340,
        isIndoor: false,
        hasGpsTrack: true,
        gpsQuality: GpsQuality.good,
        splitPacesSecPerKm: const [360, 355, 354, 356, 355],
        zoneDurationsSec: const [120, 400, 800, 380, 80],
        trackPoints: const [],
        lapSplits: const [],
      );

      expect(activity.startTimeLocal, DateTime.utc(2026, 11, 12, 7, 30));
    });
  });
}

