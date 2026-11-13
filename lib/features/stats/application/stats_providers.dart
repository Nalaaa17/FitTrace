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

/// Computes weekly, monthly, yearly, or all-time running totals directly in SQLite (PRD M3-07).
final aggregateStatsProvider = FutureProvider<ActivityAggregateStats>((ref) {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(userPreferencesProvider).value;
  final mode = prefs?.weeklyMonthlyToggle ?? 'weekly';

  final nowUtc = DateTime.now().toUtc();
  DateTime? sinceUtc;
  switch (mode) {
    case 'weekly':
      sinceUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
          .subtract(Duration(days: nowUtc.weekday - 1));
      break;
    case 'monthly':
      sinceUtc = DateTime.utc(nowUtc.year, nowUtc.month, 1);
      break;
    case 'yearly':
      sinceUtc = DateTime.utc(nowUtc.year, 1, 1);
      break;
    case 'allTime':
      sinceUtc = null;
      break;
    default:
      sinceUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
          .subtract(Duration(days: nowUtc.weekday - 1));
  }

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

/// Data point representing a single week's aggregate running statistics.
class WeeklyTrendPoint {
  const WeeklyTrendPoint({
    required this.weekIndex,
    required this.startLocal,
    required this.endLocal,
    required this.totalDistanceMeters,
    required this.totalMovingSec,
    required this.avgPaceSecPerKm,
    required this.avgHeartRate,
    required this.runCount,
    required this.totalElevationGainM,
    required this.isCurrentWeek,
  });

  final int weekIndex;
  final DateTime startLocal;
  final DateTime endLocal;
  final double totalDistanceMeters;
  final int totalMovingSec;
  final double avgPaceSecPerKm;
  final double? avgHeartRate;
  final int runCount;
  final double totalElevationGainM;
  final bool isCurrentWeek;

  String get dateRangeLabel {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final sDay = startLocal.day;
    final eDay = endLocal.day;
    final sMo = months[startLocal.month - 1];
    final eMo = months[endLocal.month - 1];
    if (startLocal.month == endLocal.month) {
      return '$sDay - $eDay $sMo';
    }
    return '$sDay $sMo - $eDay $eMo';
  }

  String get shortWeekLabel {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${startLocal.day} ${months[startLocal.month - 1]}';
  }
}

/// Full trend dataset over 12 or 24 weeks with training insights and statistics.
class WeeklyTrendData {
  const WeeklyTrendData({
    required this.weeks,
    required this.maxDistanceMeters,
    required this.minPaceSecPerKm,
    required this.maxPaceSecPerKm,
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.avgWeeklyDistanceMeters,
    required this.totalPeriodDistanceMeters,
    required this.totalRuns,
    required this.peakWeekDistanceMeters,
    required this.peakWeekLabel,
    required this.volumeChangePercentVsPrevWeek,
  });

  final List<WeeklyTrendPoint> weeks;
  final double maxDistanceMeters;
  final double minPaceSecPerKm;
  final double maxPaceSecPerKm;
  final double minHeartRate;
  final double maxHeartRate;
  final double avgWeeklyDistanceMeters;
  final double totalPeriodDistanceMeters;
  final int totalRuns;
  final double peakWeekDistanceMeters;
  final String peakWeekLabel;
  final double? volumeChangePercentVsPrevWeek;

  static WeeklyTrendData fromActivities({
    required List<ActivityRecord> activities,
    int weekCount = 12,
    DateTime? referenceDateLocal,
  }) {
    final nowLocal = referenceDateLocal ?? DateTime.now();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    // Monday of current week
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    // Oldest Monday in the window
    final oldestMonday =
        currentMonday.subtract(Duration(days: (weekCount - 1) * 7));

    final points = <WeeklyTrendPoint>[];
    var maxDist = 0.0;
    var minPace = double.infinity;
    var maxPace = 0.0;
    var minHr = double.infinity;
    var maxHr = 0.0;
    var totalDist = 0.0;
    var totalRunCount = 0;
    var peakDist = 0.0;
    var peakLabel = '—';

    for (var i = 0; i < weekCount; i++) {
      final start = oldestMonday.add(Duration(days: i * 7));
      final end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      final isCurrent = i == weekCount - 1;

      var weekDist = 0.0;
      var weekMoving = 0;
      var weekElev = 0.0;
      var runs = 0;
      var hrSum = 0.0;
      var hrCount = 0;

      for (final act in activities) {
        final local = act.startTimeUtc
            .toUtc()
            .add(Duration(seconds: act.utcOffsetSeconds));
        if (local.isBefore(start) || local.isAfter(end)) continue;

        weekDist += act.distanceMeters;
        weekMoving += act.durationMovingSec;
        weekElev += act.totalElevationGainM;
        runs++;
        if (act.avgHeartRate != null && act.avgHeartRate! > 0) {
          hrSum += act.avgHeartRate!;
          hrCount++;
        }
      }

      final avgPace =
          weekDist > 0 ? weekMoving / (weekDist / 1000.0) : 0.0;
      final avgHr = hrCount > 0 ? hrSum / hrCount : null;

      if (weekDist > maxDist) maxDist = weekDist;
      if (weekDist > peakDist) {
        peakDist = weekDist;
        const months = <String>[
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
        ];
        peakLabel =
            '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]}';
      }
      if (avgPace > 0) {
        if (avgPace < minPace) minPace = avgPace;
        if (avgPace > maxPace) maxPace = avgPace;
      }
      if (avgHr != null) {
        if (avgHr < minHr) minHr = avgHr;
        if (avgHr > maxHr) maxHr = avgHr;
      }

      totalDist += weekDist;
      totalRunCount += runs;

      points.add(
        WeeklyTrendPoint(
          weekIndex: i,
          startLocal: start,
          endLocal: end,
          totalDistanceMeters: weekDist,
          totalMovingSec: weekMoving,
          avgPaceSecPerKm: avgPace,
          avgHeartRate: avgHr,
          runCount: runs,
          totalElevationGainM: weekElev,
          isCurrentWeek: isCurrent,
        ),
      );
    }

    double? volumeChange;
    if (points.length >= 2) {
      final latest = points[points.length - 1];
      final previous = points[points.length - 2];
      if (previous.totalDistanceMeters > 0) {
        volumeChange = ((latest.totalDistanceMeters -
                    previous.totalDistanceMeters) /
                previous.totalDistanceMeters) *
            100.0;
      }
    }

    final avgWeeklyDist = weekCount > 0 ? totalDist / weekCount : 0.0;

    return WeeklyTrendData(
      weeks: points,
      maxDistanceMeters: maxDist > 0 ? maxDist : 10000.0,
      minPaceSecPerKm: minPace.isFinite ? minPace : 300.0,
      maxPaceSecPerKm: maxPace > 0 ? maxPace : 420.0,
      minHeartRate: minHr.isFinite ? minHr : 130.0,
      maxHeartRate: maxHr > 0 ? maxHr : 170.0,
      avgWeeklyDistanceMeters: avgWeeklyDist,
      totalPeriodDistanceMeters: totalDist,
      totalRuns: totalRunCount,
      peakWeekDistanceMeters: peakDist,
      peakWeekLabel: peakLabel,
      volumeChangePercentVsPrevWeek: volumeChange,
    );
  }
}

class WeeklyTrendHorizonNotifier extends Notifier<int> {
  @override
  int build() => 12;

  void select(int weeks) => state = weeks;
}

final weeklyTrendHorizonProvider =
    NotifierProvider<WeeklyTrendHorizonNotifier, int>(
  WeeklyTrendHorizonNotifier.new,
);

class WeeklyTrendMetricNotifier extends Notifier<String> {
  @override
  String build() => 'distance';

  void select(String metric) => state = metric;
}

final weeklyTrendMetricProvider =
    NotifierProvider<WeeklyTrendMetricNotifier, String>(
  WeeklyTrendMetricNotifier.new,
);

class WeeklyTrendInspectedIndexNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? index) => state = index;
}

final weeklyTrendInspectedIndexProvider =
    NotifierProvider<WeeklyTrendInspectedIndexNotifier, int?>(
  WeeklyTrendInspectedIndexNotifier.new,
);

/// 12/24-week trend analytics data provider.
final weeklyTrendDataProvider = FutureProvider<WeeklyTrendData>((ref) async {
  ref.watch(_activitiesMutationTickProvider);
  final db = ref.watch(appDatabaseProvider);
  final weeks = ref.watch(weeklyTrendHorizonProvider);
  final sinceUtc =
      DateTime.now().toUtc().subtract(Duration(days: (weeks * 7) + 14));
  final activities = await db.getValidActivitiesSince(sinceUtc);
  return WeeklyTrendData.fromActivities(
    activities: activities,
    weekCount: weeks,
  );
});
