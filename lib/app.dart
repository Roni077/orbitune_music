import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/theme/theme_provider.dart';
import 'package:orbitune/shell/main_navigation_shell.dart';

/// Root application widget configuring themes and main navigation shell
class OrbituneApp extends ConsumerWidget {
  const OrbituneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);

    return MaterialApp(
      title: 'Orbitune',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.currentThemeData,
      home: const MainNavigationShell(),
    );
  }
}
