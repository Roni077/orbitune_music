import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/equalizer/presentation/screens/equalizer_screen.dart';

/// Volume and playback speed modal bottom sheet
class VolumeSpeedSlider extends ConsumerWidget {
  const VolumeSpeedSlider({super.key});

  /// Displays the Volume and Speed control sheet
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const VolumeSpeedSlider(),
    );
  }

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVolume = ref.watch(playerVolumeProvider);
    final currentSpeed = ref.watch(playerSpeedProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF0141424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.0,
        16.0,
        20.0,
        MediaQuery.of(context).padding.bottom + 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Volume Slider Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VOLUME',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(currentVolume * 100).toInt()}%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              IconButton(
                icon: Icon(
                  currentVolume == 0 ? LucideIcons.volumeX : LucideIcons.volume1,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  playerNotifier.setVolume(currentVolume > 0 ? 0.0 : 1.0);
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.accentGreen,
                    inactiveTrackColor: AppColors.darkSurfaceVariant,
                    thumbColor: AppColors.accentGreen,
                    overlayColor: AppColors.accentGreen.withValues(alpha: 0.2),
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  ),
                  child: Slider(
                    value: currentVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      playerNotifier.setVolume(val);
                    },
                  ),
                ),
              ),
              const Icon(
                LucideIcons.volume2,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Playback Speed Chips
          Text(
            'PLAYBACK SPEED',
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.2,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: _speedOptions.map((speed) {
              final isSelected = (currentSpeed - speed).abs() < 0.05;
              return ExpressiveCard(
                onTap: () {
                  HapticFeedback.selectionClick();
                  playerNotifier.setSpeed(speed);
                },
                borderRadius: AppConstants.roundedSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.darkSurfaceVariant,
                    borderRadius: AppConstants.roundedSmall,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGreen
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? AppColors.getAccessibleTextColor(AppColors.accentGreen) : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Equalizer Quick Button
          ExpressiveCard(
            borderRadius: AppConstants.roundedLarge,
            onTap: () {
              Navigator.pop(context);
              EqualizerScreen.open(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: AppConstants.roundedLarge,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.slidersHorizontal,
                          color: AppColors.accentGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '10-Band Equalizer & DSP',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Presets, Bass Boost & 3D Surround',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
