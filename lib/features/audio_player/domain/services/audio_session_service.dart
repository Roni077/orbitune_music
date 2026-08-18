import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the AudioSessionService singleton
final audioSessionServiceProvider = Provider<AudioSessionService>((ref) {
  return AudioSessionService();
});

/// Manages system audio focus, headphone disconnects, interruptions & hardware routing
class AudioSessionService {
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  StreamSubscription<AudioDevicesChangedEvent>? _devicesChangedSub;

  bool _isConfigured = false;
  bool _playInterrupted = false;

  // Callbacks for player engine integration
  VoidCallback? onPauseRequested;
  VoidCallback? onResumeRequested;
  ValueChanged<double>? onVolumeDuckRequested;

  bool get isConfigured => _isConfigured;

  /// Initializes the audio session with professional music streaming configuration
  Future<void> init({
    VoidCallback? onPause,
    VoidCallback? onResume,
    ValueChanged<double>? onDuckVolume,
  }) async {
    if (_isConfigured) return;

    onPauseRequested = onPause;
    onResumeRequested = onResume;
    onVolumeDuckRequested = onDuckVolume;

    try {
      _session = await AudioSession.instance;
      await _session!.configure(const AudioSessionConfiguration.music());

      _setupInterruptionListener();
      _setupBecomingNoisyListener();
      _setupDevicesChangedListener();

      _isConfigured = true;
      debugPrint('[AudioSessionService] Audio session successfully initialized and configured for Music.');
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to initialize native audio session: $e');
      // Graceful fallback for test environments or unsupported platforms
      _isConfigured = true;
    }
  }

  /// Request active audio focus from the OS
  Future<bool> setActive(bool active) async {
    if (_session == null) return false;
    try {
      return await _session!.setActive(active);
    } catch (e) {
      debugPrint('[AudioSessionService] Error setting active state ($active): $e');
      return false;
    }
  }

  /// Listen for system audio interruptions (e.g. Phone calls, Alarms, Navigation prompts)
  void _setupInterruptionListener() {
    _interruptionSub?.cancel();
    _interruptionSub = _session?.interruptionEventStream.listen((event) {
      debugPrint('[AudioSessionService] Interruption event: begin=${event.begin}, type=${event.type}');

      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Lower volume temporarily (e.g. GPS navigation prompt)
            onVolumeDuckRequested?.call(0.2);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Interruption begins (e.g. incoming phone call) -> pause playback
            _playInterrupted = true;
            onPauseRequested?.call();
            break;
        }
      } else {
        // Interruption ended
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Restore full volume
            onVolumeDuckRequested?.call(1.0);
            break;
          case AudioInterruptionType.pause:
            // Phone call finished -> auto resume if interrupted
            if (_playInterrupted) {
              _playInterrupted = false;
              onResumeRequested?.call();
            }
            break;
          case AudioInterruptionType.unknown:
            _playInterrupted = false;
            break;
        }
      }
    });
  }

  /// Listen for becoming noisy events (Headphones unplugged or Bluetooth disconnects)
  void _setupBecomingNoisyListener() {
    _becomingNoisySub?.cancel();
    _becomingNoisySub = _session?.becomingNoisyEventStream.listen((_) {
      debugPrint('[AudioSessionService] Becoming noisy event received (Headphones unplugged / Bluetooth lost). Pausing audio.');
      onPauseRequested?.call();
    });
  }

  /// Listen for hardware audio output device changes (Bluetooth AVRCP, Wired, Speakers)
  void _setupDevicesChangedListener() {
    _devicesChangedSub?.cancel();
    _devicesChangedSub = _session?.devicesChangedEventStream.listen((event) {
      final added = event.devicesAdded.map((d) => '${d.name} (${d.type.name})').join(', ');
      final removed = event.devicesRemoved.map((d) => '${d.name} (${d.type.name})').join(', ');
      debugPrint('[AudioSessionService] Audio devices changed. Added: [$added], Removed: [$removed]');
    });
  }

  /// Dispose listeners and deactivate session
  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    await _becomingNoisySub?.cancel();
    await _devicesChangedSub?.cancel();
    _interruptionSub = null;
    _becomingNoisySub = null;
    _devicesChangedSub = null;

    if (_session != null) {
      try {
        await _session!.setActive(false);
      } catch (_) {}
    }
    _isConfigured = false;
  }
}
