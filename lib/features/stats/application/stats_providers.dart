import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

final _activitiesMutationTickProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActivitiesMutationTick();
});

/// Computes weekly or monthly running totals directly in SQLite (PRD M3-07).
final aggregateStatsProvider = FutureProvider<ActivityAggregateStats>((ref) {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(userPreferencesProvider).value;
  final mode = prefs?.weeklyMonthlyToggle ?? 'weekly';

  final nowUtc = DateTime.now().toUtc();
  final sinceUtc = mode == 'monthly'
      ? DateTime.utc(nowUtc.year, nowUtc.month, 1)
      : DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
          .subtract(Duration(days: nowUtc.weekday - 1));

  return db.getAggregateStats(sinceUtc: sinceUtc);
});

Future<void> setWeeklyMonthlyMode(WidgetRef ref, String mode) {
  final db = ref.read(appDatabaseProvider);
  return db.updatePreferences(
    UserPreferencesTableCompanion(weeklyMonthlyToggle: Value(mode)),
  );
}

/// All-time Best Effort Personal Records (`5K`, `10K`, `HM`, `FM`) (`PRD M2-10`).
final allTimeBestEffortsProvider =
    FutureProvider<Map<String, BestEffortPrRecord>>((ref) async {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  await db.backfillMissingBestEfforts();
  return db.getAllTimeBestEffortPrs();
});

/// Single-run detected Best Efforts for Activity Detail (`PRD M2-10`).
final activityBestEffortsProvider =
    FutureProvider.family<List<BestEffortRecord>, int>((ref, activityId) async {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  return db.getBestEffortsForActivity(activityId);
});

/// Estimated VO2max & VDOT-lite race predictor (`PRD M2-11`).
final vdotEstimateProvider = FutureProvider<VdotEstimate?>((ref) async {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  final samples = await db.getVdotPerformanceSamples();
  return const VdotPredictor().estimateFromSamples(samples);
});

class HeatmapDayCell {
  const HeatmapDayCell({
    required this.dateLocal,
    required this.activityCount,
    required this.totalDistanceMeters,
    required this.isFuture,
  });

  final DateTime dateLocal;
  final int activityCount;
  final double totalDistanceMeters;
  final bool isFuture;
}

class ConsistencyHeatmapData {
  const ConsistencyHeatmapData({
    required this.weeks,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.activeDaysCount,
    required this.maxDayDistanceMeters,
  });

  /// Columns sorted chronologically left-to-right (each week = 7 Mon..Sun rows).
  final List<List<HeatmapDayCell>> weeks;
  final int currentStreakDays;
  final int longestStreakDays;
  final int activeDaysCount;
  final double maxDayDistanceMeters;

  static ConsistencyHeatmapData fromActivities({
    required List<ActivityRecord> activities,
    DateTime? todayLocal,
    int weekColumns = 20,
  }) {
    final nowLocal = todayLocal ?? DateTime.now();
    final todayDay = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final dailyCount = <DateTime, int>{};
    final dailyDistance = <DateTime, double>{};
    var maxDayDist = 0.0;

    for (final act in activities) {
      final localStart = act.startTimeUtc
          .toUtc()
          .add(Duration(seconds: act.utcOffsetSeconds));
      final dayKey =
          DateTime(localStart.year, localStart.month, localStart.day);
      dailyCount[dayKey] = (dailyCount[dayKey] ?? 0) + 1;
      final nextDist = (dailyDistance[dayKey] ?? 0) + act.distanceMeters;
      dailyDistance[dayKey] = nextDist;
      if (nextDist > maxDayDist) {
        maxDayDist = nextDist;
      }
    }

    // Align grid so rightmost column ends on the Sunday of today's week.
    final endOfWeek = todayDay.add(Duration(days: 7 - todayDay.weekday));
    final gridStart = endOfWeek.subtract(Duration(days: weekColumns * 7 - 1));

    final weeks = <List<HeatmapDayCell>>[];
    var activeDaysInGrid = 0;

    for (var w = 0; w < weekColumns; w++) {
      final col = <HeatmapDayCell>[];
      for (var d = 0; d < 7; d++) {
        final date = gridStart.add(Duration(days: w * 7 + d));
        final count = dailyCount[date] ?? 0;
        final dist = dailyDistance[date] ?? 0;
        final isFuture = date.isAfter(todayDay);
        if (!isFuture && count > 0) {
          activeDaysInGrid++;
        }
        col.add(
          HeatmapDayCell(
            dateLocal: date,
            activityCount: count,
            totalDistanceMeters: dist,
            isFuture: isFuture,
          ),
        );
      }
      weeks.add(col);
    }

    // Compute longest streak across all known days.
    final sortedDays = dailyCount.keys.toList()..sort();
    var longestStreak = 0;
    var runningStreak = 0;
    DateTime? prevDay;
    for (final day in sortedDays) {
      if (prevDay != null && day.difference(prevDay).inDays == 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      longestStreak = math.max(longestStreak, runningStreak);
      prevDay = day;
    }

    // Current streak: counts consecutive days ending today or yesterday.
    var currentStreak = 0;
    var cursor = dailyCount.containsKey(todayDay)
        ? todayDay
        : todayDay.subtract(const Duration(days: 1));
    while (dailyCount.containsKey(cursor)) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return ConsistencyHeatmapData(
      weeks: weeks,
      currentStreakDays: currentStreak,
      longestStreakDays: longestStreak,
      activeDaysCount: activeDaysInGrid,
      maxDayDistanceMeters: maxDayDist,
    );
  }
}

/// 20-week monochrome consistency calendar heatmap & streak summary (`PRD M3-09`).
final consistencyHeatmapProvider =
    FutureProvider<ConsistencyHeatmapData>((ref) async {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  // Query ~365 days so longest streak also reflects annual runs.
  final sinceUtc = DateTime.now().toUtc().subtract(const Duration(days: 370));
  final rows = await db.getValidActivitiesSince(sinceUtc);
  return ConsistencyHeatmapData.fromActivities(activities: rows);
});
