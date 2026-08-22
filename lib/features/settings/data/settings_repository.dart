import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';

/// Riverpod provider for SettingsRepository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(HiveService.instance);
});

/// Data repository for persisting and watching AppSettings in Hive
class SettingsRepository {
  final HiveService _hiveService;

  SettingsRepository(this._hiveService);

  Box get _box => _hiveService.settingsBox;
  static const String _settingsKey = 'app_settings';

  AppSettings getSettings() {
    final raw = _box.get(_settingsKey);
    if (raw != null && raw is Map) {
      try {
        return AppSettings.fromMap(raw);
      } catch (_) {}
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _box.put(_settingsKey, settings.toMap());
  }

  Future<void> updateThemeMode(String themeMode) async {
    final current = getSettings();
    await saveSettings(current.copyWith(themeMode: themeMode));
  }

  Future<void> updateStreamingQuality(AudioQuality quality) async {
    final current = getSettings();
    await saveSettings(current.copyWith(streamingQuality: quality));
  }

  Future<void> updateDownloadQuality(AudioQuality quality) async {
    final current = getSettings();
    await saveSettings(current.copyWith(downloadQuality: quality));
  }

  Future<void> updateCrossfadeDuration(int seconds) async {
    final current = getSettings();
    await saveSettings(current.copyWith(crossfadeDurationSeconds: seconds));
  }

  Future<void> updateEqualizerPreset(String preset) async {
    final current = getSettings();
    await saveSettings(current.copyWith(equalizerPreset: preset));
  }

  Future<void> updateEqualizerEnabled(bool enabled) async {
    final current = getSettings();
    await saveSettings(current.copyWith(equalizerEnabled: enabled));
  }

  Future<void> updateOnboardingData({
    required bool hasCompletedOnboarding,
    required String username,
    required String country,
  }) async {
    final current = getSettings();
    await saveSettings(current.copyWith(
      hasCompletedOnboarding: hasCompletedOnboarding,
      username: username,
      country: country,
    ));
  }

  Stream<AppSettings> watchSettings() {
    return _box.watch(key: _settingsKey).map((_) => getSettings());
  }
}
