import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'album_model.dart';

/// Universal Artist entity
class ArtistModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bio;
  final int monthlyListeners;
  final int fansCount;
  final List<Track> topTracks;
  final List<AlbumModel> albums;
  final List<Track> singles;
  final List<String> genres;
  final String source;
  final bool isFollowed;

  ArtistModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bannerUrl,
    this.bio,
    this.monthlyListeners = 0,
    this.fansCount = 0,
    this.topTracks = const [],
    this.albums = const [],
    this.singles = const [],
    this.genres = const [],
    this.source = 'youtube',
    this.isFollowed = false,
  });

  ArtistModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    int? monthlyListeners,
    int? fansCount,
    List<Track>? topTracks,
    List<AlbumModel>? albums,
    List<Track>? singles,
    List<String>? genres,
    String? source,
    bool? isFollowed,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      fansCount: fansCount ?? this.fansCount,
      topTracks: topTracks ?? this.topTracks,
      albums: albums ?? this.albums,
      singles: singles ?? this.singles,
      genres: genres ?? this.genres,
      source: source ?? this.source,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'bio': bio,
      'monthlyListeners': monthlyListeners,
      'fansCount': fansCount,
      'topTracks': topTracks.map((t) => t.toMap()).toList(),
      'albums': albums.map((a) => a.toMap()).toList(),
      'singles': singles.map((s) => s.toMap()).toList(),
      'genres': genres,
      'source': source,
      'isFollowed': isFollowed,
    };
  }

  factory ArtistModel.fromMap(Map<dynamic, dynamic> map) {
    return ArtistModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Artist',
      avatarUrl: map['avatarUrl']?.toString(),
      bannerUrl: map['bannerUrl']?.toString(),
      bio: map['bio']?.toString(),
      monthlyListeners: (map['monthlyListeners'] as num?)?.toInt() ?? 0,
      fansCount: (map['fansCount'] as num?)?.toInt() ?? 0,
      topTracks: map['topTracks'] != null
          ? (map['topTracks'] as List)
              .map((item) => Track.fromMap(item as Map<dynamic, dynamic>))
              .toList()
          : const [],
      albums: map['albums'] != null
          ? (map['albums'] as List)
              .map((item) => AlbumModel.fromMap(item as Map<dynamic, dynamic>))
              .toList()
          : const [],
      singles: map['singles'] != null
          ? (map['singles'] as List)
              .map((item) => Track.fromMap(item as Map<dynamic, dynamic>))
              .toList()
          : const [],
      genres: map['genres'] != null
          ? List<String>.from(map['genres'] as List)
          : const [],
      source: map['source']?.toString() ?? 'youtube',
      isFollowed: map['isFollowed'] == true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ArtistModel.fromJson(String source) =>
      ArtistModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
