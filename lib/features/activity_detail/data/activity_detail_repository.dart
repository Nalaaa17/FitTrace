import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Repository abstraction for single-activity analytics & metadata.
abstract class ActivityDetailRepository {
  Future<ActivityRecord?> getActivityById(int activityId);
  Future<List<TrackPointRecord>> getTrackPoints(int activityId);
  Future<List<LapSplitRecord>> getLapSplits(int activityId);
  Future<List<BestEffortRecord>> getBestEfforts(int activityId);
  Future<Map<String, BestEffortPrRecord>> getAllTimeBestEffortPrs();
}

class DriftActivityDetailRepository implements ActivityDetailRepository {
  const DriftActivityDetailRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ActivityRecord?> getActivityById(int activityId) =>
      _db.getActivityById(activityId);

  @override
  Future<List<TrackPointRecord>> getTrackPoints(int activityId) =>
      _db.getTrackPointsForActivity(activityId);

  @override
  Future<List<LapSplitRecord>> getLapSplits(int activityId) =>
      _db.getLapSplitsForActivity(activityId);

  @override
  Future<List<BestEffortRecord>> getBestEfforts(int activityId) =>
      _db.getBestEffortsForActivity(activityId);

  @override
  Future<Map<String, BestEffortPrRecord>> getAllTimeBestEffortPrs() =>
      _db.getAllTimeBestEffortPrs();
}

final activityDetailRepositoryProvider = Provider<ActivityDetailRepository>((ref) {
  return DriftActivityDetailRepository(ref.watch(appDatabaseProvider));
});
