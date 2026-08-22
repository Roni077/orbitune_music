import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/app.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/core/widgets/custom_bottom_nav.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
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

  testWidgets('Orbitune app bootstrap smoke test shows onboarding or main shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider))..state = const AppSettings(hasCompletedOnboarding: true)),
        ],
        child: const OrbituneApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Main navigation shell and bottom nav render
    expect(find.byType(CustomBottomNav), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
