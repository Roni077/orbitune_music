import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/stats_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/library/presentation/screens/library_screen.dart';
import 'package:orbitune/features/library/presentation/widgets/create_playlist_dialog.dart';
import 'package:orbitune/features/library/presentation/widgets/library_card.dart';
import '../helpers/mock_audio_platform.dart';

class _MockFavoritesNotifier extends StateNotifier<List<FavoriteSong>>
    implements FavoritesNotifier {
  _MockFavoritesNotifier(super.state);

  @override
  bool isFavorite(String trackId) => state.any((f) => f.track.id == trackId);

  @override
  Future<void> toggleFavorite(Track track) async {
    if (isFavorite(track.id)) {
      state = state.where((f) => f.track.id != track.id).toList();
    } else {
      state = [FavoriteSong(track: track), ...state];
    }
  }

  @override
  Future<void> removeFavorite(String trackId) async {
    state = state.where((f) => f.track.id != trackId).toList();
  }

  @override
  void refresh() {}
}

class _MockPlaylistsNotifier extends StateNotifier<List<UserPlaylist>>
    implements UserPlaylistsNotifier {
  _MockPlaylistsNotifier(super.state);

  @override
  Future<UserPlaylist> createPlaylist(String name,
      {String? description, String? artworkUrl, List<Track> initialTracks = const []}) async {
    final pl = UserPlaylist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      songs: initialTracks,
    );
    state = [pl, ...state];
    return pl;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    state = state.where((p) => p.id != id).toList();
  }

  @override
  Future<void> renamePlaylist(String id, String newName) async {
    state = state.map((p) => p.id == id ? p.copyWith(name: newName) : p).toList();
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, Track track) async {}

  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {}

  @override
  Future<void> reorderTracks(String playlistId, int oldIndex, int newIndex) async {}

  @override
  Future<void> togglePin(String playlistId) async {
    state = state.map((p) => p.id == playlistId ? p.copyWith(isPinned: !p.isPinned) : p).toList();
  }

  @override
  void refresh() {}
}

class _MockHistoryNotifier extends StateNotifier<List<HistoryItem>>
    implements HistoryNotifier {
  _MockHistoryNotifier(super.state);

  @override
  Future<void> recordPlay(Track track,
      {Duration durationPlayed = Duration.zero, bool completed = false}) async {}

  @override
  Future<void> removeHistoryItem(String trackId) async {
    state = state.where((h) => h.track.id != trackId).toList();
  }

  @override
  Future<void> clearHistory() async {
    state = [];
  }

  @override
  void refresh() {}
}

class _MockStatsNotifier extends StateNotifier<ListeningStats>
    implements StatsNotifier {
  _MockStatsNotifier(super.state);

  @override
  Future<void> recordSession(Track track, Duration durationPlayed) async {}

  @override
  void refresh() {}
}

class _MockDownloadNotifier extends StateNotifier<List<DownloadTask>>
    implements DownloadListNotifier {
  _MockDownloadNotifier(super.state);

  @override
  Future<void> addOrUpdateTask(DownloadTask task) async {
    state = [task, ...state];
  }

  @override
  Future<void> removeTask(String trackId) async {
    state = state.where((d) => d.id != trackId).toList();
  }

  @override
  bool isDownloaded(String trackId) => state.any((d) => d.id == trackId && d.isCompleted);

  @override
  void refresh() {}
}

void main() {
  setUpAll(() {
    registerMockJustAudioPlatform();
  });

  final testTrack = Track(
    id: 'lib_track_1',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
  );

  final testPlaylist = UserPlaylist(
    id: 'pl_test_1',
    name: 'Late Night Chill',
    songs: [testTrack],
  );

  Widget createWidgetUnderTest({
    List<FavoriteSong> favorites = const [],
    List<UserPlaylist> playlists = const [],
    List<HistoryItem> history = const [],
    ListeningStats stats = const ListeningStats(totalPlays: 10),
    List<DownloadTask> downloads = const [],
  }) {
    return ProviderScope(
      overrides: [
        favoritesProvider.overrideWith((ref) => _MockFavoritesNotifier(favorites)),
        userPlaylistsProvider.overrideWith((ref) => _MockPlaylistsNotifier(playlists)),
        historyProvider.overrideWith((ref) => _MockHistoryNotifier(history)),
        statsProvider.overrideWith((ref) => _MockStatsNotifier(stats)),
        downloadListProvider.overrideWith((ref) => _MockDownloadNotifier(downloads)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const LibraryScreen(),
      ),
    );
  }

  group('LibraryScreen Widget Tests', () {
    testWidgets('LibraryScreen renders header, quick access shortcuts, and empty playlist state',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Your Library'), findsOneWidget);
      expect(find.byType(LibraryCard), findsNWidgets(4));
      expect(find.text('Liked Songs'), findsOneWidget);
      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.text('Listening History'), findsOneWidget);
      expect(find.text('Listening Insights & Stats'), findsOneWidget);
      expect(find.text('Create Your First Playlist'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('LibraryScreen renders user playlists list when populated',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(createWidgetUnderTest(
        playlists: [testPlaylist],
        favorites: [FavoriteSong(track: testTrack)],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Late Night Chill'), findsOneWidget);
      expect(find.text('1 songs saved'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Tapping New Playlist button opens CreatePlaylistDialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip('New Playlist'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CreatePlaylistDialog), findsOneWidget);
      expect(find.text('Playlist Name'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
