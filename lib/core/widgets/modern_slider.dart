import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Modern Waveform/Slider Seeker with buffered progress and smooth touch
class ModernSlider extends StatelessWidget {
  final double value;
  final double max;
  final double bufferedValue;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? bufferedColor;

  const ModernSlider({
    super.key,
    required this.value,
    required this.max,
    this.bufferedValue = 0.0,
    required this.onChanged,
    this.onChangeEnd,
    this.activeColor,
    this.inactiveColor,
    this.bufferedColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActive = activeColor ?? AppColors.accentGreen;
    final effectiveInactive = inactiveColor ?? AppColors.darkSurfaceVariant;
    final effectiveBuffered = bufferedColor ?? AppColors.textMuted.withValues(alpha: 0.3);

    final safeMax = max > 0 ? max : 1.0;
    final safeValue = value.clamp(0.0, safeMax);
    final safeBuffered = bufferedValue.clamp(0.0, safeMax);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4.0,
        activeTrackColor: effectiveActive,
        inactiveTrackColor: effectiveInactive,
        secondaryActiveTrackColor: effectiveBuffered,
        thumbColor: effectiveActive,
        overlayColor: effectiveActive.withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6.0,
          elevation: 2.0,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
      ),
      child: Slider(
        value: safeValue,
        secondaryTrackValue: safeBuffered,
        min: 0.0,
        max: safeMax,
        onChanged: onChanged,
        onChangeEnd: (val) {
          HapticFeedback.selectionClick();
          onChangeEnd?.call(val);
        },
      ),
    );
  }
}
