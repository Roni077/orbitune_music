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

  static final Map<String, ThemeData> _themeCache = {};

  // Dynamic Theme Builder based on theme mode string, accent color index, and font family
  static ThemeData buildTheme({
    String mode = 'dark',
    int accentIndex = 0,
    double cornerRadius = 20.0,
    String fontFamily = 'righteous_poppins',
  }) {
    final cacheKey = '$mode:$accentIndex:$cornerRadius:$fontFamily';
    return _themeCache.putIfAbsent(cacheKey, () {
      AppTypography.activeFontKey = fontFamily;
      AppTypography.clearCache();

      final accent = (accentIndex >= 0 && accentIndex < AppColors.accentPalette.length)
          ? AppColors.accentPalette[accentIndex]
          : AppColors.accentGreen;

      ColorScheme scheme;
      Color scaffoldBg;
      Color surfaceContainer;

      switch (mode) {
        case 'oled':
          scheme = AppColorSchemes.oledScheme.copyWith(primary: accent);
          scaffoldBg = AppColors.oledBackground;
          surfaceContainer = AppColors.oledSurfaceVariant;
          break;
        case 'light':
          scheme = AppColorSchemes.lightScheme.copyWith(primary: accent);
          scaffoldBg = const Color(0xFFF8FAFC);
          surfaceContainer = const Color(0xFFE2E8F0);
          break;
        case 'solarized':
          scheme = AppColorSchemes.solarizedScheme.copyWith(primary: accent);
          scaffoldBg = const Color(0xFF14120E);
          surfaceContainer = const Color(0xFF2C251F);
          break;
        case 'cyberpunk':
          scheme = AppColorSchemes.cyberpunkScheme.copyWith(primary: accent);
          scaffoldBg = const Color(0xFF08090E);
          surfaceContainer = const Color(0xFF1B1D2A);
          break;
        case 'dynamic':
          scheme = AppColorSchemes.darkScheme.copyWith(
            primary: accent,
            secondary: AppColors.accentIndigo,
            surface: const Color(0xFF131326),
            surfaceContainerHighest: const Color(0xFF1E1B4B),
          );
          scaffoldBg = const Color(0xFF0D0D1A);
          surfaceContainer = const Color(0xFF1E1B4B);
          break;
        case 'dark':
        default:
          scheme = AppColorSchemes.darkScheme.copyWith(primary: accent);
          scaffoldBg = AppColors.darkBackground;
          surfaceContainer = AppColors.darkSurfaceVariant;
          break;
      }

      final textTheme = AppTypography.buildTextTheme(scheme);
      final customCardShape = ExpressiveShapes.buildCustomCardShape(cornerRadius);

      return ThemeData(
        useMaterial3: true,
        brightness: scheme.brightness,
        colorScheme: scheme,
        scaffoldBackgroundColor: scaffoldBg,
        canvasColor: scaffoldBg,
        cardColor: scheme.surface,
        dialogBackgroundColor: scheme.surface,
        fontFamily: AppTypography.fontFamilyBody,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTypography.headlineMedium.copyWith(color: scheme.onSurface),
          iconTheme: IconThemeData(color: scheme.onSurface),
        ),
        cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          shape: customCardShape,
          margin: EdgeInsets.zero,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          modalBackgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadius + 4)),
          ),
          showDragHandle: true,
          dragHandleColor: scheme.outline.withValues(alpha: 0.4),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: surfaceContainer,
          thumbColor: accent,
          overlayColor: accent.withValues(alpha: 0.2),
          trackHeight: 4.0,
        ),
      );
    });
  }
}
