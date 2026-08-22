import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'app_theme.dart';

enum AppThemeMode {
  darkMidnight,
  pureOled,
  light,
  solarized,
  cyberpunk,
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final Ref? _ref;

  ThemeNotifier([this._ref]) : super(AppThemeMode.darkMidnight);

  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == AppThemeMode.darkMidnight ? AppThemeMode.pureOled : AppThemeMode.darkMidnight;
  }

  bool get isDarkMode => state != AppThemeMode.light;
  bool get isOled => state == AppThemeMode.pureOled;

  ThemeData get currentThemeData {
    if (_ref != null) {
      final settings = _ref.watch(settingsProvider);
      return AppTheme.buildTheme(
        mode: settings.themeMode,
        accentIndex: settings.accentColorIndex,
        cornerRadius: settings.cornerRadius,
      );
    }
    switch (state) {
      case AppThemeMode.darkMidnight:
        return AppTheme.darkTheme;
      case AppThemeMode.pureOled:
        return AppTheme.oledTheme;
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.solarized:
        return AppTheme.solarizedTheme;
      case AppThemeMode.cyberpunk:
        return AppTheme.cyberpunkTheme;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier(ref);
});

final currentThemeDataProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);
  return AppTheme.buildTheme(
    mode: settings.themeMode,
    accentIndex: settings.accentColorIndex,
    cornerRadius: settings.cornerRadius,
  );
});
