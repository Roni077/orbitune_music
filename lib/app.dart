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
      builder: (context, child) {
        // Enforce accessible text scaling bounds (0.85x - 1.25x)
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: ScrollConfiguration(
            behavior: const _OrbituneScrollBehavior(),
            child: AnimatedTheme(
              data: themeData,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: child!,
            ),
          ),
        );
      },
      home: hasCompletedOnboarding 
          ? const MainNavigationShell() 
          : const OnboardingScreen(),
    );
  }
}

class _OrbituneScrollBehavior extends ScrollBehavior {
  const _OrbituneScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
