import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/lyrics/data/lyrics_cache_repository.dart';
import 'package:orbitune/features/lyrics/data/lyrics_repository.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';
import 'package:orbitune/features/lyrics/presentation/providers/lyrics_provider.dart';
import '../helpers/mock_audio_platform.dart';

class MockLyricsRepository extends LyricsRepository {
  final List<LyricLine> sampleSyncedLines;
  final String? samplePlainLyrics;

  MockLyricsRepository({
    required super.cacheRepository,
    required this.sampleSyncedLines,
    this.samplePlainLyrics,
  });

  @override
  Future<List<LyricLine>> getSyncedLyrics(Track track) async {
    return sampleSyncedLines;
  }

  @override
  Future<String?> getPlainLyrics(Track track) async {
    return samplePlainLyrics;
  }
}

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late LyricsCacheRepository cacheRepo;

  final sampleTrack = Track(
    id: 'test_track_1',
    title: 'Starboy',
    artist: 'The Weeknd',
    duration: const Duration(seconds: 230),
    artworkUrl: 'https://example.com/artwork.jpg',
  );

  final sampleLyrics = [
    LyricLine(timestamp: const Duration(seconds: 0), text: "I'm tryna put you in the worst mood"),
    LyricLine(timestamp: const Duration(seconds: 5), text: 'P1 cleaner than your church shoes'),
    LyricLine(timestamp: const Duration(seconds: 10), text: 'Milli point two just to hurt you'),
    LyricLine(timestamp: const Duration(seconds: 15), text: "Look what you've done, I'm a starboy"),
  ];

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_lyrics_test_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
    cacheRepo = LyricsCacheRepository(hiveService);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LyricsNotifier & LyricsState Unit Tests', () {
    test('LyricsState hasLyrics returns true when lines or plainLyrics present', () {
      const stateEmpty = LyricsState();
      expect(stateEmpty.hasLyrics, isFalse);

      final stateWithLines = LyricsState(lines: sampleLyrics, isSynced: true);
      expect(stateWithLines.hasLyrics, isTrue);

      const stateWithPlain = LyricsState(plainLyrics: 'Some song lyrics...');
      expect(stateWithPlain.hasLyrics, isTrue);
    });

    test('LyricsNotifier loads synced lyrics and initializes state', () async {
      final mockRepo = MockLyricsRepository(
        cacheRepository: cacheRepo,
        sampleSyncedLines: sampleLyrics,
      );

      final container = ProviderContainer(
        overrides: [
          lyricsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(lyricsProvider.notifier);
      await notifier.loadLyricsForTrack(sampleTrack);

      final state = container.read(lyricsProvider);
      expect(state.isLoading, isFalse);
      expect(state.trackId, equals('test_track_1'));
      expect(state.lines.length, equals(4));
      expect(state.isSynced, isTrue);
      expect(state.lines.first.text, equals("I'm tryna put you in the worst mood"));
    });

    test('LyricsNotifier updates font size and auto scroll controls', () {
      final mockRepo = MockLyricsRepository(
        cacheRepository: cacheRepo,
        sampleSyncedLines: sampleLyrics,
      );

      final container = ProviderContainer(
        overrides: [
          lyricsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(lyricsProvider.notifier);

      notifier.setFontSize(26.0);
      expect(container.read(lyricsProvider).fontSize, equals(26.0));

      notifier.setFontSize(40.0); // Clamped to 32.0 max
      expect(container.read(lyricsProvider).fontSize, equals(32.0));

      notifier.pauseAutoScroll();
      expect(container.read(lyricsProvider).isAutoScrollEnabled, isFalse);

      notifier.resumeAutoScroll();
      expect(container.read(lyricsProvider).isAutoScrollEnabled, isTrue);

      notifier.toggleAutoScroll();
      expect(container.read(lyricsProvider).isAutoScrollEnabled, isFalse);
    });
  });
}
