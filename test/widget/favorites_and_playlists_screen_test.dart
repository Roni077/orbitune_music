import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/library/presentation/screens/favorites_screen.dart';
import 'package:orbitune/features/library/presentation/screens/playlist_view_screen.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';
import '../helpers/mock_audio_platform.dart';

class _MockFavsNotifier extends StateNotifier<List<FavoriteSong>>
    implements FavoritesNotifier {
  _MockFavsNotifier(super.state);

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

class _MockPlsNotifier extends StateNotifier<List<UserPlaylist>>
    implements UserPlaylistsNotifier {
  _MockPlsNotifier(super.state);

  @override
  Future<UserPlaylist> createPlaylist(String name,
      {String? description, String? artworkUrl, List<Track> initialTracks = const []}) async {
    return UserPlaylist(id: '1', name: name);
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

void main() {
  setUpAll(() {
    registerMockJustAudioPlatform();
  });

  final track1 = Track(
    id: 'fav_1',
    title: 'Anti-Hero',
    artist: 'Taylor Swift',
    album: 'Midnights',
    duration: const Duration(minutes: 3, seconds: 20),
  );

  final track2 = Track(
    id: 'fav_2',
    title: 'Flowers',
    artist: 'Miley Cyrus',
    album: 'Endless Summer Vacation',
    duration: const Duration(minutes: 3, seconds: 20),
  );

  final testPlaylist = UserPlaylist(
    id: 'pl_100',
    name: 'Top Hits 2026',
    description: 'Fresh chart hits',
    songs: [track1, track2],
  );

  group('FavoritesScreen & PlaylistViewScreen Widget Tests', () {
    testWidgets('FavoritesScreen renders liked tracks, Play All, and filters by search',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => _MockFavsNotifier([
                  FavoriteSong(track: track1),
                  FavoriteSong(track: track2),
                ])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const FavoritesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Liked Songs'), findsWidgets);
      expect(find.text('Play All (2)'), findsOneWidget);
      expect(find.byType(TrackTile), findsNWidgets(2));

      // Enter search query in filter field
      await tester.enterText(find.byType(TextField), 'Anti');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Anti-Hero'), findsOneWidget);
      expect(find.text('Flowers'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('PlaylistViewScreen renders playlist details and song list',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => _MockFavsNotifier([])),
            userPlaylistsProvider.overrideWith((ref) => _MockPlsNotifier([testPlaylist])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PlaylistViewScreen(playlistId: 'pl_100'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Top Hits 2026'), findsOneWidget);
      expect(find.text('Fresh chart hits'), findsOneWidget);
      expect(find.text('Play All (2)'), findsOneWidget);
      expect(find.byType(TrackTile), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
