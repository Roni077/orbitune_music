import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'color_schemes.dart';
import 'expressive_shapes.dart';

/// Complete Material 3 Expressive ThemeData setup for Orbitune
class AppTheme {
  AppTheme._();

  // Dark Theme (Default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColorSchemes.darkScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: AppTypography.titleMedium.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: ExpressiveShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: ExpressiveShapes.sheetShape,
        showDragHandle: true,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentGreen,
        inactiveTrackColor: AppColors.darkSurfaceVariant,
        thumbColor: AppColors.accentGreen,
        overlayColor: AppColors.accentGreen.withValues(alpha: 0.2),
        trackHeight: 4.0,
      ),
    );
  }

  // Pure OLED Theme
  static ThemeData get oledTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColorSchemes.oledScheme,
      scaffoldBackgroundColor: AppColors.oledBackground,
      fontFamily: AppTypography.titleMedium.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.oledSurface,
        elevation: 0,
        shape: ExpressiveShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.oledSurface,
        shape: ExpressiveShapes.sheetShape,
        showDragHandle: true,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentGreen,
        inactiveTrackColor: AppColors.oledSurfaceVariant,
        thumbColor: AppColors.accentGreen,
        overlayColor: AppColors.accentGreen.withValues(alpha: 0.2),
        trackHeight: 4.0,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: AppColorSchemes.lightScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: AppTypography.titleMedium.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: const Color(0xFF0F172A)),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: ExpressiveShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: ExpressiveShapes.sheetShape,
        showDragHandle: true,
      ),
    );
  }
}
