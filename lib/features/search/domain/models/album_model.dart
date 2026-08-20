import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Universal Album entity
class AlbumModel {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final String? artworkUrl;
  final String? highResArtworkUrl;
  final String? releaseYear;
  final int totalTracks;
  final List<Track> songs;
  final String source;
  final String? description;
  final String? language;
  final bool isFavorite;
  final int playCount;

  AlbumModel({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    this.artworkUrl,
    this.highResArtworkUrl,
    this.releaseYear,
    this.totalTracks = 0,
    this.songs = const [],
    this.source = 'youtube',
    this.description,
    this.language,
    this.isFavorite = false,
    this.playCount = 0,
  });

  String? get bestArtworkUrl => highResArtworkUrl ?? artworkUrl;

  AlbumModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? artworkUrl,
    String? highResArtworkUrl,
    String? releaseYear,
    int? totalTracks,
    List<Track>? songs,
    String? source,
    String? description,
    String? language,
    bool? isFavorite,
    int? playCount,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      highResArtworkUrl: highResArtworkUrl ?? this.highResArtworkUrl,
      releaseYear: releaseYear ?? this.releaseYear,
      totalTracks: totalTracks ?? this.totalTracks,
      songs: songs ?? this.songs,
      source: source ?? this.source,
      description: description ?? this.description,
      language: language ?? this.language,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'artworkUrl': artworkUrl,
      'highResArtworkUrl': highResArtworkUrl,
      'releaseYear': releaseYear,
      'totalTracks': totalTracks,
      'songs': songs.map((s) => s.toMap()).toList(),
      'source': source,
      'description': description,
      'language': language,
      'isFavorite': isFavorite,
      'playCount': playCount,
    };
  }

  factory AlbumModel.fromMap(Map<dynamic, dynamic> map) {
    return AlbumModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Album',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      artistId: map['artistId']?.toString(),
      artworkUrl: map['artworkUrl']?.toString(),
      highResArtworkUrl: map['highResArtworkUrl']?.toString(),
      releaseYear: map['releaseYear']?.toString(),
      totalTracks: (map['totalTracks'] as num?)?.toInt() ?? 0,
      songs: map['songs'] != null
          ? (map['songs'] as List)
              .map((item) => Track.fromMap(item as Map<dynamic, dynamic>))
              .toList()
          : const [],
      source: map['source']?.toString() ?? 'youtube',
      description: map['description']?.toString(),
      language: map['language']?.toString(),
      isFavorite: map['isFavorite'] == true,
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AlbumModel.fromJson(String source) =>
      AlbumModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
