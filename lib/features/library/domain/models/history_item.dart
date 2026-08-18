import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Single listening history log item
class HistoryItem {
  final String id;
  final Track track;
  final DateTime playedAt;
  final Duration durationPlayed;
  final bool completed;
  final int playCount;

  HistoryItem({
    required this.id,
    required this.track,
    DateTime? playedAt,
    this.durationPlayed = Duration.zero,
    this.completed = false,
    this.playCount = 1,
  }) : playedAt = playedAt ?? DateTime.now();

  HistoryItem copyWith({
    String? id,
    Track? track,
    DateTime? playedAt,
    Duration? durationPlayed,
    bool? completed,
    int? playCount,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      track: track ?? this.track,
      playedAt: playedAt ?? this.playedAt,
      durationPlayed: durationPlayed ?? this.durationPlayed,
      completed: completed ?? this.completed,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'track': track.toMap(),
      'playedAt': playedAt.toIso8601String(),
      'durationPlayedMs': durationPlayed.inMilliseconds,
      'completed': completed,
      'playCount': playCount,
    };
  }

  factory HistoryItem.fromMap(Map<dynamic, dynamic> map) {
    return HistoryItem(
      id: map['id']?.toString() ?? '',
      track: Track.fromMap(map['track'] as Map<dynamic, dynamic>),
      playedAt: map['playedAt'] != null
          ? DateTime.tryParse(map['playedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationPlayed: Duration(
        milliseconds: (map['durationPlayedMs'] as num?)?.toInt() ?? 0,
      ),
      completed: map['completed'] == true,
      playCount: (map['playCount'] as num?)?.toInt() ?? 1,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HistoryItem.fromJson(String source) =>
      HistoryItem.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
