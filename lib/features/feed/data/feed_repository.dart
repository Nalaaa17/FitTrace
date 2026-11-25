import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Repository abstraction for activity feed queries and mutations.
abstract class FeedRepository {
  Future<List<ActivityRecord>> fetchPage({
    required int limit,
    required int offset,
    ActivityFeedFilter filter = const ActivityFeedFilter(),
  });

  Future<void> renameActivity({
    required int activityId,
    required String newTitle,
  });
}

class DriftFeedRepository implements FeedRepository {
  const DriftFeedRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ActivityRecord>> fetchPage({
    required int limit,
    required int offset,
    ActivityFeedFilter filter = const ActivityFeedFilter(),
  }) =>
      _db.fetchFeedActivities(limit: limit, offset: offset, filter: filter);

  @override
  Future<void> renameActivity({
    required int activityId,
    required String newTitle,
  }) =>
      _db.renameActivity(activityId: activityId, newTitle: newTitle);
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return DriftFeedRepository(ref.watch(appDatabaseProvider));
});
