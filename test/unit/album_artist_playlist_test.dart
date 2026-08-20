import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/domain/models/search_result.dart';

void main() {
  group('Album, Artist, Playlist Domain Models', () {
    test('AlbumModel serialization and properties', () {
      final track1 = Track(id: 't1', title: 'Song 1', artist: 'Artist');
      final track2 = Track(id: 't2', title: 'Song 2', artist: 'Artist');

      final album = AlbumModel(
        id: 'album_1',
        title: 'Dawn FM',
        artist: 'The Weeknd',
        releaseYear: '2022',
        totalTracks: 2,
        songs: [track1, track2],
        artworkUrl: 'https://example.com/cover.jpg',
        source: 'youtube',
      );

      final map = album.toMap();
      expect(map['id'], 'album_1');
      expect(map['totalTracks'], 2);
      expect((map['songs'] as List).length, 2);

      final restored = AlbumModel.fromMap(map);
      expect(restored.id, album.id);
      expect(restored.title, album.title);
      expect(restored.songs.length, 2);
      expect(restored.songs.first.id, 't1');
    });

    test('ArtistModel serialization and discography', () {
      final track = Track(id: 't1', title: 'Hits', artist: 'Arijit Singh');
      final album = AlbumModel(
        id: 'a1',
        title: 'Best of Arijit',
        artist: 'Arijit Singh',
      );

      final artist = ArtistModel(
        id: 'artist_1',
        name: 'Arijit Singh',
        bio: 'Bollywood Playback Singer',
        monthlyListeners: 42000000,
        topTracks: [track],
        albums: [album],
        genres: ['Bollywood', 'Romantic', 'Pop'],
        source: 'youtube',
      );

      final map = artist.toMap();
      final restored = ArtistModel.fromMap(map);
      expect(restored.name, 'Arijit Singh');
      expect(restored.monthlyListeners, 42000000);
      expect(restored.topTracks.length, 1);
      expect(restored.albums.length, 1);
      expect(restored.genres, contains('Bollywood'));
    });

    test('PlaylistModel and SearchResult container', () {
      final track = Track(id: 't_pop', title: 'Dance Monkey', artist: 'Tones and I');
      final playlist = PlaylistModel(
        id: 'pl_1',
        title: 'Global Top 50',
        trackCount: 1,
        songs: [track],
        isFeatured: true,
      );

      final searchResult = SearchResult(
        query: 'Pop',
        source: 'all',
        songs: [track],
        playlists: [playlist],
      );

      expect(searchResult.isNotEmpty, true);
      expect(searchResult.songs.length, 1);
      expect(searchResult.playlists.first.title, 'Global Top 50');

      final map = searchResult.toMap();
      final fromMap = SearchResult.fromMap(map);
      expect(fromMap.query, 'Pop');
      expect(fromMap.songs.first.title, 'Dance Monkey');
    });
  });
}
