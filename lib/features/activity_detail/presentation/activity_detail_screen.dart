import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/unit_formatter.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../backup/application/backup_providers.dart';
import '../../feed/application/feed_providers.dart';
import '../../import/application/import_providers.dart';
import '../../stats/application/stats_providers.dart';
import '../../story_share/presentation/story_editor_screen.dart';
import '../application/activity_detail_providers.dart';
import 'widgets/activity_route_map.dart';
import 'widgets/hr_zones_card.dart';
import 'widgets/splits_table.dart';
import 'widgets/synced_metrics_chart.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    this.mapTileProvider,
  });

  final int activityId;

  /// Optional override used in widget tests to avoid network tile calls.
  final TileProvider? mapTileProvider;

  @override
  ConsumerState<ActivityDetailScreen> createState() =>
      _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  int? _selectedChartIndex;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(activityDetailProvider(widget.activityId));
    final prefsAsync = ref.watch(userPreferencesProvider);
    final effortsAsync = ref.watch(activityBestEffortsProvider(widget.activityId));
    final allPrsAsync = ref.watch(allTimeBestEffortsProvider);
    final colors = context.fitColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(detailAsync.value?.activity.title ?? 'Detail Lari'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ubah Nama Aktivitas',
            icon: const Icon(Icons.edit_outlined),
            onPressed: detailAsync.value == null
                ? null
                : () => _renameActivity(
                      context,
                      detailAsync.value!.activity.id,
                      detailAsync.value!.activity.title,
                    ),
          ),
          IconButton(
            tooltip: 'Buat Story Card',
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            onPressed: detailAsync.value == null
                ? null
                : () => _openStoryEditor(context, detailAsync.value!),
          ),
          IconButton(
            tooltip: 'Hapus Aktivitas',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat detail: $err')),
        data: (bundle) {
          if (bundle == null) {
            return const Center(child: Text('Aktivitas tidak ditemukan.'));
          }

          final act = bundle.activity;
          final unitSystem = prefsAsync.value?.unitSystem ?? 'metric';
          final distText = UnitFormatter.formatDistanceValue(
            act.distanceMeters,
            unitSystem,
          );
          final distUnit = UnitFormatter.distanceUnitLabel(
            unitSystem,
            upperCase: true,
          );
          final selectedPoint =
              (_selectedChartIndex != null &&
                      _selectedChartIndex! >= 0 &&
                      _selectedChartIndex! < bundle.chartPoints.length)
                  ? bundle.chartPoints[_selectedChartIndex!]
                  : null;

          final hrThresholds = prefsAsync.value?.hrZoneThresholds ??
              const <int>[60, 70, 80, 90];

          return ListView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            children: <Widget>[
              // 1. Header & Hero numbers (§2.4 #1)
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      formatActivityLocalDate(
                        act.startTimeUtc,
                        act.utcOffsetSeconds,
                      ),
                      style: AppTypography.metricLabel(colors.textSecondary),
                    ),
                  ),
                  if (GpsQuality.fromStorageKey(act.gpsQuality) ==
                      GpsQuality.degraded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.hairlineBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GPS SPIKE FILTERED',
                        style: AppTypography.chartAxis(colors.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Hero(
                tag: 'activity_title_${act.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    act.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(distText, style: AppTypography.heroDistance(colors.textPrimary)),
                  const SizedBox(width: 8),
                  Text(distUnit, style: AppTypography.metricLabel(colors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _HeroSubMetric(
                      label: 'AVG PACE',
                      value: UnitFormatter.formatPaceWithUnit(
                        act.avgPaceSecPerKm,
                        unitSystem,
                      ),
                      colors: colors,
                    ),
                  ),
                  Expanded(
                    child: _HeroSubMetric(
                      label: 'MOVING TIME',
                      value: formatDuration(act.durationMovingSec),
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _CompactStat(
                          label: 'AVG HR',
                          value: act.avgHeartRate != null
                              ? '${act.avgHeartRate!.round()} bpm'
                              : '—',
                          colors: colors,
                        ),
                      ),
                      Expanded(
                        child: _CompactStat(
                          label: 'ELEV GAIN',
                          value: UnitFormatter.formatElevation(
                            act.totalElevationGainM,
                            unitSystem,
                            signed: true,
                          ),
                          colors: colors,
                        ),
                      ),
                      Expanded(
                        child: _CompactStat(
                          label: 'KALORI',
                          value: act.caloriesKcal > 0
                              ? '${act.caloriesKcal} kcal'
                              : '—',
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Map (M3-03)
              ActivityRouteMap(
                bundle: bundle,
                selectedPoint: selectedPoint,
                tileProvider: widget.mapTileProvider ??
                    ref.read(mapTileProviderFactoryProvider)(),
              ),
              const SizedBox(height: 16),

              // 3. Synchronized interactive chart (M3-04)
              SyncedMetricsChart(
                points: bundle.chartPoints,
                selectedIndex: _selectedChartIndex,
                unitSystem: unitSystem,
                onSelectedIndexChanged: (idx) {
                  setState(() => _selectedChartIndex = idx);
                },
              ),
              const SizedBox(height: 16),

              // 4. Splits table per km (M3-05)
              SplitsTable(
                splits: bundle.lapSplits,
                unitSystem: unitSystem,
              ),
              const SizedBox(height: 16),

              // 5. HR Zone distribution (M3-06)
              HrZonesCard(
                zoneDurationsSec: act.zoneDurationsSec,
                thresholdsPercent: hrThresholds,
              ),
              const SizedBox(height: 16),

              // 5b. Best Efforts / PR & VDOT estimate (M2-10, M2-11)
              _DetailPerformanceCard(
                efforts: effortsAsync.value ?? const [],
                allPrs: allPrsAsync.value ?? const {},
                activityId: act.id,
                distanceMeters: act.distanceMeters,
                movingDurationSec: act.durationMovingSec,
                unitSystem: unitSystem,
                colors: colors,
              ),
              const SizedBox(height: 16),

              // 6. Actions (§2.4 #6, M5-01)
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openStoryEditor(context, bundle),
                      icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 18),
                      label: const Text('Buat Story Card'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportFitFile(context, act.id),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Ekspor .FIT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportFitFile(BuildContext context, int activityId) async {
    try {
      final result = await ref
          .read(fitExportServiceProvider)
          .exportAndSaveFit(activityId);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      if (result.savedUri == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Ekspor .FIT dibatalkan.')),
        );
      } else {
        final modeNote = result.payload.isRegenerated
            ? 'diregenerasi dari SQLite'
            : 'arsip asli';
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengekspor ${result.payload.fileName} ($modeNote).',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Gagal mengekspor .FIT: $error')),
        );
    }
  }

  Future<void> _renameActivity(
    BuildContext context,
    int activityId,
    String currentTitle,
  ) async {
    final res = await showDialog<TextInputDialogResult>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Ubah Nama Aktivitas',
        initialValue: currentTitle,
        labelText: 'Judul Aktivitas',
      ),
    );
    if (res == null || res.action != 'save' || !context.mounted) return;
    final trimmed = res.text.trim();
    if (trimmed.isEmpty) return;
    await ref
        .read(appDatabaseProvider)
        .renameActivity(activityId: activityId, newTitle: trimmed);
  }

  void _openStoryEditor(BuildContext context, ActivityDetailBundle bundle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryEditorScreen(bundle: bundle),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus aktivitas?'),
        content: const Text(
          'Trackpoints, splits, dan thumbnail aktivitas ini akan dihapus dari penyimpanan lokal.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(importControllerProvider.notifier)
        .deleteActivity(widget.activityId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _HeroSubMetric extends StatelessWidget {
  const _HeroSubMetric({
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
        Text(
          value,
          style: AppTypography.paceLarge(colors.textPrimary).copyWith(
            fontSize: 28,
          ),
        ),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
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

class _DetailPerformanceCard extends StatelessWidget {
  const _DetailPerformanceCard({
    required this.efforts,
    required this.allPrs,
    required this.activityId,
    required this.distanceMeters,
    required this.movingDurationSec,
    required this.unitSystem,
    required this.colors,
  });

  final List<dynamic> efforts;
  final Map<String, dynamic> allPrs;
  final int activityId;
  final double distanceMeters;
  final int movingDurationSec;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final runVdot = VdotPredictor.computeVdot(
      distanceMeters: distanceMeters,
      durationSec: movingDurationSec,
    );

    if (efforts.isEmpty && runVdot == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'BEST EFFORTS & ESTIMASI PERFORMA',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            if (runVdot != null) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Estimasi VO2max (VDOT-lite)',
                      style: AppTypography.splitTable(colors.textSecondary),
                    ),
                  ),
                  Text(
                    '${runVdot.toStringAsFixed(1)} ml/kg/min',
                    style: AppTypography.splitTable(colors.textPrimary),
                  ),
                ],
              ),
            ],
            if (efforts.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),
              for (final effort in efforts) ...<Widget>[
                Builder(
                  builder: (context) {
                    final distEnum = BestEffortDistance.fromStorageKey(
                      effort.distanceKey as String,
                    );
                    final pr = allPrs[effort.distanceKey];
                    final isAllTimePr = pr != null && pr.activityId == activityId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 112,
                            child: Text(
                              distEnum?.label ?? (effort.distanceKey as String),
                              style:
                                  AppTypography.splitTable(colors.textSecondary),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${formatDuration(effort.durationSec as int)} '
                              '(${UnitFormatter.formatPaceWithUnit(effort.paceSecPerKm as double, unitSystem)})',
                              style:
                                  AppTypography.splitTable(colors.textPrimary),
                            ),
                          ),
                          if (isAllTimePr)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentSharp,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PR',
                                style: AppTypography.chartAxis(colors.bgBase),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
