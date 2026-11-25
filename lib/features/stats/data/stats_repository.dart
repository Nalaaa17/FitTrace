import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Repository abstraction for aggregate statistics, PRs, and VDOT samples.
abstract class StatsRepository {
  Future<ActivityAggregateStats> getAggregateStats({
    DateTime? sinceUtc,
  });
  Future<Map<String, BestEffortPrRecord>> getAllTimeBestEffortPrs();
  Future<List<PerformanceSample>> getVdotPerformanceSamples();
  Future<List<ActivityRecord>> getValidActivitiesSince(DateTime sinceUtc);
}

class DriftStatsRepository implements StatsRepository {
  const DriftStatsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ActivityAggregateStats> getAggregateStats({
    DateTime? sinceUtc,
  }) =>
      _db.getAggregateStats(sinceUtc: sinceUtc);

  @override
  Future<Map<String, BestEffortPrRecord>> getAllTimeBestEffortPrs() =>
      _db.getAllTimeBestEffortPrs();

  @override
  Future<List<PerformanceSample>> getVdotPerformanceSamples() =>
      _db.getVdotPerformanceSamples();

  @override
  Future<List<ActivityRecord>> getValidActivitiesSince(DateTime sinceUtc) =>
      _db.getValidActivitiesSince(sinceUtc);
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return DriftStatsRepository(ref.watch(appDatabaseProvider));
});
