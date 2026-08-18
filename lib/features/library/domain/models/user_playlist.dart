import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// User-created custom playlist stored locally in Hive
class UserPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? artworkUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Track> songs;
  final bool isPinned;

  UserPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.songs = const [],
    this.isPinned = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get songCount => songs.length;

  Duration get totalDuration => songs.fold(
        Duration.zero,
        (prev, track) => prev + track.duration,
      );

  String? get coverArtworkUrl =>
      artworkUrl ?? (songs.isNotEmpty ? songs.first.bestArtworkUrl : null);

  UserPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Track>? songs,
    bool? isPinned,
  }) {
    return UserPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      songs: songs ?? this.songs,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'artworkUrl': artworkUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'songs': songs.map((s) => s.toMap()).toList(),
      'isPinned': isPinned,
    };
  }

  factory UserPlaylist.fromMap(Map<dynamic, dynamic> map) {
    return UserPlaylist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'My Playlist',
      description: map['description']?.toString(),
      artworkUrl: map['artworkUrl']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      songs: map['songs'] != null
          ? (map['songs'] as List)
              .map((item) => Track.fromMap(item as Map<dynamic, dynamic>))
              .toList()
          : const [],
      isPinned: map['isPinned'] == true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserPlaylist.fromJson(String source) =>
      UserPlaylist.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPlaylist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
