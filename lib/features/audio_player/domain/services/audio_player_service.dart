import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:orbitune/features/audio_player/data/audio_handler.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Riverpod provider for AudioPlayerService
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Core audio playback engine wrapping `just_audio.AudioPlayer`
class AudioPlayerService {
  final AudioPlayer _player;
  final bool _ownsPlayer;

  // Active track and sequence state
  Track? _currentTrack;
  List<Track> _currentPlaylist = [];
  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();
  final StreamController<PlayerStateSnapshot> _snapshotController =
      StreamController<PlayerStateSnapshot>.broadcast();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _bufferedPositionSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<SequenceState?>? _sequenceSub;

  PlayerStateSnapshot _snapshot = const PlayerStateSnapshot();

  /// External control hooks for system media notification & lock screen actions
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  AudioPlayerService({AudioPlayer? player})
      : _player = player ??
            AudioPlayer(
              audioLoadConfiguration: const AudioLoadConfiguration(
                androidLoadControl: AndroidLoadControl(
                  maxBufferDuration: Duration(seconds: 60),
                  bufferForPlaybackDuration: Duration(milliseconds: 500),
                  bufferForPlaybackAfterRebufferDuration: Duration(seconds: 2),
                ),
              ),
            ),
        _ownsPlayer = player == null {
    _initStreams();
  }

  AudioPlayer get player => _player;
  Track? get currentTrack => _currentTrack;
  List<Track> get currentPlaylist => List.unmodifiable(_currentPlaylist);
  PlayerStateSnapshot get currentSnapshot => _snapshot;

