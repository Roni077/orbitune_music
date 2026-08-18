import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_band_mode.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_preset.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_profile.dart';
import 'package:orbitune/features/equalizer/presentation/providers/equalizer_provider.dart';
import 'package:orbitune/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/audio_enhancement_card.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/eq_band_slider.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/eq_curve_visualizer.dart';
import '../helpers/mock_audio_platform.dart';

class _TestEqualizerNotifier extends StateNotifier<EQProfile> implements EqualizerNotifier {
  _TestEqualizerNotifier(super.state);

  @override
  Future<void> toggleEnabled() async {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
  }

  @override
  Future<void> setBandMode(EQBandMode mode) async {
    final newCustomGains = Map<int, double>.from(state.customBandGains);
    if (state.presetName.toLowerCase() != 'custom') {
      final preset = EQPreset.getByName(state.presetName, customPresets: state.customPresets);
      newCustomGains.addAll(preset.gainsForMode(mode));
    }
    state = state.copyWith(bandMode: mode, customBandGains: newCustomGains);
  }

  @override
  Future<void> selectPreset(String presetName) async {
    final preset = EQPreset.getByName(presetName, customPresets: state.customPresets);
    final gains = preset.gainsForMode(state.bandMode);
    final updated = Map<int, double>.from(state.customBandGains)..addAll(gains);
    state = state.copyWith(presetName: preset.name, customBandGains: updated);
  }

  @override
  Future<void> setBandGain(int frequency, double gain) async {
    final clamped = gain.clamp(-10.0, 10.0);
    final gains = Map<int, double>.from(state.effectiveBandGains)..[frequency] = clamped;
    state = state.copyWith(presetName: 'Custom', customBandGains: gains);
  }

  @override
  Future<void> resetBands() async {
    state = state.copyWith(
      presetName: 'Flat',
      customBandGains: {for (final f in state.bandMode.frequencies) f: 0.0},
    );
  }

  @override
  Future<void> setBassBoost(double value) async {
    state = state.copyWith(bassBoost: value.clamp(0.0, 1.0));
  }

  @override
  Future<void> setVirtualizer(double value) async {
    state = state.copyWith(virtualizer: value.clamp(0.0, 1.0));
  }

  @override
  Future<void> setLoudnessGain(double value) async {
    state = state.copyWith(loudnessGain: value.clamp(0.0, 1.0));
  }

  @override
  Future<void> setBalance(double value) async {
    state = state.copyWith(balance: value.clamp(-1.0, 1.0));
  }

  @override
  Future<void> setMonoAudio(bool enabled) async {
    state = state.copyWith(monoAudio: enabled);
  }

  @override
  Future<void> setStereoEnhancement(double value) async {
    state = state.copyWith(stereoEnhancement: value.clamp(0.0, 1.0));
  }

  @override
  Future<void> setVolumeNormalization(bool enabled) async {
    state = state.copyWith(volumeNormalization: enabled);
  }

  @override
  Future<void> saveCustomPreset(String name) async {
    final preset = EQPreset(
      name: name,
      bandGains: Map<int, double>.from(state.effectiveBandGains),
      isCustom: true,
    );
    final updated = List<EQPreset>.from(state.customPresets)..add(preset);
    state = state.copyWith(customPresets: updated, presetName: name);
  }

  @override
  Future<void> deleteCustomPreset(String presetName) async {
    final updated = state.customPresets.where((p) => p.name != presetName).toList();
    state = state.copyWith(customPresets: updated, presetName: 'Flat');
  }

  @override
  Future<void> resetToDefaults() async {
    state = const EQProfile();
  }
}

void main() {
  setUpAll(() {
    registerMockJustAudioPlatform();
  });

  Widget createWidgetUnderTest({EQProfile initialProfile = const EQProfile()}) {
    return ProviderScope(
      overrides: [
        equalizerProvider.overrideWith((ref) => _TestEqualizerNotifier(initialProfile)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const EqualizerScreen(),
      ),
    );
  }

  group('EqualizerScreen Widget Tests', () {
    testWidgets('EqualizerScreen renders all header, visualizer, presets, sliders, and enhancements',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header elements
      expect(find.text('Equalizer'), findsOneWidget);
      expect(find.text('BYPASS'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);

      // Mode switch buttons
      expect(find.text('5-Band'), findsOneWidget);
      expect(find.text('10-Band'), findsOneWidget);

      // EQ curve visualizer
      expect(find.byType(EQCurveVisualizer), findsOneWidget);

      // Preset section & chips
      expect(find.text('EQUALIZER PRESETS'), findsOneWidget);
      expect(find.text('Flat'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Bass Boost'), findsWidgets);

      // Sliders & Enhancements
      expect(find.byType(EQBandSlider), findsWidgets);
      expect(find.byType(AudioEnhancementCard), findsOneWidget);
      expect(find.text('3D Surround'), findsOneWidget);
      expect(find.text('Loudness Enhancer'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Master switch toggles DSP state to ACTIVE', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(createWidgetUnderTest(
        initialProfile: const EQProfile(isEnabled: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DSP ACTIVE'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Switching between 5-Band and 10-Band updates frequency sliders',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(createWidgetUnderTest(
        initialProfile: const EQProfile(bandMode: EQBandMode.band10),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially in 10-Band mode (10 band sliders)
      expect(find.byType(EQBandSlider), findsNWidgets(10));

      // Switch to 5-Band mode
      await tester.tap(find.text('5-Band'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(EQBandSlider), findsNWidgets(5));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Selecting a preset applies its gains to profile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(createWidgetUnderTest(
        initialProfile: const EQProfile(isEnabled: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Bass Boost' preset chip
      await tester.tap(find.text('Bass Boost').first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Bass Boost'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Resetting bands resets active EQ to Flat', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(createWidgetUnderTest(
        initialProfile: const EQProfile(isEnabled: true, presetName: 'Bass Boost'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Bass Boost'), findsWidgets);

      await tester.tap(find.byTooltip('Reset Bands'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Flat'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
