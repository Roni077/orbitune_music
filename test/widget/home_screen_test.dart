import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/discovery/presentation/screens/home_screen.dart';
import 'package:orbitune/features/discovery/presentation/widgets/banner_carousel.dart';
import 'package:orbitune/features/discovery/presentation/widgets/greeting_header.dart';
import 'package:orbitune/features/discovery/presentation/widgets/trending_chips.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_home_screen_test_');
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

  testWidgets('HomeScreen renders greeting header, discovery chips and home feed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Pump to process frame without waiting for repeating shimmer animation
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Greeting Header
    expect(find.byType(GreetingHeader), findsOneWidget);
    expect(find.text('Orbitune'), findsOneWidget);

    // Verify Discovery Filter Chips
    expect(find.byType(TrendingChips), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Verify Hero Banner Carousel
    expect(find.byType(BannerCarousel), findsOneWidget);

    // Tap on a filter chip
    await tester.tap(find.text('Hindi'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
