import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/theme/theme_provider.dart';
import 'package:orbitune/shell/main_navigation_shell.dart';
import 'package:orbitune/features/onboarding/presentation/onboarding_screen.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// Root application widget configuring themes and main navigation shell
class OrbituneApp extends ConsumerWidget {
  const OrbituneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(currentThemeDataProvider);
    final appSettings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Orbitune',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: appSettings.hasCompletedOnboarding 
          ? const MainNavigationShell() 
          : const OnboardingScreen(),
    );
  }
}
