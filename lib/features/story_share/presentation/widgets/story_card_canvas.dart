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
/// supporting Route Glow, Photo Overlay, Minimalist, Pastel Aesthetic,
/// Run Receipt, Cyber Neon, and Cute Scrapbook (`PRD M4-01`..`M4-05`, `ADR-005`).
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
                    alignment: switch (config.templateId) {
                      StoryTemplateId.minimalist => Alignment.center,
                      StoryTemplateId.receiptRunner => Alignment.center,
                      StoryTemplateId.cuteJournal => Alignment.bottomCenter,
                      _ => Alignment.bottomCenter,
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        config.templateId == StoryTemplateId.receiptRunner ? 20 : 24,
                        switch (config.templateId) {
                          StoryTemplateId.minimalist => 44,
                          StoryTemplateId.receiptRunner => 20,
                          StoryTemplateId.cuteJournal => 20,
                          _ => 24,
                        },
                        config.templateId == StoryTemplateId.receiptRunner ? 20 : 24,
                        switch (config.templateId) {
                          StoryTemplateId.receiptRunner => 20,
                          StoryTemplateId.cuteJournal => 24,
                          _ => 44,
                        },
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

      case StoryTemplateId.pastelAesthetic:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFFE9D5FF), // Soft lavender
                Color(0xFFFFE4E6), // Soft rose blush
                Color(0xFFFEF3C7), // Warm buttery cream
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _PastelSparkleDecorations(),
              CustomPaint(
                painter: _PastelRoutePainter(bundle: bundle),
              ),
            ],
          ),
        );

      case StoryTemplateId.receiptRunner:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF191C24),
                Color(0xFF0E1014),
              ],
            ),
          ),
          child: const CustomPaint(
            painter: _DotGridBackgroundPainter(),
          ),
        );

      case StoryTemplateId.cyberNeon:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.25),
              radius: 1.15,
              colors: <Color>[
                Color(0xFF0F1B2F),
                Color(0xFF07080D),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _CyberNeonRoutePainter(bundle: bundle),
          ),
        );

      case StoryTemplateId.cuteJournal:
        return Container(
          color: const Color(0xFFF6F1E9), // Warm oat / linen craft paper
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Align(
                alignment: const Alignment(0, -0.66),
                child: _PolaroidRouteCard(bundle: bundle),
              ),
            ],
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
    switch (config.templateId) {
      case StoryTemplateId.routeGlow:
      case StoryTemplateId.photoOverlay:
      case StoryTemplateId.minimalist:
        return _ClassicStatsStickerOverlay(
          bundle: bundle,
          config: config,
          unitSystem: unitSystem,
        );

      case StoryTemplateId.pastelAesthetic:
        return _PastelStatsStickerOverlay(
          bundle: bundle,
          config: config,
          unitSystem: unitSystem,
        );

      case StoryTemplateId.receiptRunner:
        return _ReceiptStatsStickerOverlay(
          bundle: bundle,
          config: config,
          unitSystem: unitSystem,
        );

      case StoryTemplateId.cyberNeon:
        return _CyberNeonStatsStickerOverlay(
          bundle: bundle,
          config: config,
          unitSystem: unitSystem,
        );

      case StoryTemplateId.cuteJournal:
        return _CuteJournalStatsStickerOverlay(
          bundle: bundle,
          config: config,
          unitSystem: unitSystem,
        );
    }
  }
}

