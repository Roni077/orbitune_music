import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';

/// State representation for active sleep timer
@immutable
class SleepTimerState {
  final bool isActive;
  final Duration? remainingTime;
  final Duration? totalDuration;
  final bool stopAfterCurrentTrack;
  final String? activeLabel;

  const SleepTimerState({
    this.isActive = false,
    this.remainingTime,
    this.totalDuration,
    this.stopAfterCurrentTrack = false,
    this.activeLabel,
  });

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remainingTime,
    Duration? totalDuration,
    bool? stopAfterCurrentTrack,
    String? activeLabel,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remainingTime: remainingTime ?? this.remainingTime,
      totalDuration: totalDuration ?? this.totalDuration,
      stopAfterCurrentTrack:
          stopAfterCurrentTrack ?? this.stopAfterCurrentTrack,
      activeLabel: activeLabel ?? this.activeLabel,
    );
  }

  /// Formatted remaining countdown (e.g., '14:32' or 'End of Track')
  String get formattedCountdown {
    if (stopAfterCurrentTrack) return 'End of song';
    if (remainingTime == null) return '';
    final minutes = remainingTime!.inMinutes;
    final seconds = remainingTime!.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Provider for active sleep timer state
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});

/// StateNotifier controlling sleep timer countdown and playback termination
class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _timer;
  ProviderSubscription<PlayerStateSnapshot>? _playerSubscription;

  SleepTimerNotifier(this._ref) : super(const SleepTimerState());

  /// Sets a countdown sleep timer for [duration] with optional display [label]
  void setTimer(Duration duration, {String? label}) {
    cancelTimer();

    final displayLabel = label ?? '${duration.inMinutes} mins';
    state = SleepTimerState(
      isActive: true,
      remainingTime: duration,
      totalDuration: duration,
      stopAfterCurrentTrack: false,
      activeLabel: displayLabel,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentRemaining = state.remainingTime;
      if (currentRemaining == null || currentRemaining.inSeconds <= 1) {
        _triggerSleepAction();
      } else {
        final newRemaining = currentRemaining - const Duration(seconds: 1);
        state = state.copyWith(remainingTime: newRemaining);
      }
    });
  }

  /// Sets timer to pause playback at the end of the current song
  void setStopAfterCurrentTrack() {
    cancelTimer();

    final currentTrackId = _ref.read(playerProvider).currentTrack?.id;
    if (currentTrackId == null) return;

    state = const SleepTimerState(
      isActive: true,
      stopAfterCurrentTrack: true,
      activeLabel: 'End of Song',
    );

    // Listen to track changes
    _playerSubscription = _ref.listen<PlayerStateSnapshot>(playerProvider,
        (previous, next) {
      if (previous?.currentTrack?.id != null &&
          next.currentTrack?.id != null &&
          previous!.currentTrack!.id != next.currentTrack!.id) {
        _triggerSleepAction();
      }
    });
  }

  /// Cancels any active sleep timer
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _playerSubscription?.close();
    _playerSubscription = null;
    state = const SleepTimerState();
  }

  /// Pauses playback and resets timer state
  Future<void> _triggerSleepAction() async {
    cancelTimer();
    try {
      final player = _ref.read(playerProvider.notifier);
      await player.pause();
    } catch (e) {
      debugPrint('[SleepTimer] Error pausing playback on timer trigger: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerSubscription?.close();
    super.dispose();
  }
}
