import 'package:flutter/material.dart';

/// Typographic tokens defined in PRD §6.2 with tabular figures enforced
/// for numeric metrics so counters and tables remain visually stable.
class AppTypography {
  AppTypography._();

  static const String displayFontFamily = 'Space Grotesk';
  static const String bodyFontFamily = 'Inter';
  static const List<String> fallbackFamilies = <String>[
    'Inter',
    'Roboto',
    'sans-serif',
  ];

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextStyle heroDistance(Color color) => TextStyle(
        fontFamily: displayFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 56,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: color,
        fontFeatures: tabularFigures,
      );

  static TextStyle paceLarge(Color color) => TextStyle(
        fontFamily: displayFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 40,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: color,
        fontFeatures: tabularFigures,
      );

  static TextStyle metricLabel(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.96, // 0.08em
        color: color,
      );

  static TextStyle splitTable(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: color,
        fontFeatures: tabularFigures,
      );

  static TextStyle chartAxis(Color color) => TextStyle(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w400,
        color: color,
        fontFeatures: tabularFigures,
      );

  static TextTheme buildTextTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displayLarge: heroDistance(primary),
      displayMedium: paceLarge(primary),
      headlineSmall: TextStyle(
        fontFamily: displayFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelSmall: metricLabel(secondary),
    );
  }
}

