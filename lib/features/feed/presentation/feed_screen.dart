import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/unit_formatter.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../activity_detail/presentation/activity_detail_screen.dart';
import '../../backup/application/backup_providers.dart';
import '../../garmin_sync/application/garmin_sync_providers.dart';
import '../../garmin_sync/domain/garmin_session.dart';
import '../../garmin_sync/presentation/garmin_webview_login_screen.dart';
import '../../import/application/import_providers.dart';
import '../../import/domain/activity_import_source.dart';
import '../../stats/application/stats_providers.dart';
import '../../weekly_target/presentation/widgets/weekly_target_card.dart';
import '../application/feed_providers.dart';
import '../data/thumbnail_cache_service.dart';
import 'feed_filter_sheet.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;
  DateTime? _lastSyncAttemptAt;
  static const Duration _manualSyncCooldown = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _toggleSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        final current = ref.read(feedFilterProvider);
        if (current.searchQuery != null) {
          ref
              .read(feedFilterProvider.notifier)
              .update(current.copyWith(searchQuery: () => null));
        }
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = value.trim();
      final current = ref.read(feedFilterProvider);
      ref.read(feedFilterProvider.notifier).update(
            current.copyWith(
              searchQuery: () => trimmed.isEmpty ? null : trimmed,
            ),
          );
    });
  }

  Future<void> _renameActivity(ActivityRecord activity) async {
    final res = await showDialog<TextInputDialogResult>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Ubah Nama Aktivitas',
        initialValue: activity.title,
        labelText: 'Judul Aktivitas',
        hintText: 'Contoh: Sunday Long Run GBK',
      ),
    );
    if (res == null || res.action != 'save' || !mounted) return;
    final trimmed = res.text.trim();
    if (trimmed.isEmpty) return;
    await ref
        .read(appDatabaseProvider)
        .renameActivity(activityId: activity.id, newTitle: trimmed);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(feedPagingProvider.notifier).loadMore();
    }
  }

  Future<void> _triggerManualImport() async {
    final summary =
        await ref.read(importControllerProvider.notifier).importFromFilePicker();
    if (!mounted || summary == null) return;
    _showBatchSummarySnackBar(summary);
  }

  Future<void> _triggerGarminSync({bool showCooldownFeedback = false}) async {
    final now = DateTime.now();
    if (_lastSyncAttemptAt != null &&
        now.difference(_lastSyncAttemptAt!) < _manualSyncCooldown) {
      if (showCooldownFeedback && mounted) {
        final remainingSec = _manualSyncCooldown.inSeconds -
            now.difference(_lastSyncAttemptAt!).inSeconds;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Sinkronisasi baru saja dilakukan. Tunggu $remainingSec detik.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
      }
      return;
    }
    _lastSyncAttemptAt = now;

    final result =
        await ref.read(garminSyncControllerProvider.notifier).syncNow();
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.summaryBannerText)));
  }

  Future<void> _openReloginWebView({required bool isChallenge}) async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            GarminWebViewLoginScreen(isChallengeFallback: isChallenge),
      ),
    );
    if (success == true && mounted) {
      await _triggerGarminSync();
    }
  }

  void _showBatchSummarySnackBar(BatchImportSummary summary) {
    final text =
        '${summary.importedCount} baru • ${summary.updatedCount} diperbarui • '
        '${summary.skippedCount} dilewati'
        '${summary.failedCount > 0 ? ' • ${summary.failedCount} gagal' : ''}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openFilterSheet() async {
    final current = ref.read(feedFilterProvider);
    final updated = await showModalBottomSheet<ActivityFeedFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FeedFilterSheet(initialFilter: current),
    );
    if (updated != null) {
      ref.read(feedFilterProvider.notifier).update(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagingState = ref.watch(feedPagingProvider);
    final filter = ref.watch(feedFilterProvider);
    final importState = ref.watch(importControllerProvider);
    final syncState = ref.watch(garminSyncControllerProvider);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final statsAsync = ref.watch(aggregateStatsProvider);
    final prsAsync = ref.watch(allTimeBestEffortsProvider);
    final backupReminderAsync = ref.watch(backupReminderProvider);
    final colors = context.fitColors;
    final garminConnected = prefsAsync.value?.garminLoggedIn ?? false;
    final unitSystem = prefsAsync.value?.unitSystem ?? 'metric';

    final prLabelsByActivity = <int, List<String>>{};
    final prs = prsAsync.value;
    if (prs != null) {
      for (final entry in prs.entries) {
        final badge = switch (entry.key) {
          '5k' => 'PR 5K',
          '10k' => 'PR 10K',
          'hm' => 'PR HM',
          'fm' => 'PR FM',
          _ => 'PR',
        };
        (prLabelsByActivity[entry.value.activityId] ??= <String>[]).add(badge);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                key: const ValueKey<String>('feed_search_field'),
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Cari judul aktivitas...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('FitTrace'),
                ],
              ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('feed_search_toggle'),
            tooltip: _isSearching ? 'Tutup Pencarian' : 'Cari Aktivitas',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: 'Filter Aktivitas',
            icon: Icon(
              filter.isEmpty ? Icons.filter_list : Icons.filter_alt,
            ),
            onPressed: _openFilterSheet,
          ),
          IconButton(
            tooltip: 'Impor .FIT',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: importState.isImporting ? null : _triggerManualImport,
          ),
        ],
      ),
      floatingActionButton: garminConnected
          ? FloatingActionButton(
              tooltip: 'Sinkronkan Garmin',
              backgroundColor: colors.accentSharp,
              foregroundColor: colors.bgBase,
              onPressed: syncState.isSyncing
                  ? null
                  : () => _triggerGarminSync(showCooldownFeedback: true),
              child: const Icon(Icons.sync_rounded),
            )
          : null,
      body: Column(
        children: <Widget>[
          if (backupReminderAsync.value?.isDue ?? false)
            _BackupReminderBanner(
              reason: backupReminderAsync.value!.reason ??
                  'Sudah > 30 hari sejak backup terakhir.',
              colors: colors,
              onBackupTap: () async {
                final res = await ref
                    .read(backupControllerProvider.notifier)
                    .exportFullBackupZip();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        res.saved
                            ? 'Backup ZIP berhasil disimpan.'
                            : 'Backup dibatalkan.',
                      ),
                    ),
                  );
              },
              onDismissTap: () => ref
                  .read(backupReminderServiceProvider)
                  .snoozeReminder()
                  .then((_) => ref.invalidate(backupReminderProvider)),
            ),
          if (garminConnected && syncState.needsUserAttention)
            _GarminAttentionBanner(
              isChallenge:
                  syncState.authStatus == GarminAuthStatus.challengeRequired,
              message: syncState.errorMessage,
              colors: colors,
              onResolveTap: () => _openReloginWebView(
                isChallenge: syncState.authStatus ==
                    GarminAuthStatus.challengeRequired,
              ),
            ),
          if (syncState.isSyncing)
            _LinearProgressBanner(
              message: syncState.statusMessage ?? 'Menyinkronkan Garmin...',
              completed: syncState.completed,
              total: syncState.total,
              colors: colors,
            ),
          if (!syncState.isSyncing &&
              syncState.errorMessage != null &&
              !syncState.needsUserAttention)
            _SyncErrorBanner(
              message: syncState.errorMessage!,
              colors: colors,
              onRetryTap: _triggerGarminSync,
            ),
          if (importState.isImporting)
            _LinearProgressBanner(
              message: importState.total > 0
                  ? 'Mengimpor file .FIT (${importState.completed}/${importState.total})...'
                  : 'Mempersiapkan impor .FIT...',
              completed: importState.completed,
              total: importState.total,
              colors: colors,
            ),
          if (!filter.isEmpty)
            _ActiveFilterBar(
              filter: filter,
              onClear: () {
                _searchController.clear();
                setState(() => _isSearching = false);
                ref.read(feedFilterProvider.notifier).reset();
              },
              colors: colors,
            ),
          Expanded(
            child: _buildBody(
              context,
              pagingState: pagingState,
              filter: filter,
              garminConnected: garminConnected,
              unitSystem: unitSystem,
              statsAsync: statsAsync,
              prLabelsByActivity: prLabelsByActivity,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required FeedPagingState pagingState,
    required ActivityFeedFilter filter,
    required bool garminConnected,
    required String unitSystem,
    required AsyncValue<ActivityAggregateStats> statsAsync,
    required Map<int, List<String>> prLabelsByActivity,
    required FitTraceColors colors,
  }) {
    if (pagingState.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pagingState.errorMessage != null && pagingState.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          child: Text(
            'Gagal memuat aktivitas: ${pagingState.errorMessage}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (pagingState.items.isEmpty) {
      return _EmptyFeedState(
        hasActiveFilter: !filter.isEmpty,
        garminConnected: garminConnected,
        onImportTap: _triggerManualImport,
        onResetFilterTap: () => ref.read(feedFilterProvider.notifier).reset(),
        onSyncTap: () => _triggerGarminSync(showCooldownFeedback: true),
      );
    }

    final itemCount =
        pagingState.items.length + 1 + (pagingState.isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async {
        if (garminConnected) {
          await _triggerGarminSync();
        }
        await ref.read(feedPagingProvider.notifier).refresh();
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const WeeklyTargetCard();
          }

          final activityIndex = index - 1;
          if (activityIndex >= pagingState.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final activity = pagingState.items[activityIndex];
          final syncStatus = SyncStatus.fromStorageKey(activity.syncStatus);
          final isFailed = syncStatus == SyncStatus.parseFailed ||
              syncStatus == SyncStatus.failed;

          if (isFailed) {
            final isDownloadFailure = syncStatus == SyncStatus.failed;
            return _FailedActivityCard(
              activity: activity,
              isDownloadFailure: isDownloadFailure,
              colors: colors,
              onRetry: () async {
                final outcome = isDownloadFailure
                    ? await ref
                        .read(garminSyncControllerProvider.notifier)
                        .retryFailedActivity(activity.id)
                    : await ref
                        .read(importControllerProvider.notifier)
                        .retryFailedActivity(activity.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        outcome.type == ImportOutcomeType.imported ||
                                outcome.type == ImportOutcomeType.reparsed
                            ? 'Berhasil memproses ulang ${outcome.label}.'
                            : 'Gagal memproses ulang: ${outcome.errorMessage ?? ''}',
                      ),
                    ),
                  );
              },
              onDelete: () => ref
                  .read(importControllerProvider.notifier)
                  .deleteActivity(activity.id),
            );
          }

          return _ActivitySummaryCard(
            activity: activity,
            unitSystem: unitSystem,
            colors: colors,
            thumbnails: ref.read(thumbnailCacheServiceProvider),
            prBadges: prLabelsByActivity[activity.id] ?? const <String>[],
            onRenameTap: () => _renameActivity(activity),
            onDeleteTap: () => ref
                .read(importControllerProvider.notifier)
                .deleteActivity(activity.id),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActivityDetailScreen(activityId: activity.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LinearProgressBanner extends StatelessWidget {
  const _LinearProgressBanner({
    required this.message,
    required this.completed,
    required this.total,
    required this.colors,
  });

  final String message;
  final int completed;
  final int total;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.hairlineBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: AppTypography.splitTable(colors.textPrimary)
                .copyWith(fontSize: 13),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.filter,
    required this.onClear,
    required this.colors,
  });

  final ActivityFeedFilter filter;
  final VoidCallback onClear;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty)
        'Cari: "${filter.searchQuery!.trim()}"',
      if (filter.startDateUtc != null) 'Rentang Tanggal',
      if (filter.sportTypeCode != null)
        SportType.fromCode(filter.sportTypeCode!).label,
      if (filter.sourceKey != null)
        filter.sourceKey == ActivitySource.garminSync.storageKey
            ? 'Garmin Sync'
            : 'Import Manual',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.hairlineBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Filter: ${labels.join(' • ')}',
              style: AppTypography.chartAxis(colors.textSecondary)
                  .copyWith(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Hapus Filter'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState({
    required this.hasActiveFilter,
    required this.garminConnected,
    required this.onImportTap,
    required this.onResetFilterTap,
    required this.onSyncTap,
  });

  final bool hasActiveFilter;
  final bool garminConnected;
  final VoidCallback onImportTap;
  final VoidCallback onResetFilterTap;
  final VoidCallback onSyncTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.directions_run_rounded,
                  size: 40,
                  color: colors.accentSharp,
                ),
                const SizedBox(height: 16),
                Text(
                  hasActiveFilter
                      ? 'TIDAK ADA AKTIVITAS SESUAI FILTER'
                      : 'BELUM ADA AKTIVITAS LARI',
                  style: AppTypography.metricLabel(colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hasActiveFilter
                      ? 'Ubah atau reset filter untuk melihat aktivitas tersimpan.'
                      : 'Impor file .FIT dari perangkat Anda atau bagikan langsung ke FitTrace.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (hasActiveFilter)
                  FilledButton(
                    onPressed: onResetFilterTap,
                    child: const Text('Reset Filter'),
                  )
                else
                  FilledButton.icon(
                    onPressed: onImportTap,
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: const Text('Impor File .FIT'),
                  ),
                if (!hasActiveFilter && garminConnected) ...<Widget>[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onSyncTap,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Sinkronkan Garmin'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivitySummaryCard extends StatelessWidget {
  const _ActivitySummaryCard({
    required this.activity,
    required this.unitSystem,
    required this.colors,
    required this.thumbnails,
    this.prBadges = const <String>[],
    this.onRenameTap,
    this.onDeleteTap,
    required this.onTap,
  });

  final ActivityRecord activity;
  final String unitSystem;
  final FitTraceColors colors;
  final ThumbnailCacheService thumbnails;
  final List<String> prBadges;
  final VoidCallback? onRenameTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dist = UnitFormatter.formatDistanceValue(
      activity.distanceMeters,
      unitSystem,
    );
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem);
    final pace = UnitFormatter.formatPace(activity.avgPaceSecPerKm, unitSystem);
    final hr = activity.avgHeartRate != null
        ? '${activity.avgHeartRate!.round()} bpm'
        : '—';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onRenameTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              _ThumbnailPreview(
                activity: activity,
                thumbnails: thumbnails,
                colors: colors,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            formatActivityLocalDate(
                              activity.startTimeUtc,
                              activity.utcOffsetSeconds,
                            ),
                            style:
                                AppTypography.chartAxis(colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.hairlineBorder),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            syncBadgeLabel(activity.syncStatus),
                            style: AppTypography.chartAxis(
                              colors.textSecondary,
                            ),
                          ),
                        ),
                        if (onRenameTap != null || onDeleteTap != null)
                          PopupMenuButton<String>(
                            tooltip: 'Opsi Aktivitas',
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            onSelected: (value) {
                              if (value == 'rename') {
                                onRenameTap?.call();
                              } else if (value == 'delete') {
                                onDeleteTap?.call();
                              }
                            },
                            itemBuilder: (_) => const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text('Ubah Nama'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Hero(
                      tag: 'activity_title_${activity.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          activity.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (prBadges.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: prBadges
                            .map(
                              (badge) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accentSharp,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge,
                                  style: AppTypography.chartAxis(colors.bgBase),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MetricPair(
                            label: 'JARAK',
                            value: '$dist $distUnit',
                            colors: colors,
                          ),
                        ),
                        Expanded(
                          child: _MetricPair(
                            label: 'PACE',
                            value: pace,
                            colors: colors,
                          ),
                        ),
                        Expanded(
                          child: _MetricPair(
                            label: 'HR',
                            value: hr,
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailPreview extends StatefulWidget {
  const _ThumbnailPreview({
    required this.activity,
    required this.thumbnails,
    required this.colors,
  });

  final ActivityRecord activity;
  final ThumbnailCacheService thumbnails;
  final FitTraceColors colors;

  @override
  State<_ThumbnailPreview> createState() => _ThumbnailPreviewState();
}

class _ThumbnailPreviewState extends State<_ThumbnailPreview> {
  Future<File?>? _thumbFuture;

  @override
  void initState() {
    super.initState();
    _resolveFuture();
  }

  @override
  void didUpdateWidget(covariant _ThumbnailPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.id != widget.activity.id ||
        oldWidget.activity.updatedAt != widget.activity.updatedAt) {
      _resolveFuture();
    }
  }

  void _resolveFuture() {
    if (widget.activity.isIndoor || !widget.activity.hasGpsTrack) {
      _thumbFuture = null;
    } else {
      _thumbFuture = widget.thumbnails.getExistingThumbnail(widget.activity.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    if (widget.activity.isIndoor || !widget.activity.hasGpsTrack) {
      return Container(
        width: 96,
        height: 64,
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.hairlineBorder),
        ),
        child: Center(
          child: Text(
            'INDOOR',
            style: AppTypography.chartAxis(colors.textSecondary),
          ),
        ),
      );
    }

    return FutureBuilder<File?>(
      future: _thumbFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        return Container(
          width: 96,
          height: 64,
          decoration: BoxDecoration(
            color: colors.bgBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.hairlineBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: file != null
              ? Image.file(
                  file,
                  fit: BoxFit.cover,
                  cacheWidth: 288,
                )
              : Center(
                  child: Icon(
                    Icons.route_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
        );
      },
    );
  }
}

class _GarminAttentionBanner extends StatelessWidget {
  const _GarminAttentionBanner({
    required this.isChallenge,
    required this.message,
    required this.colors,
    required this.onResolveTap,
  });

  final bool isChallenge;
  final String? message;
  final FitTraceColors colors;
  final VoidCallback onResolveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(
          bottom: BorderSide(color: colors.accentSharp.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isChallenge
                ? Icons.security_rounded
                : Icons.lock_reset_rounded,
            size: 18,
            color: colors.accentSharp,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ??
                  (isChallenge
                      ? 'Verifikasi keamanan Garmin (CAPTCHA/Cloudflare) diperlukan.'
                      : 'Sesi Garmin Connect kedaluwarsa. Login ulang untuk melanjutkan sinkronisasi.'),
              style: AppTypography.chartAxis(colors.textPrimary)
                  .copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onResolveTap,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isChallenge ? 'Verifikasi' : 'Login Ulang'),
          ),
        ],
      ),
    );
  }
}

class _SyncErrorBanner extends StatelessWidget {
  const _SyncErrorBanner({
    required this.message,
    required this.colors,
    required this.onRetryTap,
  });

  final String message;
  final FitTraceColors colors;
  final VoidCallback onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.hairlineBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              message,
              style: AppTypography.chartAxis(colors.textSecondary)
                  .copyWith(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetryTap,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _FailedActivityCard extends StatelessWidget {
  const _FailedActivityCard({
    required this.activity,
    required this.isDownloadFailure,
    required this.colors,
    required this.onRetry,
    required this.onDelete,
  });

  final ActivityRecord activity;
  final bool isDownloadFailure;
  final FitTraceColors colors;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(
          color: colors.accentSharp.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    activity.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.accentSharp),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'GAGAL',
                    style: AppTypography.chartAxis(colors.accentSharp),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isDownloadFailure
                  ? 'Unduhan .FIT dari Garmin gagal setelah beberapa percobaan.'
                  : 'File .FIT korup atau gagal diparse.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Hapus'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPair extends StatelessWidget {
  const _MetricPair({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.metricLabel(colors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.splitTable(colors.textPrimary)),
      ],
    );
  }
}

class _BackupReminderBanner extends StatelessWidget {
  const _BackupReminderBanner({
    required this.reason,
    required this.colors,
    required this.onBackupTap,
    required this.onDismissTap,
  });

  final String reason;
  final FitTraceColors colors;
  final VoidCallback onBackupTap;
  final VoidCallback onDismissTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.hairlineBorder)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.archive_outlined, size: 18, color: colors.accentSharp),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: AppTypography.chartAxis(colors.textPrimary)
                  .copyWith(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onDismissTap,
            child: const Text('Nanti'),
          ),
          OutlinedButton(
            onPressed: onBackupTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }
}
