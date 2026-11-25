import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/utils/unit_formatter.dart';

class FeedFilterNotifier extends Notifier<ActivityFeedFilter> {
  @override
  ActivityFeedFilter build() => const ActivityFeedFilter();

  void update(ActivityFeedFilter filter) => state = filter;

  void reset() => state = const ActivityFeedFilter();
}

final feedFilterProvider =
    NotifierProvider<FeedFilterNotifier, ActivityFeedFilter>(
  FeedFilterNotifier.new,
);

class FeedPagingState {
  const FeedPagingState({
    this.items = const <ActivityRecord>[],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<ActivityRecord> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  FeedPagingState copyWith({
    List<ActivityRecord>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? Function()? errorMessage,
  }) {
    return FeedPagingState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

final _feedMutationTickProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActivitiesMutationTick();
});

/// Paginated Activity Feed controller (30 items per page, PRD M3-01 & M3-02).
class FeedPagingNotifier extends Notifier<FeedPagingState> {
  static const int pageSize = 30;
  int _generation = 0;

  @override
  FeedPagingState build() {
    final filter = ref.watch(feedFilterProvider);
    final db = ref.watch(appDatabaseProvider);

    Timer? debounceTimer;
    ref.listen<AsyncValue<int>>(_feedMutationTickProvider, (prev, next) {
      if (prev?.value != next.value && next.hasValue) {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 500), () {
          refresh();
        });
      }
    });
    ref.onDispose(() => debounceTimer?.cancel());

    final currentGen = ++_generation;
    Future<void>.microtask(() => _loadFirstPage(db, filter, currentGen));
    return const FeedPagingState();
  }

  Future<void> _loadFirstPage(
    AppDatabase db,
    ActivityFeedFilter filter,
    int generation,
  ) async {
    try {
      final firstPage = await db.fetchFeedActivities(
        filter: filter,
        limit: pageSize,
        offset: 0,
      );
      if (generation != _generation) return;
      state = FeedPagingState(
        items: firstPage,
        isInitialLoading: false,
        hasMore: firstPage.length == pageSize,
      );
    } on Object catch (error) {
      if (generation != _generation) return;
      state = FeedPagingState(
        isInitialLoading: false,
        hasMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;

    final db = ref.read(appDatabaseProvider);
    final filter = ref.read(feedFilterProvider);
    final currentGen = _generation;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = await db.fetchFeedActivities(
        filter: filter,
        limit: pageSize,
        offset: state.items.length,
      );
      if (currentGen != _generation) return;
      state = state.copyWith(
        items: <ActivityRecord>[...state.items, ...nextPage],
        isLoadingMore: false,
        hasMore: nextPage.length == pageSize,
      );
    } on Object catch (error) {
      if (currentGen != _generation) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: () => error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    final db = ref.read(appDatabaseProvider);
    final filter = ref.read(feedFilterProvider);
    final currentGen = ++_generation;
    await _loadFirstPage(db, filter, currentGen);
  }
}

final feedPagingProvider =
    NotifierProvider<FeedPagingNotifier, FeedPagingState>(
  FeedPagingNotifier.new,
);

/// Formats a pace in seconds per kilometer as `MM'SS"` (PRD M2-07).
String formatPace(double paceSecPerKm) =>
    UnitFormatter.formatPaceRaw(paceSecPerKm);

/// Formats elapsed/moving seconds as `HH:MM:SS` or `MM:SS`.
String formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '00:00';
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Formats UTC timestamp shifted by activity's stored local offset (PRD §7).
String formatActivityLocalDate(DateTime startTimeUtc, int utcOffsetSeconds) {
  final local = startTimeUtc.toUtc().add(Duration(seconds: utcOffsetSeconds));
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month ${local.year} • $hour:$minute';
}

/// Human-readable label for feed badge (`TERSINKRON` / `HANYA LOKAL` / `GAGAL`).
String syncBadgeLabel(String rawStatus) {
  switch (SyncStatus.fromStorageKey(rawStatus)) {
    case SyncStatus.synced:
      return 'TERSINKRON';
    case SyncStatus.localOnly:
      return 'HANYA LOKAL';
    case SyncStatus.failed:
    case SyncStatus.parseFailed:
      return 'GAGAL';
  }
}
