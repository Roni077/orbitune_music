import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/presentation/providers/sleep_timer_provider.dart';

/// Modal bottom sheet for configuring sleep timer presets and custom durations
class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  /// Displays the Sleep Timer bottom sheet modal
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SleepTimerSheet(),
    );
  }

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  double _customMinutes = 20.0;

  static const List<int> _presetMinutes = [5, 10, 15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sleepTimerProvider);
    final timerNotifier = ref.read(sleepTimerProvider.notifier);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xF012121E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1.0),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20.0,
          12.0,
          20.0,
          MediaQuery.of(context).padding.bottom + 20.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Grab Bar
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

            // Header with Icon & Active Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentNeonBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.timer,
                    size: 22,
                    color: AppColors.accentNeonBlue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Timer',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timerState.isActive
                            ? 'Stops playback in ${timerState.formattedCountdown}'
                            : 'Automatically pause playback when you fall asleep',
                        style: AppTypography.bodySmall.copyWith(
                          color: timerState.isActive
                              ? AppColors.accentGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (timerState.isActive)
                  IconButton(
                    icon: const Icon(
                      LucideIcons.circleX,
                      color: AppColors.accentPink,
                      size: 22,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      timerNotifier.cancelTimer();
                    },
                    tooltip: 'Cancel Timer',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Preset Grid
            Text(
              'QUICK PRESETS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ..._presetMinutes.map((mins) {
                  final isSelected = timerState.isActive &&
                      !timerState.stopAfterCurrentTrack &&
                      timerState.activeLabel == '$mins mins';

                  return ExpressiveCard(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      timerNotifier.setTimer(
                        Duration(minutes: mins),
                        label: '$mins mins',
                      );
                      Navigator.pop(context);
                    },
                    borderRadius: AppConstants.roundedSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentNeonBlue
                            : AppColors.darkSurfaceVariant,
                        borderRadius: AppConstants.roundedSmall,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentNeonBlue
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        '$mins min',
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.black
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                // Stop after current track button
                ExpressiveCard(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    timerNotifier.setStopAfterCurrentTrack();
                    Navigator.pop(context);
                  },
                  borderRadius: AppConstants.roundedSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: timerState.stopAfterCurrentTrack
                          ? AppColors.accentGreen
                          : AppColors.darkSurfaceVariant,
                      borderRadius: AppConstants.roundedSmall,
                      border: Border.all(
                        color: timerState.stopAfterCurrentTrack
                            ? AppColors.accentGreen
                            : AppColors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.disc,
                          size: 14,
                          color: timerState.stopAfterCurrentTrack
                              ? Colors.black
                              : AppColors.accentGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'End of song',
                          style: AppTypography.labelMedium.copyWith(
                            color: timerState.stopAfterCurrentTrack
                                ? Colors.black
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Custom Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CUSTOM DURATION',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_customMinutes.toInt()} mins',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.accentNeonBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.accentNeonBlue,
                inactiveTrackColor: AppColors.darkSurfaceVariant,
                thumbColor: AppColors.accentNeonBlue,
                overlayColor: AppColors.accentNeonBlue.withValues(alpha: 0.2),
                trackHeight: 4.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7.0),
              ),
              child: Slider(
                value: _customMinutes,
                min: 5.0,
                max: 120.0,
                divisions: 23,
                onChanged: (val) {
                  setState(() {
                    _customMinutes = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Start Custom Timer Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentNeonBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.roundedSmall,
                ),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                final mins = _customMinutes.toInt();
                timerNotifier.setTimer(
                  Duration(minutes: mins),
                  label: '$mins mins',
                );
                Navigator.pop(context);
              },
              child: Text(
                'Set Timer for ${_customMinutes.toInt()} Minutes',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (timerState.isActive) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentPink,
                  side: const BorderSide(color: AppColors.accentPink),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.roundedSmall,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  timerNotifier.cancelTimer();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel Sleep Timer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
