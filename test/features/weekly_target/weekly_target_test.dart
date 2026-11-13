import 'package:drift/native.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/features/weekly_target/domain/weekly_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('WeeklyTargetProgress computes ratios and completion states accurately', () {
    final now = DateTime.now().toUtc();
    final progress = WeeklyTargetProgress(
      targetKm: 30.0,
      currentKm: 18.0,
      activityCount: 2,
      weekStartUtc: now.subtract(const Duration(days: 3)),
      weekEndUtc: now.add(const Duration(days: 3)),
      daysRemainingInWeek: 3,
    );

    expect(progress.targetKm, equals(30.0));
    expect(progress.currentKm, equals(18.0));
    expect(progress.progressPercent, closeTo(0.6, 0.001));
    expect(progress.isAchieved, isFalse);
    expect(progress.remainingKm, closeTo(12.0, 0.001));

    // Achieved state (35 km out of 30 km)
    final achieved = WeeklyTargetProgress(
      targetKm: 30.0,
      currentKm: 35.0,
      activityCount: 4,
      weekStartUtc: now.subtract(const Duration(days: 5)),
      weekEndUtc: now.add(const Duration(days: 1)),
      daysRemainingInWeek: 1,
    );

    expect(achieved.progressPercent, equals(1.0)); // clamped
    expect(achieved.progressRatioRaw, closeTo(1.166, 0.001));
    expect(achieved.isAchieved, isTrue);
    expect(achieved.remainingKm, equals(0.0));
  });

  test('Database weekly target persistence and distance querying', () async {
    // Default weekly target is 30 km
    final defaultTarget = await db.getWeeklyTargetKm();
    expect(defaultTarget, equals(30.0));

    // Update target
    await db.setWeeklyTargetKm(45.0);
    final updatedTarget = await db.getWeeklyTargetKm();
    expect(updatedTarget, equals(45.0));

    // Insert activity within range
    final now = DateTime.now().toUtc();
    await db.insertParsedActivity(
      parsed: ParsedActivity(
        title: 'Weekly Run',
        sportType: SportType.run,
        startTimeUtc: now,
        utcOffsetSeconds: 0,
        durationTotalSec: 1800,
        durationMovingSec: 1800,
        distanceMeters: 5500.0,
        avgPaceSecPerKm: 327.0,
        totalElevationGainM: 20.0,
        totalElevationLossM: 20.0,
        caloriesKcal: 350,
        isIndoor: false,
        hasGpsTrack: false,
        gpsQuality: GpsQuality.none,
        trackPoints: const <ParsedTrackPoint>[],
        lapSplits: const <ParsedLapSplit>[],
        bestEfforts: const <BestEffortSegment>[],
        splitPacesSecPerKm: const <int>[],
        zoneDurationsSec: const <int>[0, 0, 0, 0, 0],
      ),
      source: ActivitySource.manualImport,
      syncStatus: SyncStatus.synced,
      fitFileHash: 'fit_hash_target_test_1',
    );

    final distanceMeters = await db.getDistanceMetersBetween(
      startUtc: now.subtract(const Duration(days: 1)),
      endUtc: now.add(const Duration(days: 1)),
    );
    expect(distanceMeters, equals(5500.0));

    final count = await db.getActivityCountBetween(
      startUtc: now.subtract(const Duration(days: 1)),
      endUtc: now.add(const Duration(days: 1)),
    );
    expect(count, equals(1));
  });
}

