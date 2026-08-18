import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/download_repository.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/stats_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late LibraryRepository libraryRepo;
  late SettingsRepository settingsRepo;
  late DownloadRepository downloadRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('orbitune_providers_test_hive_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);

    libraryRepo = LibraryRepository(hiveService);
    settingsRepo = SettingsRepository(hiveService);
    downloadRepo = DownloadRepository(hiveService);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Library & Settings State Notifiers Unit Tests', () {
    final trackA = Track(
      id: 'song_a',
      title: 'Levitating',
      artist: 'Dua Lipa',
      album: 'Future Nostalgia',
      genre: 'Pop',
      duration: const Duration(minutes: 3, seconds: 23),
    );

    final trackB = Track(
      id: 'song_b',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      genre: 'Synthwave',
      duration: const Duration(minutes: 3, seconds: 20),
    );

    test('FavoritesNotifier adds, checks, and toggles favorite state', () async {
      final notifier = FavoritesNotifier(libraryRepo);

      expect(notifier.state, isEmpty);
      expect(notifier.isFavorite(trackA.id), isFalse);

      await notifier.toggleFavorite(trackA);
      expect(notifier.isFavorite(trackA.id), isTrue);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.track.title, 'Levitating');

      // Toggle again to remove
      await notifier.toggleFavorite(trackA);
      expect(notifier.isFavorite(trackA.id), isFalse);
      expect(notifier.state, isEmpty);
    });

    test('UserPlaylistsNotifier creates, renames, reorders and deletes playlists', () async {
      final notifier = UserPlaylistsNotifier(libraryRepo);

      // Create playlist
      final playlist = await notifier.createPlaylist(
        'Workout Mix',
        description: 'High energy songs',
        initialTracks: [trackA, trackB],
      );

      expect(notifier.state.length, 1);
      expect(playlist.name, 'Workout Mix');
      expect(playlist.songs.length, 2);

      // Rename playlist
      await notifier.renamePlaylist(playlist.id, 'Gym Pump');
      expect(notifier.state.first.name, 'Gym Pump');

      // Reorder tracks
      await notifier.reorderTracks(playlist.id, 0, 2);
      final updatedPlaylist = notifier.state.first;
      expect(updatedPlaylist.songs.first.id, trackB.id);

      // Remove single track
      await notifier.removeTrackFromPlaylist(playlist.id, trackA.id);
      expect(notifier.state.first.songs.length, 1);

      // Toggle pin
      await notifier.togglePin(playlist.id);
      expect(notifier.state.first.isPinned, isTrue);

      // Delete playlist
      await notifier.deletePlaylist(playlist.id);
      expect(notifier.state, isEmpty);
    });

    test('HistoryNotifier records, removes and clears history', () async {
      final notifier = HistoryNotifier(libraryRepo);

      await notifier.recordPlay(trackA, durationPlayed: const Duration(seconds: 45));
      expect(notifier.state.length, 1);
      expect(notifier.state.first.track.title, 'Levitating');

      await notifier.removeHistoryItem(trackA.id);
      expect(notifier.state, isEmpty);

      await notifier.recordPlay(trackB);
      expect(notifier.state.length, 1);
      await notifier.clearHistory();
      expect(notifier.state, isEmpty);
    });

    test('StatsNotifier records session and refreshes state', () async {
      final notifier = StatsNotifier(libraryRepo);

      await notifier.recordSession(trackA, const Duration(minutes: 3));
      expect(notifier.state.totalPlays, greaterThanOrEqualTo(1));
      expect(notifier.state.artistPlayCounts['Dua Lipa'], greaterThanOrEqualTo(1));
    });

    test('DownloadListNotifier adds, updates, checks and removes downloads', () async {
      final notifier = DownloadListNotifier(downloadRepo);

      final task = DownloadTask(
        id: trackA.id,
        track: trackA,
        status: DownloadStatus.completed,
        progress: 1.0,
      );

      await notifier.addOrUpdateTask(task);
      expect(notifier.isDownloaded(trackA.id), isTrue);
      expect(notifier.state.length, 1);

      await notifier.removeTask(trackA.id);
      expect(notifier.isDownloaded(trackA.id), isFalse);
      expect(notifier.state, isEmpty);
    });

    test('SettingsNotifier updates all app preferences', () async {
      final notifier = SettingsNotifier(settingsRepo);

      await notifier.setThemeMode('oled');
      expect(notifier.state.themeMode, 'oled');

      await notifier.setStreamingQuality(AudioQuality.high320k);
      expect(notifier.state.streamingQuality, AudioQuality.high320k);

      await notifier.setCrossfadeDuration(8);
      expect(notifier.state.crossfadeDurationSeconds, 8);

      await notifier.setGaplessPlayback(true);
      expect(notifier.state.gaplessPlayback, isTrue);

      await notifier.setAutoPlay(false);
      expect(notifier.state.autoPlay, isFalse);

      await notifier.setWifiOnlyStreaming(true);
      expect(notifier.state.wifiOnlyStreaming, isTrue);

      await notifier.setWifiOnlyDownloads(true);
      expect(notifier.state.wifiOnlyDownloads, isTrue);
    });
  });
}