/// Original high-contrast typography sticker used by Route Glow, Photo Overlay, and Minimalist.
class _ClassicStatsStickerOverlay extends StatelessWidget {
  const _ClassicStatsStickerOverlay({
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
          label: 'PACE RATA-RATA',
          value: UnitFormatter.formatPaceWithUnit(act.avgPaceSecPerKm, unitSystem),
        ),
      if (config.showMovingTime)
        (label: 'WAKTU BERGERAK', value: formatDuration(act.durationMovingSec)),
      if (config.showAvgHr && act.avgHeartRate != null)
        (label: 'HR RATA-RATA', value: '${act.avgHeartRate!.round()} bpm'),
      if (config.showElevation)
        (
          label: 'ELEVASI',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 12,
                    height: 12,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'FITTRACE',
                  style: AppTypography.metricLabel(secondaryInk).copyWith(
                    fontSize: 9,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Aesthetic Frosted Glass & Pastel badge sticker overlay.
class _PastelStatsStickerOverlay extends StatelessWidget {
  const _PastelStatsStickerOverlay({
    required this.bundle,
    required this.config,
    required this.unitSystem,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final act = bundle.activity;
    final crossAxis = switch (config.alignment) {
      StoryTextAlignment.left => CrossAxisAlignment.start,
      StoryTextAlignment.center => CrossAxisAlignment.center,
      StoryTextAlignment.right => CrossAxisAlignment.end,
    };
    final weight = config.fontWeight.weight;
    final distText = UnitFormatter.formatDistanceValue(act.distanceMeters, unitSystem);
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem, upperCase: true);

    return Container(
      constraints: const BoxConstraints(maxWidth: 312),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFC4B5FD).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxis,
        children: <Widget>[
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '✦ RUN DIARY ✦',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (config.showDate)
                Text(
                  formatActivityLocalDate(act.startTimeUtc, act.utcOffsetSeconds),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (config.showTitle) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              act.title,
              textAlign: config.alignment.textAlign,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF1E1B4B),
                fontSize: 17,
                fontWeight: weight,
                letterSpacing: -0.2,
              ),
            ),
          ],
          if (config.showDistance) ...<Widget>[
            const SizedBox(height: 8),
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
                    color: const Color(0xFF1E1B4B),
                    fontSize: 48,
                    height: 0.96,
                    fontWeight: weight,
                    letterSpacing: -1.5,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      distUnit,
                      style: const TextStyle(
                        color: Color(0xFFC2410C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (config.showPace)
                _PastelChip(
                  label: '⚡ PACE',
                  value: UnitFormatter.formatPaceWithUnit(act.avgPaceSecPerKm, unitSystem),
                  bg: const Color(0xFFECFDF5),
                  border: const Color(0xFFA7F3D0),
                  textColor: const Color(0xFF047857),
                  weight: weight,
                ),
              if (config.showMovingTime)
                _PastelChip(
                  label: '⏱️ TIME',
                  value: formatDuration(act.durationMovingSec),
                  bg: const Color(0xFFFFFBEB),
                  border: const Color(0xFFFDE68A),
                  textColor: const Color(0xFFB45309),
                  weight: weight,
                ),
              if (config.showAvgHr && act.avgHeartRate != null)
                _PastelChip(
                  label: '💖 HR RATA-RATA',
                  value: '${act.avgHeartRate!.round()} bpm',
                  bg: const Color(0xFFFFF1F2),
                  border: const Color(0xFFFECDD3),
                  textColor: const Color(0xFFBE185D),
                  weight: weight,
                ),
              if (config.showElevation)
                _PastelChip(
                  label: '⛰️ ELEV',
                  value: UnitFormatter.formatElevation(act.totalElevationGainM, unitSystem, signed: true),
                  bg: const Color(0xFFF0F9FF),
                  border: const Color(0xFFBAE6FD),
                  textColor: const Color(0xFF0369A1),
                  weight: weight,
                ),
            ],
          ),
          if (config.showWatermark) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '✿ FITTRACE RUN CLUB',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PastelChip extends StatelessWidget {
  const _PastelChip({
    required this.label,
    required this.value,
    required this.bg,
    required this.border,
    required this.textColor,
    required this.weight,
  });

  final String label;
  final String value;
  final Color bg;
  final Color border;
  final Color textColor;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF1E1B4B),
              fontSize: 13,
              fontWeight: weight,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Official Run Receipt sticker inspired by receiptify & boarding passes.
class _ReceiptStatsStickerOverlay extends StatelessWidget {
  const _ReceiptStatsStickerOverlay({
    required this.bundle,
    required this.config,
    required this.unitSystem,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final act = bundle.activity;
    final distText = UnitFormatter.formatDistanceValue(act.distanceMeters, unitSystem);
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem, upperCase: true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CustomPaint(
          size: Size(304, 7),
          painter: _ReceiptZigZagPainter(color: Color(0xFFFBFBFB), isTop: true),
        ),
        Container(
          width: 304,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFB),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '*** FITTRACE OFFICIAL RECEIPT ***',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'STORE: RUN TRACK // ORDER #RUN-${act.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  color: Colors.black54,
                ),
              ),
              if (config.showDate) ...<Widget>[
                const SizedBox(height: 1),
                Text(
                  'DATE: ${formatActivityLocalDate(act.startTimeUtc, act.utcOffsetSeconds).toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    color: Colors.black87,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                '- - - - - - - - - - - - - - - - - - - - - - - - - -',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black38),
              ),
              if (config.showTitle) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  'ITEM: ${act.title.toUpperCase()}',
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
              // Miniature black ink route map
              Container(
                height: 70,
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  color: const Color(0xFFF4F4F4),
                ),
                child: CustomPaint(
                  painter: _ReceiptRoutePainter(bundle: bundle),
                ),
              ),
              if (config.showDistance) ...<Widget>[
                const Text(
                  '- - - - - - - - - - - - - - - - - - - - - - - - - -',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black38),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'TOTAL DISTANCE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        '$distText $distUnit',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Text(
                '- - - - - - - - - - - - - - - - - - - - - - - - - -',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black38),
              ),
              if (config.showPace)
                _ReceiptRow(
                  label: 'PACE RATA-RATA',
                  value: UnitFormatter.formatPaceWithUnit(act.avgPaceSecPerKm, unitSystem),
                ),
              if (config.showMovingTime)
                _ReceiptRow(
                  label: 'WAKTU BERGERAK',
                  value: formatDuration(act.durationMovingSec),
                ),
              if (config.showAvgHr && act.avgHeartRate != null)
                _ReceiptRow(
                  label: 'DETAK JANTUNG',
                  value: '${act.avgHeartRate!.round()} BPM',
                ),
              if (config.showElevation)
                _ReceiptRow(
                  label: 'ELEVATION GAIN',
                  value: UnitFormatter.formatElevation(act.totalElevationGainM, unitSystem, signed: true),
                ),
              const Text(
                '- - - - - - - - - - - - - - - - - - - - - - - - - -',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.black38),
              ),
              const SizedBox(height: 2),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'EFFORT: 100%',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'NO SHORTCUTS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Center(
                child: CustomPaint(
                  size: Size(250, 22),
                  painter: _BarcodePainter(),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'THANK YOU FOR RUNNING!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black,
                ),
              ),
              if (config.showWatermark) ...<Widget>[
                const SizedBox(height: 2),
                const Text(
                  '* FITTRACE OFFICIAL VERIFIED *',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
        const CustomPaint(
          size: Size(304, 7),
          painter: _ReceiptZigZagPainter(color: Color(0xFFFBFBFB), isTop: false),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cyber Neon HUD night runner sticker overlay.
class _CyberNeonStatsStickerOverlay extends StatelessWidget {
  const _CyberNeonStatsStickerOverlay({
    required this.bundle,
    required this.config,
    required this.unitSystem,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final act = bundle.activity;
    final crossAxis = switch (config.alignment) {
      StoryTextAlignment.left => CrossAxisAlignment.start,
      StoryTextAlignment.center => CrossAxisAlignment.center,
      StoryTextAlignment.right => CrossAxisAlignment.end,
    };
    final weight = config.fontWeight.weight;
    final distText = UnitFormatter.formatDistanceValue(act.distanceMeters, unitSystem);
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem, upperCase: true);

    return Container(
      constraints: const BoxConstraints(maxWidth: 312),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF090E1A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxis,
        children: <Widget>[
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00FF88),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: Color(0xFF00FF88), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'TELEMETRY // RUN_LOG',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              if (config.showDate)
                Text(
                  formatActivityLocalDate(act.startTimeUtc, act.utcOffsetSeconds),
                  style: const TextStyle(
                    color: Color(0xFF80DEEA),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          if (config.showTitle) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              act.title,
              textAlign: config.alignment.textAlign,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: weight,
                letterSpacing: 0.3,
              ),
            ),
          ],
          if (config.showDistance) ...<Widget>[
            const SizedBox(height: 8),
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
                    color: const Color(0xFF00FF88),
                    fontSize: 48,
                    height: 0.96,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    shadows: const <Shadow>[
                      Shadow(color: Color(0xFF00FF88), blurRadius: 14),
                    ],
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    distUnit,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (config.showPace)
                _CyberTechBox(
                  label: '// PACE',
                  value: UnitFormatter.formatPaceWithUnit(act.avgPaceSecPerKm, unitSystem),
                  weight: weight,
                ),
              if (config.showMovingTime)
                _CyberTechBox(
                  label: '// TIME',
                  value: formatDuration(act.durationMovingSec),
                  weight: weight,
                ),
              if (config.showAvgHr && act.avgHeartRate != null)
                _CyberTechBox(
                  label: '// PULSE',
                  value: '${act.avgHeartRate!.round()} BPM',
                  weight: weight,
                ),
              if (config.showElevation)
                _CyberTechBox(
                  label: '// ELEV',
                  value: UnitFormatter.formatElevation(act.totalElevationGainM, unitSystem, signed: true),
                  weight: weight,
                ),
            ],
          ),
          if (config.showWatermark) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '[ FITTRACE // NIGHT OPS ]',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CyberTechBox extends StatelessWidget {
  const _CyberTechBox({
    required this.label,
    required this.value,
    required this.weight,
  });

  final String label;
  final String value;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF060A13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: weight,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cute Scrapbook & Polaroid sticker overlay with playful badges.
class _CuteJournalStatsStickerOverlay extends StatelessWidget {
  const _CuteJournalStatsStickerOverlay({
    required this.bundle,
    required this.config,
    required this.unitSystem,
  });

  final ActivityDetailBundle bundle;
  final StoryEditorConfig config;
  final String unitSystem;

  @override
  Widget build(BuildContext context) {
    final act = bundle.activity;
    final crossAxis = switch (config.alignment) {
      StoryTextAlignment.left => CrossAxisAlignment.start,
      StoryTextAlignment.center => CrossAxisAlignment.center,
      StoryTextAlignment.right => CrossAxisAlignment.end,
    };
    final weight = config.fontWeight.weight;
    final distText = UnitFormatter.formatDistanceValue(act.distanceMeters, unitSystem);
    final distUnit = UnitFormatter.distanceUnitLabel(unitSystem, upperCase: true);

    return Container(
      constraints: const BoxConstraints(maxWidth: 312),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E5E4), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF292524).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxis,
        children: <Widget>[
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF08A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '✿ GOOD RUN ✿',
                  style: TextStyle(
                    color: Color(0xFF854D0E),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💖 HAPPY MILES',
                  style: TextStyle(
                    color: Color(0xFF9D174D),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (config.showDate)
                Text(
                  formatActivityLocalDate(act.startTimeUtc, act.utcOffsetSeconds),
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (config.showTitle) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              act.title,
              textAlign: config.alignment.textAlign,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF1C1917),
                fontSize: 17,
                fontWeight: weight,
                letterSpacing: -0.2,
              ),
            ),
          ],
          if (config.showDistance) ...<Widget>[
            const SizedBox(height: 8),
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
                    color: const Color(0xFF1C1917),
                    fontSize: 48,
                    height: 0.96,
                    fontWeight: weight,
                    letterSpacing: -1.5,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    distUnit,
                    style: const TextStyle(
                      color: Color(0xFFE11D48),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('👟✨', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: switch (config.alignment) {
              StoryTextAlignment.left => WrapAlignment.start,
              StoryTextAlignment.center => WrapAlignment.center,
              StoryTextAlignment.right => WrapAlignment.end,
            },
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (config.showPace)
                _JournalChip(
                  label: '🌸 PACE',
                  value: UnitFormatter.formatPaceWithUnit(act.avgPaceSecPerKm, unitSystem),
                  bg: const Color(0xFFFFE4E6),
                  textColor: const Color(0xFF9F1239),
                  weight: weight,
                ),
              if (config.showMovingTime)
                _JournalChip(
                  label: '⏱️ TIME',
                  value: formatDuration(act.durationMovingSec),
                  bg: const Color(0xFFFEF9C3),
                  textColor: const Color(0xFF854D0E),
                  weight: weight,
                ),
              if (config.showAvgHr && act.avgHeartRate != null)
                _JournalChip(
                  label: '💖 HEART',
                  value: '${act.avgHeartRate!.round()} BPM',
                  bg: const Color(0xFFFFEDD5),
                  textColor: const Color(0xFF9A3412),
                  weight: weight,
                ),
              if (config.showElevation)
                _JournalChip(
                  label: '⛰️ ELEV',
                  value: UnitFormatter.formatElevation(act.totalElevationGainM, unitSystem, signed: true),
                  bg: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF166534),
                  weight: weight,
                ),
            ],
          ),
          if (config.showWatermark) ...<Widget>[
            const SizedBox(height: 12),
            const Text(
              'fittrace scrapbook • happy miles ✿',
              style: TextStyle(
                color: Color(0xFF57534E),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JournalChip extends StatelessWidget {
  const _JournalChip({
    required this.label,
    required this.value,
    required this.bg,
    required this.textColor,
    required this.weight,
  });

  final String label;
  final String value;
  final Color bg;
  final Color textColor;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF1C1917),
              fontSize: 13,
              fontWeight: weight,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Route Projections, Painters, & Aesthetic Background Widgets
// -----------------------------------------------------------------------------

class _RouteGeometry {
  _RouteGeometry({
    required this.bundle,
    required this.routeRect,
  }) {
    if (!bundle.activity.hasGpsTrack || bundle.mapSegments.isEmpty) {
      hasPoints = false;
      return;
    }

    final allPoints = bundle.mapSegments.expand((s) => s.points).toList();
    if (allPoints.length < 2) {
      hasPoints = false;
      return;
    }

    hasPoints = true;
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
    _cosLat = math.cos(midLatRad).abs().clamp(0.2, 1.0);
    final latSpan = math.max(maxLat - minLat, 1e-6);
    final lngSpan = math.max((maxLng - minLng) * _cosLat, 1e-6);

    _scale = math.min(routeRect.width / lngSpan, routeRect.height / latSpan);
    final drawnW = lngSpan * _scale;
    final drawnH = latSpan * _scale;
    _originX = routeRect.left + (routeRect.width - drawnW) * 0.5;
    _originY = routeRect.top + (routeRect.height - drawnH) * 0.5;
    _minLng = minLng;
    _maxLat = maxLat;
  }

  final ActivityDetailBundle bundle;
  final Rect routeRect;
  late final bool hasPoints;
  late final double _cosLat;
  late final double _scale;
  late final double _originX;
  late final double _originY;
  late final double _minLng;
  late final double _maxLat;

  Offset project(double lat, double lng) {
    final dx = _originX + ((lng - _minLng) * _cosLat) * _scale;
    final dy = _originY + (_maxLat - lat) * _scale;
    return Offset(dx, dy);
  }

  Path buildFullPath() {
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
    return fullPath;
  }
}

class _RouteGlowPainter extends CustomPainter {
  _RouteGlowPainter({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _RouteGeometry(
      bundle: bundle,
      routeRect: Rect.fromLTWH(34, 72, size.width - 68, size.height * 0.44),
    );

    if (!geo.hasPoints) {
      _paintIndoorPulse(canvas, size, Colors.white);
      return;
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

    final fullPath = geo.buildFullPath();
    canvas.drawPath(fullPath, outerGlowPaint);
    canvas.drawPath(fullPath, innerGlowPaint);

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
      final p0 = geo.project(segment.points.first.latitude, segment.points.first.longitude);
      segPath.moveTo(p0.dx, p0.dy);
      for (var i = 1; i < segment.points.length; i++) {
        final p = geo.project(segment.points[i].latitude, segment.points[i].longitude);
        segPath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(segPath, corePaint);
    }

    if (bundle.startPoint != null) {
      final start = geo.project(bundle.startPoint!.latitude, bundle.startPoint!.longitude);
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
      final end = geo.project(bundle.endPoint!.latitude, bundle.endPoint!.longitude);
      canvas.drawCircle(end, 9, Paint()..color = Colors.white.withValues(alpha: 0.25));
      canvas.drawCircle(end, 4.5, Paint()..color = Colors.white);
    }
  }

  void _paintIndoorPulse(Canvas canvas, Size size, Color color) {
    final center = Offset(size.width * 0.5, size.height * 0.30);
    for (final radius in <double>[36, 68, 102, 136]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: 0.14),
      );
    }
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RouteGlowPainter oldDelegate) =>
      oldDelegate.bundle.activity.id != bundle.activity.id ||
      oldDelegate.bundle.mapSegments != bundle.mapSegments;
}

class _PastelRoutePainter extends CustomPainter {
  _PastelRoutePainter({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _RouteGeometry(
      bundle: bundle,
      routeRect: Rect.fromLTWH(36, 64, size.width - 72, size.height * 0.38),
    );

    if (!geo.hasPoints) {
      final center = Offset(size.width * 0.5, size.height * 0.26);
      for (final radius in <double>[30, 60, 90, 120]) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFC084FC).withValues(alpha: 0.25),
        );
      }
      canvas.drawCircle(center, 8, Paint()..color = const Color(0xFFEC4899));
      return;
    }

    final fullPath = geo.buildFullPath();

    // Soft lilac halo
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFC084FC).withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Pure white core ribbon
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );

    if (bundle.startPoint != null) {
      final start = geo.project(bundle.startPoint!.latitude, bundle.startPoint!.longitude);
      canvas.drawCircle(start, 5.5, Paint()..color = const Color(0xFFEC4899));
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
      final end = geo.project(bundle.endPoint!.latitude, bundle.endPoint!.longitude);
      canvas.drawCircle(end, 8, Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.4));
      canvas.drawCircle(end, 4.5, Paint()..color = const Color(0xFF8B5CF6));
    }
  }

  @override
  bool shouldRepaint(covariant _PastelRoutePainter oldDelegate) =>
      oldDelegate.bundle.activity.id != bundle.activity.id ||
      oldDelegate.bundle.mapSegments != bundle.mapSegments;
}

class _PastelSparkleDecorations extends StatelessWidget {
  const _PastelSparkleDecorations();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 36,
            left: 28,
            child: Text(
              '✦',
              style: TextStyle(color: Color(0xFFC084FC), fontSize: 18),
            ),
          ),
          Positioned(
            top: 70,
            right: 32,
            child: Text(
              '✧',
              style: TextStyle(color: Color(0xFFF472B6), fontSize: 16),
            ),
          ),
          Positioned(
            top: 220,
            left: 36,
            child: Text(
              '⋆',
              style: TextStyle(color: Color(0xFFFBBF24), fontSize: 20),
            ),
          ),
          Positioned(
            top: 250,
            right: 34,
            child: Text(
              '✦',
              style: TextStyle(color: Color(0xFFA855F7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberNeonRoutePainter extends CustomPainter {
  _CyberNeonRoutePainter({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _RouteGeometry(
      bundle: bundle,
      routeRect: Rect.fromLTWH(34, 64, size.width - 68, size.height * 0.42),
    );

    if (!geo.hasPoints) {
      final center = Offset(size.width * 0.5, size.height * 0.28);
      for (final radius in <double>[34, 68, 102, 136]) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFF00F0FF).withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = const Color(0xFF00FF88)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      return;
    }

    final fullPath = geo.buildFullPath();

    // Outer cyan bloom
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner lime bloom
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF00FF88).withValues(alpha: 0.70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Electric lime core line
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF00FF88),
    );

    if (bundle.startPoint != null) {
      final start = geo.project(bundle.startPoint!.latitude, bundle.startPoint!.longitude);
      canvas.drawCircle(
        start,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF00F0FF),
      );
      canvas.drawCircle(start, 3, Paint()..color = const Color(0xFF00FF88));
    }
    if (bundle.endPoint != null) {
      final end = geo.project(bundle.endPoint!.latitude, bundle.endPoint!.longitude);
      canvas.drawCircle(end, 9, Paint()..color = const Color(0xFF00F0FF).withValues(alpha: 0.35));
      canvas.drawCircle(end, 4, Paint()..color = const Color(0xFF00F0FF));
    }
  }

  @override
  bool shouldRepaint(covariant _CyberNeonRoutePainter oldDelegate) =>
      oldDelegate.bundle.activity.id != bundle.activity.id ||
      oldDelegate.bundle.mapSegments != bundle.mapSegments;
}

class _ReceiptRoutePainter extends CustomPainter {
  _ReceiptRoutePainter({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _RouteGeometry(
      bundle: bundle,
      routeRect: Rect.fromLTWH(10, 8, size.width - 20, size.height - 16),
    );

    if (!geo.hasPoints) {
      final center = Offset(size.width * 0.5, size.height * 0.5);
      canvas.drawCircle(
        center,
        18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black38,
      );
      canvas.drawCircle(center, 4, Paint()..color = Colors.black);
      return;
    }

    final fullPath = geo.buildFullPath();
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF1E293B),
    );

    if (bundle.startPoint != null) {
      final start = geo.project(bundle.startPoint!.latitude, bundle.startPoint!.longitude);
      canvas.drawCircle(start, 3.5, Paint()..color = Colors.black);
    }
    if (bundle.endPoint != null) {
      final end = geo.project(bundle.endPoint!.latitude, bundle.endPoint!.longitude);
      canvas.drawCircle(
        end,
        4.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.black,
      );
      canvas.drawCircle(end, 2, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptRoutePainter oldDelegate) =>
      oldDelegate.bundle.activity.id != bundle.activity.id ||
      oldDelegate.bundle.mapSegments != bundle.mapSegments;
}

class _JournalPolaroidRoutePainter extends CustomPainter {
  _JournalPolaroidRoutePainter({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = _RouteGeometry(
      bundle: bundle,
      routeRect: Rect.fromLTWH(12, 10, size.width - 24, size.height - 20),
    );

    if (!geo.hasPoints) {
      final center = Offset(size.width * 0.5, size.height * 0.5);
      canvas.drawCircle(
        center,
        24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFFDA4AF),
      );
      canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFE11D48));
      return;
    }

    final fullPath = geo.buildFullPath();
    canvas.drawPath(
      fullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFE11D48),
    );

    if (bundle.startPoint != null) {
      final start = geo.project(bundle.startPoint!.latitude, bundle.startPoint!.longitude);
      canvas.drawCircle(start, 4.5, Paint()..color = const Color(0xFF059669));
    }
    if (bundle.endPoint != null) {
      final end = geo.project(bundle.endPoint!.latitude, bundle.endPoint!.longitude);
      canvas.drawCircle(end, 6.5, Paint()..color = const Color(0xFFE11D48).withValues(alpha: 0.3));
      canvas.drawCircle(end, 3.5, Paint()..color = const Color(0xFFE11D48));
    }
  }

  @override
  bool shouldRepaint(covariant _JournalPolaroidRoutePainter oldDelegate) =>
      oldDelegate.bundle.activity.id != bundle.activity.id ||
      oldDelegate.bundle.mapSegments != bundle.mapSegments;
}

class _PolaroidRouteCard extends StatelessWidget {
  const _PolaroidRouteCard({required this.bundle});

  final ActivityDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 270,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF44403C).withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0xFFE7E5E4)),
                ),
                child: CustomPaint(
                  painter: _JournalPolaroidRoutePainter(bundle: bundle),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'happy running adventures ☀️👟',
                style: TextStyle(
                  color: Color(0xFF78716C),
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Washi tape top-left (peach/coral)
        Positioned(
          top: -7,
          left: 12,
          child: Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 50,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFFFCA5A5).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // Washi tape top-right (sage/mint)
        Positioned(
          top: -7,
          right: 12,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 50,
              height: 15,
              decoration: BoxDecoration(
                color: const Color(0xFF86EFAC).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotGridBackgroundPainter extends CustomPainter {
  const _DotGridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const step = 20.0;
    for (var x = step * 0.5; x < size.width; x += step) {
      for (var y = step * 0.5; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReceiptZigZagPainter extends CustomPainter {
  const _ReceiptZigZagPainter({required this.color, required this.isTop});

  final Color color;
  final bool isTop;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const toothWidth = 8.0;
    final toothHeight = size.height;
    final count = (size.width / toothWidth).ceil();

    if (isTop) {
      path.moveTo(0, toothHeight);
      for (var i = 0; i < count; i++) {
        final x1 = i * toothWidth + toothWidth * 0.5;
        final x2 = (i + 1) * toothWidth;
        path.lineTo(x1, 0);
        path.lineTo(x2, toothHeight);
      }
      path.lineTo(size.width, toothHeight);
      path.close();
    } else {
      path.moveTo(0, 0);
      for (var i = 0; i < count; i++) {
        final x1 = i * toothWidth + toothWidth * 0.5;
        final x2 = (i + 1) * toothWidth;
        path.lineTo(x1, toothHeight);
        path.lineTo(x2, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReceiptZigZagPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isTop != isTop;
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    const pattern = <double>[
      2, 1, 3, 2, 1, 2, 4, 1, 2, 3, 1, 2, 1, 3, 2, 4, 1, 2, 1, 3, 2, 1, 4, 2, 1,
      3, 1, 2, 3, 1, 4, 2, 1, 2, 3, 2, 1, 3, 1, 2, 4, 1, 2, 3, 1, 2, 1, 3, 2, 4
    ];

    var currentX = 6.0;
    final totalAvailable = size.width - 12.0;
    final sumPattern = pattern.reduce((a, b) => a + b);
    final scale = totalAvailable / sumPattern;

    for (var i = 0; i < pattern.length; i++) {
      final w = pattern[i] * scale;
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, w, size.height), paint);
      }
      currentX += w;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
