import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Audio DSP Enhancements Card featuring Bass Boost, 3D Virtualizer, Loudness, Balance Pan, and Mono Audio
class AudioEnhancementCard extends StatelessWidget {
  final bool isEnabled;
  final double bassBoost;
  final double virtualizer;
  final double loudnessGain;
  final double balance;
  final bool monoAudio;
  final bool volumeNormalization;
  final ValueChanged<double> onBassBoostChanged;
  final ValueChanged<double> onVirtualizerChanged;
  final ValueChanged<double> onLoudnessGainChanged;
  final ValueChanged<double> onBalanceChanged;
  final ValueChanged<bool> onMonoAudioChanged;
  final ValueChanged<bool> onVolumeNormalizationChanged;

  const AudioEnhancementCard({
    super.key,
    required this.isEnabled,
    required this.bassBoost,
    required this.virtualizer,
    required this.loudnessGain,
    required this.balance,
    required this.monoAudio,
    required this.volumeNormalization,
    required this.onBassBoostChanged,
    required this.onVirtualizerChanged,
    required this.onLoudnessGainChanged,
    required this.onBalanceChanged,
    required this.onMonoAudioChanged,
    required this.onVolumeNormalizationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'SOUND ENHANCEMENTS & DSP',
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 1.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Dial/Slider Cards: Bass Boost & 3D Virtualizer
        Row(
          children: [
            // Bass Boost Card
            Expanded(
              child: _buildEnhancementControlCard(
                title: 'Bass Boost',
                subtitle: 'Sub-bass punch',
                icon: LucideIcons.disc,
                value: bassBoost,
                activeColor: AppColors.accentGreen,
                onChanged: onBassBoostChanged,
              ),
            ),
            const SizedBox(width: 12),

            // 3D Virtualizer Card
            Expanded(
              child: _buildEnhancementControlCard(
                title: '3D Surround',
                subtitle: 'Spatial audio',
                icon: LucideIcons.radio,
                value: virtualizer,
                activeColor: AppColors.accentIndigo,
                onChanged: onVirtualizerChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Loudness Enhancer Card
        _buildEnhancementSliderRow(
          title: 'Loudness Enhancer',
          subtitle: 'Expands dynamic clarity without clipping',
          icon: LucideIcons.volume2,
          value: loudnessGain,
          activeColor: AppColors.accentPink,
          onChanged: onLoudnessGainChanged,
        ),
        const SizedBox(height: 12),

        // Stereo Balance Pan Slider
        _buildStereoBalanceRow(),
        const SizedBox(height: 12),

        // Toggles: Mono Audio & Volume Normalization
        Row(
          children: [
            Expanded(
              child: _buildSwitchCard(
                title: 'Mono Audio',
                icon: LucideIcons.audioWaveform,
                value: monoAudio,
                onChanged: onMonoAudioChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSwitchCard(
                title: 'Volume Normalize',
                icon: LucideIcons.slidersHorizontal,
                value: volumeNormalization,
                onChanged: onVolumeNormalizationChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancementControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    final percentage = (value * 100).toInt();

    return ExpressiveCard(
      borderRadius: AppConstants.roundedLarge,
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 20,
                color: isEnabled ? activeColor : AppColors.textMuted,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isEnabled && percentage > 0
                      ? activeColor.withValues(alpha: 0.15)
                      : AppColors.darkSurfaceVariant,
                  borderRadius: AppConstants.roundedSmall,
                ),
                child: Text(
                  '$percentage%',
                  style: AppTypography.labelSmall.copyWith(
                    color: isEnabled && percentage > 0
                        ? activeColor
                        : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: isEnabled ? activeColor : AppColors.textMuted,
              inactiveTrackColor: AppColors.darkSurfaceVariant,
              thumbColor: isEnabled ? activeColor : AppColors.textMuted,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: isEnabled
                  ? (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancementSliderRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    final percentage = (value * 100).toInt();

    return ExpressiveCard(
      borderRadius: AppConstants.roundedLarge,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isEnabled ? activeColor : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEnabled && percentage > 0
                      ? activeColor.withValues(alpha: 0.15)
                      : AppColors.darkSurfaceVariant,
                  borderRadius: AppConstants.roundedSmall,
                ),
                child: Text(
                  '$percentage%',
                  style: AppTypography.labelSmall.copyWith(
                    color: isEnabled && percentage > 0
                        ? activeColor
                        : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: isEnabled ? activeColor : AppColors.textMuted,
              inactiveTrackColor: AppColors.darkSurfaceVariant,
              thumbColor: isEnabled ? activeColor : AppColors.textMuted,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: isEnabled
                  ? (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStereoBalanceRow() {
    String balanceLabel;
    if (balance.abs() < 0.05) {
      balanceLabel = 'Center';
    } else if (balance < 0) {
      balanceLabel = 'Left ${((balance.abs()) * 100).toInt()}%';
    } else {
      balanceLabel = 'Right ${((balance) * 100).toInt()}%';
    }

    return ExpressiveCard(
      borderRadius: AppConstants.roundedLarge,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.headphones,
                    size: 20,
                    color: AppColors.accentNeonBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Stereo Balance Pan',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: isEnabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onBalanceChanged(0.0);
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentNeonBlue.withValues(alpha: 0.15),
                    borderRadius: AppConstants.roundedSmall,
                  ),
                  child: Text(
                    balanceLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentNeonBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'L',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.5,
                    activeTrackColor: isEnabled
                        ? AppColors.accentNeonBlue
                        : AppColors.textMuted,
                    inactiveTrackColor: AppColors.darkSurfaceVariant,
                    thumbColor: isEnabled
                        ? AppColors.accentNeonBlue
                        : AppColors.textMuted,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                  ),
                  child: Slider(
                    value: balance.clamp(-1.0, 1.0),
                    min: -1.0,
                    max: 1.0,
                    onChanged: isEnabled
                        ? (v) {
                            final snapped = v.abs() < 0.08 ? 0.0 : v;
                            onBalanceChanged(snapped);
                          }
                        : null,
                  ),
                ),
              ),
              Text(
                'R',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ExpressiveCard(
      borderRadius: AppConstants.roundedLarge,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isEnabled && value
                    ? AppColors.accentGreen
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
          Switch(
            value: isEnabled && value,
            activeTrackColor: AppColors.accentGreen,
            onChanged: isEnabled
                ? (newVal) {
                    HapticFeedback.selectionClick();
                    onChanged(newVal);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
