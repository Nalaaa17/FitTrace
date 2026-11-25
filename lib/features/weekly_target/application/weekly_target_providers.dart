import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/weekly_target_repository.dart';
import '../domain/weekly_target.dart';

class WeeklyTargetNotifier extends AsyncNotifier<WeeklyTargetProgress> {
  @override
  Future<WeeklyTargetProgress> build() async {
    // Re-fetch automatically when activities are imported, synced, or deleted.
    ref.watch(activitiesMutationTickProvider);
    final repo = ref.watch(weeklyTargetRepositoryProvider);

    final now = DateTime.now().toUtc();
    // Monday as start of week (weekday: 1 = Monday, 7 = Sunday)
    final daysSinceMonday = now.weekday - DateTime.monday;
    final mondayStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysSinceMonday));
    final sundayEnd = mondayStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    final targetKm = await repo.getWeeklyTargetKm();
    final totalMeters = await repo.getDistanceMetersBetween(
      startUtc: mondayStart,
      endUtc: sundayEnd,
    );
    final activityCount = await repo.getActivityCountBetween(
      startUtc: mondayStart,
      endUtc: sundayEnd,
    );

    final daysRemaining = 7 - now.weekday;

    return WeeklyTargetProgress(
      targetKm: targetKm,
      currentKm: totalMeters / 1000.0,
      activityCount: activityCount,
      weekStartUtc: mondayStart,
      weekEndUtc: sundayEnd,
      daysRemainingInWeek: daysRemaining,
    );
  }

  Future<void> updateTargetKm(double newTargetKm) async {
    final repo = ref.read(weeklyTargetRepositoryProvider);
    await repo.setWeeklyTargetKm(newTargetKm);
    ref.invalidateSelf();
  }
}

final weeklyTargetProvider =
    AsyncNotifierProvider<WeeklyTargetNotifier, WeeklyTargetProgress>(
  WeeklyTargetNotifier.new,
);
