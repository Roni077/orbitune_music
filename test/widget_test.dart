import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/app.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/core/widgets/custom_bottom_nav.dart';
import 'helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_app_smoke_test_');
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

  testWidgets('Orbitune app bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OrbituneApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Orbitune brand title and bottom navigation render
    expect(find.text('Orbitune'), findsOneWidget);
    expect(find.byType(CustomBottomNav), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
