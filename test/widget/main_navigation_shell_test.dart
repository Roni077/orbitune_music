import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/core/widgets/custom_bottom_nav.dart';
import 'package:orbitune/features/discovery/presentation/screens/home_screen.dart';
import 'package:orbitune/shell/main_navigation_shell.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_nav_shell_test_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    HiveService.instance.resetForTesting();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('MainNavigationShell handles navigation between all tabs seamlessly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationShell(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify CustomBottomNav exists
    final bottomNav = find.byType(CustomBottomNav);
    expect(bottomNav, findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    // Tap on Search tab icon
    await tester.tap(find.descendant(of: bottomNav, matching: find.byIcon(LucideIcons.search)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Trending Searches'), findsOneWidget);

    // Tap on Library tab icon
    await tester.tap(find.descendant(of: bottomNav, matching: find.byIcon(LucideIcons.library)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your Library'), findsOneWidget);

    // Tap on Settings tab icon
    await tester.tap(find.descendant(of: bottomNav, matching: find.byIcon(LucideIcons.settings)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Streaming Quality'), findsOneWidget);

    // Tap back to Home tab icon
    await tester.tap(find.descendant(of: bottomNav, matching: find.byIcon(LucideIcons.house)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
