import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';

/// Fullscreen player control bar featuring normalized playback buttons, skips, seeks, shuffle and loop modes
class PlayerControls extends ConsumerWidget {
  final Color? primaryColor;

  const PlayerControls({
    super.key,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final isBuffering = ref.watch(isBufferingProvider);
    final playbackMode = ref.watch(playbackModeProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final primary = primaryColor ?? AppColors.accentGreen;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle Toggle Button
        IconButton(
          icon: Icon(
            LucideIcons.shuffle,
            size: 20,
            color: playbackMode.isShuffle
                ? primary
                : AppColors.textMuted,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            final nextMode = playbackMode == PlaybackMode.shuffle
                ? PlaybackMode.off
                : PlaybackMode.shuffle;
            playerNotifier.setPlaybackMode(nextMode);
          },
          tooltip: 'Shuffle',
        ),

        // Skip Previous
        IconButton(
          icon: const Icon(
            LucideIcons.skipBack,
            size: 26,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            playerNotifier.previous();
          },
          tooltip: 'Previous',
        ),

        // 10s Rewind
        IconButton(
          icon: const Icon(
            LucideIcons.rotateCcw,
            size: 19,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            playerNotifier.seekBackward(offset: const Duration(seconds: 10));
          },
          tooltip: 'Rewind 10s',
        ),

        // Expressive Morphing Play / Pause Button (Standard 58x58 dimension)
        ExpressiveCard(
          onTap: () {
            HapticFeedback.mediumImpact();
            playerNotifier.togglePlayPause();
          },
          borderRadius: BorderRadius.circular(29),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isBuffering
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Icon(
                      isPlaying ? LucideIcons.pause : LucideIcons.play,
                      size: 28,
                      color: Colors.black,
                    ),
            ),
          ),
        ),

        // 10s Fast-Forward
        IconButton(
          icon: const Icon(
            LucideIcons.rotateCw,
            size: 19,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            playerNotifier.seekForward(offset: const Duration(seconds: 10));
          },
          tooltip: 'Forward 10s',
        ),

        // Skip Next
        IconButton(
          icon: const Icon(
            LucideIcons.skipForward,
            size: 26,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            playerNotifier.next();
          },
          tooltip: 'Next',
        ),

        // Repeat Mode Cycle Button
        IconButton(
          icon: _buildRepeatIcon(playbackMode, primary),
          onPressed: () {
            HapticFeedback.selectionClick();
            playerNotifier.cyclePlaybackMode();
          },
          tooltip: 'Repeat',
        ),
      ],
    );
  }

  Widget _buildRepeatIcon(PlaybackMode mode, Color activeColor) {
    switch (mode) {
      case PlaybackMode.repeatOne:
        return Icon(
          LucideIcons.repeat1,
          size: 20,
          color: activeColor,
        );
      case PlaybackMode.repeatAll:
        return Icon(
          LucideIcons.repeat,
          size: 20,
          color: activeColor,
        );
      case PlaybackMode.off:
      case PlaybackMode.shuffle:
        return const Icon(
          LucideIcons.repeat,
          size: 20,
          color: AppColors.textMuted,
        );
    }
  }
}
