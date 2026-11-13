import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../activity_detail/application/activity_detail_providers.dart';
import '../../../feed/application/feed_providers.dart';
import '../../application/story_share_providers.dart';
import '../../domain/story_template_config.dart';

typedef StickerScaleUpdateCallback = void Function(ScaleUpdateDetails details);
typedef StickerScaleStartCallback = void Function(ScaleStartDetails details);

/// Exact `360×640` (exports at `3.0x` -> `1080×1920 px`) interactive 9:16 Story canvas
/// supporting Template A (Route Glow), Template B (Photo Overlay), and
/// Template C (Minimalist Metrics) (`PRD M4-01`..`M4-05`, `ADR-005`).
class StoryCardCanvas extends StatelessWidget {
  const StoryCardCanvas({
    super.key,
    required this.bundle,
    required this.config,
    required this.fullCardKey,
    required this.backgroundOnlyKey,
    required this.stickerOnlyKey,
    this.unitSystem = 'metric',
    this.onStickerScaleStart,
    this.onStickerScaleUpdate,
    this.onStickerDoubleTap,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;
  final GlobalKey fullCardKey;
  final GlobalKey backgroundOnlyKey;
  final GlobalKey stickerOnlyKey;
  final String unitSystem;
  final StickerScaleStartCallback? onStickerScaleStart;
  final StickerScaleUpdateCallback? onStickerScaleUpdate;
  final VoidCallback? onStickerDoubleTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: fullCardKey,
      child: SizedBox(
        width: storyLogicalWidth,
        height: storyLogicalHeight,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            RepaintBoundary(
              key: backgroundOnlyKey,
              child: _StoryBackgroundLayer(
                bundle: bundle,
                config: config,
              ),
            ),
            GestureDetector(
              key: const ValueKey<String>('story_sticker_gesture_area'),
              behavior: HitTestBehavior.translucent,
              onScaleStart: onStickerScaleStart,
              onScaleUpdate: onStickerScaleUpdate,
              onDoubleTap: onStickerDoubleTap,
              child: RepaintBoundary(
                key: stickerOnlyKey,
                child: ColoredBox(
                  color: Colors.transparent,
                  child: Align(
                    alignment: config.templateId == StoryTemplateId.minimalist
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        26,
                        config.templateId == StoryTemplateId.minimalist
                            ? 44
                            : 24,
                        26,
                        48,
                      ),
                      child: Transform.translate(
                        offset: config.stickerOffset,
                        child: Transform.rotate(
                          angle: config.stickerRotationRad,
                          child: Transform.scale(
                            scale: config.stickerScale,
                            child: _StatsStickerOverlay(
                              bundle: bundle,
                              config: config,
                              unitSystem: unitSystem,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryBackgroundLayer extends StatelessWidget {
  const _StoryBackgroundLayer({
    required this.bundle,
    required this.config,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;

  @override
  Widget build(BuildContext context) {
    switch (config.templateId) {
      case StoryTemplateId.routeGlow:
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.22),
              radius: 1.05,
              colors: <Color>[
                const Color(0xFF171717),
                FitTraceColors.dark.bgBase,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _RouteGlowPainter(bundle: bundle),
          ),
        );

      case StoryTemplateId.photoOverlay:
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (config.photoBytes != null)
              Image.memory(
                config.photoBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF1B1B1B),
                      Color(0xFF0A0A0A),
                    ],
                  ),
                ),
              ),
            // 60% dark gradient from bottom (PRD M4-03)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const <double>[0.0, 0.45, 1.0],
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );

      case StoryTemplateId.minimalist:
        final bg = config.minimalistDark
            ? FitTraceColors.dark.bgBase
            : FitTraceColors.light.bgBase;
        final border = config.minimalistDark
            ? const Color(0xFF262626)
            : const Color(0xFFE0E0E0);
        return Container(
          color: bg,
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1),
            ),
          ),
        );
    }
  }
}

class _StatsStickerOverlay extends StatelessWidget {
  const _StatsStickerOverlay({
    required this.bundle,
    required this.config,
    required this.unitSystem,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final isLightMinimalist =
        config.templateId == StoryTemplateId.minimalist &&
            !config.minimalistDark;

    final primaryInk = isLightMinimalist
        ? FitTraceColors.light.textPrimary
        : FitTraceColors.dark.textPrimary;
    final secondaryInk = isLightMinimalist
        ? FitTraceColors.light.textSecondary
        : FitTraceColors.dark.textSecondary;
    final hairline = isLightMinimalist
        ? const Color(0xFFDCDCDC)
        : const Color(0xFF2C2C2C);

    final act = bundle.activity;
    final crossAxis = switch (config.alignment) {
      StoryTextAlignment.left => CrossAxisAlignment.start,
      StoryTextAlignment.center => CrossAxisAlignment.center,
      StoryTextAlignment.right => CrossAxisAlignment.end,
    };

    final statCells = <({String label, String value})>[
      if (config.showPace)
        (
          label: 'AVG PACE',
          value: UnitFormatter.formatPaceWithUnit(act.avgPaceSecPerKm, unitSystem),
        ),
      if (config.showMovingTime)
        (label: 'MOVING TIME', value: formatDuration(act.durationMovingSec)),
      if (config.showAvgHr && act.avgHeartRate != null)
        (label: 'AVG HR', value: '${act.avgHeartRate!.round()} bpm'),
      if (config.showElevation)
        (
          label: 'ELEV GAIN',
          value: UnitFormatter.formatElevation(
            act.totalElevationGainM,
            unitSystem,
            signed: true,
          ),
        ),
    ];

    final distText = UnitFormatter.formatDistanceValue(
      act.distanceMeters,
      unitSystem,
    );
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem, upperCase: true);
    final weight = config.fontWeight.weight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxis,
      children: <Widget>[
        if (config.showDate)
          Text(
            formatActivityLocalDate(act.startTimeUtc, act.utcOffsetSeconds)
                .toUpperCase(),
            textAlign: config.alignment.textAlign,
            style: AppTypography.metricLabel(secondaryInk).copyWith(
              letterSpacing: 1.4,
            ),
          ),
        if (config.showTitle) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            act.title,
            textAlign: config.alignment.textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryInk,
              fontSize: 18,
              fontWeight: weight,
              letterSpacing: -0.2,
            ),
          ),
        ],
        if (config.showDistance) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            spacing: 6,
            children: <Widget>[
              Text(
                distText,
                style: TextStyle(
                  color: primaryInk,
                  fontSize: 56,
                  height: 0.96,
                  fontWeight: weight,
                  letterSpacing: -1.6,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  distUnit,
                  style: AppTypography.metricLabel(secondaryInk).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (statCells.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Divider(color: hairline, height: 1, thickness: 1),
          const SizedBox(height: 12),
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            spacing: 18,
            runSpacing: 12,
            children: statCells.map((cell) {
              return SizedBox(
                width: config.templateId == StoryTemplateId.minimalist
                    ? 122
                    : 108,
                child: Column(
                  crossAxisAlignment: crossAxis,
                  children: <Widget>[
                    Text(
                      cell.label,
                      textAlign: config.alignment.textAlign,
                      style: AppTypography.metricLabel(secondaryInk).copyWith(
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cell.value,
                      textAlign: config.alignment.textAlign,
                      style: TextStyle(
                        color: primaryInk,
                        fontSize: 16,
                        fontWeight: weight,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        ],
        if (config.showWatermark) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: hairline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'FITTRACE',
              style: AppTypography.metricLabel(secondaryInk).copyWith(
                fontSize: 9,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteGlowPainter extends CustomPainter {
  _RouteGlowPainter({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  void paint(Canvas canvas, Size size) {
    if (!bundle.activity.hasGpsTrack || bundle.mapSegments.isEmpty) {
      _paintIndoorPulse(canvas, size);
      return;
    }

    final allPoints = bundle.mapSegments.expand((s) => s.points).toList();
    if (allPoints.length < 2) {
      _paintIndoorPulse(canvas, size);
      return;
    }

    var minLat = allPoints.first.latitude;
    var maxLat = minLat;
    var minLng = allPoints.first.longitude;
    var maxLng = minLng;
    for (final pt in allPoints) {
      minLat = math.min(minLat, pt.latitude);
      maxLat = math.max(maxLat, pt.latitude);
      minLng = math.min(minLng, pt.longitude);
      maxLng = math.max(maxLng, pt.longitude);
    }

    final midLatRad = ((minLat + maxLat) * 0.5) * math.pi / 180.0;
    final cosLat = math.cos(midLatRad).abs().clamp(0.2, 1.0);
    final latSpan = math.max(maxLat - minLat, 1e-6);
    final lngSpan = math.max((maxLng - minLng) * cosLat, 1e-6);

    final routeRect = Rect.fromLTWH(34, 72, size.width - 68, size.height * 0.44);
    final scale = math.min(routeRect.width / lngSpan, routeRect.height / latSpan);
    final drawnW = lngSpan * scale;
    final drawnH = latSpan * scale;
    final originX = routeRect.left + (routeRect.width - drawnW) * 0.5;
    final originY = routeRect.top + (routeRect.height - drawnH) * 0.5;

    Offset project(double lat, double lng) {
      final dx = originX + ((lng - minLng) * cosLat) * scale;
      final dy = originY + (maxLat - lat) * scale;
      return Offset(dx, dy);
    }

    final outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final innerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final fullPath = Path();
    var first = true;
    for (final segment in bundle.mapSegments) {
      for (final pt in segment.points) {
        final offset = project(pt.latitude, pt.longitude);
        if (first) {
          fullPath.moveTo(offset.dx, offset.dy);
          first = false;
        } else {
          fullPath.lineTo(offset.dx, offset.dy);
        }
      }
    }
    canvas.drawPath(fullPath, outerGlowPaint);
    canvas.drawPath(fullPath, innerGlowPaint);

    // Core pace-gradient monochrome strokes.
    for (final segment in bundle.mapSegments) {
      if (segment.points.length < 2) continue;
      final shade = Color.lerp(
            const Color(0xFF757575),
            Colors.white,
            segment.paceIntensity.clamp(0.0, 1.0),
          ) ??
          Colors.white;
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = shade;

      final segPath = Path();
      final p0 = project(segment.points.first.latitude, segment.points.first.longitude);
      segPath.moveTo(p0.dx, p0.dy);
      for (var i = 1; i < segment.points.length; i++) {
        final p = project(segment.points[i].latitude, segment.points[i].longitude);
        segPath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(segPath, corePaint);
    }

    if (bundle.startPoint != null) {
      final start = project(
        bundle.startPoint!.latitude,
        bundle.startPoint!.longitude,
      );
      canvas.drawCircle(start, 5.5, Paint()..color = FitTraceColors.dark.bgBase);
      canvas.drawCircle(
        start,
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
    }
    if (bundle.endPoint != null) {
      final end = project(
        bundle.endPoint!.latitude,
        bundle.endPoint!.longitude,
      );
      canvas.drawCircle(
        end,
        9,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
      canvas.drawCircle(end, 4.5, Paint()..color = Colors.white);
    }
  }

  void _paintIndoorPulse(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.30);
    for (final radius in <double>[36, 68, 102, 136]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.14),
      );
    }
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RouteGlowPainter oldDelegate) =>
      oldDelegate.bundle.activity.id != bundle.activity.id ||
      oldDelegate.bundle.mapSegments != bundle.mapSegments;
}
