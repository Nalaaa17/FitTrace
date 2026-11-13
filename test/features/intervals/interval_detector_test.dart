import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/features/intervals/application/interval_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = IntervalDetector();
  final dummyActivity = ActivityRecord(
    id: 1,
    title: 'Interval Workout',
    sportType: 1,
    startTimeUtc: DateTime.now().toUtc(),
    utcOffsetSeconds: 0,
    durationTotalSec: 1800,
    durationMovingSec: 1800,
    distanceMeters: 5000.0,
    avgPaceSecPerKm: 300.0,
    totalElevationGainM: 10.0,
    totalElevationLossM: 10.0,
    caloriesKcal: 400,
    isIndoor: false,
    hasGpsTrack: true,
    gpsQuality: 'good',
    source: 'manual',
    syncStatus: 'synced',
    fitFileHash: 'dummy',
    splitPacesSecPerKm: const [],
    zoneDurationsSec: const [],
    hasCustomTitle: false,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );

  test('detects interval session when laps show alternating sprint-recovery pattern', () {
    // 4 laps: Warmup, Rep 1 (fast), Rest 1 (slow), Rep 2 (fast), Rest 2 (slow)
    final laps = <LapSplitRecord>[
      const LapSplitRecord(
        id: 1,
        activityId: 1,
        splitIndex: 1,
        distanceMeters: 400.0,
        durationSec: 90, // Pace: 225 s/km (3:45 /km)
        avgPaceSecPerKm: 225.0,
        avgHeartRate: 165.0,
        avgCadence: 180.0,
        elevationDeltaM: 0.0,
      ),
      const LapSplitRecord(
        id: 2,
        activityId: 1,
        splitIndex: 2,
        distanceMeters: 200.0,
        durationSec: 80, // Pace: 400 s/km (6:40 /km)
        avgPaceSecPerKm: 400.0,
        avgHeartRate: 135.0,
        avgCadence: 150.0,
        elevationDeltaM: 0.0,
      ),
      const LapSplitRecord(
        id: 3,
        activityId: 1,
        splitIndex: 3,
        distanceMeters: 400.0,
        durationSec: 88, // Pace: 220 s/km (3:40 /km)
        avgPaceSecPerKm: 220.0,
        avgHeartRate: 168.0,
        avgCadence: 182.0,
        elevationDeltaM: 0.0,
      ),
      const LapSplitRecord(
        id: 4,
        activityId: 1,
        splitIndex: 4,
        distanceMeters: 200.0,
        durationSec: 82, // Pace: 410 s/km (6:50 /km)
        avgPaceSecPerKm: 410.0,
        avgHeartRate: 138.0,
        avgCadence: 152.0,
        elevationDeltaM: 0.0,
      ),
    ];

    final result = detector.detectIntervals(
      activity: dummyActivity,
      lapSplits: laps,
      trackPoints: const [],
    );

    expect(result.isIntervalSession, isTrue);
    expect(result.reps.length, equals(2));
    expect(result.reps[0].repIndex, equals(1));
    expect(result.reps[0].workDistanceMeters, equals(400.0));
    expect(result.reps[0].restDistanceMeters, equals(200.0));
    expect(result.totalWorkDistanceMeters, equals(800.0));
    expect(result.detectionSource, equals('laps'));
  });

  test('does not detect intervals for uniform steady-pace runs', () {
    final uniformSplits = <LapSplitRecord>[
      const LapSplitRecord(
        id: 1,
        activityId: 1,
        splitIndex: 1,
        distanceMeters: 1000.0,
        durationSec: 320,
        avgPaceSecPerKm: 320.0,
        avgHeartRate: 145.0,
        elevationDeltaM: 0.0,
      ),
      const LapSplitRecord(
        id: 2,
        activityId: 1,
        splitIndex: 2,
        distanceMeters: 1000.0,
        durationSec: 325,
        avgPaceSecPerKm: 325.0,
        avgHeartRate: 146.0,
        elevationDeltaM: 0.0,
      ),
      const LapSplitRecord(
        id: 3,
        activityId: 1,
        splitIndex: 3,
        distanceMeters: 1000.0,
        durationSec: 322,
        avgPaceSecPerKm: 322.0,
        avgHeartRate: 148.0,
        elevationDeltaM: 0.0,
      ),
    ];

    final result = detector.detectIntervals(
      activity: dummyActivity,
      lapSplits: uniformSplits,
      trackPoints: const [],
    );

    expect(result.isIntervalSession, isFalse);
    expect(result.reps, isEmpty);
  });
}

