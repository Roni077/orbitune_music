import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/mini_player.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_mini_player_test_');
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

  testWidgets('MiniPlayer renders nothing when no track is playing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MiniPlayer(),
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Midnight Odyssey'), findsNothing);
  });

  testWidgets('MiniPlayer renders track info, controls and progress bar when track is loaded', (WidgetTester tester) async {
    final testTrack = Track(
      id: 'mini_test_1',
      title: 'Midnight Odyssey',
      artist: 'Arijit Singh',
      duration: const Duration(seconds: 180),
      artworkUrl: '',
    );

    final container = ProviderContainer();

    await tester.runAsync(() async {
      await container.read(playerProvider.notifier).playTrack(
            testTrack.copyWith(localFilePath: 'C:/music/test.mp3'),
          );
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MiniPlayer(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify track information rendered
    expect(find.text('Midnight Odyssey'), findsOneWidget);
    expect(find.text('Arijit Singh'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Verify icons present
    expect(find.byIcon(LucideIcons.skipForward), findsOneWidget);
    expect(find.byIcon(LucideIcons.heart), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() async {
      container.dispose();
    });
  });
}
