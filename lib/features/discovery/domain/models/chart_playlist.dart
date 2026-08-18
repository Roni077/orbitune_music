import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Represents a curated chart or featured mix playlist
class ChartPlaylist {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? highResArtworkUrl;
  final String? bannerUrl;
  final int trackCount;
  final String category; // 'Chart', 'Daily Mix', 'Mood', 'Genre', 'Featured'
  final List<Track> songs;
  final String? colorHex;
  final String source;

  const ChartPlaylist({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.highResArtworkUrl,
    this.bannerUrl,
    this.trackCount = 0,
    this.category = 'Chart',
    this.songs = const [],
    this.colorHex,
    this.source = 'jiosaavn',
  });

  ChartPlaylist copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? artworkUrl,
    String? highResArtworkUrl,
    String? bannerUrl,
    int? trackCount,
    String? category,
    List<Track>? songs,
    String? colorHex,
    String? source,
  }) {
    return ChartPlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      highResArtworkUrl: highResArtworkUrl ?? this.highResArtworkUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      trackCount: trackCount ?? this.trackCount,
      category: category ?? this.category,
      songs: songs ?? this.songs,
      colorHex: colorHex ?? this.colorHex,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'artworkUrl': artworkUrl,
        'highResArtworkUrl': highResArtworkUrl,
        'bannerUrl': bannerUrl,
        'trackCount': trackCount,
        'category': category,
        'songs': songs.map((s) => s.toMap()).toList(),
        'colorHex': colorHex,
        'source': source,
      };

  factory ChartPlaylist.fromMap(Map<dynamic, dynamic> map) => ChartPlaylist(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString(),
        description: map['description']?.toString(),
        artworkUrl: map['artworkUrl']?.toString(),
        highResArtworkUrl: map['highResArtworkUrl']?.toString(),
        bannerUrl: map['bannerUrl']?.toString(),
        trackCount: (map['trackCount'] as num?)?.toInt() ?? 0,
        category: map['category']?.toString() ?? 'Chart',
        songs: map['songs'] != null
            ? (map['songs'] as List)
                .map((s) => Track.fromMap(s as Map<dynamic, dynamic>))
                .toList()
            : const [],
        colorHex: map['colorHex']?.toString(),
        source: map['source']?.toString() ?? 'jiosaavn',
      );
}
