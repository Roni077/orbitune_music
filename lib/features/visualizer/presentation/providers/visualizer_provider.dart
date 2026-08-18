import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/visualizer/domain/models/visualizer_mode.dart';

/// State representation for audio spectrum visualizer configuration
@immutable
class VisualizerState {
  final VisualizerMode mode;
  final VisualizerColorTheme colorTheme;
  final int targetFps;
  final double sensitivity;
  final bool isArtworkReactive;

  const VisualizerState({
    this.mode = VisualizerMode.bars,
    this.colorTheme = VisualizerColorTheme.dynamicArtwork,
    this.targetFps = 60,
    this.sensitivity = 1.0,
    this.isArtworkReactive = true,
  });

  bool get isEnabled => mode != VisualizerMode.off;

  VisualizerState copyWith({
    VisualizerMode? mode,
    VisualizerColorTheme? colorTheme,
    int? targetFps,
    double? sensitivity,
    bool? isArtworkReactive,
  }) {
    return VisualizerState(
      mode: mode ?? this.mode,
      colorTheme: colorTheme ?? this.colorTheme,
      targetFps: targetFps ?? this.targetFps,
      sensitivity: sensitivity ?? this.sensitivity,
      isArtworkReactive: isArtworkReactive ?? this.isArtworkReactive,
    );
  }
}

/// Provider for audio visualizer settings
final visualizerProvider =
    StateNotifierProvider<VisualizerNotifier, VisualizerState>((ref) {
  return VisualizerNotifier();
});

/// StateNotifier controlling visualizer settings and mode transitions
class VisualizerNotifier extends StateNotifier<VisualizerState> {
  VisualizerNotifier() : super(const VisualizerState());

  /// Sets active visualizer mode
  void setMode(VisualizerMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// Cycles to next visualizer mode: Bars -> Wave -> Circular -> Off -> Bars
  void cycleMode() {
    state = state.copyWith(mode: state.mode.next);
  }

  /// Sets color theme
  void setColorTheme(VisualizerColorTheme theme) {
    state = state.copyWith(colorTheme: theme);
  }

  /// Toggles target frame rate between 30 FPS (battery-saver) and 60 FPS (smooth)
  void setTargetFps(int fps) {
    state = state.copyWith(targetFps: fps.clamp(30, 60));
  }

  /// Sets visualizer sensitivity (0.5x to 2.0x)
  void setSensitivity(double sensitivity) {
    state = state.copyWith(sensitivity: sensitivity.clamp(0.5, 2.0));
  }

  /// Toggles artwork pulsating reactivity
  void toggleArtworkReactivity() {
    state = state.copyWith(isArtworkReactive: !state.isArtworkReactive);
  }

  /// Toggles visualizer on/off
  void toggleEnabled() {
    if (state.mode == VisualizerMode.off) {
      state = state.copyWith(mode: VisualizerMode.bars);
    } else {
      state = state.copyWith(mode: VisualizerMode.off);
    }
  }
}
