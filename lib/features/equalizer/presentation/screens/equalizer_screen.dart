import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_band_mode.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_preset.dart';
import 'package:orbitune/features/equalizer/presentation/providers/equalizer_provider.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/audio_enhancement_card.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/eq_band_slider.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/eq_curve_visualizer.dart';
import 'package:orbitune/features/equalizer/presentation/widgets/save_preset_dialog.dart';

/// Fullscreen Material 3 Expressive Equalizer and DSP Sound Enhancement Screen
class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  /// Opens EqualizerScreen with smooth slide navigation
  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EqualizerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqProfile = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);
    final isEnabled = eqProfile.isEnabled;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equalizer',
              style: AppTypography.brandTitle.copyWith(fontSize: 20),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isEnabled ? AppColors.accentGreen : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isEnabled ? 'DSP ACTIVE' : 'BYPASS',
                  style: AppTypography.bodySmall.copyWith(
                    color: isEnabled ? AppColors.accentGreen : AppColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Save Custom Preset Button
          IconButton(
            icon: const Icon(LucideIcons.save, color: AppColors.textSecondary, size: 20),
            onPressed: isEnabled
                ? () {
                    SavePresetDialog.show(
                      context,
                      initialName: eqProfile.presetName == 'Custom' ? 'My Preset' : eqProfile.presetName,
                      onSave: (name) {
                        eqNotifier.saveCustomPreset(name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved preset "$name"'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.darkSurfaceVariant,
                          ),
                        );
                      },
                    );
                  }
                : null,
            tooltip: 'Save Preset',
          ),

          // Reset to Flat
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, color: AppColors.textSecondary, size: 20),
            onPressed: isEnabled
                ? () {
                    HapticFeedback.mediumImpact();
                    eqNotifier.resetBands();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Equalizer reset to Flat'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                : null,
            tooltip: 'Reset Bands',
          ),

          // Master Power Switch
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Switch(
              key: const ValueKey('master_equalizer_switch'),
              value: isEnabled,
              activeTrackColor: AppColors.accentGreen,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                eqNotifier.setEnabled(val);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 5-Band vs 10-Band Segmented Mode Selector
            _buildBandModeSelector(context, eqProfile, eqNotifier),
            const SizedBox(height: 14),

            // 2. Interactive Frequency Response Curve Graph
            EQCurveVisualizer(
              bandGains: eqProfile.effectiveBandGains,
              bandMode: eqProfile.bandMode,
              isEnabled: isEnabled,
              height: 160,
              onGainChanged: (freq, gain) {
                eqNotifier.setBandGain(freq, gain);
              },
            ),
            const SizedBox(height: 16),

            // 3. Preset Carousel / Horizontal Chips Row
            _buildPresetsRow(context, eqProfile, eqNotifier),
            const SizedBox(height: 18),

            // 4. Main Frequency Band Sliders Row
            _buildBandsSliderRow(context, eqProfile, eqNotifier),
            const SizedBox(height: 24),

            // 5. Sound Enhancements (Bass Boost, Virtualizer 3D, Loudness, Balance Pan, Mono)
            AudioEnhancementCard(
              isEnabled: isEnabled,
              bassBoost: eqProfile.bassBoost,
              virtualizer: eqProfile.virtualizer,
              loudnessGain: eqProfile.loudnessGain,
              balance: eqProfile.balance,
              monoAudio: eqProfile.monoAudio,
              volumeNormalization: eqProfile.volumeNormalization,
              onBassBoostChanged: (val) => eqNotifier.setBassBoost(val),
              onVirtualizerChanged: (val) => eqNotifier.setVirtualizer(val),
              onLoudnessGainChanged: (val) => eqNotifier.setLoudnessGain(val),
              onBalanceChanged: (val) => eqNotifier.setBalance(val),
              onMonoAudioChanged: (val) => eqNotifier.setMonoAudio(val),
              onVolumeNormalizationChanged: (val) => eqNotifier.setVolumeNormalization(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandModeSelector(
    BuildContext context,
    dynamic eqProfile,
    EqualizerNotifier eqNotifier,
  ) {
    final currentMode = eqProfile.bandMode;

    return Center(
      child: SegmentedButton<EQBandMode>(
        segments: const [
          ButtonSegment<EQBandMode>(
            value: EQBandMode.band5,
            label: Text('5-Band'),
            icon: Icon(LucideIcons.sliders, size: 16),
          ),
          ButtonSegment<EQBandMode>(
            value: EQBandMode.band10,
            label: Text('10-Band'),
            icon: Icon(LucideIcons.slidersHorizontal, size: 16),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (newSelection) {
          HapticFeedback.selectionClick();
          eqNotifier.setBandMode(newSelection.first);
        },
      ),
    );
  }

  Widget _buildPresetsRow(
    BuildContext context,
    dynamic eqProfile,
    EqualizerNotifier eqNotifier,
  ) {
    final isEnabled = eqProfile.isEnabled;
    final activePreset = eqProfile.presetName;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Combine built-in presets and custom user presets
    final allPresets = <EQPreset>[
      ...EQPreset.defaultPresets,
      ...eqProfile.customPresets,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EQUALIZER PRESETS',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (eqProfile.presetName == 'Custom')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.15),
                  borderRadius: AppConstants.roundedSmall,
                ),
                child: Text(
                  'Custom Tweaks',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentPink,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allPresets.length,
            separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = allPresets[index];
              final isSelected = activePreset.toLowerCase() == preset.name.toLowerCase();

              return FilterChip(
                label: Text(
                  preset.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected && isEnabled
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: isSelected && isEnabled ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: isSelected && isEnabled,
                showCheckmark: false,
                onSelected: isEnabled
                    ? (selected) {
                        HapticFeedback.selectionClick();
                        eqNotifier.selectPreset(preset.name);
                      }
                    : null,
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                side: BorderSide(
                  color: isSelected && isEnabled
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBandsSliderRow(
    BuildContext context,
    dynamic eqProfile,
    EqualizerNotifier eqNotifier,
  ) {
    final isEnabled = eqProfile.isEnabled;
    final frequencies = eqProfile.bandMode.frequencies as List<int>;
    final effectiveGains = eqProfile.effectiveBandGains as Map<int, double>;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withValues(alpha: 0.5),
        borderRadius: AppConstants.roundedLarge,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: frequencies.map((freq) {
            final gain = effectiveGains[freq] ?? 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: EQBandSlider(
                key: ValueKey('band_slider_$freq'),
                frequency: freq,
                gain: gain,
                isEnabled: isEnabled,
                height: 180.0,
                onGainChanged: (newGain) {
                  eqNotifier.setBandGain(freq, newGain);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
