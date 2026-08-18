import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

enum AppThemeMode {
  darkMidnight,
  pureOled,
  light,
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.darkMidnight);

  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == AppThemeMode.darkMidnight ? AppThemeMode.pureOled : AppThemeMode.darkMidnight;
  }

  bool get isDarkMode => state != AppThemeMode.light;
  bool get isOled => state == AppThemeMode.pureOled;

  ThemeData get currentThemeData {
    switch (state) {
      case AppThemeMode.darkMidnight:
        return AppTheme.darkTheme;
      case AppThemeMode.pureOled:
        return AppTheme.oledTheme;
      case AppThemeMode.light:
        return AppTheme.lightTheme;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
