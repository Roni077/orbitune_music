import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography tokens supporting dynamic font pairings and System Font
class AppTypography {
  AppTypography._();

  static String activeFontKey = 'righteous_poppins';

  static TextStyle _getBrandStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    final effectiveColor = color ?? AppColors.textPrimary;
    switch (activeFontKey) {
      case 'system':
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
      case 'inter':
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
      case 'outfit':
        return GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
      case 'righteous_poppins':
      default:
        return GoogleFonts.righteous(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing ?? 0.5,
          color: effectiveColor,
          height: height,
        );
    }
  }

  static TextStyle _getBodyStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
    double? height,
  }) {
    final effectiveColor = color ?? AppColors.textPrimary;
    switch (activeFontKey) {
      case 'system':
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
      case 'inter':
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
      case 'outfit':
        return GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
      case 'righteous_poppins':
      default:
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
          height: height,
        );
    }
  }

  // Headings & Brand Titles
  static TextStyle get brandTitle => _getBrandStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      );

  static TextStyle get headlineLarge => _getBrandStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get headlineMedium => _getBrandStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get headlineSmall => _getBrandStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
      );

  // Body & Track Details
  static TextStyle get titleLarge => _getBodyStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => _getBodyStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleSmall => _getBodyStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyLarge => _getBodyStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => _getBodyStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => _getBodyStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textMuted,
      );

  // Labels & Badges
  static TextStyle get labelLarge => _getBodyStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelMedium => _getBodyStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSmall => _getBodyStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get caption => _getBodyStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textMuted,
      );

  static TextStyle get lyricActive => _getBodyStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get lyricInactive => _getBodyStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        height: 1.5,
      );

  static String? get fontFamilyBody {
    switch (activeFontKey) {
      case 'system':
        return null;
      case 'inter':
        return GoogleFonts.inter().fontFamily;
      case 'outfit':
        return GoogleFonts.plusJakartaSans().fontFamily;
      case 'righteous_poppins':
      default:
        return GoogleFonts.poppins().fontFamily;
    }
  }

  static String? get fontFamilyBrand {
    switch (activeFontKey) {
      case 'system':
        return null;
      case 'inter':
        return GoogleFonts.inter().fontFamily;
      case 'outfit':
        return GoogleFonts.outfit().fontFamily;
      case 'righteous_poppins':
      default:
        return GoogleFonts.righteous().fontFamily;
    }
  }

  /// Builds a complete Material 3 TextTheme according to active font family key
  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: _getBrandStyle(fontSize: 57, fontWeight: FontWeight.normal, color: colorScheme.onSurface),
      displayMedium: _getBrandStyle(fontSize: 45, fontWeight: FontWeight.normal, color: colorScheme.onSurface),
      displaySmall: _getBrandStyle(fontSize: 36, fontWeight: FontWeight.normal, color: colorScheme.onSurface),
      headlineLarge: _getBrandStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineMedium: _getBrandStyle(fontSize: 28, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      headlineSmall: _getBrandStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleLarge: _getBodyStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleMedium: _getBodyStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleSmall: _getBodyStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      bodyLarge: _getBodyStyle(fontSize: 16, fontWeight: FontWeight.normal, color: colorScheme.onSurface),
      bodyMedium: _getBodyStyle(fontSize: 14, fontWeight: FontWeight.normal, color: colorScheme.onSurfaceVariant),
      bodySmall: _getBodyStyle(fontSize: 12, fontWeight: FontWeight.normal, color: colorScheme.onSurfaceVariant),
      labelLarge: _getBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      labelMedium: _getBodyStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      labelSmall: _getBodyStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
    );
  }
}
