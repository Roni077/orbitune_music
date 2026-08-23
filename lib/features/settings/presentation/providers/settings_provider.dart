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

  Future<void> setOnboardingData({
    required bool hasCompletedOnboarding,
    required String username,
    required String country,
  }) async {
    state = state.copyWith(
      hasCompletedOnboarding: hasCompletedOnboarding,
      username: username,
      country: country,
      contentCountry: country,
    );
    await _repository.saveSettings(state);
  }

  Future<void> setUsername(String username) async {
    state = state.copyWith(username: username);
    await _repository.saveSettings(state);
  }

  Future<void> setBio(String bio) async {
    state = state.copyWith(bio: bio);
    await _repository.saveSettings(state);
  }

  Future<void> setAvatarIcon(String icon) async {
    state = state.copyWith(avatarIcon: icon);
    await _repository.saveSettings(state);
  }

  Future<void> setAvatarColorIndex(int index) async {
    state = state.copyWith(avatarColorIndex: index);
    await _repository.saveSettings(state);
  }

  Future<void> setProfileBadge(String badge) async {
    state = state.copyWith(profileBadge: badge);
    await _repository.saveSettings(state);
  }

  Future<void> setFavoriteGenre(String genre) async {
    state = state.copyWith(favoriteGenre: genre);
    await _repository.saveSettings(state);
  }

  Future<void> setCustomAvatarPath(String? path) async {
    state = state.copyWith(
      customAvatarPath: path,
      clearCustomAvatar: path == null,
    );
    await _repository.saveSettings(state);
  }

  Future<void> updateProfile({
    String? username,
    String? bio,
    String? avatarIcon,
    int? avatarColorIndex,
    String? customAvatarPath,
    bool clearCustomAvatar = false,
    String? profileBadge,
    String? favoriteGenre,
    String? country,
  }) async {
    state = state.copyWith(
      username: username ?? state.username,
      bio: bio ?? state.bio,
      avatarIcon: avatarIcon ?? state.avatarIcon,
      avatarColorIndex: avatarColorIndex ?? state.avatarColorIndex,
      customAvatarPath: customAvatarPath,
      clearCustomAvatar: clearCustomAvatar,
      profileBadge: profileBadge ?? state.profileBadge,
      favoriteGenre: favoriteGenre ?? state.favoriteGenre,
      country: country ?? state.country,
      contentCountry: country ?? state.contentCountry,
    );
    await _repository.saveSettings(state);
  }

  Future<void> setAccentColorIndex(int index) async {
    state = state.copyWith(accentColorIndex: index);
    await _repository.saveSettings(state);
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _repository.saveSettings(state);
  }

  Future<void> setCornerRadius(double radius) async {
    state = state.copyWith(cornerRadius: radius);
    await _repository.saveSettings(state);
  }

  Future<void> setGlassmorphism(bool enabled) async {
    state = state.copyWith(enableGlassmorphism: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setVisualizerEnabled(bool enabled) async {
    state = state.copyWith(enableVisualizer: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setShowBitrateBadge(bool show) async {
    state = state.copyWith(showBitrateBadge: show);
    await _repository.saveSettings(state);
  }

  Future<void> setAudioNormalization(bool enabled) async {
    state = state.copyWith(audioNormalization: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setPauseOnUnplug(bool enabled) async {
    state = state.copyWith(pauseOnUnplug: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setResumeOnBluetooth(bool enabled) async {
    state = state.copyWith(resumeOnBluetooth: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setSkipSilence(bool enabled) async {
    state = state.copyWith(skipSilence: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setContentCountry(String country) async {
    state = state.copyWith(
      contentCountry: country,
      country: country,
    );
    await _repository.saveSettings(state);
  }

  Future<void> setLyricsSource(String source) async {
    state = state.copyWith(lyricsSource: source);
    await _repository.saveSettings(state);
  }

  Future<void> setExplicitFilter(bool enabled) async {
    state = state.copyWith(explicitFilter: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _repository.saveSettings(state);
  }

  Future<void> setIncognitoMode(bool enabled) async {
    state = state.copyWith(incognitoMode: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> resetAllSettings() async {
    final prevCompleted = state.hasCompletedOnboarding;
    final prevUser = state.username;
    final prevCountry = state.country;
    state = AppSettings(
      hasCompletedOnboarding: prevCompleted,
      username: prevUser,
      country: prevCountry,
    );
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
