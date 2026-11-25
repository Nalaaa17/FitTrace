import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../domain/interval_session.dart';

class IntervalBreakdownCard extends StatelessWidget {
  const IntervalBreakdownCard({
    super.key,
    required this.result,
    required this.unitSystem,
  });

  final IntervalAnalysisResult result;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    if (!result.isIntervalSession || result.reps.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lari Stabil — Pola interval tidak terdeteksi.',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFontFamily,
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final reps = result.reps;
    final accent = colors.accentWarning;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.speed_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'DETEKSI INTERVAL OTOMATIS',
                      style: AppTypography.metricLabel(colors.textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${reps.length}x REPETISI',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFontFamily,
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.hairlineBorder),

          // Summary stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    colors: colors,
                    label: 'TOTAL KERJA',
                    value: UnitFormatter.formatShortDistance(
                      result.totalWorkDistanceMeters,
                      unitSystem,
                    ),
                  ),
                ),
                Container(height: 28, width: 1, color: colors.hairlineBorder),
                Expanded(
                  child: _buildSummaryMetric(
                    colors: colors,
                    label: 'PACE RATA-RATA',
                    value: UnitFormatter.formatPace(
                      result.avgWorkPaceSecPerKm,
                      unitSystem,
                    ),
                  ),
                ),
                Container(height: 28, width: 1, color: colors.hairlineBorder),
                Expanded(
                  child: _buildSummaryMetric(
                    colors: colors,
                    label: 'WAKTU ISTIRAHAT',
                    value: _formatDur(result.totalRestDurationSec),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.hairlineBorder),

          // Reps List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reps.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: colors.hairlineBorder),
            itemBuilder: (ctx, idx) {
              final rep = reps[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Work Segment
                    Row(
                      children: [
                        Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REP ${rep.repIndex}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFontFamily,
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            UnitFormatter.formatShortDistance(
                              rep.workDistanceMeters,
                              unitSystem,
                            ),
                            style: AppTypography.splitTable(colors.textPrimary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          UnitFormatter.formatPace(
                            rep.workPaceSecPerKm,
                            unitSystem,
                          ),
                          style: AppTypography.splitTable(accent).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDur(rep.workDurationSec),
                          style: AppTypography.splitTable(colors.textSecondary).copyWith(
                            fontSize: 12,
                          ),
                        ),
                        if (rep.workAvgHeartRate != null) ...[
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: colors.accentDanger,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${rep.workAvgHeartRate!.round()}',
                                style: AppTypography.chartAxis(colors.textSecondary).copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    // Rest Segment (if duration > 0)
                    if (rep.restDurationSec > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 64,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.trackBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Istirahat',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFontFamily,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              UnitFormatter.formatShortDistance(
                                rep.restDistanceMeters,
                                unitSystem,
                              ),
                              style: AppTypography.splitTable(colors.textSecondary).copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            rep.restPaceSecPerKm > 0
                                ? UnitFormatter.formatPace(
                                    rep.restPaceSecPerKm,
                                    unitSystem,
                                  )
                                : '—',
                            style: AppTypography.splitTable(colors.textSecondary).copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDur(rep.restDurationSec),
                            style: AppTypography.splitTable(colors.textSecondary).copyWith(
                              fontSize: 12,
                            ),
                          ),
                          if (rep.restAvgHeartRate != null) ...[
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  color: colors.textSecondary,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${rep.restAvgHeartRate!.round()}',
                                  style: AppTypography.chartAxis(colors.textSecondary).copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required FitTraceColors colors,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.chartAxis(colors.textSecondary).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.splitTable(colors.textPrimary).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static String _formatDur(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }
}
