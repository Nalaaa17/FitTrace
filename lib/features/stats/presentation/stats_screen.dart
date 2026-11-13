import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/unit_formatter.dart';
import '../../activity_detail/presentation/activity_detail_screen.dart';
import '../../feed/application/feed_providers.dart';
import '../application/stats_providers.dart';
import 'widgets/consistency_heatmap_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final statsAsync = ref.watch(aggregateStatsProvider);
    final prsAsync = ref.watch(allTimeBestEffortsProvider);
    final vdotAsync = ref.watch(vdotEstimateProvider);
    final heatmapAsync = ref.watch(consistencyHeatmapProvider);
    final colors = context.fitColors;
    final period = prefsAsync.value?.weeklyMonthlyToggle ?? 'weekly';
    final unitSystem = prefsAsync.value?.unitSystem ?? 'metric';

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: <Widget>[
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'weekly',
                label: Text('Mingguan'),
              ),
              ButtonSegment<String>(
                value: 'monthly',
                label: Text('Bulanan'),
              ),
            ],
            selected: <String>{period},
            onSelectionChanged: (selection) {
              setWeeklyMonthlyMode(ref, selection.first);
            },
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Gagal menghitung statistik: $err'),
              ),
            ),
            data: (stats) {
              final dist = UnitFormatter.formatDistanceValue(
                stats.totalDistanceMeters,
                unitSystem,
              );
              final distUnit = UnitFormatter.distanceUnitLabel(
                unitSystem,
                upperCase: true,
              );
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        period == 'monthly'
                            ? 'TOTAL JARAK BULAN INI'
                            : 'TOTAL JARAK MINGGU INI',
                        style: AppTypography.metricLabel(colors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Text(
                            dist,
                            style:
                                AppTypography.heroDistance(colors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            distUnit,
                            style: AppTypography.metricLabel(
                              colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _SubStat(
                              label: 'AVG PACE',
                              value: UnitFormatter.formatPaceWithUnit(
                                stats.avgPaceSecPerKm,
                                unitSystem,
                              ),
                              colors: colors,
                            ),
                          ),
                          Expanded(
                            child: _SubStat(
                              label: 'MOVING TIME',
                              value: formatDuration(
                                stats.totalMovingDurationSec,
                              ),
                              colors: colors,
                            ),
                          ),
                          Expanded(
                            child: _SubStat(
                              label: 'AKTIVITAS',
                              value: '${stats.activityCount}',
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (heatmapAsync.hasValue)
            ConsistencyHeatmapCard(
              data: heatmapAsync.value!,
              colors: colors,
            ),
          const SizedBox(height: 16),
          _PersonalRecordsCard(
            prsAsync: prsAsync,
            unitSystem: unitSystem,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _VdotPredictorCard(
            vdotAsync: vdotAsync,
            unitSystem: unitSystem,
            colors: colors,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PersonalRecordsCard extends StatelessWidget {
  const _PersonalRecordsCard({
    required this.prsAsync,
    required this.unitSystem,
    required this.colors,
  });

  final AsyncValue<Map<String, BestEffortPrRecord>> prsAsync;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final prs = prsAsync.value ?? const <String, BestEffortPrRecord>{};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'BEST EFFORT PR (M2-10)',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (prs.isEmpty)
              Text(
                'Belum ada PR 5K / 10K / Half Marathon / Marathon. Catat minimal 5 km untuk mendeteksi segmen tercepat.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final dist in BestEffortDistance.values)
                _PrRow(
                  distance: dist,
                  record: prs[dist.storageKey],
                  unitSystem: unitSystem,
                  colors: colors,
                ),
          ],
        ),
      ),
    );
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({
    required this.distance,
    required this.record,
    required this.unitSystem,
    required this.colors,
  });

  final BestEffortDistance distance;
  final BestEffortPrRecord? record;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return InkWell(
      onTap: r == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActivityDetailScreen(activityId: r.activityId),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: r != null ? colors.accentSharp : colors.hairlineBorder,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                distance == BestEffortDistance.halfMarathon
                    ? 'HM'
                    : distance == BestEffortDistance.marathon
                        ? 'FM'
                        : distance.label,
                textAlign: TextAlign.center,
                style: AppTypography.chartAxis(
                  r != null ? colors.accentSharp : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    r != null ? formatDuration(r.durationSec) : '—',
                    style: AppTypography.splitTable(colors.textPrimary),
                  ),
                  if (r != null)
                    Text(
                      '${r.activityTitle} • ${UnitFormatter.formatPaceWithUnit(r.paceSecPerKm, unitSystem)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.chartAxis(colors.textSecondary),
                    ),
                ],
              ),
            ),
            if (r != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _VdotPredictorCard extends StatelessWidget {
  const _VdotPredictorCard({
    required this.vdotAsync,
    required this.unitSystem,
    required this.colors,
  });

  final AsyncValue<VdotEstimate?> vdotAsync;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final est = vdotAsync.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'VO2MAX & PREDIKSI LOMBA (M2-11)',
                    style: AppTypography.metricLabel(colors.textSecondary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.hairlineBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ESTIMASI',
                    style: AppTypography.chartAxis(colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (est == null)
              Text(
                'Selesaikan minimal 1 aktivitas lari ≥ 1.5 km untuk menghitung estimasi VO2max & prediksi lomba.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    est.vo2Max.toStringAsFixed(1),
                    style: AppTypography.paceLarge(colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ml/kg/min (VDOT-lite • estimasi)',
                    style: AppTypography.chartAxis(colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Basis: ${est.sourceTitle} (${formatDuration(est.sourceDurationSec)})',
                style: AppTypography.chartAxis(colors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              for (final pred in est.predictions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        child: Text(
                          pred.distance.label,
                          style: AppTypography.splitTable(colors.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatDuration(pred.predictedDurationSec),
                          style: AppTypography.splitTable(colors.textPrimary),
                        ),
                      ),
                      Text(
                        UnitFormatter.formatPaceWithUnit(
                          pred.predictedPaceSecPerKm,
                          unitSystem,
                        ),
                        style: AppTypography.chartAxis(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  const _SubStat({
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
        const SizedBox(height: 4),
        Text(value, style: AppTypography.splitTable(colors.textPrimary)),
      ],
    );
  }
}
