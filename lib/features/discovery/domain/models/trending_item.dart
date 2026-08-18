import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Hero trending item for discovery feed banner carousel
class TrendingItem {
  final String id;
  final String title;
  final String subtitle;
  final String? bannerUrl;
  final String? artworkUrl;
  final String type; // 'song', 'album', 'playlist', 'artist'
  final Track? track;
  final String? actionId;

  TrendingItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.bannerUrl,
    this.artworkUrl,
    this.type = 'song',
    this.track,
    this.actionId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'bannerUrl': bannerUrl,
        'artworkUrl': artworkUrl,
        'type': type,
        'track': track?.toMap(),
        'actionId': actionId,
      };

  factory TrendingItem.fromMap(Map<dynamic, dynamic> map) => TrendingItem(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        bannerUrl: map['bannerUrl']?.toString(),
        artworkUrl: map['artworkUrl']?.toString(),
        type: map['type']?.toString() ?? 'song',
        track: map['track'] != null ? Track.fromMap(map['track'] as Map<dynamic, dynamic>) : null,
        actionId: map['actionId']?.toString(),
      );
}
