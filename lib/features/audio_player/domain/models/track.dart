import 'dart:convert';
import 'package:just_audio_background/just_audio_background.dart';
import 'audio_quality.dart';

/// Universal audio track model across all streaming sources and local files
class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final String? artworkUrl;
  final String? highResArtworkUrl;
  final String? streamUrl;
  final String? downloadUrl;
  final String? localFilePath;
  final String source; // 'youtube', 'extractor', 'local'
  final int bitrate; // in kbps (e.g. 320, 160, 96)
  final AudioQuality audioQuality;
  final String? releaseDate;
  final String? genre;
  final String? language;
  final String? lyrics;
  final bool hasSyncedLyrics;
  final bool isExplicit;
  final bool isFavorite;
  final int playCount;
  final DateTime addedAt;
  final Map<String, dynamic> extra;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration = Duration.zero,
    this.artworkUrl,
    this.highResArtworkUrl,
    this.streamUrl,
    this.downloadUrl,
    this.localFilePath,
    this.source = 'youtube',
    this.bitrate = 160,
    this.audioQuality = AudioQuality.high320k,
    this.releaseDate,
    this.genre,
    this.language,
    this.lyrics,
    this.hasSyncedLyrics = false,
    this.isExplicit = false,
    this.isFavorite = false,
    this.playCount = 0,
    DateTime? addedAt,
    Map<String, dynamic>? extra,
  })  : addedAt = addedAt ?? DateTime.now(),
        extra = extra ?? const {};

  /// Returns the highest resolution available artwork URL
  String? get bestArtworkUrl => highResArtworkUrl ?? artworkUrl;

  /// Whether this track is downloaded and playable offline
  bool get isOfflineAvailable =>
      localFilePath != null && localFilePath!.trim().isNotEmpty;

  /// Whether this track is a local or downloaded file
  bool get isLocal => source == 'local' || isOfflineAvailable;

  /// Converts track to JustAudioBackground MediaItem for lockscreen/notification controls
  MediaItem toMediaItem() {
    Uri? resolvedArtUri;
    final art = bestArtworkUrl?.trim();
    if (art != null && art.isNotEmpty) {
      if (art.startsWith('http://') ||
          art.startsWith('https://') ||
          art.startsWith('content://') ||
          art.startsWith('file://')) {
        resolvedArtUri = Uri.tryParse(art);
      } else {
        resolvedArtUri = Uri.file(art);
      }
    }

    return MediaItem(
      id: id,
      title: title.trim().isNotEmpty ? title.trim() : 'Unknown Track',
      artist: artist.trim().isNotEmpty ? artist.trim() : 'Unknown Artist',
      album: (album != null && album!.trim().isNotEmpty) ? album!.trim() : 'Orbitune',
      duration: duration > Duration.zero ? duration : null,
      artUri: resolvedArtUri,
      extras: {
        'source': source,
        'bitrate': bitrate,
        'audioQuality': audioQuality.name,
        'isExplicit': isExplicit,
        'hasSyncedLyrics': hasSyncedLyrics,
        'isFavorite': isFavorite,
      },
    );
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkUrl,
    String? highResArtworkUrl,
    String? streamUrl,
    String? downloadUrl,
    String? localFilePath,
    String? source,
    int? bitrate,
    AudioQuality? audioQuality,
    String? releaseDate,
    String? genre,
    String? language,
    String? lyrics,
    bool? hasSyncedLyrics,
    bool? isExplicit,
    bool? isFavorite,
    int? playCount,
    DateTime? addedAt,
    Map<String, dynamic>? extra,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      highResArtworkUrl: highResArtworkUrl ?? this.highResArtworkUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      source: source ?? this.source,
      bitrate: bitrate ?? this.bitrate,
      audioQuality: audioQuality ?? this.audioQuality,
      releaseDate: releaseDate ?? this.releaseDate,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      lyrics: lyrics ?? this.lyrics,
      hasSyncedLyrics: hasSyncedLyrics ?? this.hasSyncedLyrics,
      isExplicit: isExplicit ?? this.isExplicit,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      addedAt: addedAt ?? this.addedAt,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'artworkUrl': artworkUrl,
      'highResArtworkUrl': highResArtworkUrl,
      'streamUrl': streamUrl,
      'downloadUrl': downloadUrl,
      'localFilePath': localFilePath,
      'source': source,
      'bitrate': bitrate,
      'audioQuality': audioQuality.name,
      'releaseDate': releaseDate,
      'genre': genre,
      'language': language,
      'lyrics': lyrics,
      'hasSyncedLyrics': hasSyncedLyrics,
      'isExplicit': isExplicit,
      'isFavorite': isFavorite,
      'playCount': playCount,
      'addedAt': addedAt.toIso8601String(),
      'extra': extra,
    };
  }

  factory Track.fromMap(Map<dynamic, dynamic> map) {
    return Track(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Track',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      album: map['album']?.toString(),
      duration: Duration(milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0),
      artworkUrl: map['artworkUrl']?.toString(),
      highResArtworkUrl: map['highResArtworkUrl']?.toString(),
      streamUrl: map['streamUrl']?.toString(),
      downloadUrl: map['downloadUrl']?.toString(),
      localFilePath: map['localFilePath']?.toString(),
      source: map['source']?.toString() ?? 'youtube',
      bitrate: (map['bitrate'] as num?)?.toInt() ?? 160,
      audioQuality: AudioQuality.fromString(map['audioQuality']?.toString()),
      releaseDate: map['releaseDate']?.toString(),
      genre: map['genre']?.toString(),
      language: map['language']?.toString(),
      lyrics: map['lyrics']?.toString(),
      hasSyncedLyrics: map['hasSyncedLyrics'] == true,
      isExplicit: map['isExplicit'] == true,
      isFavorite: map['isFavorite'] == true,
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      extra: map['extra'] != null
          ? Map<String, dynamic>.from(map['extra'] as Map)
          : const {},
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Track.fromJson(String source) =>
      Track.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Track(id: $id, title: $title, artist: $artist, duration: $duration, bitrate: ${bitrate}kbps)';
}
