import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/application/feed_providers.dart';

/// Proportional 5-zone monochrome HR distribution bar & legend (PRD M3-06).
class HrZonesCard extends StatelessWidget {
  const HrZonesCard({
    super.key,
    required this.zoneDurationsSec,
    required this.thresholdsPercent,
  });

  final List<int> zoneDurationsSec;
  final List<int> thresholdsPercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;
    final totalSec = zoneDurationsSec.fold<int>(0, (a, b) => a + b);

    if (totalSec <= 0 || zoneDurationsSec.length != 5) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'DISTRIBUSI HR ZONE',
                style: AppTypography.metricLabel(colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Data detak jantung tidak tersedia pada aktivitas ini.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shades = isDark
        ? const <Color>[
            Color(0xFF424242),
            Color(0xFF686868),
            Color(0xFF919191),
            Color(0xFFC7C7C7),
            Color(0xFFFFFFFF),
          ]
        : const <Color>[
            Color(0xFFD6D6D6),
            Color(0xFFA8A8A8),
            Color(0xFF757575),
            Color(0xFF424242),
            Color(0xFF0A0A0A),
          ];

    final labels = _zoneLabels();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'DISTRIBUSI HR ZONE 1–5',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: List<Widget>.generate(5, (i) {
                    final sec = zoneDurationsSec[i];
                    if (sec <= 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: sec,
                      child: Container(color: shades[i]),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < 5; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: shades[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        labels[i],
                        style: AppTypography.splitTable(colors.textPrimary)
                            .copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      formatDuration(zoneDurationsSec[i]),
                      style: AppTypography.splitTable(colors.textSecondary)
                          .copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${((zoneDurationsSec[i] * 100.0) / totalSec).round()}%',
                        textAlign: TextAlign.right,
                        style: AppTypography.splitTable(colors.textPrimary)
                            .copyWith(fontSize: 13),
                      ),
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

  List<String> _zoneLabels() {
    final t = thresholdsPercent.length == 4
        ? thresholdsPercent
        : const <int>[60, 70, 80, 90];
    return <String>[
      'Z1 Recovery (<${t[0]}%)',
      'Z2 Aerobic (${t[0]}–${t[1]}%)',
      'Z3 Tempo (${t[1]}–${t[2]}%)',
      'Z4 Threshold (${t[2]}–${t[3]}%)',
      'Z5 Max (≥${t[3]}%)',
    ];
  }
}

