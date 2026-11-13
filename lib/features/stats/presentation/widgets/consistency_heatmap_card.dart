import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/stats_providers.dart';

/// Monochrome GitHub-style 20-week running consistency heatmap (`PRD M3-09`).
class ConsistencyHeatmapCard extends StatelessWidget {
  const ConsistencyHeatmapCard({
    super.key,
    required this.data,
    required this.colors,
  });

  final ConsistencyHeatmapData data;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'KONSISTENSI & STREAK (20 MINGGU)',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StreakStat(
                    label: 'STREAK SAAT INI',
                    value: '${data.currentStreakDays} hr',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _StreakStat(
                    label: 'STREAK TERPANJANG',
                    value: '${data.longestStreakDays} hr',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _StreakStat(
                    label: 'HARI AKTIF',
                    value: '${data.activeDaysCount} hr',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <String>['S', 'S', 'R', 'K', 'J', 'S', 'M']
                        .map(
                          (day) => Container(
                            width: 14,
                            height: 14,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(bottom: 3, right: 4),
                            child: Text(
                              day,
                              style: TextStyle(fontSize: 9, color: colors.textSecondary),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  for (final week in data.weeks)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Column(
                        children: week
                            .map((cell) => _HeatmapSquare(cell: cell, colors: colors))
                            .toList(growable: false),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Sedikit',
                  style: AppTypography.chartAxis(colors.textSecondary),
                ),
                const SizedBox(width: 6),
                for (final alpha in const <double>[0.0, 0.25, 0.50, 0.78, 1.0])
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: alpha == 0.0
                          ? colors.bgBase
                          : colors.accentSharp.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: colors.hairlineBorder,
                        width: 0.7,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  'Intensif',
                  style: AppTypography.chartAxis(colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapSquare extends StatelessWidget {
  const _HeatmapSquare({
    required this.cell,
    required this.colors,
  });

  final HeatmapDayCell cell;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    if (cell.isFuture) {
      return const SizedBox(width: 14, height: 14);
    }

    final km = cell.totalDistanceMeters / 1000.0;
    final double alpha;
    if (cell.activityCount == 0) {
      alpha = 0.0;
    } else if (km < 5.0) {
      alpha = 0.28;
    } else if (km < 10.0) {
      alpha = 0.55;
    } else if (km < 21.0) {
      alpha = 0.80;
    } else {
      alpha = 1.0;
    }

    final tooltip = cell.activityCount == 0
        ? '${cell.dateLocal.day}/${cell.dateLocal.month}: Tidak ada lari'
        : '${cell.dateLocal.day}/${cell.dateLocal.month}: ${km.toStringAsFixed(1)} km (${cell.activityCount}x)';

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 11,
        height: 11,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: alpha == 0.0
              ? colors.bgBase
              : colors.accentSharp.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(
            color: colors.hairlineBorder,
            width: 0.6,
          ),
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
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
        Text(label, style: AppTypography.chartAxis(colors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.splitTable(colors.textPrimary)),
      ],
    );
  }
}

