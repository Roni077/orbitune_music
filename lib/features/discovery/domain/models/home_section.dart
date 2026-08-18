import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/discovery/domain/models/chart_playlist.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';

/// Dynamic discovery home section container
class HomeSection {
  final String id;
  final String title;
  final String? subtitle;
  final String sectionType; // 'tracks', 'albums', 'artists', 'playlists', 'charts', 'grid'
  final List<Track> tracks;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<PlaylistModel> playlists;
  final List<ChartPlaylist> charts;

  HomeSection({
    required this.id,
    required this.title,
    this.subtitle,
    required this.sectionType,
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.charts = const [],
  });

  bool get isEmpty =>
      tracks.isEmpty &&
      albums.isEmpty &&
      artists.isEmpty &&
      playlists.isEmpty &&
      charts.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
