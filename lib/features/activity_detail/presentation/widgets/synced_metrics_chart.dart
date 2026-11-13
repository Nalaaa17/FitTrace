import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../application/activity_detail_providers.dart';

/// Synchronized multi-metric canvas combining Pace, Elevation, and Heart Rate
/// over cumulative distance with tap/drag crosshair (PRD M3-04).
class SyncedMetricsChart extends StatelessWidget {
  const SyncedMetricsChart({
    super.key,
    required this.points,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    this.unitSystem = 'metric',
  });

  final List<ChartSamplePoint> points;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectedIndexChanged;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;
    final hasHr = points.any((p) => p.heartRateBpm != null);
    final hasPace = points.any((p) => p.paceSecPerKm != null);

    if (points.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Data grafik tidak cukup.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final selected =
        (selectedIndex != null &&
                selectedIndex! >= 0 &&
                selectedIndex! < points.length)
            ? points[selectedIndex!]
            : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'GRAFIK ANALISIS',
                  style: AppTypography.metricLabel(colors.textSecondary),
                ),
                const Spacer(),
                _LegendItem(
                  label: 'PACE',
                  color: colors.accentSharp,
                  dashed: false,
                ),
                if (hasHr) ...<Widget>[
                  const SizedBox(width: 10),
                  _LegendItem(
                    label: 'HR',
                    color: colors.textSecondary,
                    dashed: true,
                  ),
                ],
                const SizedBox(width: 10),
                _LegendItem(
                  label: 'ELEV',
                  color: colors.textSecondary.withValues(alpha: 0.45),
                  filled: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (selected != null) ...<Widget>[
              _CrosshairReadout(
                point: selected,
                unitSystem: unitSystem,
                colors: colors,
              ),
              const SizedBox(height: 8),
            ] else ...<Widget>[
              Text(
                'Ketuk atau geser grafik untuk sinkron dengan peta.',
                style: AppTypography.chartAxis(colors.textSecondary),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 190,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    key: const ValueKey<String>('metrics_chart_canvas'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _selectAtX(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    ),
                    onHorizontalDragStart: (details) => _selectAtX(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    ),
                    onHorizontalDragUpdate: (details) => _selectAtX(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    ),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, 190),
                      painter: _MetricsChartPainter(
                        points: points,
                        selectedIndex: selectedIndex,
                        hasHr: hasHr,
                        hasPace: hasPace,
                        colors: colors,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAtX(double dx, double width) {
    const leftPad = 8.0;
    const rightPad = 8.0;
    final plotWidth = math.max(1.0, width - leftPad - rightPad);
    final norm = ((dx - leftPad) / plotWidth).clamp(0.0, 1.0);
    final maxDist = math.max(1.0, points.last.distanceMeters);
    final targetDist = norm * maxDist;

    var bestIdx = 0;
    var bestDiff = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final diff = (points[i].distanceMeters - targetDist).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIdx = i;
      }
    }
    onSelectedIndexChanged(bestIdx);
  }
}

class _CrosshairReadout extends StatelessWidget {
  const _CrosshairReadout({
    required this.point,
    required this.unitSystem,
    required this.colors,
  });

  final ChartSamplePoint point;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final dist = UnitFormatter.formatDistanceValue(
      point.distanceMeters,
      unitSystem,
    );
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem);
    final pace = point.paceSecPerKm != null
        ? UnitFormatter.formatPaceWithUnit(point.paceSecPerKm!, unitSystem)
        : '--\'--"${UnitFormatter.paceUnitSuffix(unitSystem)}';
    final hr = point.heartRateBpm != null ? '${point.heartRateBpm} bpm' : '—';
    final elev = UnitFormatter.formatElevation(point.altitudeM, unitSystem);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.hairlineBorder),
      ),
      child: Text(
        '$dist $distUnit  •  $pace  •  $hr  •  $elev',
        style: AppTypography.splitTable(colors.textPrimary).copyWith(
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    this.dashed = false,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool dashed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: filled ? 8 : (dashed ? 2 : 2.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.chartAxis(context.fitColors.textSecondary),
        ),
      ],
    );
  }
}

