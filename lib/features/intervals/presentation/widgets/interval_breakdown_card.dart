import 'package:flutter/material.dart';
import 'package:metrics_engine/metrics_engine.dart';

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
    if (!result.isIntervalSession || result.reps.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lari Berkelanjutan (Steady Run) — Pola interval tidak terdeteksi.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final reps = result.reps;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.35)),
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
                        color: const Color(0xFFFF9100).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: Color(0xFFFF9100),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'DETEKSI INTERVAL OTOMATIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9100).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${reps.length}x REPETISI',
                    style: const TextStyle(
                      color: Color(0xFFFF9100),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // Summary stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    label: 'TOTAL KERJA',
                    value: _formatDist(
                      result.totalWorkDistanceMeters,
                    ),
                  ),
                ),
                Container(height: 28, width: 1, color: Colors.white12),
                Expanded(
                  child: _buildSummaryMetric(
                    label: 'PACE KERJA RATA2',
                    value: UnitFormatter.formatPace(
                      result.avgWorkPaceSecPerKm,
                      unitSystem,
                    ),
                  ),
                ),
                Container(height: 28, width: 1, color: Colors.white12),
                Expanded(
                  child: _buildSummaryMetric(
                    label: 'WAKTU ISTIRAHAT',
                    value: _formatDur(
                      result.totalRestDurationSec,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // Reps List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reps.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white10),
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
                            color: const Color(0xFFFF9100).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REP ${rep.repIndex}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF9100),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDist(
                              rep.workDistanceMeters,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          UnitFormatter.formatPace(
                            rep.workPaceSecPerKm,
                            unitSystem,
                          ),
                          style: const TextStyle(
                            color: Color(0xFFFF9100),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDur(rep.workDurationSec),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (rep.workAvgHeartRate != null) ...[
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Color(0xFFFF5252),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${rep.workAvgHeartRate!.round()}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
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
                              color: Colors.blueGrey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Rest',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blueGrey.shade200,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDist(
                                rep.restDistanceMeters,
                              ),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
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
                            style: TextStyle(
                              color: Colors.blueGrey.shade200,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDur(rep.restDurationSec),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          if (rep.restAvgHeartRate != null) ...[
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite_border,
                                  color: Colors.blueGrey,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${rep.restAvgHeartRate!.round()}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
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
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E9BAE),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static String _formatDist(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000.0).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
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
