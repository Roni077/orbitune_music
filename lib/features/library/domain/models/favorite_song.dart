import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Representation of a favorited song saved in user's library
class FavoriteSong {
  final Track track;
  final DateTime likedAt;
  final int playCount;

  FavoriteSong({
    required this.track,
    DateTime? likedAt,
    this.playCount = 0,
  }) : likedAt = likedAt ?? DateTime.now();

  String get id => track.id;

  FavoriteSong copyWith({
    Track? track,
    DateTime? likedAt,
    int? playCount,
  }) {
    return FavoriteSong(
      track: track ?? this.track,
      likedAt: likedAt ?? this.likedAt,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'track': track.toMap(),
      'likedAt': likedAt.toIso8601String(),
      'playCount': playCount,
    };
  }

  factory FavoriteSong.fromMap(Map<dynamic, dynamic> map) {
    return FavoriteSong(
      track: Track.fromMap(map['track'] as Map<dynamic, dynamic>),
      likedAt: map['likedAt'] != null
          ? DateTime.tryParse(map['likedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FavoriteSong.fromJson(String source) =>
      FavoriteSong.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteSong &&
          runtimeType == other.runtimeType &&
          track.id == other.track.id;

  @override
  int get hashCode => track.id.hashCode;
}
