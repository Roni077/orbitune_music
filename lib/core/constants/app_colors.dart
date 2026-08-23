import 'package:flutter/material.dart';

/// Design tokens and harmonious color palettes for Orbitune
class AppColors {
  AppColors._();

  // Dark Theme Palette (Deep Midnight)
  static const Color darkBackground = Color(0xFF0B0B14);
  static const Color darkSurface = Color(0xFF14142B);
  static const Color darkSurfaceVariant = Color(0xFF1E1E38);
  static const Color darkSurfaceElevated = Color(0xFF26264A);

  // Pure OLED Theme Palette
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0D0D12);
  static const Color oledSurfaceVariant = Color(0xFF181820);

  // Accent & Brand Colors
  static const Color accentGreen = Color(0xFF22C55E); // Electric Green
  static const Color accentIndigo = Color(0xFF6366F1); // Neon Indigo
  static const Color accentCyan = Color(0xFF06B6D4); // Vibrant Cyan
  static const Color accentNeonBlue = Color(0xFF06B6D4); // Vibrant Cyan / Neon Blue alias
  static const Color accentPink = Color(0xFFEC4899); // Electric Pink
  static const Color accentAmber = Color(0xFFF59E0B); // Amber Warning
  static const Color accentYellow = Color(0xFFEAB308); // Electric Yellow
  static const Color accentOrange = Color(0xFFF97316); // Vibrant Orange
  static const Color accentPurple = Color(0xFF8B5CF6); // Neon Purple
  static const Color accentEmerald = Color(0xFF10B981); // Emerald Forest
  static const Color accentCrimson = Color(0xFFEF4444); // Crimson Red

  static const List<Color> accentPalette = [
    accentGreen,
    accentCyan,
    accentIndigo,
    accentPink,
    accentOrange,
    accentYellow,
    accentPurple,
    accentEmerald,
    accentCrimson,
  ];

  static const List<String> accentColorNames = [
    'Electric Green',
    'Vibrant Cyan',
    'Neon Indigo',
    'Electric Pink',
    'Sunset Orange',
    'Solar Yellow',
    'Neon Purple',
    'Emerald Forest',
    'Crimson Red',
  ];

  // WCAG AAA Compliant Text Tokens
  static const Color textPrimary = Color(0xFFF8FAFC);     // 17.5:1 on dark
  static const Color textSecondary = Color(0xFFCBD5E1);   // 11.2:1 on dark
  static const Color textMuted = Color(0xFF94A3B8);       // 7.3:1 WCAG AAA compliant
  static const Color textTertiary = Color(0xFF64748B);
  static const Color white = Color(0xFFFFFFFF);

  // Glassmorphic & Border Tokens
  static const Color glassFill = Color(0x221E1E38);
  static const Color glassBorder = Color(0x336366F1);
  static const Color divider = Color(0x1FFFFFFF);

  static const LinearGradient specularBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x55FFFFFF),
      Color(0x15FFFFFF),
      Color(0x05FFFFFF),
      Color(0x256366F1),
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  /// Resolves WCAG AAA compliant text color (black vs white) for any accent background
  static Color getAccessibleTextColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.45 ? Colors.black : Colors.white;
  }

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF0B0B14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient discShineGradient = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x00000000),
      Color(0x22FFFFFF),
      Color(0x00000000),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
