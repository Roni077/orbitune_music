import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/data/player_repository.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';

/// Provider for current playback repeat & shuffle mode
final playbackModeProvider = StateProvider<PlaybackMode>((ref) => PlaybackMode.off);

/// Central Riverpod provider for active audio playback state
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerStateSnapshot>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return PlayerNotifier(ref, repository);
});

/// Convenience selector providers
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(playerProvider.select((s) => s.currentTrack));
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playerProvider.select((s) => s.isPlaying));
});

final isBufferingProvider = Provider<bool>((ref) {
  return ref.watch(playerProvider.select((s) => s.isBuffering));
});

final playerPositionProvider = Provider<Duration>((ref) {
  return ref.watch(playerProvider.select((s) => s.position));
});

final playerDurationProvider = Provider<Duration>((ref) {
  return ref.watch(playerProvider.select((s) => s.duration));
});

final playerStatusProvider = Provider<PlaybackStatus>((ref) {
  return ref.watch(playerProvider.select((s) => s.status));
});

final playerVolumeProvider = Provider<double>((ref) {
  return ref.watch(playerProvider.select((s) => s.volume));
});

final playerSpeedProvider = Provider<double>((ref) {
  return ref.watch(playerProvider.select((s) => s.speed));
});

/// StateNotifier managing reactive audio player actions and updates
class PlayerNotifier extends StateNotifier<PlayerStateSnapshot> {
  final Ref _ref;
  final PlayerRepository _repository;
  StreamSubscription<PlayerStateSnapshot>? _snapshotSub;

  PlayerNotifier(this._ref, this._repository)
      : super(const PlayerStateSnapshot()) {
    _listenToPlayerService();
  }

  void _listenToPlayerService() {
    _snapshotSub = _repository.playerService.snapshotStream.listen((snapshot) {
      // Sync favorite state if current track exists
      if (snapshot.currentTrack != null) {
        final isFav = _repository.libraryRepository.isFavorite(snapshot.currentTrack!.id);
        final syncedTrack = snapshot.currentTrack!.copyWith(isFavorite: isFav);
        state = snapshot.copyWith(currentTrack: syncedTrack);
      } else {
        state = snapshot;
      }
    });
  }

  /// Plays a single [track]
  Future<void> playTrack(
    Track track, {
    AudioQuality? quality,
    Duration? initialPosition,
  }) async {
    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentTrack: track,
      position: initialPosition ?? Duration.zero,
      errorMessage: null,
    );
    try {
      await _repository.playTrack(
        track,
        quality: quality,
        initialPosition: initialPosition,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Plays a playlist sequence from [initialIndex]
  Future<void> playPlaylist(
    List<Track> tracks, {
    int initialIndex = 0,
    AudioQuality? quality,
    Duration? initialPosition,
  }) async {
    if (tracks.isEmpty) return;
    try {
      await _ref.read(queueProvider.notifier).playPlaylist(
        tracks,
        initialIndex: initialIndex,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Toggles play / pause state
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Resumes playback
  Future<void> resume() async {
    await _repository.resume();
  }

  /// Pauses playback
  Future<void> pause() async {
    await _repository.pause();
  }

  /// Stops playback
  Future<void> stop() async {
    state = state.copyWith(
      status: PlaybackStatus.idle,
      position: Duration.zero,
    );
    await _repository.stop();
  }

  /// Seeks to a specific [position]
  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
    await _repository.seek(position);
  }

  /// Relative seek forward (+10s default)
  Future<void> seekForward({Duration offset = const Duration(seconds: 10)}) async {
    await _repository.seekForward(offset: offset);
  }

  /// Relative seek backward (-10s default)
  Future<void> seekBackward({Duration offset = const Duration(seconds: 10)}) async {
    await _repository.seekBackward(offset: offset);
  }

  /// Skips to the next track in queue or fallback service
  Future<void> next() async {
    try {
      final queueNotifier = _ref.read(queueProvider.notifier);
      if (queueNotifier.state.hasNext || queueNotifier.state.isAutoplayEnabled) {
        await queueNotifier.next();
        return;
      }
    } catch (_) {}
    await _repository.next();
  }

  /// Skips to previous track in queue or seeks to start
  Future<void> previous() async {
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    try {
      final queueNotifier = _ref.read(queueProvider.notifier);
      if (queueNotifier.state.hasPrevious) {
        await queueNotifier.previous();
        return;
      }
    } catch (_) {}
    await seek(Duration.zero);
  }

  /// Sets audio playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    await _repository.setVolume(clamped);
  }

  /// Sets playback speed (0.5x to 2.0x)
  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.5);
    state = state.copyWith(speed: clamped);
    await _repository.setSpeed(clamped);
  }

  /// Sets playback repeat & shuffle mode
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _ref.read(playbackModeProvider.notifier).state = mode;
    await _repository.setPlaybackMode(mode);
  }

  /// Cycles through standard repeat modes: Off -> Repeat All -> Repeat One -> Off
  Future<void> cyclePlaybackMode() async {
    final currentMode = _ref.read(playbackModeProvider);
    final nextMode = currentMode.nextRepeatMode();
    await setPlaybackMode(nextMode);
  }

  /// Toggles favorite for the currently playing track
  Future<void> toggleFavorite() async {
    final current = state.currentTrack;
    if (current == null) return;

    final isNowFavorite = await _repository.toggleFavorite(current);
    final updated = current.copyWith(isFavorite: isNowFavorite);
    state = state.copyWith(currentTrack: updated);

    // Invalidate favorites provider so UI refreshes automatically
    _ref.invalidate(favoritesProvider);
  }

  @override
  void dispose() {
    _snapshotSub?.cancel();
    super.dispose();
  }
}
