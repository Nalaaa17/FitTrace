import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Monochrome theme builder following PRD §6.1–§6.3.
class AppTheme {
  AppTheme._();

  static const double pagePadding = 16;
  static const double cardRadius = 12;

  static ThemeData dark() => _build(Brightness.dark, FitTraceColors.dark);

  static ThemeData light() => _build(Brightness.light, FitTraceColors.light);

  static ThemeData _build(Brightness brightness, FitTraceColors colors) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accentSharp,
      onPrimary: colors.bgBase,
      secondary: colors.accentMetric,
      onSecondary: colors.bgBase,
      error: colors.accentSharp,
      onError: colors.bgBase,
      surface: colors.bgElevated,
      onSurface: colors.textPrimary,
      outline: colors.hairlineBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bgBase,
      canvasColor: colors.bgBase,
      textTheme: AppTypography.buildTextTheme(
        primary: colors.textPrimary,
        secondary: colors.textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.displayFontFamily,
          fontFamilyFallback: AppTypography.fallbackFamilies,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.bgElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colors.hairlineBorder, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.hairlineBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.accentSharp.withValues(alpha: isDark ? 0.14 : 0.10),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.accentSharp : colors.textSecondary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontFamilyFallback: AppTypography.fallbackFamilies,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.textPrimary : colors.textSecondary,
            letterSpacing: 0.3,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentSharp,
          foregroundColor: colors.bgBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.hairlineBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}

