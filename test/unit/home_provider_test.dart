import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/discovery/presentation/providers/home_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late ProviderContainer container;

  setUpAll(() async {
    registerMockJustAudioPlatform();

    tempDir = await Directory.systemTemp.createTemp('orbitune_home_provider_test_');

    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);

    container = ProviderContainer();
  });

  tearDownAll(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HomeProvider & HomeNotifier Tests', () {
    test('HomeState default initialization and copyWith', () {
      const state = HomeState();
      expect(state.isLoading, isTrue);
      expect(state.isRefreshing, isFalse);
      expect(state.selectedFilter, 'All');
      expect(state.banners, isEmpty);
      expect(state.sections, isEmpty);

      final updated = state.copyWith(
        isLoading: false,
        selectedFilter: 'Punjabi',
      );
      expect(updated.isLoading, isFalse);
      expect(updated.selectedFilter, 'Punjabi');
    });

    test('HomeNotifier loads feed data and populates banners & sections', () async {
      final notifier = container.read(homeProvider.notifier);
      await notifier.loadHomeFeed();

      final state = container.read(homeProvider);
      expect(state.isLoading, isFalse);
      expect(state.banners.isNotEmpty, isTrue);
      expect(state.sections.isNotEmpty, isTrue);
      expect(state.charts.isNotEmpty, isTrue);
      expect(state.popularArtists.isNotEmpty, isTrue);
      expect(state.dailyMixes.isNotEmpty, isTrue);
    });

    test('HomeNotifier computes quick picks from history or favorites', () async {
      final sampleTrack = Track(
        id: 'hist_song_1',
        title: 'History Song',
        artist: 'Sample Artist',
      );

      // Add to history
      await container.read(historyProvider.notifier).recordPlay(sampleTrack);

      final notifier = container.read(homeProvider.notifier);
      await notifier.loadHomeFeed();

      final state = container.read(homeProvider);
      expect(state.quickPicks.any((t) => t.id == 'hist_song_1'), isTrue);
    });

    test('HomeNotifier setFilter updates selected filter', () async {
      final notifier = container.read(homeProvider.notifier);
      await notifier.setFilter('Hindi');

      final state = container.read(homeProvider);
      expect(state.selectedFilter, 'Hindi');
      expect(state.banners.isNotEmpty, isTrue);
    });

    test('HomeNotifier refresh updates feed without reset', () async {
      final notifier = container.read(homeProvider.notifier);
      await notifier.refresh();

      final state = container.read(homeProvider);
      expect(state.isRefreshing, isFalse);
      expect(state.banners.isNotEmpty, isTrue);
    });
  });
}
