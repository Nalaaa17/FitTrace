import 'package:drift/native.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/theme/app_colors.dart';
import 'package:fit_trace/core/theme/app_theme.dart';
import 'package:fit_trace/features/stats/application/stats_providers.dart';
import 'package:fit_trace/features/stats/presentation/widgets/weekly_trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('WeeklyTrendData.fromActivities correctly groups runs into 12 weeks with pace and HR', () {
    final refDate = DateTime(2026, 11, 13, 10, 0); // Friday
    final t0 = refDate.toUtc();

    // 2 runs in current week: 5km and 10km
    final act1 = ActivityRecord(
      id: 1,
      title: 'Current Week Run 1',
      sportType: 1,
      startTimeUtc: t0.subtract(const Duration(days: 1)),
      utcOffsetSeconds: 0,
      durationTotalSec: 1800,
      durationMovingSec: 1800,
      distanceMeters: 5000.0,
      avgPaceSecPerKm: 360.0,
      avgHeartRate: 150.0,
      maxHeartRate: 175.0,
      avgCadence: 165.0,
      totalElevationGainM: 20.0,
      totalElevationLossM: 20.0,
      caloriesKcal: 350,
      isIndoor: false,
      hasGpsTrack: true,
      gpsQuality: 'good',
      syncStatus: 'synced',
      source: 'garmin',
      fitFileHash: 'hash',
      splitPacesSecPerKm: const <int>[],
      zoneDurationsSec: const <int>[],
      hasCustomTitle: false,
      createdAt: t0,
      updatedAt: t0,
    );

    final act2 = ActivityRecord(
      id: 2,
      title: 'Current Week Run 2',
      sportType: 1,
      startTimeUtc: t0.subtract(const Duration(days: 2)),
      utcOffsetSeconds: 0,
      durationTotalSec: 3600,
      durationMovingSec: 3600,
      distanceMeters: 10000.0,
      avgPaceSecPerKm: 360.0,
      avgHeartRate: 160.0,
      maxHeartRate: 180.0,
      avgCadence: 170.0,
      totalElevationGainM: 50.0,
      totalElevationLossM: 45.0,
      caloriesKcal: 700,
      isIndoor: false,
      hasGpsTrack: true,
      gpsQuality: 'good',
      syncStatus: 'synced',
      source: 'garmin',
      fitFileHash: 'hash',
      splitPacesSecPerKm: const <int>[],
      zoneDurationsSec: const <int>[],
      hasCustomTitle: false,
      createdAt: t0,
      updatedAt: t0,
    );

    // 1 run in previous week: 8km
    final act3 = ActivityRecord(
      id: 3,
      title: 'Previous Week Run',
      sportType: 1,
      startTimeUtc: t0.subtract(const Duration(days: 9)),
      utcOffsetSeconds: 0,
      durationTotalSec: 2880,
      durationMovingSec: 2880,
      distanceMeters: 8000.0,
      avgPaceSecPerKm: 360.0,
      avgHeartRate: 145.0,
      maxHeartRate: 165.0,
      avgCadence: 160.0,
      totalElevationGainM: 30.0,
      totalElevationLossM: 30.0,
      caloriesKcal: 550,
      isIndoor: false,
      hasGpsTrack: true,
      gpsQuality: 'good',
      syncStatus: 'synced',
      source: 'garmin',
      fitFileHash: 'hash',
      splitPacesSecPerKm: const <int>[],
      zoneDurationsSec: const <int>[],
      hasCustomTitle: false,
      createdAt: t0,
      updatedAt: t0,
    );

    final trend = WeeklyTrendData.fromActivities(
      activities: <ActivityRecord>[act1, act2, act3],
      weekCount: 12,
      referenceDateLocal: refDate,
    );

    expect(trend.weeks.length, 12);
    expect(trend.totalRuns, 3);
    expect(trend.totalPeriodDistanceMeters, 23000.0);

    // Latest week has 15km (5km + 10km)
    final latestWeek = trend.weeks.last;
    expect(latestWeek.totalDistanceMeters, 15000.0);
    expect(latestWeek.runCount, 2);
    expect(latestWeek.isCurrentWeek, isTrue);
    expect(latestWeek.avgHeartRate, 155.0); // (150 + 160) / 2

    // Previous week has 8km
    final prevWeek = trend.weeks[trend.weeks.length - 2];
    expect(prevWeek.totalDistanceMeters, 8000.0);
    expect(prevWeek.runCount, 1);

    // Volume change: (15000 - 8000) / 8000 * 100 = +87.5%
    expect(trend.volumeChangePercentVsPrevWeek, closeTo(87.5, 0.1));
  });

  testWidgets('WeeklyTrendCard renders header, switcher buttons, and highlights', (tester) async {
    final colors = AppTheme.dark().extension<FitTraceColors>()!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyTrendDataProvider.overrideWith((ref) {
            return WeeklyTrendData(
              weeks: <WeeklyTrendPoint>[
                WeeklyTrendPoint(
                  weekIndex: 0,
                  startLocal: DateTime.utc(2026, 11, 2),
                  endLocal: DateTime.utc(2026, 11, 8),
                  totalDistanceMeters: 25000.0,
                  totalMovingSec: 7500,
                  avgPaceSecPerKm: 300.0,
                  avgHeartRate: 148.0,
                  runCount: 3,
                  totalElevationGainM: 120.0,
                  isCurrentWeek: false,
                ),
                WeeklyTrendPoint(
                  weekIndex: 1,
                  startLocal: DateTime.utc(2026, 11, 9),
                  endLocal: DateTime.utc(2026, 11, 15),
                  totalDistanceMeters: 32000.0,
                  totalMovingSec: 9600,
                  avgPaceSecPerKm: 300.0,
                  avgHeartRate: 152.0,
                  runCount: 4,
                  totalElevationGainM: 160.0,
                  isCurrentWeek: true,
                ),
              ],
              maxDistanceMeters: 32000.0,
              minPaceSecPerKm: 300.0,
              maxPaceSecPerKm: 360.0,
              minHeartRate: 145.0,
              maxHeartRate: 155.0,
              avgWeeklyDistanceMeters: 28500.0,
              totalPeriodDistanceMeters: 57000.0,
              totalRuns: 7,
              peakWeekDistanceMeters: 32000.0,
              peakWeekLabel: '9 Nov - 15 Nov',
              volumeChangePercentVsPrevWeek: 28.0,
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyTrendCard(
                colors: colors,
                unitSystem: 'metric',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Controls
    expect(find.text('TREN MINGGUAN (PROGRES TRAINING)'), findsOneWidget);
    expect(find.text('12 Mgg'), findsOneWidget);
    expect(find.text('24 Mgg'), findsOneWidget);
    expect(find.text('Jarak'), findsOneWidget);
    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('Detak Jantung'), findsOneWidget);

    // Verify Stats
    expect(find.text('TOTAL JARAK'), findsOneWidget);
    expect(find.text('57.00 KM'), findsOneWidget);
    expect(find.text('TOTAL SESI'), findsOneWidget);
    expect(find.text('7 sesi'), findsOneWidget);
    expect(find.textContaining('+28.0% vs minggu lalu'), findsOneWidget);

    // Switch metric to Pace
    await tester.tap(find.text('Pace'));
    await tester.pumpAndSettle();

    // Switch metric to Detak Jantung
    await tester.tap(find.text('Detak Jantung'));
    await tester.pumpAndSettle();
  });
}
