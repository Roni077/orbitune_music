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

  // Solarized Amber Theme
  static ThemeData get solarizedTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColorSchemes.solarizedScheme,
      scaffoldBackgroundColor: const Color(0xFF14120E),
      fontFamily: AppTypography.titleMedium.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: const Color(0xFFEDE0D4)),
        iconTheme: const IconThemeData(color: Color(0xFFEDE0D4)),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1A16),
        elevation: 0,
        shape: ExpressiveShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentAmber,
        inactiveTrackColor: const Color(0xFF2C251F),
        thumbColor: AppColors.accentAmber,
        overlayColor: AppColors.accentAmber.withValues(alpha: 0.2),
        trackHeight: 4.0,
      ),
    );
  }

  // Cyberpunk Neon Theme
  static ThemeData get cyberpunkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AppColorSchemes.cyberpunkScheme,
      scaffoldBackgroundColor: const Color(0xFF08090E),
      fontFamily: AppTypography.titleMedium.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE2E8F0)),
        iconTheme: const IconThemeData(color: Color(0xFFE2E8F0)),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF0F111A),
        elevation: 0,
        shape: ExpressiveShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentCyan,
        inactiveTrackColor: const Color(0xFF1B1D2A),
        thumbColor: AppColors.accentPink,
        overlayColor: AppColors.accentCyan.withValues(alpha: 0.2),
        trackHeight: 4.0,
      ),
    );
  }

  // Dynamic Theme Builder based on theme mode string and accent color index
  static ThemeData buildTheme({
    String mode = 'dark',
    int accentIndex = 0,
    double cornerRadius = 20.0,
  }) {
    final accent = (accentIndex >= 0 && accentIndex < AppColors.accentPalette.length)
        ? AppColors.accentPalette[accentIndex]
        : AppColors.accentGreen;

    switch (mode) {
      case 'oled':
        return oledTheme.copyWith(
          colorScheme: AppColorSchemes.oledScheme.copyWith(primary: accent),
          sliderTheme: oledTheme.sliderTheme.copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
          ),
        );
      case 'light':
        return lightTheme.copyWith(
          colorScheme: AppColorSchemes.lightScheme.copyWith(primary: accent),
        );
      case 'solarized':
        return solarizedTheme.copyWith(
          colorScheme: AppColorSchemes.solarizedScheme.copyWith(primary: accent),
          sliderTheme: solarizedTheme.sliderTheme.copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
          ),
        );
      case 'cyberpunk':
        return cyberpunkTheme.copyWith(
          colorScheme: AppColorSchemes.cyberpunkScheme.copyWith(primary: accent),
          sliderTheme: cyberpunkTheme.sliderTheme.copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
          ),
        );
      case 'dark':
      default:
        return darkTheme.copyWith(
          colorScheme: AppColorSchemes.darkScheme.copyWith(primary: accent),
          sliderTheme: darkTheme.sliderTheme.copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
          ),
        );
    }
  }
}
