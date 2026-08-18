import 'dart:convert';
import 'track.dart';

/// Item in the active playback queue
class QueueItem {
  final String queueId;
  final Track track;
  final bool isAutoplay;
  final DateTime addedAt;
  final String? sourceContext;

  QueueItem({
    required this.queueId,
    required this.track,
    this.isAutoplay = false,
    DateTime? addedAt,
    this.sourceContext,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Creates a QueueItem from a Track with auto-generated unique queueId
  factory QueueItem.fromTrack(
    Track track, {
    bool isAutoplay = false,
    String? sourceContext,
    String? queueId,
  }) {
    return QueueItem(
      queueId: queueId ??
          '${track.id}_${DateTime.now().microsecondsSinceEpoch}_${track.title.hashCode}',
      track: track,
      isAutoplay: isAutoplay,
      sourceContext: sourceContext,
    );
  }

  QueueItem copyWith({
    String? queueId,
    Track? track,
    bool? isAutoplay,
    DateTime? addedAt,
    String? sourceContext,
  }) {
    return QueueItem(
      queueId: queueId ?? this.queueId,
      track: track ?? this.track,
      isAutoplay: isAutoplay ?? this.isAutoplay,
      addedAt: addedAt ?? this.addedAt,
      sourceContext: sourceContext ?? this.sourceContext,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queueId': queueId,
      'track': track.toMap(),
      'isAutoplay': isAutoplay,
      'addedAt': addedAt.toIso8601String(),
      'sourceContext': sourceContext,
    };
  }

  factory QueueItem.fromMap(Map<dynamic, dynamic> map) {
    return QueueItem(
      queueId: map['queueId']?.toString() ?? '',
      track: Track.fromMap(map['track'] as Map<dynamic, dynamic>),
      isAutoplay: map['isAutoplay'] == true,
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sourceContext: map['sourceContext']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QueueItem.fromJson(String source) =>
      QueueItem.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueItem &&
          runtimeType == other.runtimeType &&
          queueId == other.queueId;

  @override
  int get hashCode => queueId.hashCode;
}
