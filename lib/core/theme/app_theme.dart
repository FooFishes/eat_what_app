import 'package:eat_what_app/core/theme/app_colors.dart';
import 'package:eat_what_app/core/theme/app_font_sizes.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const new _();

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: .light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primarySoft,
        tertiary: AppColors.accentBrown,
        error: AppColors.accentRed,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      );

  static final TextTheme _textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: AppFontSizes.s48,
      fontWeight: .w700,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: AppFontSizes.s40,
      fontWeight: .w700,
      height: 1.1,
    ),
    displaySmall: TextStyle(
      fontSize: AppFontSizes.s36,
      fontWeight: .w700,
      height: 1.15,
    ),
    headlineLarge: TextStyle(
      fontSize: AppFontSizes.s32,
      fontWeight: .w600,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: AppFontSizes.s28,
      fontWeight: .w600,
      height: 1.2,
    ),
    titleLarge: TextStyle(
      fontSize: AppFontSizes.s24,
      fontWeight: .w600,
      height: 1.25,
    ),
    titleMedium: TextStyle(
      fontSize: AppFontSizes.s20,
      fontWeight: .w600,
      height: 1.25,
    ),
    bodyLarge: TextStyle(
      fontSize: AppFontSizes.s16,
      fontWeight: .w400,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: AppFontSizes.s14,
      fontWeight: .w400,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: AppFontSizes.s12,
      fontWeight: .w400,
      height: 1.3,
    ),
    labelLarge: TextStyle(
      fontSize: AppFontSizes.s16,
      fontWeight: .w600,
      height: 1.25,
    ),
    labelMedium: TextStyle(
      fontSize: AppFontSizes.s14,
      fontWeight: .w500,
      height: 1.25,
    ),
    labelSmall: TextStyle(
      fontSize: AppFontSizes.s12,
      fontWeight: .w500,
      height: 1.2,
    ),
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(color: AppColors.card, margin: .zero),
      dividerColor: AppColors.border,
    );
  }
}
