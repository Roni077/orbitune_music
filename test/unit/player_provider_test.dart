import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late ProviderContainer container;

  setUpAll(() async {
    registerMockJustAudioPlatform();

    tempDir = await Directory.systemTemp.createTemp('orbitune_player_provider_test_');

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

  group('PlayerNotifier & Riverpod State Tests', () {
    test('Initial player state is idle', () {
      final state = container.read(playerProvider);
      expect(state.status, PlaybackStatus.idle);
      expect(state.currentTrack, isNull);
      expect(state.isPlaying, false);
      expect(state.position, Duration.zero);
      expect(state.volume, 1.0);
    });

    test('Playback mode state provider cycles correctly', () async {
      final notifier = container.read(playerProvider.notifier);

      expect(container.read(playbackModeProvider), PlaybackMode.off);

      await notifier.cyclePlaybackMode();
      expect(container.read(playbackModeProvider), PlaybackMode.repeatAll);

      await notifier.cyclePlaybackMode();
      expect(container.read(playbackModeProvider), PlaybackMode.repeatOne);

      await notifier.cyclePlaybackMode();
      expect(container.read(playbackModeProvider), PlaybackMode.off);
    });

    test('Volume and speed updates via PlayerNotifier', () async {
      final notifier = container.read(playerProvider.notifier);

      await notifier.setVolume(0.7);
      await notifier.setSpeed(1.5);

      final state = container.read(playerProvider);
      expect(state.volume, 0.7);
      expect(state.speed, 1.5);
    });

    test('Favorite toggling integrates with favoritesProvider', () async {
      final notifier = container.read(playerProvider.notifier);
      final testTrack = Track(
        id: 'fav_prov_track_1',
        title: 'Provider Song',
        artist: 'Orbitune',
      );

      // Play local / offline track to load snapshot
      await notifier.playTrack(testTrack.copyWith(
        localFilePath: 'C:/music/song.mp3',
      ));

      // Toggle favorite
      await notifier.toggleFavorite();
      final favorites = container.read(favoritesProvider);
      expect(favorites.any((f) => f.track.id == 'fav_prov_track_1'), true);
    });
  });
}
