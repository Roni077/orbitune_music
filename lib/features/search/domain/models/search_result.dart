import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'album_model.dart';
import 'artist_model.dart';
import 'playlist_model.dart';

/// Aggregated multi-source search response container
class SearchResult {
  final String query;
  final String source; // 'all', 'jiosaavn', 'youtube', 'extractor'
  final List<Track> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
  final List<PlaylistModel> playlists;
  final DateTime timestamp;

  SearchResult({
    required this.query,
    this.source = 'all',
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isEmpty =>
      songs.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;
  bool get isNotEmpty => !isEmpty;

  SearchResult copyWith({
    String? query,
    String? source,
    List<Track>? songs,
    List<AlbumModel>? albums,
    List<ArtistModel>? artists,
    List<PlaylistModel>? playlists,
    DateTime? timestamp,
  }) {
    return SearchResult(
      query: query ?? this.query,
      source: source ?? this.source,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'source': source,
      'songs': songs.map((s) => s.toMap()).toList(),
      'albums': albums.map((a) => a.toMap()).toList(),
      'artists': artists.map((a) => a.toMap()).toList(),
      'playlists': playlists.map((p) => p.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchResult.fromMap(Map<dynamic, dynamic> map) {
    return SearchResult(
      query: map['query']?.toString() ?? '',
      source: map['source']?.toString() ?? 'all',
      songs: map['songs'] != null
          ? (map['songs'] as List)
              .map((e) => Track.fromMap(e as Map<dynamic, dynamic>))
              .toList()
          : const [],
      albums: map['albums'] != null
          ? (map['albums'] as List)
              .map((e) => AlbumModel.fromMap(e as Map<dynamic, dynamic>))
              .toList()
          : const [],
      artists: map['artists'] != null
          ? (map['artists'] as List)
              .map((e) => ArtistModel.fromMap(e as Map<dynamic, dynamic>))
              .toList()
          : const [],
      playlists: map['playlists'] != null
          ? (map['playlists'] as List)
              .map((e) => PlaylistModel.fromMap(e as Map<dynamic, dynamic>))
              .toList()
          : const [],
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SearchResult.fromJson(String source) =>
      SearchResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
