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

  // Solarized Amber Scheme
  static const ColorScheme solarizedScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accentAmber,
    onPrimary: Color(0xFF3F2E00),
    primaryContainer: Color(0xFF5B4300),
    onPrimaryContainer: Color(0xFFFFDF9E),
    secondary: AppColors.accentOrange,
    onSecondary: Color(0xFF431B00),
    secondaryContainer: Color(0xFF632B00),
    onSecondaryContainer: Color(0xFFFFDBC9),
    tertiary: AppColors.accentYellow,
    onTertiary: Color(0xFF3B3000),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF1E1A16),
    onSurface: Color(0xFFEDE0D4),
    surfaceContainerHighest: Color(0xFF2C251F),
    onSurfaceVariant: Color(0xFFD3C4B8),
    outline: Color(0x33F59E0B),
    outlineVariant: Color(0x1AF59E0B),
    shadow: Color(0xFF000000),
  );

  // Cyberpunk Neon Scheme
  static const ColorScheme cyberpunkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accentCyan,
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF004E5B),
    onPrimaryContainer: Color(0xFF97F0FF),
    secondary: AppColors.accentPink,
    onSecondary: Color(0xFF580036),
    secondaryContainer: Color(0xFF7D004F),
    onSecondaryContainer: Color(0xFFFFD8E7),
    tertiary: AppColors.accentPurple,
    onTertiary: Color(0xFF381E72),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF0F111A),
    onSurface: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFF1B1D2A),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0x4D06B6D4),
    outlineVariant: Color(0x26EC4899),
    shadow: Color(0xFF000000),
  );

  // Helper method to create custom accented ColorScheme
  static ColorScheme buildCustomScheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
  }) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      primaryContainer: primary.withValues(alpha: 0.3),
      onPrimaryContainer: isDark ? const Color(0xFFFFFFFF) : primary,
      secondary: AppColors.accentIndigo,
      onSecondary: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      secondaryContainer: AppColors.accentIndigo.withValues(alpha: 0.3),
      onSecondaryContainer: isDark ? const Color(0xFFFFFFFF) : AppColors.accentIndigo,
      tertiary: AppColors.accentCyan,
      onTertiary: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      surface: surface,
      onSurface: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: isDark ? AppColors.textSecondary : const Color(0xFF475569),
      outline: primary.withValues(alpha: 0.3),
      outlineVariant: AppColors.divider,
      shadow: const Color(0xFF000000),
    );
  }
}
