import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/audio_player/presentation/screens/queue_sheet.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  final testTracks = [
    Track(
      id: 'ws_track_1',
      title: 'Cosmic Beats',
      artist: 'Stellar DJ',
      duration: const Duration(seconds: 215),
      localFilePath: 'C:/mock/music/1.mp3',
    ),
    Track(
      id: 'ws_track_2',
      title: 'Neon Skyline',
      artist: 'Synthwave Prodigy',
      duration: const Duration(seconds: 190),
      localFilePath: 'C:/mock/music/2.mp3',
    ),
    Track(
      id: 'ws_track_3',
      title: 'Orbitune Voyage',
      artist: 'Audio Architect',
      duration: const Duration(seconds: 240),
      localFilePath: 'C:/mock/music/3.mp3',
    ),
  ];

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_queue_widget_test_');

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

  testWidgets('QueueSheet renders empty state when queue is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QueueSheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Playing Queue'), findsOneWidget);
    expect(find.text('Queue is empty'), findsOneWidget);
    expect(find.text('Your Queue is Empty'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('QueueSheet renders Now Playing and Up Next list correctly', (WidgetTester tester) async {
    final container = ProviderContainer();

    await tester.runAsync(() async {
      await container.read(queueProvider.notifier).playPlaylist(
        testTracks,
        initialIndex: 0,
        queueTitle: 'Cosmic Mix',
      );
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: QueueSheet(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Header checks
    expect(find.text('Playing Queue'), findsOneWidget);
    expect(find.text('2 upcoming • 07:10 left'), findsOneWidget);

    // Now Playing card
    expect(find.text('PLAYING'), findsOneWidget);
    expect(find.text('Cosmic Beats'), findsOneWidget);
    expect(find.text('Stellar DJ'), findsOneWidget);

    expect(find.text('Neon Skyline'), findsOneWidget);
    expect(find.text('Orbitune Voyage'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() async {
      container.dispose();
    });
  });
}
