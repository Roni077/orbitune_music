import 'track.dart';

/// State of the audio player engine
enum PlaybackStatus {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// Immutable state snapshot of the active player
class PlayerStateSnapshot {
  final PlaybackStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final double speed;
  final String? errorMessage;

  const PlayerStateSnapshot({
    this.status = PlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.errorMessage,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isBuffering => status == PlaybackStatus.buffering || status == PlaybackStatus.loading;
  bool get isCompleted => status == PlaybackStatus.completed;
  bool get hasError => status == PlaybackStatus.error;

  double get progressRatio {
    if (duration.inMilliseconds <= 0) return 0.0;
    final ratio = position.inMilliseconds / duration.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  double get bufferedRatio {
    if (duration.inMilliseconds <= 0) return 0.0;
    final ratio = bufferedPosition.inMilliseconds / duration.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  PlayerStateSnapshot copyWith({
    PlaybackStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    double? speed,
    String? errorMessage,
  }) {
    return PlayerStateSnapshot(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      errorMessage: errorMessage,
    );
  }
}
