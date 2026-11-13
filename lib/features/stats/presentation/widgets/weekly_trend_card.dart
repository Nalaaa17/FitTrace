import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../feed/application/feed_providers.dart';
import '../../application/stats_providers.dart';

/// Interactive 12/24-week trend analytics card for distance, pace, and heart rate.
class WeeklyTrendCard extends ConsumerWidget {
  const WeeklyTrendCard({
    super.key,
    required this.colors,
    required this.unitSystem,
  });

  final FitTraceColors colors;
  final String unitSystem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weeklyTrendDataProvider);
    final horizon = ref.watch(weeklyTrendHorizonProvider);
    final metric = ref.watch(weeklyTrendMetricProvider);
    final inspectedIndex = ref.watch(weeklyTrendInspectedIndexProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header with title and horizon selector
            Row(
              children: <Widget>[
                const Icon(Icons.trending_up_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TREN MINGGUAN (PROGRES TRAINING)',
                    style: AppTypography.metricLabel(colors.textSecondary),
                  ),
                ),
                // Horizon toggle: 12 vs 24 weeks
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment(value: 12, label: Text('12 Mgg')),
                    ButtonSegment(value: 24, label: Text('24 Mgg')),
                  ],
                  selected: <int>{horizon},
                  onSelectionChanged: (sel) {
                    ref.read(weeklyTrendInspectedIndexProvider.notifier).select(null);
                    ref.read(weeklyTrendHorizonProvider.notifier).select(sel.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metric Switcher Segmented Button
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<String>>[
                  ButtonSegment(
                    value: 'distance',
                    label: Text('Jarak'),
                    icon: Icon(Icons.straighten, size: 16),
                  ),
                  ButtonSegment(
                    value: 'pace',
                    label: Text('Pace'),
                    icon: Icon(Icons.speed, size: 16),
                  ),
                  ButtonSegment(
                    value: 'hr',
                    label: Text('Detak Jantung'),
                    icon: Icon(Icons.favorite_rounded, size: 16),
                  ),
                ],
                selected: <String>{metric},
                onSelectionChanged: (sel) {
                  ref.read(weeklyTrendMetricProvider.notifier).select(sel.first);
                },
              ),
            ),
            const SizedBox(height: 16),

            trendAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Gagal memuat tren: $err'),
              ),
              data: (trend) {
                if (trend.totalRuns == 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    alignment: Alignment.center,
                    child: Text(
                      'Belum ada aktivitas lari dalam $horizon minggu terakhir.',
                      style: AppTypography.chartAxis(colors.textSecondary),
                    ),
                  );
                }

                final distUnit =
                    UnitFormatter.distanceUnitLabel(unitSystem, upperCase: true);

                // Highlight Summary Row
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _TrendStatItem(
                            label: 'TOTAL JARAK',
                            value:
                                '${UnitFormatter.formatDistanceValue(trend.totalPeriodDistanceMeters, unitSystem)} $distUnit',
                            colors: colors,
                          ),
                        ),
                        Expanded(
                          child: _TrendStatItem(
                            label: 'RATA-RATA / MGG',
                            value:
                                '${UnitFormatter.formatDistanceValue(trend.avgWeeklyDistanceMeters, unitSystem)} $distUnit',
                            colors: colors,
                          ),
                        ),
                        Expanded(
                          child: _TrendStatItem(
                            label: 'TOTAL SESI',
                            value: '${trend.totalRuns} sesi',
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Volume change chip & peak info
                    Row(
                      children: <Widget>[
                        if (trend.volumeChangePercentVsPrevWeek != null) ...<
                            Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: trend.volumeChangePercentVsPrevWeek! >= 0
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: trend.volumeChangePercentVsPrevWeek! >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  trend.volumeChangePercentVsPrevWeek! >= 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 12,
                                  color: trend.volumeChangePercentVsPrevWeek! >=
                                          0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${trend.volumeChangePercentVsPrevWeek! >= 0 ? '+' : ''}${trend.volumeChangePercentVsPrevWeek!.toStringAsFixed(1)}% vs minggu lalu',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        trend.volumeChangePercentVsPrevWeek! >=
                                                0
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            'Puncak: ${UnitFormatter.formatDistanceValue(trend.peakWeekDistanceMeters, unitSystem)} $distUnit (${trend.peakWeekLabel})',
                            style: AppTypography.chartAxis(colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Interactive CustomPainter Chart Canvas
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          _handleChartTouch(
                            details.localPosition,
                            trend.weeks.length,
                            ref,
                          );
                        },
                        onHorizontalDragUpdate: (details) {
                          _handleChartTouch(
                            details.localPosition,
                            trend.weeks.length,
                            ref,
                          );
                        },
                        child: CustomPaint(
                          painter: _WeeklyTrendChartPainter(
                            data: trend,
                            metric: metric,
                            inspectedIndex: inspectedIndex,
                            colors: colors,
                            unitSystem: unitSystem,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Inspection Banner when a week is tapped
                    if (inspectedIndex != null &&
                        inspectedIndex >= 0 &&
                        inspectedIndex < trend.weeks.length) ...<Widget>[
                      const SizedBox(height: 6),
                      _InspectedWeekBanner(
                        week: trend.weeks[inspectedIndex],
                        unitSystem: unitSystem,
                        colors: colors,
                        onClose: () {
                          ref
                              .read(weeklyTrendInspectedIndexProvider.notifier)
                              .select(null);
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleChartTouch(Offset pos, int weekCount, WidgetRef ref) {
    if (weekCount <= 0) return;
    const leftPadding = 32.0;
    const rightPadding = 12.0;
    final width =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
                WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio -
            64.0;
    final usableWidth = width - leftPadding - rightPadding;
    final dx = pos.dx - leftPadding;
    if (dx < 0 || dx > usableWidth) return;

    final fraction = dx / usableWidth;
    final index = (fraction * weekCount).floor().clamp(0, weekCount - 1);
    ref.read(weeklyTrendInspectedIndexProvider.notifier).select(index);
  }
}

class _TrendStatItem extends StatelessWidget {
  const _TrendStatItem({
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
        Text(
          label,
          style: AppTypography.metricLabel(colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.splitTable(colors.textPrimary),
        ),
      ],
    );
  }
}

class _InspectedWeekBanner extends StatelessWidget {
  const _InspectedWeekBanner({
    required this.week,
    required this.unitSystem,
    required this.colors,
    required this.onClose,
  });

  final WeeklyTrendPoint week;
  final String unitSystem;
  final FitTraceColors colors;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem);
    final distText =
        '${UnitFormatter.formatDistanceValue(week.totalDistanceMeters, unitSystem)} $distUnit';
    final paceText = week.totalDistanceMeters > 0
        ? UnitFormatter.formatPaceWithUnit(week.avgPaceSecPerKm, unitSystem)
        : '—';
    final hrText =
        week.avgHeartRate != null ? '${week.avgHeartRate!.round()} bpm' : '—';
    final timeText = formatDuration(week.totalMovingSec);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accentSharp.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: colors.accentSharp,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${week.dateRangeLabel} ${week.isCurrentWeek ? '(Minggu Ini)' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close, size: 14, color: colors.textSecondary),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: <Widget>[
              _DetailPill(label: 'Jarak', value: distText, colors: colors),
              _DetailPill(
                label: 'Sesi',
                value: '${week.runCount}x',
                colors: colors,
              ),
              _DetailPill(label: 'Waktu', value: timeText, colors: colors),
              _DetailPill(label: 'Pace', value: paceText, colors: colors),
              _DetailPill(label: 'HR', value: hrText, colors: colors),
              if (week.totalElevationGainM > 0)
                _DetailPill(
                  label: 'D+',
                  value: UnitFormatter.formatElevation(
                    week.totalElevationGainM,
                    unitSystem,
                    signed: true,
                  ),
                  colors: colors,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 11, color: colors.textSecondary),
        children: <TextSpan>[
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Canvas painter for rendering weekly bars or smooth trend curves.
class _WeeklyTrendChartPainter extends CustomPainter {
  _WeeklyTrendChartPainter({
    required this.data,
    required this.metric,
    required this.inspectedIndex,
    required this.colors,
    required this.unitSystem,
  });

  final WeeklyTrendData data;
  final String metric;
  final int? inspectedIndex;
  final FitTraceColors colors;
  final String unitSystem;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 32.0;
    const rightPad = 12.0;
    const topPad = 14.0;
    const bottomPad = 22.0;

    final plotWidth = size.width - leftPad - rightPad;
    final plotHeight = size.height - topPad - bottomPad;

    if (plotWidth <= 0 || plotHeight <= 0) return;

    final weeks = data.weeks;

    // Draw reference horizontal grid lines & Y labels
    _paintGridAndYLabels(
      canvas: canvas,
      leftPad: leftPad,
      topPad: topPad,
      plotWidth: plotWidth,
      plotHeight: plotHeight,
    );

    if (metric == 'distance') {
      _paintDistanceBars(
        canvas: canvas,
        weeks: weeks,
        leftPad: leftPad,
        topPad: topPad,
        plotWidth: plotWidth,
        plotHeight: plotHeight,
      );
    } else if (metric == 'pace') {
      _paintTrendLine(
        canvas: canvas,
        weeks: weeks,
        getValue: (WeeklyTrendPoint w) =>
            w.totalDistanceMeters > 0 ? w.avgPaceSecPerKm : null,
        minVal: data.minPaceSecPerKm,
        maxVal: data.maxPaceSecPerKm,
        invertY: true, // Lower pace (faster) is higher
        leftPad: leftPad,
        topPad: topPad,
        plotWidth: plotWidth,
        plotHeight: plotHeight,
      );
    } else {
      // metric == 'hr'
      _paintTrendLine(
        canvas: canvas,
        weeks: weeks,
        getValue: (WeeklyTrendPoint w) => w.avgHeartRate,
        minVal: data.minHeartRate,
        maxVal: data.maxHeartRate,
        invertY: false,
        leftPad: leftPad,
        topPad: topPad,
        plotWidth: plotWidth,
        plotHeight: plotHeight,
      );
    }

    // Paint X-axis week labels
    _paintXAxisLabels(
      canvas: canvas,
      weeks: weeks,
      leftPad: leftPad,
      topPad: topPad,
      plotWidth: plotWidth,
      plotHeight: plotHeight,
      size: size,
    );
  }

  void _paintGridAndYLabels({
    required Canvas canvas,
    required double leftPad,
    required double topPad,
    required double plotWidth,
    required double plotHeight,
  }) {
    final gridPaint = Paint()
      ..color = colors.hairlineBorder.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const divisions = 3;
    for (var i = 0; i <= divisions; i++) {
      final y = topPad + (plotHeight * (i / divisions));
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + plotWidth, y),
        gridPaint,
      );

      // Label
      String yText = '';
      if (metric == 'distance') {
        final distVal = data.maxDistanceMeters * (1.0 - (i / divisions));
        final val = unitSystem == 'imperial'
            ? distVal / 1609.344
            : distVal / 1000.0;
        yText = '${val.round()}';
      } else if (metric == 'pace') {
        final paceSec = data.minPaceSecPerKm +
            ((data.maxPaceSecPerKm - data.minPaceSecPerKm) * (i / divisions));
        final m = paceSec ~/ 60;
        final s = (paceSec % 60).round();
        yText = '$m\'${s.toString().padLeft(2, '0')}"';
      } else {
        final hr = data.maxHeartRate -
            ((data.maxHeartRate - data.minHeartRate) * (i / divisions));
        yText = '${hr.round()}';
      }

      final tp = TextPainter(
        text: TextSpan(
          text: yText,
          style: TextStyle(
            fontSize: 9,
            color: colors.textSecondary.withValues(alpha: 0.7),
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - (tp.height / 2)));
    }
  }

  void _paintDistanceBars({
    required Canvas canvas,
    required List<WeeklyTrendPoint> weeks,
    required double leftPad,
    required double topPad,
    required double plotWidth,
    required double plotHeight,
  }) {
    final count = weeks.length;
    final slotWidth = plotWidth / count;
    final barWidth = math.max(3.0, slotWidth * 0.65);
    final maxDist = data.maxDistanceMeters > 0 ? data.maxDistanceMeters : 1.0;

    for (var i = 0; i < count; i++) {
      final w = weeks[i];
      final cx = leftPad + (i * slotWidth) + (slotWidth / 2);
      final barH = (w.totalDistanceMeters / maxDist) * plotHeight;
      final topY = topPad + plotHeight - barH;
      final bottomY = topPad + plotHeight;

      final isSelected = inspectedIndex == i;
      final barRect = Rect.fromLTRB(
        cx - (barWidth / 2),
        topY,
        cx + (barWidth / 2),
        bottomY,
      );

      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      final barPaint = Paint();
      if (isSelected) {
        barPaint.color = colors.accentSharp;
      } else if (w.isCurrentWeek) {
        barPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colors.accentSharp.withValues(alpha: 0.85),
            colors.accentSharp.withValues(alpha: 0.45),
          ],
        ).createShader(barRect);
      } else if (w.totalDistanceMeters > 0) {
        barPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colors.textPrimary.withValues(alpha: 0.75),
            colors.textSecondary.withValues(alpha: 0.35),
          ],
        ).createShader(barRect);
      } else {
        // Zero run week: faint dotted bottom marker
        barPaint.color = colors.hairlineBorder.withValues(alpha: 0.4);
      }

      if (w.totalDistanceMeters > 0) {
        canvas.drawRRect(rrect, barPaint);
      } else {
        canvas.drawCircle(
          Offset(cx, bottomY - 2),
          1.5,
          barPaint,
        );
      }

      if (isSelected) {
        // Glow / indicator ring on top of bar
        final haloPaint = Paint()
          ..color = colors.accentSharp
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx, topY - 4), 3, haloPaint);
      }
    }

    // Average line across weeks
    if (data.avgWeeklyDistanceMeters > 0) {
      final avgY = topPad +
          plotHeight -
          ((data.avgWeeklyDistanceMeters / maxDist) * plotHeight);
      final avgPaint = Paint()
        ..color = colors.accentSharp.withValues(alpha: 0.5)
        ..strokeWidth = 1.0;

      // Draw dashed average line
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      var curX = leftPad;
      while (curX < leftPad + plotWidth) {
        canvas.drawLine(
          Offset(curX, avgY),
          Offset(math.min(curX + dashWidth, leftPad + plotWidth), avgY),
          avgPaint,
        );
        curX += dashWidth + dashSpace;
      }
    }
  }

  void _paintTrendLine({
    required Canvas canvas,
    required List<WeeklyTrendPoint> weeks,
    required double? Function(WeeklyTrendPoint) getValue,
    required double minVal,
    required double maxVal,
    required bool invertY,
    required double leftPad,
    required double topPad,
    required double plotWidth,
    required double plotHeight,
  }) {
    final count = weeks.length;
    final slotWidth = plotWidth / count;
    final range = (maxVal - minVal) > 0 ? (maxVal - minVal) : 1.0;

    final points = <({int index, Offset pos, double value})>[];
    for (var i = 0; i < count; i++) {
      final val = getValue(weeks[i]);
      if (val == null || val <= 0) continue;

      final cx = leftPad + (i * slotWidth) + (slotWidth / 2);
      final norm = ((val - minVal) / range).clamp(0.0, 1.0);
      final y = invertY
          ? topPad + (norm * plotHeight) // Invert so lower (faster) is higher
          : topPad + plotHeight - (norm * plotHeight);

      points.add((index: i, pos: Offset(cx, y), value: val));
    }

    if (points.isEmpty) return;

    // Line Path
    final path = Path();
    path.moveTo(points.first.pos.dx, points.first.pos.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].pos.dx, points[i].pos.dy);
    }

    // Draw Line
    final linePaint = Paint()
      ..color = colors.accentSharp
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Draw Nodes
    final nodeFill = Paint()..color = colors.bgBase;
    final nodeBorder = Paint()
      ..color = colors.accentSharp
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final p in points) {
      final isSelected = inspectedIndex == p.index;
      canvas.drawCircle(p.pos, isSelected ? 5.0 : 3.0, nodeFill);
      canvas.drawCircle(p.pos, isSelected ? 5.0 : 3.0, nodeBorder);
      if (isSelected) {
        final glowPaint = Paint()..color = colors.accentSharp;
        canvas.drawCircle(p.pos, 2.5, glowPaint);
      }
    }
  }

  void _paintXAxisLabels({
    required Canvas canvas,
    required List<WeeklyTrendPoint> weeks,
    required double leftPad,
    required double topPad,
    required double plotWidth,
    required double plotHeight,
    required Size size,
  }) {
    final count = weeks.length;
    final slotWidth = plotWidth / count;

    // Show every 2nd or 3rd label depending on 12 vs 24 weeks
    final step = count > 12 ? 4 : 2;

    for (var i = 0; i < count; i += step) {
      final w = weeks[i];
      final cx = leftPad + (i * slotWidth) + (slotWidth / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: w.shortWeekLabel,
          style: TextStyle(
            fontSize: 8.5,
            color: colors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(cx - (tp.width / 2), topPad + plotHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.metric != metric ||
        oldDelegate.inspectedIndex != inspectedIndex ||
        oldDelegate.unitSystem != unitSystem;
  }
}
