import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Vertical Material 3 Expressive Equalizer Slider for an individual frequency band
class EQBandSlider extends StatelessWidget {
  final int frequency;
  final double gain;
  final bool isEnabled;
  final ValueChanged<double> onGainChanged;
  final double height;

  const EQBandSlider({
    super.key,
    required this.frequency,
    required this.gain,
    required this.isEnabled,
    required this.onGainChanged,
    this.height = 190.0,
  });

  String _formatFrequency(int freq) {
    if (freq >= 1000) {
      final khz = freq / 1000;
      return khz == khz.roundToDouble()
          ? '${khz.toInt()}k'
          : '${khz.toStringAsFixed(1)}k';
    }
    return '$freq';
  }

  String _formatGain(double val) {
    if (val.abs() < 0.05) return '0.0';
    final prefix = val > 0 ? '+' : '';
    return '$prefix${val.toStringAsFixed(1)}';
  }

  Color _getGainColor(double val) {
    if (!isEnabled) return AppColors.textMuted;
    if (val > 0.1) return AppColors.accentGreen;
    if (val < -0.1) return AppColors.accentPink;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final freqLabel = _formatFrequency(frequency);
    final gainLabel = _formatGain(gain);
    final gainColor = _getGainColor(gain);

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Decibel Value Pill Badge (Double-tap to reset to 0dB)
          GestureDetector(
            onDoubleTap: isEnabled
                ? () {
                    HapticFeedback.selectionClick();
                    onGainChanged(0.0);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
              decoration: BoxDecoration(
                color: isEnabled
                    ? gainColor.withValues(alpha: 0.15)
                    : AppColors.darkSurfaceVariant,
                borderRadius: AppConstants.roundedSmall,
                border: Border.all(
                  color: isEnabled
                      ? gainColor.withValues(alpha: 0.35)
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                gainLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: isEnabled ? gainColor : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Vertical Slider Track
          SizedBox(
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center 0 dB guide line
                Positioned(
                  child: Container(
                    width: 24,
                    height: 1.5,
                    color: isEnabled
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),

                // Rotated standard slider for natural fluid touch
                RotatedBox(
                  quarterTurns: 3, // 270 degrees: Bottom is -10dB, Top is +10dB
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4.0,
                      activeTrackColor: isEnabled ? gainColor : AppColors.textMuted,
                      inactiveTrackColor: AppColors.darkSurfaceVariant,
                      thumbColor: isEnabled ? gainColor : AppColors.textMuted,
                      overlayColor: isEnabled
                          ? gainColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.5,
                        elevation: 2.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14.0,
                      ),
                    ),
                    child: Slider(
                      value: gain.clamp(-10.0, 10.0),
                      min: -10.0,
                      max: 10.0,
                      onChanged: isEnabled
                          ? (newVal) {
                              // Magnetic snap at 0.0 dB
                              final snappedVal = newVal.abs() < 0.25 ? 0.0 : newVal;
                              if ((gain.abs() > 0.2 && snappedVal == 0.0) ||
                                  (gain == 0.0 && snappedVal.abs() > 0.2)) {
                                HapticFeedback.selectionClick();
                              }
                              onGainChanged(double.parse(snappedVal.toStringAsFixed(1)));
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Frequency Label (e.g. 60, 1k, 14k)
          Text(
            freqLabel,
            style: AppTypography.labelSmall.copyWith(
              color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Text(
            'Hz',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }
}
