import 'package:flutter/material.dart';

/// Monochrome color tokens defined in PRD §6.1.
@immutable
class FitTraceColors extends ThemeExtension<FitTraceColors> {
  const FitTraceColors({
    required this.bgBase,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentSharp,
    required this.accentMetric,
    required this.hairlineBorder,
    this.accentSuccess = const Color(0xFF00E676),
    this.accentInfo = const Color(0xFF00E5FF),
    this.accentWarning = const Color(0xFFFF9100),
    this.accentDanger = const Color(0xFFFF5252),
    this.trackBg = const Color(0x14FFFFFF),
  });

  final Color bgBase;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentSharp;
  final Color accentMetric;
  final Color hairlineBorder;
  final Color accentSuccess;
  final Color accentInfo;
  final Color accentWarning;
  final Color accentDanger;
  final Color trackBg;

  static const FitTraceColors dark = FitTraceColors(
    bgBase: Color(0xFF0A0A0A),
    bgElevated: Color(0xFF161616),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFF9E9E9E),
    accentSharp: Color(0xFFFFFFFF),
    accentMetric: Color(0xFFE8E8E8),
    hairlineBorder: Color(0x1FFFFFFF), // 12% opacity of #FFFFFF (PRD §6.3)
    accentSuccess: Color(0xFF00E676),
    accentInfo: Color(0xFF00E5FF),
    accentWarning: Color(0xFFFF9100),
    accentDanger: Color(0xFFFF5252),
    trackBg: Color(0x14FFFFFF),
  );

  static const FitTraceColors light = FitTraceColors(
    bgBase: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF4F4F4),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF5C5C5C),
    accentSharp: Color(0xFF000000),
    accentMetric: Color(0xFF2E2E2E),
    hairlineBorder: Color(0x1F000000), // 12% opacity of #000000 (PRD §6.3)
    accentSuccess: Color(0xFF008744),
    accentInfo: Color(0xFF007791),
    accentWarning: Color(0xFFB85C00),
    accentDanger: Color(0xFFC62828),
    trackBg: Color(0x14000000),
  );

  @override
  FitTraceColors copyWith({
    Color? bgBase,
    Color? bgElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? accentSharp,
    Color? accentMetric,
    Color? hairlineBorder,
    Color? accentSuccess,
    Color? accentInfo,
    Color? accentWarning,
    Color? accentDanger,
    Color? trackBg,
  }) {
    return FitTraceColors(
      bgBase: bgBase ?? this.bgBase,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accentSharp: accentSharp ?? this.accentSharp,
      accentMetric: accentMetric ?? this.accentMetric,
      hairlineBorder: hairlineBorder ?? this.hairlineBorder,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentInfo: accentInfo ?? this.accentInfo,
      accentWarning: accentWarning ?? this.accentWarning,
      accentDanger: accentDanger ?? this.accentDanger,
      trackBg: trackBg ?? this.trackBg,
    );
  }

  @override
  FitTraceColors lerp(ThemeExtension<FitTraceColors>? other, double t) {
    if (other is! FitTraceColors) return this;
    return FitTraceColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t) ?? bgBase,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t) ?? bgElevated,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      accentSharp: Color.lerp(accentSharp, other.accentSharp, t) ?? accentSharp,
      accentMetric:
          Color.lerp(accentMetric, other.accentMetric, t) ?? accentMetric,
      hairlineBorder:
          Color.lerp(hairlineBorder, other.hairlineBorder, t) ?? hairlineBorder,
      accentSuccess:
          Color.lerp(accentSuccess, other.accentSuccess, t) ?? accentSuccess,
      accentInfo: Color.lerp(accentInfo, other.accentInfo, t) ?? accentInfo,
      accentWarning:
          Color.lerp(accentWarning, other.accentWarning, t) ?? accentWarning,
      accentDanger:
          Color.lerp(accentDanger, other.accentDanger, t) ?? accentDanger,
      trackBg: Color.lerp(trackBg, other.trackBg, t) ?? trackBg,
    );
  }
}

extension FitTraceColorsX on BuildContext {
  FitTraceColors get fitColors =>
      Theme.of(this).extension<FitTraceColors>() ?? FitTraceColors.dark;
}