  // Public reactive streams
  Stream<PlayerStateSnapshot> get snapshotStream => _snapshotController.stream;
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  void _initStreams() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      _updateStatus(state);
    }, onError: (err) {
      debugPrint('[AudioPlayerService] Player error event: $err');
      _snapshot = _snapshot.copyWith(
        status: PlaybackStatus.error,
        errorMessage: err.toString(),
      );
      _snapshotController.add(_snapshot);
    });

    _positionSub = _player.positionStream.listen((pos) {
      _snapshot = _snapshot.copyWith(position: pos);
      _snapshotController.add(_snapshot);
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        _snapshot = _snapshot.copyWith(duration: dur);
        _snapshotController.add(_snapshot);
      }
    });

    _bufferedPositionSub = _player.bufferedPositionStream.listen((buf) {
      _snapshot = _snapshot.copyWith(bufferedPosition: buf);
      _snapshotController.add(_snapshot);
    });

    _currentIndexSub = _player.currentIndexStream.listen((index) {
      if (index != null &&
          index >= 0 &&
          index < _currentPlaylist.length) {
        _setCurrentTrack(_currentPlaylist[index]);
      }
    });

    _sequenceSub = _player.sequenceStateStream.listen((seqState) {
      final index = seqState.currentIndex;
      if (index != null && index >= 0 && index < _currentPlaylist.length) {
        _setCurrentTrack(_currentPlaylist[index]);
      } else {
        final currentSource = seqState.currentSource;
        if (currentSource != null) {
          final tag = currentSource.tag;
          if (tag is MediaItem) {
            final matched = _currentPlaylist.firstWhere(
              (t) => t.id == tag.id,
              orElse: () => _currentTrack ?? Track(
                id: tag.id,
                title: tag.title,
                artist: tag.artist ?? 'Unknown Artist',
                album: tag.album,
                duration: tag.duration ?? Duration.zero,
                artworkUrl: tag.artUri?.toString(),
              ),
            );
            _setCurrentTrack(matched);
          }
        }
      }
    });
  }

  void _updateStatus(PlayerState state) {
    PlaybackStatus status;
    if (state.processingState == ProcessingState.idle) {
      status = PlaybackStatus.idle;
    } else if (state.processingState == ProcessingState.loading) {
      status = PlaybackStatus.loading;
    } else if (state.processingState == ProcessingState.buffering) {
      status = PlaybackStatus.buffering;
    } else if (state.processingState == ProcessingState.ready) {
      status = state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
    } else if (state.processingState == ProcessingState.completed) {
      status = PlaybackStatus.completed;
    } else {
      status = PlaybackStatus.idle;
    }

    _snapshot = _snapshot.copyWith(status: status);
    _snapshotController.add(_snapshot);
  }

  void _setCurrentTrack(Track track) {
    _currentTrack = track;
    _snapshot = _snapshot.copyWith(
      currentTrack: track,
      duration: track.duration > Duration.zero ? track.duration : _snapshot.duration,
    );
    _currentTrackController.add(track);
    _snapshotController.add(_snapshot);
  }

  /// Plays a single [Track] or a track within a [queueContext]
  Future<void> playTrack(
    Track track,
    String streamOrFilePath, {
    Map<String, String>? headers,
    Duration? initialPosition,
    List<Track>? queueContext,
    int queueIndex = 0,
  }) async {
    try {
      _setCurrentTrack(track);
      _currentPlaylist = (queueContext != null && queueContext.isNotEmpty)
          ? List.from(queueContext)
          : [track];

      _snapshot = _snapshot.copyWith(
        status: PlaybackStatus.loading,
        currentTrack: track,
        position: initialPosition ?? Duration.zero,
        duration: track.duration,
        errorMessage: null,
      );
      _snapshotController.add(_snapshot);

      final AudioSource audioSource;
      final safeIndex = (queueContext != null && queueContext.isNotEmpty)
          ? queueIndex.clamp(0, queueContext.length - 1)
          : 0;

      if (queueContext != null && queueContext.length > 1) {
        final sources = <AudioSource>[];
        for (int i = 0; i < queueContext.length; i++) {
          final t = queueContext[i];
          if (i == safeIndex) {
            sources.add(OrbituneAudioHandler.createAudioSource(
              t,
              streamOrFilePath,
              headers: headers,
            ));
          } else {
            final fallbackUrl = (t.streamUrl != null && t.streamUrl!.isNotEmpty)
                ? t.streamUrl!
                : (t.localFilePath ?? 'https://music.youtube.com/watch?v=${t.id}');
            sources.add(OrbituneAudioHandler.createAudioSource(
              t,
              fallbackUrl,
              headers: headers,
            ));
          }
        }
        audioSource = ConcatenatingAudioSource(
          useLazyPreparation: true,
          children: sources,
        );
      } else {
        audioSource = OrbituneAudioHandler.createAudioSource(
          track,
          streamOrFilePath,
          headers: headers,
        );
      }

      await _player
          .setAudioSource(
            audioSource,
            initialIndex: safeIndex,
            initialPosition: initialPosition,
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Audio stream buffering timed out after 8s'),
          );
      await _player.play();
    } catch (e, stack) {
      debugPrint('[AudioPlayerService] playTrack error: $e\n$stack');
      _snapshot = _snapshot.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
      _snapshotController.add(_snapshot);
      rethrow;
    }
  }

  /// Sets up a gapless playlist from multiple tracks and starts playing from [initialIndex]
  Future<void> playPlaylist(
    List<Track> tracks,
    List<String> streamUrls, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    if (tracks.isEmpty || streamUrls.isEmpty) return;

    try {
      final safeIndex = initialIndex.clamp(0, tracks.length - 1);
      _currentPlaylist = List.from(tracks);
      _setCurrentTrack(tracks[safeIndex]);

      _snapshot = _snapshot.copyWith(
        status: PlaybackStatus.loading,
        currentTrack: tracks[safeIndex],
        position: initialPosition ?? Duration.zero,
        duration: tracks[safeIndex].duration,
        errorMessage: null,
      );
      _snapshotController.add(_snapshot);

      final entries = <MapEntry<Track, String>>[];
      for (int i = 0; i < tracks.length && i < streamUrls.length; i++) {
        entries.add(MapEntry(tracks[i], streamUrls[i]));
      }

      final concatenatingSource = OrbituneAudioHandler.createConcatenatingSource(entries);

      await _player.setAudioSource(
        concatenatingSource,
        initialIndex: safeIndex,
        initialPosition: initialPosition,
      );
      await _player.play();
    } catch (e, stack) {
      debugPrint('[AudioPlayerService] playPlaylist error: $e\n$stack');
      _snapshot = _snapshot.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
      _snapshotController.add(_snapshot);
      rethrow;
    }
  }

  /// Resumes playback
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('[AudioPlayerService] resume error: $e');
    }
  }

  /// Pauses playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('[AudioPlayerService] pause error: $e');
    }
  }

  /// Toggles between play and pause
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Stops playback and resets state
  Future<void> stop() async {
    try {
      await _player.stop();
      _snapshot = _snapshot.copyWith(
        status: PlaybackStatus.idle,
        position: Duration.zero,
      );
      _snapshotController.add(_snapshot);
    } catch (e) {
      debugPrint('[AudioPlayerService] stop error: $e');
    }
  }

  /// Seeks to a specific [position]
  Future<void> seek(Duration position, {int? index}) async {
    try {
      await _player.seek(position, index: index);
      _snapshot = _snapshot.copyWith(position: position);
      _snapshotController.add(_snapshot);
    } catch (e) {
      debugPrint('[AudioPlayerService] seek error: $e');
    }
  }

  /// Seeks relative forward (e.g. +10 seconds)
  Future<void> seekForward({Duration offset = const Duration(seconds: 10)}) async {
    final current = _player.position;
    final max = _player.duration ?? Duration.zero;
    final target = current + offset;
    final clamped = target > max ? max : target;
    await seek(clamped);
  }

  /// Seeks relative backward (e.g. -10 seconds)
  Future<void> seekBackward({Duration offset = const Duration(seconds: 10)}) async {
    final current = _player.position;
    final target = current - offset;
    final clamped = target < Duration.zero ? Duration.zero : target;
    await seek(clamped);
  }

  /// Skips to the next track in the playlist sequence or invokes external queue handler
  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (onSkipToNext != null) {
      await onSkipToNext!();
    }
  }

  /// Skips to the previous track or restarts track if > 3s played
  Future<void> previous() async {
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (onSkipToPrevious != null) {
      await onSkipToPrevious!();
    } else {
      await seek(Duration.zero);
    }
  }

  double _userVolume = 1.0;

  /// Sets the player volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    _userVolume = clamped;
    _snapshot = _snapshot.copyWith(volume: clamped);
    _snapshotController.add(_snapshot);
    try {
      await _player.setVolume(clamped);
    } catch (_) {}
  }

  /// Dynamically normalizes volume based on track loudness metrics in dB (e.g. YouTube loudnessDb)
  Future<void> applyLoudnessNormalization(double? loudnessDb, {bool enabled = true}) async {
    if (!enabled || loudnessDb == null) {
      try {
        await _player.setVolume(_userVolume);
      } catch (_) {}
      return;
    }

    // Target reference level: -5.0 dB LUFS equivalent
    final loudnessDifference = -5.0 - loudnessDb;
    final volumeMultiplier = math.pow(10.0, loudnessDifference / 20.0).clamp(0.1, 1.0);
    final effectiveVolume = (_userVolume * volumeMultiplier).clamp(0.0, 1.0);

    try {
      await _player.setVolume(effectiveVolume.toDouble());
    } catch (_) {}
  }

  /// Enables or disables automatic skipping of silent audio segments
  Future<void> setSkipSilenceEnabled(bool enabled) async {
    try {
      await _player.setSkipSilenceEnabled(enabled);
    } catch (_) {}
  }

  /// Sets the playback speed (0.5x to 2.0x)
  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.5);
    _snapshot = _snapshot.copyWith(speed: clamped);
    _snapshotController.add(_snapshot);
    try {
      await _player.setSpeed(clamped);
    } catch (_) {}
  }

  /// Sets loop mode based on domain [PlaybackMode]
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    try {
      switch (mode) {
        case PlaybackMode.off:
          await _player.setLoopMode(LoopMode.off);
          await _player.setShuffleModeEnabled(false);
          break;
        case PlaybackMode.repeatAll:
          await _player.setLoopMode(LoopMode.all);
          await _player.setShuffleModeEnabled(false);
          break;
        case PlaybackMode.repeatOne:
          await _player.setLoopMode(LoopMode.one);
          await _player.setShuffleModeEnabled(false);
          break;
        case PlaybackMode.shuffle:
          await _player.setLoopMode(LoopMode.all);
          await _player.setShuffleModeEnabled(true);
          break;
      }
    } catch (_) {}
  }

  /// Applies volume ducking for temporary audio interruptions (e.g. notifications)
  Future<void> duckVolume(double level) async {
    final clamped = level.clamp(0.0, 1.0);
    _snapshot = _snapshot.copyWith(volume: clamped);
    _snapshotController.add(_snapshot);
    try {
      await _player.setVolume(clamped);
    } catch (_) {}
  }

  /// Smooth volume fade ramp for crossfading or sleep timer fadeout
  Future<void> fadeVolume({
    required double from,
    required double to,
    Duration duration = const Duration(seconds: 2),
    int steps = 20,
  }) async {
    final interval = duration.inMilliseconds ~/ steps;
    final stepDiff = (to - from) / steps;

    for (int i = 1; i <= steps; i++) {
      final current = from + (stepDiff * i);
      final clamped = current.clamp(0.0, 1.0);
      _snapshot = _snapshot.copyWith(volume: clamped);
      _snapshotController.add(_snapshot);
      try {
        await _player.setVolume(clamped);
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: interval));
    }
  }

  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  int? get currentIndex => _player.currentIndex;
  bool get isPlaying => _player.playing;

  /// Dispose resources
  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _bufferedPositionSub?.cancel();
    await _currentIndexSub?.cancel();
    await _sequenceSub?.cancel();

    await _currentTrackController.close();
    await _snapshotController.close();

    if (_ownsPlayer) {
      try {
        await _player.dispose();
      } catch (_) {}
    }
  }
}
