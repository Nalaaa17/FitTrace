import 'package:drift/native.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/stats/application/stats_providers.dart';
import 'package:fit_trace/features/stats/presentation/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test('getAggregateStats computes complete Garmin metrics and HR zones across activities', () async {
    final now = DateTime.now().toUtc();

    await db.insertParsedActivity(
      parsed: ParsedActivity(
        title: 'Run 1 (Garmin)',
        sportType: SportType.run,
        startTimeUtc: now.subtract(const Duration(hours: 2)),
        utcOffsetSeconds: 0,
        durationTotalSec: 1800,
        durationMovingSec: 1800,
        distanceMeters: 5000.0,
        avgPaceSecPerKm: 360.0,
        avgHeartRate: 150.0,
        maxHeartRate: 175.0,
        avgCadence: 168.0,
        totalElevationGainM: 45.0,
        totalElevationLossM: 40.0,
        caloriesKcal: 350,
        isIndoor: false,
        hasGpsTrack: true,
        gpsQuality: GpsQuality.good,
        trackPoints: const <ParsedTrackPoint>[],
        lapSplits: const <ParsedLapSplit>[],
        bestEfforts: const <BestEffortSegment>[],
        splitPacesSecPerKm: const <int>[360, 360, 360, 360, 360],
        zoneDurationsSec: const <int>[100, 800, 600, 300, 0],
      ),
      source: ActivitySource.garminSync,
      syncStatus: SyncStatus.synced,
      fitFileHash: 'hash_test_1',
    );

    await db.insertParsedActivity(
      parsed: ParsedActivity(
        title: 'Run 2 (Garmin Indoor)',
        sportType: SportType.treadmill,
        startTimeUtc: now.subtract(const Duration(hours: 1)),
        utcOffsetSeconds: 0,
        durationTotalSec: 1200,
        durationMovingSec: 1200,
        distanceMeters: 3000.0,
        avgPaceSecPerKm: 400.0,
        avgHeartRate: 140.0,
        maxHeartRate: 160.0,
        avgCadence: 162.0,
        totalElevationGainM: 0.0,
        totalElevationLossM: 0.0,
        caloriesKcal: 200,
        isIndoor: true,
        hasGpsTrack: false,
        gpsQuality: GpsQuality.none,
        trackPoints: const <ParsedTrackPoint>[],
        lapSplits: const <ParsedLapSplit>[],
        bestEfforts: const <BestEffortSegment>[],
        splitPacesSecPerKm: const <int>[400, 400, 400],
        zoneDurationsSec: const <int>[200, 600, 400, 0, 0],
      ),
      source: ActivitySource.garminSync,
      syncStatus: SyncStatus.synced,
      fitFileHash: 'hash_test_2',
    );

    final stats = await db.getAggregateStats();
    expect(stats.activityCount, equals(2));
    expect(stats.totalDistanceMeters, closeTo(8000.0, 0.1));
    expect(stats.totalMovingDurationSec, equals(3000));
    expect(stats.totalCaloriesKcal, equals(550));
    expect(stats.totalElevationGainM, closeTo(45.0, 0.1));
    expect(stats.totalElevationLossM, closeTo(40.0, 0.1));
    expect(stats.avgHeartRate, closeTo(145.0, 0.1));
    expect(stats.maxHeartRate, closeTo(175.0, 0.1));
    expect(stats.avgCadence, closeTo(165.0, 0.1));
    expect(stats.longestDistanceMeters, closeTo(5000.0, 0.1));
    expect(stats.outdoorRunsCount, equals(1));
    expect(stats.indoorRunsCount, equals(1));
    expect(stats.zoneDurationsSec, equals(<int>[300, 1400, 1000, 300, 0]));
  });

  testWidgets('StatsScreen displays Garmin sync banner, cardio metrics, and elevation/cadence cards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          userPreferencesProvider.overrideWith((ref) => Stream.value(
                const UserPreference(
                  id: 1,
                  garminLoggedIn: false,
                  hrZoneThresholds: <int>[60, 70, 80, 90],
                  themeMode: 'dark',
                  unitSystem: 'metric',
                  weeklyMonthlyToggle: 'weekly',
                  watermarkEnabled: true,
                  defaultTemplateId: 'pastelAesthetic',
                  backgroundSyncEnabled: false,
                  backgroundSyncWifiOnly: false,
                  backgroundSyncRequireCharging: false,
                  backgroundSyncIntervalMinutes: 15,
                  onboardingCompleted: true,
                  backupReminderEnabled: false,
                ),
              )),
          allTimeBestEffortsProvider.overrideWith((ref) async => const <String, BestEffortPrRecord>{}),
          vdotEstimateProvider.overrideWith((ref) async => null),
          consistencyHeatmapProvider.overrideWith((ref) async => const ConsistencyHeatmapData(
                weeks: <List<HeatmapDayCell>>[],
                currentStreakDays: 0,
                longestStreakDays: 0,
                activeDaysCount: 0,
                maxDayDistanceMeters: 0,
              )),
          aggregateStatsProvider.overrideWith((ref) async {
            return const ActivityAggregateStats(
              activityCount: 4,
              totalDistanceMeters: 28000.0,
              totalMovingDurationSec: 8400,
              avgPaceSecPerKm: 300.0,
              totalCaloriesKcal: 1850,
              totalElevationGainM: 120.0,
              totalElevationLossM: 110.0,
              avgHeartRate: 152.0,
              maxHeartRate: 178.0,
              avgCadence: 169.0,
              longestDistanceMeters: 10000.0,
              avgDistanceMeters: 7000.0,
              outdoorRunsCount: 3,
              indoorRunsCount: 1,
              zoneDurationsSec: <int>[500, 4200, 2500, 1200, 0],
            );
          }),
        ],
        child: const MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Statistik'), findsOneWidget);
    expect(find.text('Garmin Belum Terhubung'), findsOneWidget);
    expect(find.text('Mingguan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
    expect(find.text('Tahunan'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);

    expect(find.text('GARMIN CARDIO & ZONA DETAK JANTUNG'), findsOneWidget);
    expect(find.text('152 BPM'), findsOneWidget);
    expect(find.text('178 BPM'), findsOneWidget);
    expect(find.text('1850 kcal'), findsOneWidget);
    expect(find.text('✨ Base Dominan'), findsOneWidget);

    expect(find.text('ELEVASI & KADENSI LANGKAH GARMIN'), findsOneWidget);
    expect(find.text('+120 m'), findsOneWidget);
    expect(find.text('169 SPM'), findsOneWidget);
    expect(find.text('Baik (Standar)'), findsOneWidget);
  });
}
