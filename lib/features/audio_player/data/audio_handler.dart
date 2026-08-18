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
      debugPrint('[OrbituneAudioHandler] JustAudioBackground init warning (might be test or desktop environment): $e');
      _isInitialized = true;
    }
  }

  /// Converts a [Track] and its stream/file URI into a tagged [AudioSource] with complete [MediaItem]
  static AudioSource createAudioSource(
    Track track,
    String streamOrFilePath, {
    Map<String, String>? headers,
  }) {
    final uri = Uri.parse(streamOrFilePath);
    final mediaItem = track.toMediaItem();

    // If stream is a local file URI (e.g. file:/// or start with /)
    if (uri.scheme == 'file' || !streamOrFilePath.startsWith('http')) {
      return AudioSource.file(
        streamOrFilePath.replaceFirst('file://', ''),
        tag: mediaItem,
      );
    }

    // Default network audio source with custom headers for JioSaavn / YouTube
    return AudioSource.uri(
      uri,
      tag: mediaItem,
      headers: headers,
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
