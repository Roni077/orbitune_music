import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';

/// StateNotifier managing global AppSettings state
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = _repository.getSettings();
  }

  Future<void> setThemeMode(String themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _repository.saveSettings(state);
  }

  Future<void> setStreamingQuality(AudioQuality quality) async {
    state = state.copyWith(streamingQuality: quality);
    await _repository.saveSettings(state);
  }

  Future<void> setDownloadQuality(AudioQuality quality) async {
    state = state.copyWith(downloadQuality: quality);
    await _repository.saveSettings(state);
  }

  Future<void> setAutoPlay(bool autoPlay) async {
    state = state.copyWith(autoPlay: autoPlay);
    await _repository.saveSettings(state);
  }

  Future<void> setGaplessPlayback(bool gapless) async {
    state = state.copyWith(gaplessPlayback: gapless);
    await _repository.saveSettings(state);
  }

  Future<void> setCrossfadeDuration(int seconds) async {
    state = state.copyWith(crossfadeDurationSeconds: seconds);
    await _repository.saveSettings(state);
  }

  Future<void> setStopOnAppClose(bool stop) async {
    state = state.copyWith(stopOnAppClose: stop);
    await _repository.saveSettings(state);
  }

  Future<void> setWifiOnlyStreaming(bool wifiOnly) async {
    state = state.copyWith(wifiOnlyStreaming: wifiOnly);
    await _repository.saveSettings(state);
  }

  Future<void> setWifiOnlyDownloads(bool wifiOnly) async {
    state = state.copyWith(wifiOnlyDownloads: wifiOnly);
    await _repository.saveSettings(state);
  }

  Future<void> setCacheSizeLimit(int limitMb) async {
    state = state.copyWith(cacheSizeLimitMb: limitMb);
    await _repository.saveSettings(state);
  }

  Future<void> setSearchHistoryEnabled(bool enabled) async {
    state = state.copyWith(searchHistoryEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setListeningHistoryEnabled(bool enabled) async {
    state = state.copyWith(listeningHistoryEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setDynamicColorEnabled(bool enabled) async {
    state = state.copyWith(dynamicColorEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setAmoledModeEnabled(bool enabled) async {
    state = state.copyWith(amoledModeEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    state = state.copyWith(equalizerEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setEqualizerPreset(String preset) async {
    state = state.copyWith(equalizerPreset: preset);
    await _repository.saveSettings(state);
  }

  void refresh() {
    _loadSettings();
  }
}

/// Global provider for AppSettings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});
