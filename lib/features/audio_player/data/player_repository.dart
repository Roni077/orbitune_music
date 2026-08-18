import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_player_service.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_session_service.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';

/// Riverpod provider for PlayerRepository
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  final sessionService = ref.watch(audioSessionServiceProvider);
  final searchRepo = ref.watch(searchRepositoryProvider);
  final libraryRepo = ref.watch(libraryRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  final repository = PlayerRepository(
    playerService: playerService,
    sessionService: sessionService,
    searchRepository: searchRepo,
    libraryRepository: libraryRepo,
    settingsRepository: settingsRepo,
  );

  ref.onDispose(() => repository.dispose());
  return repository;
});

/// High-level repository orchestrating audio playback, stream resolution, audio focus & analytics
class PlayerRepository {
  final AudioPlayerService playerService;
  final AudioSessionService sessionService;
  final SearchRepository searchRepository;
  final LibraryRepository libraryRepository;
  final SettingsRepository settingsRepository;

  StreamSubscription<PlayerStateSnapshot>? _snapshotSub;
  Track? _lastTrackLogged;
  Duration _accumulatedPlayDuration = Duration.zero;
  bool _historyRecordedForCurrent = false;

  PlayerRepository({
    required this.playerService,
    required this.sessionService,
    required this.searchRepository,
    required this.libraryRepository,
    required this.settingsRepository,
  }) {
    _initAudioSession();
    _listenToPlaybackProgress();
  }

  void _initAudioSession() {
    sessionService.init(
      onPause: () => playerService.pause(),
      onResume: () => playerService.resume(),
      onDuckVolume: (duckLevel) => playerService.duckVolume(duckLevel),
    );
  }

  void _listenToPlaybackProgress() {
    _snapshotSub = playerService.snapshotStream.listen((snapshot) {
      final current = snapshot.currentTrack;
      if (current == null) return;

      // When track changes, flush previous history and reset tracking
      if (_lastTrackLogged?.id != current.id) {
        _flushHistoryIfNeeded();
        _lastTrackLogged = current;
        _accumulatedPlayDuration = Duration.zero;
        _historyRecordedForCurrent = false;
      }

      // Track play duration
      _accumulatedPlayDuration = snapshot.position;

      // Record to history once playback surpasses 15 seconds or completes
      if (!_historyRecordedForCurrent &&
          (snapshot.position.inSeconds >= 15 || snapshot.status == PlaybackStatus.completed)) {
        _historyRecordedForCurrent = true;
        _recordHistory(current, snapshot.position, snapshot.status == PlaybackStatus.completed);
      }
    });
  }

  void _flushHistoryIfNeeded() {
    if (_lastTrackLogged != null && !_historyRecordedForCurrent && _accumulatedPlayDuration.inSeconds >= 5) {
      _recordHistory(_lastTrackLogged!, _accumulatedPlayDuration, false);
      _historyRecordedForCurrent = true;
    }
  }

  Future<void> _recordHistory(Track track, Duration duration, bool completed) async {
    final settings = settingsRepository.getSettings();
    if (!settings.listeningHistoryEnabled) return;

    try {
      await libraryRepository.addHistoryItem(
        track,
        durationPlayed: duration,
        completed: completed,
      );
    } catch (e) {
      debugPrint('[PlayerRepository] Failed to record history: $e');
    }
  }

  /// Resolves the audio stream and starts playback for [track]
  Future<void> playTrack(
    Track track, {
    AudioQuality? quality,
    Duration? initialPosition,
  }) async {
    // Request audio focus
    await sessionService.setActive(true);

    final preferredQuality = quality ?? settingsRepository.getSettings().streamingQuality;
    final resolvedUrl = await searchRepository.resolveStreamUrl(track, quality: preferredQuality);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      throw Exception('Failed to resolve audio stream URL for "${track.title}"');
    }

    // Attach favorite status from library repository
    final isFav = libraryRepository.isFavorite(track.id);
    final trackToPlay = track.copyWith(
      streamUrl: resolvedUrl,
      audioQuality: preferredQuality,
      isFavorite: isFav,
    );

    await playerService.playTrack(
      trackToPlay,
      resolvedUrl,
      initialPosition: initialPosition,
    );
  }

  /// Resolves streams for a playlist sequence and starts gapless playback from [initialIndex]
  Future<void> playPlaylist(
    List<Track> tracks, {
    int initialIndex = 0,
    AudioQuality? quality,
    Duration? initialPosition,
  }) async {
    if (tracks.isEmpty) return;

    await sessionService.setActive(true);
    final preferredQuality = quality ?? settingsRepository.getSettings().streamingQuality;

    final resolvedUrls = <String>[];
    final preparedTracks = <Track>[];

    for (final track in tracks) {
      final isFav = libraryRepository.isFavorite(track.id);
      final url = await searchRepository.resolveStreamUrl(track, quality: preferredQuality);
      if (url != null && url.isNotEmpty) {
        resolvedUrls.add(url);
        preparedTracks.add(track.copyWith(
          streamUrl: url,
          audioQuality: preferredQuality,
          isFavorite: isFav,
        ));
      }
    }

    if (preparedTracks.isEmpty) {
      throw Exception('Failed to resolve any stream URLs for playlist');
    }

    await playerService.playPlaylist(
      preparedTracks,
      resolvedUrls,
      initialIndex: initialIndex.clamp(0, preparedTracks.length - 1),
      initialPosition: initialPosition,
    );
  }

  /// Toggles favorite status for the given track or current track
  Future<bool> toggleFavorite(Track track) async {
    await libraryRepository.toggleFavorite(track);
    return libraryRepository.isFavorite(track.id);
  }

  /// Playback controls
  Future<void> resume() => playerService.resume();
  Future<void> pause() => playerService.pause();
  Future<void> togglePlayPause() => playerService.togglePlayPause();
  Future<void> stop() => playerService.stop();
  Future<void> seek(Duration position) => playerService.seek(position);
  Future<void> seekForward({Duration offset = const Duration(seconds: 10)}) =>
      playerService.seekForward(offset: offset);
  Future<void> seekBackward({Duration offset = const Duration(seconds: 10)}) =>
      playerService.seekBackward(offset: offset);
  Future<void> next() => playerService.next();
  Future<void> previous() => playerService.previous();
  Future<void> setVolume(double volume) => playerService.setVolume(volume);
  Future<void> setSpeed(double speed) => playerService.setSpeed(speed);
  Future<void> setPlaybackMode(PlaybackMode mode) => playerService.setPlaybackMode(mode);

  void dispose() {
    _flushHistoryIfNeeded();
    _snapshotSub?.cancel();
  }
}