class _MetricsChartPainter extends CustomPainter {
  _MetricsChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.hasHr,
    required this.hasPace,
    required this.colors,
  });

  final List<ChartSamplePoint> points;
  final int? selectedIndex;
  final bool hasHr;
  final bool hasPace;
  final FitTraceColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 10.0;
    const bottomPad = 22.0;

    final plotW = math.max(1.0, size.width - leftPad - rightPad);
    final plotH = math.max(1.0, size.height - topPad - bottomPad);
    final maxDist = math.max(1.0, points.last.distanceMeters);

    double xForDist(double dist) => leftPad + (dist / maxDist) * plotW;

    // Subtle horizontal gridlines.
    final gridPaint = Paint()
      ..color = colors.hairlineBorder
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = topPad + (plotH / 3.0) * g;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + plotW, y), gridPaint);
    }

    // 1. Elevation area (bottom layer).
    var minAlt = double.infinity;
    var maxAlt = -double.infinity;
    for (final pt in points) {
      if (pt.altitudeM < minAlt) minAlt = pt.altitudeM;
      if (pt.altitudeM > maxAlt) maxAlt = pt.altitudeM;
    }
    final altSpan = math.max(5.0, maxAlt - minAlt);
    final elevPath = Path();
    for (var i = 0; i < points.length; i++) {
      final x = xForDist(points[i].distanceMeters);
      final norm = (points[i].altitudeM - minAlt) / altSpan;
      final y = topPad + plotH - norm * (plotH * 0.55);
      if (i == 0) {
        elevPath.moveTo(x, topPad + plotH);
        elevPath.lineTo(x, y);
      } else {
        elevPath.lineTo(x, y);
      }
    }
    elevPath
      ..lineTo(xForDist(points.last.distanceMeters), topPad + plotH)
      ..close();

    final elevFillPaint = Paint()
      ..color = colors.textSecondary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawPath(elevPath, elevFillPaint);

    // 2. Heart rate dashed line (if present).
    if (hasHr) {
      var minHr = 999.0;
      var maxHr = 0.0;
      for (final pt in points) {
        final hr = pt.heartRateBpm;
        if (hr != null) {
          if (hr < minHr) minHr = hr.toDouble();
          if (hr > maxHr) maxHr = hr.toDouble();
        }
      }
      final hrSpan = math.max(15.0, maxHr - minHr);
      final hrPaint = Paint()
        ..color = colors.textSecondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final hrPath = Path();
      var started = false;
      for (final pt in points) {
        final hr = pt.heartRateBpm;
        if (hr == null) continue;
        final x = xForDist(pt.distanceMeters);
        final norm = (hr - minHr) / hrSpan;
        final y = topPad + plotH - (0.1 + norm * 0.8) * plotH;
        if (!started) {
          hrPath.moveTo(x, y);
          started = true;
        } else {
          hrPath.lineTo(x, y);
        }
      }
      _drawDashedPath(canvas, hrPath, hrPaint);
    }

    // 3. Pace primary sharp line (inverted Y so faster pace = higher).
    if (hasPace) {
      var minPace = double.infinity;
      var maxPace = -double.infinity;
      for (final pt in points) {
        final p = pt.paceSecPerKm;
        if (p != null) {
          if (p < minPace) minPace = p;
          if (p > maxPace) maxPace = p;
        }
      }
      final paceSpan = math.max(20.0, maxPace - minPace);
      final pacePaint = Paint()
        ..color = colors.accentSharp
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;

      final pacePath = Path();
      var started = false;
      for (final pt in points) {
        final p = pt.paceSecPerKm;
        if (p == null) continue;
        final x = xForDist(pt.distanceMeters);
        // Faster pace (smaller sec/km) plots higher.
        final norm = 1.0 - ((p - minPace) / paceSpan);
        final y = topPad + plotH - (0.12 + norm * 0.8) * plotH;
        if (!started) {
          pacePath.moveTo(x, y);
          started = true;
        } else {
          pacePath.lineTo(x, y);
        }
      }
      canvas.drawPath(pacePath, pacePaint);
    }

    // X-axis distance labels (0 km .. mid .. total km).
    final totalKm = maxDist / 1000.0;
    _paintAxisText(canvas, '0 km', Offset(leftPad, size.height - 14), colors);
    _paintAxisText(
      canvas,
      '${(totalKm / 2).toStringAsFixed(1)} km',
      Offset(leftPad + plotW * 0.5 - 16, size.height - 14),
      colors,
    );
    _paintAxisText(
      canvas,
      '${totalKm.toStringAsFixed(1)} km',
      Offset(leftPad + plotW - 36, size.height - 14),
      colors,
    );

    // 4. Synchronized crosshair line & indicator dot.
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final sel = points[selectedIndex!];
      final cx = xForDist(sel.distanceMeters);
      final crosshairPaint = Paint()
        ..color = colors.accentSharp.withValues(alpha: 0.75)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(cx, topPad),
        Offset(cx, topPad + plotH),
        crosshairPaint,
      );
      canvas.drawCircle(
        Offset(cx, topPad + 4),
        3.5,
        Paint()..color = colors.accentSharp,
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLen = 5.0;
      const gapLen = 4.0;
      while (distance < metric.length) {
        final next = math.min(metric.length, distance + dashLen);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLen;
      }
    }
  }

  void _paintAxisText(
    Canvas canvas,
    String text,
    Offset offset,
    FitTraceColors colors,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.chartAxis(colors.textSecondary),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MetricsChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.points != points ||
        oldDelegate.colors != colors;
  }
}

