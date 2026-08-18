import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_preset.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_profile.dart';

/// Riverpod provider for EqualizerRepository
final equalizerRepositoryProvider = Provider<EqualizerRepository>((ref) {
  return EqualizerRepository(HiveService.instance);
});

/// Data repository for persisting and watching EQ profile and presets in Hive
class EqualizerRepository {
  final HiveService _hiveService;

  EqualizerRepository(this._hiveService);

  Box get _box => _hiveService.settingsBox;
  static const String _profileKey = 'eq_active_profile';

  /// Loads stored EQProfile from Hive or returns default profile
  EQProfile getProfile() {
    final raw = _box.get(_profileKey);
    if (raw != null && raw is Map) {
      try {
        return EQProfile.fromMap(raw);
      } catch (_) {}
    }
    return const EQProfile();
  }

  /// Saves the updated EQProfile to Hive
  Future<void> saveProfile(EQProfile profile) async {
    await _box.put(_profileKey, profile.toMap());
  }

  /// Saves a custom preset into the profile and updates storage
  Future<EQProfile> saveCustomPreset(EQPreset preset) async {
    final current = getProfile();
    final updatedPresets = List<EQPreset>.from(
      current.customPresets.where((p) => p.name.toLowerCase() != preset.name.toLowerCase()),
    )..add(preset);

    final updated = current.copyWith(
      customPresets: updatedPresets,
      presetName: preset.name,
      customBandGains: preset.bandGains,
    );
    await saveProfile(updated);
    return updated;
  }

  /// Deletes a custom preset from the profile
  Future<EQProfile> deleteCustomPreset(String presetName) async {
    final current = getProfile();
    final updatedPresets = current.customPresets
        .where((p) => p.name.toLowerCase() != presetName.toLowerCase())
        .toList();

    final newPresetName =
        current.presetName.toLowerCase() == presetName.toLowerCase()
            ? 'Flat'
            : current.presetName;

    final updated = current.copyWith(
      customPresets: updatedPresets,
      presetName: newPresetName,
    );
    await saveProfile(updated);
    return updated;
  }

  /// Stream to watch EQ profile changes
  Stream<EQProfile> watchProfile() {
    return _box.watch(key: _profileKey).map((_) => getProfile());
  }
}
