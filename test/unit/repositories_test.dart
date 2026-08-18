import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/download_repository.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/lyrics/data/lyrics_cache_repository.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late LibraryRepository libraryRepo;
  late SettingsRepository settingsRepo;
  late DownloadRepository downloadRepo;
  late LyricsCacheRepository lyricsRepo;
  late SearchCacheRepository searchRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('orbitune_test_hive_');

    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);

    libraryRepo = LibraryRepository(hiveService);
    settingsRepo = SettingsRepository(hiveService);
    downloadRepo = DownloadRepository(hiveService);
    lyricsRepo = LyricsCacheRepository(hiveService);
    searchRepo = SearchCacheRepository(hiveService);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Hive Repositories Integration Tests', () {
    test('LibraryRepository handles Favorites CRUD and toggle', () async {
      final track = Track(id: 'fav_song_1', title: 'Song 1', artist: 'Artist 1');

      expect(libraryRepo.isFavorite(track.id), false);

      await libraryRepo.addFavorite(track);
      expect(libraryRepo.isFavorite(track.id), true);
      expect(libraryRepo.getFavorites().length, 1);
      expect(libraryRepo.getFavorites().first.track.title, 'Song 1');

      // Toggle favorite (should remove)
      await libraryRepo.toggleFavorite(track);
      expect(libraryRepo.isFavorite(track.id), false);
      expect(libraryRepo.getFavorites().isEmpty, true);
    });

    test('LibraryRepository handles User Playlists operations', () async {
      final track1 = Track(id: 't_pl_1', title: 'Track 1', artist: 'Artist 1');
      final track2 = Track(id: 't_pl_2', title: 'Track 2', artist: 'Artist 2');

      final playlist = UserPlaylist(
        id: 'user_pl_test_1',
        name: 'Rock Classics',
        songs: [track1],
      );

      await libraryRepo.saveUserPlaylist(playlist);
      var fetched = libraryRepo.getPlaylistById('user_pl_test_1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Rock Classics');
      expect(fetched.songCount, 1);

      // Add track to playlist
      await libraryRepo.addTrackToPlaylist('user_pl_test_1', track2);
      fetched = libraryRepo.getPlaylistById('user_pl_test_1');
      expect(fetched!.songCount, 2);

      // Remove track from playlist
      await libraryRepo.removeTrackFromPlaylist('user_pl_test_1', 't_pl_1');
      fetched = libraryRepo.getPlaylistById('user_pl_test_1');
      expect(fetched!.songCount, 1);
      expect(fetched.songs.first.id, 't_pl_2');

      // Delete playlist
      await libraryRepo.deleteUserPlaylist('user_pl_test_1');
      expect(libraryRepo.getPlaylistById('user_pl_test_1'), isNull);
    });

    test('LibraryRepository handles History & Stats recording', () async {
      final track = Track(
        id: 'hist_song_1',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        genre: 'Rock',
      );

      await libraryRepo.addHistoryItem(
        track,
        durationPlayed: const Duration(minutes: 5, seconds: 55),
        completed: true,
      );

      final history = libraryRepo.getHistory();
      expect(history.length, 1);
      expect(history.first.track.title, 'Bohemian Rhapsody');

      final stats = libraryRepo.getListeningStats();
      expect(stats.totalPlays, greaterThanOrEqualTo(1));
      expect(stats.artistPlayCounts['Queen'], greaterThanOrEqualTo(1));

      await libraryRepo.clearHistory();
      expect(libraryRepo.getHistory().isEmpty, true);
    });

    test('SettingsRepository persists and updates preferences', () async {
      final initial = settingsRepo.getSettings();
      expect(initial.themeMode, 'dark');

      await settingsRepo.updateThemeMode('oled');
      await settingsRepo.updateStreamingQuality(AudioQuality.lossless);
      await settingsRepo.updateCrossfadeDuration(6);
      await settingsRepo.updateEqualizerPreset('Bass Boost');

      final updated = settingsRepo.getSettings();
      expect(updated.themeMode, 'oled');
      expect(updated.streamingQuality, AudioQuality.lossless);
      expect(updated.crossfadeDurationSeconds, 6);
      expect(updated.equalizerPreset, 'Bass Boost');
    });

    test('DownloadRepository saves and updates download tasks', () async {
      final track = Track(id: 'dl_repo_track_1', title: 'Offline Beat', artist: 'Producer');
      final task = DownloadTask(
        id: 'dl_repo_track_1',
        track: track,
        status: DownloadStatus.completed,
        progress: 1.0,
        localFilePath: '/storage/music/song.mp3',
      );

      await downloadRepo.saveDownload(task);
      expect(downloadRepo.isDownloaded('dl_repo_track_1'), true);

      final fetched = downloadRepo.getDownload('dl_repo_track_1');
      expect(fetched, isNotNull);
      expect(fetched!.localFilePath, '/storage/music/song.mp3');

      await downloadRepo.removeDownload('dl_repo_track_1');
      expect(downloadRepo.isDownloaded('dl_repo_track_1'), false);
    });

    test('Lyrics and Search Cache Repositories operate as expected', () async {
      // Lyrics Cache
      await lyricsRepo.cacheLyrics('lyric_t1', '[00:10.00] Hello World');
      expect(lyricsRepo.getCachedLyrics('lyric_t1'), '[00:10.00] Hello World');

      await lyricsRepo.clearLyricsCache();
      expect(lyricsRepo.getCachedLyrics('lyric_t1'), isNull);

      // Search Cache
      await searchRepo.addSearchQuery('Dua Lipa');
      await searchRepo.addSearchQuery('Coldplay');
      final searches = searchRepo.getRecentSearches();
      expect(searches.first, 'Coldplay');
      expect(searches.length, 2);

      await searchRepo.removeSearchQuery('Coldplay');
      expect(searchRepo.getRecentSearches().length, 1);

      await searchRepo.clearSearchHistory();
      expect(searchRepo.getRecentSearches().isEmpty, true);
    });
  });
}
