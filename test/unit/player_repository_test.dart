import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/data/player_repository.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_player_service.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_session_service.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late LibraryRepository libraryRepo;
  late SettingsRepository settingsRepo;
  late SearchCacheRepository searchCacheRepo;
  late SearchRepository searchRepo;
  late AudioPlayerService playerService;
  late AudioSessionService sessionService;
  late PlayerRepository playerRepository;

  setUpAll(() async {
    registerMockJustAudioPlatform();

    tempDir = await Directory.systemTemp.createTemp('orbitune_player_repo_test_');

    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);

    libraryRepo = LibraryRepository(hiveService);
    settingsRepo = SettingsRepository(hiveService);
    searchCacheRepo = SearchCacheRepository(hiveService);
    searchRepo = SearchRepository(
      youTubeSource: YouTubeSource(),
      extractorService: ExtractorService.instance,
      cacheRepository: searchCacheRepo,
    );
    playerService = AudioPlayerService();
    sessionService = AudioSessionService();

    playerRepository = PlayerRepository(
      playerService: playerService,
      sessionService: sessionService,
      searchRepository: searchRepo,
      libraryRepository: libraryRepo,
      settingsRepository: settingsRepo,
    );
  });

  tearDownAll(() async {
    playerRepository.dispose();
    await playerService.dispose();
    await sessionService.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PlayerRepository Integration Tests', () {
    test('PlayerRepository resolves offline track and attaches favorite status', () async {
      final track = Track(
        id: 'track_offline_1',
        title: 'Offline Hit',
        artist: 'Orbitune Artist',
        localFilePath: 'C:/music/track1.mp3',
        streamUrl: 'https://example.com/stream.mp4',
      );

      // Pre-add to favorites
      await libraryRepo.addFavorite(track);
      expect(libraryRepo.isFavorite(track.id), true);

      // Toggle favorite via player repository
      final isFavAfterToggle = await playerRepository.toggleFavorite(track);
      expect(isFavAfterToggle, false);
      expect(libraryRepo.isFavorite(track.id), false);

      final isFavAfterSecondToggle = await playerRepository.toggleFavorite(track);
      expect(isFavAfterSecondToggle, true);
    });

    test('PlayerRepository delegates playback mode and speed settings', () async {
      await playerRepository.setPlaybackMode(PlaybackMode.repeatAll);
      await playerRepository.setSpeed(1.25);
      await playerRepository.setVolume(0.85);

      expect(playerService.currentSnapshot.volume, 0.85);
      expect(playerService.currentSnapshot.speed, 1.25);
    });
  });
}
