import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_player_service.dart';
import 'package:orbitune/features/equalizer/data/equalizer_repository.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_band_mode.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_preset.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_profile.dart';
import 'package:orbitune/features/equalizer/presentation/providers/equalizer_provider.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late EqualizerRepository repository;
  late AudioPlayerService audioService;
  late EqualizerNotifier notifier;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_eq_unit_test_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
  });

  setUp(() {
    repository = EqualizerRepository(HiveService.instance);
    audioService = AudioPlayerService();
    notifier = EqualizerNotifier(repository, audioService);
  });

  tearDown(() {
    audioService.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    HiveService.instance.resetForTesting();
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Equalizer Domain Models Tests', () {
    test('EQBandMode frequencies and string parsing', () {
      expect(EQBandMode.band5.frequencies.length, 5);
      expect(EQBandMode.band10.frequencies.length, 10);
      expect(EQBandMode.band5.frequencies, [60, 230, 910, 3600, 14000]);
      expect(EQBandMode.band10.frequencies.first, 31);
      expect(EQBandMode.band10.frequencies.last, 16000);

      expect(EQBandMode.fromString('band5'), EQBandMode.band5);
      expect(EQBandMode.fromString('band10'), EQBandMode.band10);
      expect(EQBandMode.fromString(null), EQBandMode.band10);
    });

    test('EQPreset default presets and gain resolution', () {
      final rock = EQPreset.getByName('Rock');
      expect(rock.name, 'Rock');
      expect(rock.gainsForMode(EQBandMode.band10).length, 10);
      expect(rock.gainsForMode(EQBandMode.band5).length, 5);

      final bassBoost = EQPreset.getByName('Bass Boost');
      expect(bassBoost.bandGains[31], 7.0);

      final fallback = EQPreset.getByName('NonExistent');
      expect(fallback.name, 'Flat');
    });

    test('EQProfile serialization and effective band gains', () {
      const profile = EQProfile(
        isEnabled: true,
        bandMode: EQBandMode.band5,
        presetName: 'Rock',
        bassBoost: 0.8,
        virtualizer: 0.6,
        loudnessGain: 0.5,
        balance: -0.3,
        monoAudio: true,
      );

      expect(profile.isEnabled, true);
      expect(profile.bandMode, EQBandMode.band5);
      expect(profile.effectiveBandGains.length, 5);
      expect(profile.bassBoost, 0.8);
      expect(profile.balance, -0.3);
      expect(profile.monoAudio, true);

      final map = profile.toMap();
      final restored = EQProfile.fromMap(map);

      expect(restored.isEnabled, true);
      expect(restored.bandMode, EQBandMode.band5);
      expect(restored.presetName, 'Rock');
      expect(restored.bassBoost, 0.8);
      expect(restored.balance, -0.3);
      expect(restored.monoAudio, true);
    });
  });

  group('EqualizerNotifier & Repository Tests', () {
    test('Toggle and enable/disable equalizer', () async {
      expect(notifier.state.isEnabled, false);

      await notifier.toggleEnabled();
      expect(notifier.state.isEnabled, true);

      await notifier.setEnabled(false);
      expect(notifier.state.isEnabled, false);
    });

    test('Switch band mode between 5-Band and 10-Band', () async {
      expect(notifier.state.bandMode, EQBandMode.band10);

      await notifier.setBandMode(EQBandMode.band5);
      expect(notifier.state.bandMode, EQBandMode.band5);
      expect(notifier.state.effectiveBandGains.length, 5);

      await notifier.setBandMode(EQBandMode.band10);
      expect(notifier.state.bandMode, EQBandMode.band10);
      expect(notifier.state.effectiveBandGains.length, 10);
    });

    test('Select built-in presets and gain updates', () async {
      await notifier.selectPreset('Rock');
      expect(notifier.state.presetName, 'Rock');
      expect(notifier.state.effectiveBandGains[31], 5.0);

      await notifier.selectPreset('Pop');
      expect(notifier.state.presetName, 'Pop');
      expect(notifier.state.effectiveBandGains[500], 4.0);

      await notifier.resetBands();
      expect(notifier.state.presetName, 'Flat');
      expect(notifier.state.effectiveBandGains[1000], 0.0);
    });

    test('Manual band gain tweaking triggers Custom preset', () async {
      await notifier.selectPreset('Flat');
      expect(notifier.state.presetName, 'Flat');

      await notifier.setBandGain(1000, 6.5);
      expect(notifier.state.presetName, 'Custom');
      expect(notifier.state.getGain(1000), 6.5);

      // Clamp out-of-range gains to ±10dB
      await notifier.setBandGain(1000, 15.0);
      expect(notifier.state.getGain(1000), 10.0);
    });

    test('Adjust sound enhancements: Bass Boost, Virtualizer, Loudness, Balance', () async {
      await notifier.setBassBoost(0.75);
      expect(notifier.state.bassBoost, 0.75);

      await notifier.setVirtualizer(0.5);
      expect(notifier.state.virtualizer, 0.5);

      await notifier.setLoudnessGain(0.9);
      expect(notifier.state.loudnessGain, 0.9);

      await notifier.setBalance(-0.8);
      expect(notifier.state.balance, -0.8);

      await notifier.setMonoAudio(true);
      expect(notifier.state.monoAudio, true);

      await notifier.setVolumeNormalization(false);
      expect(notifier.state.volumeNormalization, false);
    });

    test('Save and delete custom user presets', () async {
      await notifier.setBandGain(63, 4.0);
      await notifier.setBandGain(125, 2.5);
      await notifier.saveCustomPreset('My Custom Studio');

      expect(notifier.state.presetName, 'My Custom Studio');
      expect(notifier.state.customPresets.length, 1);
      expect(notifier.state.customPresets.first.name, 'My Custom Studio');
      expect(notifier.state.isCustomPreset, true);

      // Delete custom preset
      await notifier.deleteCustomPreset('My Custom Studio');
      expect(notifier.state.customPresets.isEmpty, true);
      expect(notifier.state.presetName, 'Flat');
    });

    test('Reset to factory defaults', () async {
      await notifier.setEnabled(true);
      await notifier.setBassBoost(0.9);
      await notifier.setVirtualizer(0.8);
      await notifier.selectPreset('Dance');

      await notifier.resetToDefaults();
      expect(notifier.state.isEnabled, false);
      expect(notifier.state.bassBoost, 0.0);
      expect(notifier.state.virtualizer, 0.0);
      expect(notifier.state.presetName, 'Flat');
    });
  });
}
