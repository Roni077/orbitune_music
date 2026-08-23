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
    final hasCompletedOnboarding = ref.watch(
      settingsProvider.select((s) => s.hasCompletedOnboarding),
    );

    return MaterialApp(
      title: 'Orbitune',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: hasCompletedOnboarding 
          ? const MainNavigationShell() 
          : const OnboardingScreen(),
    );
  }
}
