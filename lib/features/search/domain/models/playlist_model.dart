import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Universal Public / Curated Playlist entity
class PlaylistModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? highResArtworkUrl;
  final int trackCount;
  final String? author;
  final List<Track> songs;
  final String source;
  final bool isFeatured;
  final String? language;

  PlaylistModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.highResArtworkUrl,
    this.trackCount = 0,
    this.author,
    this.songs = const [],
    this.source = 'jiosaavn',
    this.isFeatured = false,
    this.language,
  });

  String? get bestArtworkUrl => highResArtworkUrl ?? artworkUrl;

  PlaylistModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? artworkUrl,
    String? highResArtworkUrl,
    int? trackCount,
    String? author,
    List<Track>? songs,
    String? source,
    bool? isFeatured,
    String? language,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      highResArtworkUrl: highResArtworkUrl ?? this.highResArtworkUrl,
      trackCount: trackCount ?? this.trackCount,
      author: author ?? this.author,
      songs: songs ?? this.songs,
      source: source ?? this.source,
      isFeatured: isFeatured ?? this.isFeatured,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'artworkUrl': artworkUrl,
      'highResArtworkUrl': highResArtworkUrl,
      'trackCount': trackCount,
      'author': author,
      'songs': songs.map((s) => s.toMap()).toList(),
      'source': source,
      'isFeatured': isFeatured,
      'language': language,
    };
  }

  factory PlaylistModel.fromMap(Map<dynamic, dynamic> map) {
    return PlaylistModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Playlist',
      subtitle: map['subtitle']?.toString(),
      description: map['description']?.toString(),
      artworkUrl: map['artworkUrl']?.toString(),
      highResArtworkUrl: map['highResArtworkUrl']?.toString(),
      trackCount: (map['trackCount'] as num?)?.toInt() ?? 0,
      author: map['author']?.toString(),
      songs: map['songs'] != null
          ? (map['songs'] as List)
              .map((item) => Track.fromMap(item as Map<dynamic, dynamic>))
              .toList()
          : const [],
      source: map['source']?.toString() ?? 'jiosaavn',
      isFeatured: map['isFeatured'] == true,
      language: map['language']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PlaylistModel.fromJson(String source) =>
      PlaylistModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
