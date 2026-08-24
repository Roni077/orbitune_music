import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/data/sponsor_block_service.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_player_service.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_session_service.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';

/// Riverpod provider for PlayerRepository
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  final sessionService = ref.watch(audioSessionServiceProvider);
  final searchRepo = ref.watch(searchRepositoryProvider);
  final libraryRepo = ref.watch(libraryRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final sponsorService = ref.watch(sponsorBlockServiceProvider);

  final repository = PlayerRepository(
    playerService: playerService,
    sessionService: sessionService,
    searchRepository: searchRepo,
    libraryRepository: libraryRepo,
    settingsRepository: settingsRepo,
    sponsorBlockService: sponsorService,
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
  final SponsorBlockService sponsorBlockService;

  StreamSubscription<PlayerStateSnapshot>? _snapshotSub;
  StreamSubscription<AppSettings>? _settingsSub;
  Track? _lastTrackLogged;
  Duration _accumulatedPlayDuration = Duration.zero;
  bool _historyRecordedForCurrent = false;
  List<SponsorBlockSegment> _activeSponsorSegments = const [];

  // Multi-tier In-Memory Stream Cache for instant 0ms track starts
  final Map<String, ({List<String> candidates, DateTime resolvedAt})> _streamCandidateCache = {};
  static const Duration _cacheTtl = Duration(hours: 4);
  static const int _maxCacheEntries = 150;

  PlayerRepository({
    required this.playerService,
    required this.sessionService,
    required this.searchRepository,
    required this.libraryRepository,
    required this.settingsRepository,
    SponsorBlockService? sponsorBlockService,
  }) : sponsorBlockService = sponsorBlockService ?? SponsorBlockService() {
    _initAudioSession();
    _initSettingsSync();
    _listenToPlaybackProgress();
  }

  void _initAudioSession() {
    sessionService.init(
      onPause: () => playerService.pause(),
      onResume: () => playerService.resume(),
      onDuckVolume: (duckLevel) => playerService.duckVolume(duckLevel),
    );
  }

  void _initSettingsSync() {
    final settings = settingsRepository.getSettings();
    playerService.setSkipSilenceEnabled(settings.skipSilence);

    _settingsSub = settingsRepository.watchSettings().listen((newSettings) {
      playerService.setSkipSilenceEnabled(newSettings.skipSilence);
      if (_lastTrackLogged != null) {
        final loudness = (_lastTrackLogged!.extra['loudnessDb'] as num?)?.toDouble();
        playerService.applyLoudnessNormalization(loudness, enabled: newSettings.audioNormalization);
      }
    });
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
        _activeSponsorSegments = const [];

        if (!current.isLocal) {
          sponsorBlockService.getSkipSegments(current.id).then((segs) {
            if (_lastTrackLogged?.id == current.id) {
              _activeSponsorSegments = segs;
            }
          }).catchError((_) {});
        }
      }

      // Track play duration
      _accumulatedPlayDuration = snapshot.position;

      // SponsorBlock non-music segment skipping
      if (_activeSponsorSegments.isNotEmpty && snapshot.isPlaying) {
        final skipTarget = sponsorBlockService.findSkipTarget(snapshot.position, _activeSponsorSegments);
        if (skipTarget != null && (skipTarget - snapshot.position).inMilliseconds > 300) {
          playerService.seek(skipTarget);
        }
      }

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

  /// Silently preloads and caches stream URLs for upcoming queue tracks in parallel (Lookahead = 3)
  /// Supports [currentIndex] = -1 to preload from the start of any newly loaded track list.
  void preloadUpcomingTracks(List<Track> queue, int currentIndex, {int lookahead = 3}) {
    if (queue.isEmpty || currentIndex < -1) return;

    Future.microtask(() async {
      final preferredQuality = settingsRepository.getSettings().streamingQuality;
      final futures = <Future<void>>[];

      for (var i = 1; i <= lookahead; i++) {
        final nextIndex = currentIndex + i;
        if (nextIndex >= 0 && nextIndex < queue.length) {
          final nextTrack = queue[nextIndex];
          if (nextTrack.isLocal) continue;

          final cacheKey = '${nextTrack.id}_${preferredQuality.name}';
          final cached = _streamCandidateCache[cacheKey];
          if (cached != null && DateTime.now().difference(cached.resolvedAt) < _cacheTtl) {
            continue;
          }

          futures.add(
            resolveCandidateUrls(nextTrack, quality: preferredQuality)
                .then((_) {})
                .catchError((_) {}),
          );
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    });
  }

  /// Resolves the audio stream and starts playback for [track] (with optional [queueContext])
  Future<void> playTrack(
    Track track, {
    AudioQuality? quality,
    Duration? initialPosition,
    List<Track>? queueContext,
    int queueIndex = 0,
  }) async {
    final preferredQuality = quality ?? settingsRepository.getSettings().streamingQuality;
    final isFav = libraryRepository.isFavorite(track.id);

    // Request audio focus and resolve stream candidates concurrently for 0ms wasted latency
    final sessionFocusFuture = sessionService.setActive(true);
    final candidateUrls = await resolveCandidateUrls(track, quality: preferredQuality);
    await sessionFocusFuture;

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
          queueContext: queueContext,
          queueIndex: queueIndex,
        );
        return; // Successfully started playback
      } catch (e) {
        debugPrint('[PlayerRepository] Stream candidate ($url) failed: $e. Trying next candidate...');
        lastError = e;
      }
    }

    throw lastError ?? Exception('All stream candidates failed for "${track.title}"');
  }

  /// Resolves streams for a playlist sequence and starts immediate playback from [initialIndex]
  Future<void> playPlaylist(
    List<Track> tracks, {
    int initialIndex = 0,
    AudioQuality? quality,
    Duration? initialPosition,
  }) async {
    if (tracks.isEmpty) return;

    await sessionService.setActive(true);
    final preferredQuality = quality ?? settingsRepository.getSettings().streamingQuality;
    final safeIndex = initialIndex.clamp(0, tracks.length - 1);

    // 1. Resolve starting track immediately for instant 0ms playback start
    final initialTrack = tracks[safeIndex];
    final initialCandidates = await resolveCandidateUrls(initialTrack, quality: preferredQuality);
    final initialUrl = initialCandidates.isNotEmpty ? initialCandidates.first : null;
    if (initialUrl == null || initialUrl.isEmpty) {
      throw Exception('Failed to resolve initial audio stream for playlist');
    }

    final preparedInitial = initialTrack.copyWith(
      streamUrl: initialUrl,
      audioQuality: preferredQuality,
      isFavorite: libraryRepository.isFavorite(initialTrack.id),
    );

    // 2. Play initial track immediately
    await playerService.playTrack(
      preparedInitial,
      initialUrl,
      initialPosition: initialPosition,
    );

    // 3. Silently preload upcoming lookahead tracks in the background
    preloadUpcomingTracks(tracks, safeIndex, lookahead: 3);
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
    _settingsSub?.cancel();
    _streamCandidateCache.clear();
  }
}
