import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../feed/application/feed_providers.dart';

/// Horizontal-scrollable per-km split table highlighting the fastest split (PRD M3-05).
class SplitsTable extends StatelessWidget {
  const SplitsTable({
    super.key,
    required this.splits,
    this.unitSystem = 'metric',
  });

  final List<LapSplitRecord> splits;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    if (splits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Split per kilometer belum tersedia.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    int? bestSplitIndex;
    var bestPace = double.infinity;
    for (final s in splits) {
      if (s.distanceMeters >= 900 &&
          s.avgPaceSecPerKm > 0 &&
          s.avgPaceSecPerKm < bestPace) {
        bestPace = s.avgPaceSecPerKm;
        bestSplitIndex = s.splitIndex;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              UnitFormatter.isImperial(unitSystem)
                  ? 'SPLITS (IMP)'
                  : 'SPLITS PER KILOMETER',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 22,
                horizontalMargin: 0,
                headingRowHeight: 32,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 42,
                dividerThickness: 0.5,
                headingTextStyle:
                    AppTypography.metricLabel(colors.textSecondary),
                dataTextStyle: AppTypography.splitTable(colors.textPrimary),
                columns: const <DataColumn>[
                  DataColumn(label: Text('KM')),
                  DataColumn(label: Text('JARAK'), numeric: true),
                  DataColumn(label: Text('WAKTU'), numeric: true),
                  DataColumn(label: Text('PACE'), numeric: true),
                  DataColumn(label: Text('HR'), numeric: true),
                  DataColumn(label: Text('ELEV Δ'), numeric: true),
                ],
                rows: splits.map((s) {
                  final isBest = s.splitIndex == bestSplitIndex;
                  final rowStyle = AppTypography.splitTable(
                    isBest ? colors.accentSharp : colors.textPrimary,
                  ).copyWith(
                    fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
                  );
                  return DataRow(
                    color: isBest
                        ? WidgetStatePropertyAll<Color>(
                            colors.accentSharp.withValues(alpha: 0.08),
                          )
                        : null,
                    cells: <DataCell>[
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('${s.splitIndex + 1}', style: rowStyle),
                            if (isBest) ...<Widget>[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accentSharp,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BEST',
                                  style: AppTypography.chartAxis(colors.bgBase)
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          UnitFormatter.formatDistanceValue(
                            s.distanceMeters,
                            unitSystem,
                          ),
                          style: rowStyle,
                        ),
                      ),
                      DataCell(
                        Text(formatDuration(s.durationSec), style: rowStyle),
                      ),
                      DataCell(
                        Text(
                          UnitFormatter.formatPace(s.avgPaceSecPerKm, unitSystem),
                          style: rowStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          s.avgHeartRate != null
                              ? '${s.avgHeartRate!.round()}'
                              : '—',
                          style: rowStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          UnitFormatter.formatElevation(
                            s.elevationDeltaM,
                            unitSystem,
                            signed: true,
                          ),
                          style: rowStyle,
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
