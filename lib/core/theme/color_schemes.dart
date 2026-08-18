import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Predefined Material 3 ColorSchemes for Orbitune
class AppColorSchemes {
  AppColorSchemes._();

  // Dark Midnight Scheme (Default)
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accentGreen,
    onPrimary: Color(0xFF003914),
    primaryContainer: Color(0xFF005320),
    onPrimaryContainer: Color(0xFF86F9A2),
    secondary: AppColors.accentIndigo,
    onSecondary: Color(0xFF1E1B4B),
    secondaryContainer: Color(0xFF312E81),
    onSecondaryContainer: Color(0xFFE0E7FF),
    tertiary: AppColors.accentCyan,
    onTertiary: Color(0xFF00363F),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: AppColors.darkSurface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.glassBorder,
    outlineVariant: AppColors.divider,
    shadow: Color(0xFF000000),
  );

  // OLED Pure Black Scheme
  static const ColorScheme oledScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accentGreen,
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF005320),
    onPrimaryContainer: Color(0xFF86F9A2),
    secondary: AppColors.accentIndigo,
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF1E1B4B),
    onSecondaryContainer: Color(0xFFE0E7FF),
    tertiary: AppColors.accentCyan,
    onTertiary: Color(0xFF000000),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF000000),
    surface: AppColors.oledSurface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.oledSurfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    outline: Color(0x33333333),
    outlineVariant: Color(0x1A333333),
    shadow: Color(0xFF000000),
  );

  // Light Scheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF15803D),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCFCE7),
    onPrimaryContainer: Color(0xFF14532D),
    secondary: Color(0xFF4F46E5),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEEF2FF),
    onSecondaryContainer: Color(0xFF312E81),
    tertiary: Color(0xFF0891B2),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0x1A000000),
  );
}
