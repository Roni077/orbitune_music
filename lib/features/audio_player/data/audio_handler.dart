import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Helper and orchestrator for JustAudioBackground service and MediaItem synchronization
class OrbituneAudioHandler {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initialize JustAudioBackground notification service
  static Future<void> initBackgroundService() async {
    if (_isInitialized) return;
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.orbitune.music.channel.audio',
        androidNotificationChannelName: 'Orbitune Music Playback',
        androidNotificationChannelDescription: 'Active background audio stream & media controls',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
        notificationColor: const Color(0xFF14142B),
      );
      _isInitialized = true;
      debugPrint('[OrbituneAudioHandler] JustAudioBackground initialized successfully.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[OrbituneAudioHandler] JustAudioBackground init warning (might be test or desktop environment): $e');
    }
  }

  /// Default HTTP streaming headers for audio CDNs (clean, non-hop-by-hop)
  static const Map<String, String> defaultStreamHeaders = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
    'Accept': '*/*',
  };

  /// Converts a [Track] and its stream/file URI into a tagged [AudioSource] with complete [MediaItem]
  static AudioSource createAudioSource(
    Track track,
    String streamOrFilePath, {
    Map<String, String>? headers,
  }) {
    final cleanPath = streamOrFilePath.trim();
    final uri = Uri.tryParse(cleanPath) ?? Uri.file(cleanPath);
    final mediaItem = track.toMediaItem();

    // If stream is a local file path
    final isLocal = uri.scheme == 'file' ||
        !cleanPath.startsWith('http://') && !cleanPath.startsWith('https://');

    if (isLocal) {
      final filePath = cleanPath.startsWith('file://')
          ? cleanPath.replaceFirst('file://', '')
          : cleanPath;
      return AudioSource.file(
        filePath,
        tag: mediaItem,
      );
    }

    // For YouTube and googlevideo CDN streams, attach clean standard streaming headers
    if (cleanPath.contains('googlevideo.com') || cleanPath.contains('youtube.com')) {
      final Map<String, String> ytHeaders = Map.from(headers ?? {});
      if (!ytHeaders.containsKey('User-Agent') && !ytHeaders.containsKey('user-agent')) {
        ytHeaders['User-Agent'] =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1';
      }
      if (!ytHeaders.containsKey('Accept') && !ytHeaders.containsKey('accept')) {
        ytHeaders['Accept'] = '*/*';
      }
      return AudioSource.uri(
        uri,
        tag: mediaItem,
        headers: ytHeaders,
      );
    }

    // Network audio source with clean streaming headers
    final effectiveHeaders = headers ?? defaultStreamHeaders;

    return AudioSource.uri(
      uri,
      tag: mediaItem,
      headers: effectiveHeaders,
    );
  }

  /// Creates a [ConcatenatingAudioSource] from a list of tracks with their resolved URLs
  static ConcatenatingAudioSource createConcatenatingSource(
    List<MapEntry<Track, String>> tracksWithUrls, {
    bool useLazy = true,
  }) {
    final sources = tracksWithUrls.map((entry) {
      return createAudioSource(entry.key, entry.value);
    }).toList();

    return ConcatenatingAudioSource(
      useLazyPreparation: useLazy,
      children: sources,
    );
  }
}
