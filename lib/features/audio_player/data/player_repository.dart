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

/// High-level repository orchestrating audio playback, multi-tier stream resolution, preloading & analytics
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

  // Multi-tier In-Memory Stream Cache for instant 0ms track starts
  final Map<String, ({List<String> candidates, DateTime resolvedAt})> _streamCandidateCache = {};
  static const Duration _cacheTtl = Duration(hours: 2);
  static const int _maxCacheEntries = 60;

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

  /// Resolves candidate URLs with in-memory caching for instant 0ms latency
  Future<List<String>> resolveCandidateUrls(Track track, {AudioQuality? quality}) async {
    final preferredQuality = quality ?? settingsRepository.getSettings().streamingQuality;
    final cacheKey = '${track.id}_${preferredQuality.name}';

    // 1. Check in-memory stream cache
    final cached = _streamCandidateCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.resolvedAt) < _cacheTtl) {
      return cached.candidates;
    }

    final candidateUrls = <String>[];

    if (track.isLocal && track.localFilePath != null) {
      candidateUrls.add(track.localFilePath!);
    } else if (track.source == 'extractor') {
      final originalUrl = track.extra['originalUrl']?.toString() ?? track.streamUrl;
      if (originalUrl != null && (originalUrl.startsWith('http://') || originalUrl.startsWith('https://'))) {
        try {
          final extStream = await searchRepository.extractorService.getBestAudioStreamUrl(originalUrl);
          if (extStream != null && extStream.isNotEmpty) {
            candidateUrls.add(extStream);
          }
        } catch (_) {}
      }
    }

    // Pure audio format candidates from YouTube Explode (Opus ~160k itag 251, AAC ~128-142k itag 140)
    if (candidateUrls.isEmpty) {
      try {
        final ytCandidates = await searchRepository.youTubeSource
            .getAudioStreamCandidates(track.id, quality: preferredQuality);
        candidateUrls.addAll(ytCandidates);
      } catch (e) {
        debugPrint('[PlayerRepository] getAudioStreamCandidates error: $e');
      }
    }

    // Secondary fallback: general stream resolution
    if (candidateUrls.isEmpty) {
      final resolved = await searchRepository.resolveStreamUrl(track, quality: preferredQuality);
      if (resolved != null && resolved.isNotEmpty) {
        candidateUrls.add(resolved);
      }
    }

    // Cache candidates in memory
    if (candidateUrls.isNotEmpty) {
      if (_streamCandidateCache.length >= _maxCacheEntries) {
        _streamCandidateCache.remove(_streamCandidateCache.keys.first);
      }
      _streamCandidateCache[cacheKey] = (
        candidates: List.unmodifiable(candidateUrls),
        resolvedAt: DateTime.now(),
      );
    }

    return candidateUrls;
  }

  /// Silently preloads and caches stream URLs for upcoming queue tracks (Lookahead = 3)
  void preloadUpcomingTracks(List<Track> queue, int currentIndex, {int lookahead = 3}) {
    if (queue.isEmpty || currentIndex < 0) return;

    Future.microtask(() async {
      final preferredQuality = settingsRepository.getSettings().streamingQuality;
      for (var i = 1; i <= lookahead; i++) {
        final nextIndex = currentIndex + i;
        if (nextIndex < queue.length) {
          final nextTrack = queue[nextIndex];
          if (nextTrack.isLocal) continue;

          final cacheKey = '${nextTrack.id}_${preferredQuality.name}';
          final cached = _streamCandidateCache[cacheKey];
          if (cached != null && DateTime.now().difference(cached.resolvedAt) < _cacheTtl) {
            continue;
          }

          try {
            await resolveCandidateUrls(nextTrack, quality: preferredQuality);
          } catch (_) {}
        }
      }
    });
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
    final isFav = libraryRepository.isFavorite(track.id);

    final candidateUrls = await resolveCandidateUrls(track, quality: preferredQuality);

    if (candidateUrls.isEmpty) {
      throw Exception('Failed to resolve audio stream URL for "${track.title}"');
    }

    Object? lastError;
    for (final url in candidateUrls) {
      try {
        final trackToPlay = track.copyWith(
          streamUrl: url,
          audioQuality: preferredQuality,
          isFavorite: isFav,
        );

        await playerService.playTrack(
          trackToPlay,
          url,
          initialPosition: initialPosition,
        );
        return; // Successfully started playback
      } catch (e) {
        debugPrint('[PlayerRepository] Stream candidate ($url) failed: $e. Trying next candidate...');
        lastError = e;
      }
    }

    throw lastError ?? Exception('All stream candidates failed for "${track.title}"');
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
      final candidateUrls = await resolveCandidateUrls(track, quality: preferredQuality);
      final url = candidateUrls.isNotEmpty ? candidateUrls.first : null;
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

    final safeIndex = initialIndex.clamp(0, preparedTracks.length - 1);
    await playerService.playPlaylist(
      preparedTracks,
      resolvedUrls,
      initialIndex: safeIndex,
      initialPosition: initialPosition,
    );

    // Silently preload upcoming tracks from the playlist
    preloadUpcomingTracks(preparedTracks, safeIndex);
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

  /// Sets external media control skip hooks (e.g. from QueueNotifier)
  void setControlHooks({
    Future<void> Function()? onSkipToNext,
    Future<void> Function()? onSkipToPrevious,
  }) {
    playerService.onSkipToNext = onSkipToNext;
    playerService.onSkipToPrevious = onSkipToPrevious;
  }

  void dispose() {
    _flushHistoryIfNeeded();
    _snapshotSub?.cancel();
    _streamCandidateCache.clear();
  }
}
