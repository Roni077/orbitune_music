import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_player_service.dart';
import 'package:orbitune/features/equalizer/data/equalizer_repository.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_band_mode.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_preset.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_profile.dart';

/// Main StateNotifier provider for Equalizer and audio enhancement settings
final equalizerProvider =
    StateNotifierProvider<EqualizerNotifier, EQProfile>((ref) {
  final repository = ref.watch(equalizerRepositoryProvider);
  final audioService = ref.watch(audioPlayerServiceProvider);
  return EqualizerNotifier(repository, audioService);
});

/// Selector provider for checking if the equalizer DSP is enabled
final isEqualizerEnabledProvider = Provider<bool>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.isEnabled));
});

/// Selector provider for current active preset name
final activePresetNameProvider = Provider<String>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.presetName));
});

/// Selector provider for current active band mode (5-Band vs 10-Band)
final activeBandModeProvider = Provider<EQBandMode>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.bandMode));
});

/// Selector provider for effective frequency band gains
final effectiveBandGainsProvider = Provider<Map<int, double>>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.effectiveBandGains));
});

/// Selector provider for bass boost amount (0.0 to 1.0)
final bassBoostProvider = Provider<double>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.bassBoost));
});

/// Selector provider for 3D virtualizer surround sound (0.0 to 1.0)
final virtualizerProvider = Provider<double>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.virtualizer));
});

/// Selector provider for loudness gain boost (0.0 to 1.0)
final loudnessGainProvider = Provider<double>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.loudnessGain));
});

/// Selector provider for stereo pan balance (-1.0 to +1.0)
final stereoBalanceProvider = Provider<double>((ref) {
  return ref.watch(equalizerProvider.select((state) => state.balance));
});

/// StateNotifier managing EQ state, DSP enhancements, presets, and audio hardware sync
class EqualizerNotifier extends StateNotifier<EQProfile> {
  final EqualizerRepository _repository;
  final AudioPlayerService _audioService;

  EqualizerNotifier(this._repository, this._audioService)
      : super(_repository.getProfile()) {
    // Apply initial hardware audio balance and DSP parameters
    _applyHardwareSettings(state);
  }

  void _applyHardwareSettings(EQProfile profile) {
    try {
      // Hardware DSP synchronization for loudness gain and normalization
      if (profile.isEnabled && profile.volumeNormalization) {
        final baseVolume = _audioService.currentSnapshot.volume;
        final gainMultiplier = (1.0 + (profile.loudnessGain * 0.15)).clamp(0.0, 1.2);
        final effectiveVol = (baseVolume * gainMultiplier).clamp(0.0, 1.0);
        _audioService.setVolume(effectiveVol);
      }
    } catch (_) {}
  }

  /// Toggles equalizer state ON/OFF
  Future<void> toggleEnabled() async {
    await setEnabled(!state.isEnabled);
  }

  /// Sets equalizer enabled status
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _repository.saveProfile(state);
    _applyHardwareSettings(state);
  }

  /// Switches between 5-Band and 10-Band mode
  Future<void> setBandMode(EQBandMode mode) async {
    if (state.bandMode == mode) return;

    // Convert/preserve gains for new mode
    final newCustomGains = Map<int, double>.from(state.customBandGains);
    if (state.presetName.toLowerCase() != 'custom') {
      final preset = EQPreset.getByName(state.presetName, customPresets: state.customPresets);
      final gains = preset.gainsForMode(mode);
      newCustomGains.addAll(gains);
    }

    state = state.copyWith(
      bandMode: mode,
      customBandGains: newCustomGains,
    );
    await _repository.saveProfile(state);
  }

  /// Selects an existing or custom preset
  Future<void> selectPreset(String presetName) async {
    final preset = EQPreset.getByName(presetName, customPresets: state.customPresets);
    final gains = preset.gainsForMode(state.bandMode);

    final updatedCustomGains = Map<int, double>.from(state.customBandGains)
      ..addAll(gains);

    state = state.copyWith(
      presetName: preset.name,
      customBandGains: updatedCustomGains,
    );
    await _repository.saveProfile(state);
  }

  /// Updates gain for a specific frequency band (-10.0 dB to +10.0 dB)
  Future<void> setBandGain(int frequency, double gainDb) async {
    final clamped = gainDb.clamp(-10.0, 10.0);
    final updatedGains = Map<int, double>.from(state.effectiveBandGains);
    updatedGains[frequency] = clamped;

    final allCustomGains = Map<int, double>.from(state.customBandGains);
    allCustomGains[frequency] = clamped;

    // If gains deviate from preset, mark as Custom
    state = state.copyWith(
      presetName: 'Custom',
      customBandGains: allCustomGains,
    );
    await _repository.saveProfile(state);
  }

  /// Resets all frequency bands to 0.0 dB (Flat preset)
  Future<void> resetBands() async {
    await selectPreset('Flat');
  }

  /// Adjusts Bass Boost (0.0 to 1.0)
  Future<void> setBassBoost(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(bassBoost: clamped);
    await _repository.saveProfile(state);
  }

  /// Adjusts 3D Virtualizer Surround Sound (0.0 to 1.0)
  Future<void> setVirtualizer(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(virtualizer: clamped);
    await _repository.saveProfile(state);
  }

  /// Adjusts Loudness Enhancer gain (0.0 to 1.0)
  Future<void> setLoudnessGain(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(loudnessGain: clamped);
    await _repository.saveProfile(state);
  }

  /// Adjusts Stereo Pan Balance (-1.0 Left to +1.0 Right, 0.0 Center)
  Future<void> setBalance(double value) async {
    final clamped = value.clamp(-1.0, 1.0);
    state = state.copyWith(balance: clamped);
    await _repository.saveProfile(state);
    _applyHardwareSettings(state);
  }

  /// Toggles Mono Audio mode
  Future<void> setMonoAudio(bool enabled) async {
    state = state.copyWith(monoAudio: enabled);
    await _repository.saveProfile(state);
  }

  /// Adjusts Stereo Enhancement amount (0.0 to 1.0)
  Future<void> setStereoEnhancement(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(stereoEnhancement: clamped);
    await _repository.saveProfile(state);
  }

  /// Toggles Volume Normalization
  Future<void> setVolumeNormalization(bool enabled) async {
    state = state.copyWith(volumeNormalization: enabled);
    await _repository.saveProfile(state);
  }

  /// Saves current custom gains under a new preset name
  Future<void> saveCustomPreset(String name) async {
    if (name.trim().isEmpty) return;

    final trimmedName = name.trim();
    final customPreset = EQPreset(
      name: trimmedName,
      bandGains: Map<int, double>.from(state.effectiveBandGains),
      isCustom: true,
    );

    final updatedProfile = await _repository.saveCustomPreset(customPreset);
    state = updatedProfile;
  }

  /// Deletes a custom preset by name
  Future<void> deleteCustomPreset(String name) async {
    final updatedProfile = await _repository.deleteCustomPreset(name);
    state = updatedProfile;
  }

  /// Resets everything (EQ bands, presets, enhancements) to factory defaults
  Future<void> resetToDefaults() async {
    state = const EQProfile();
    await _repository.saveProfile(state);
    _applyHardwareSettings(state);
  }
}
