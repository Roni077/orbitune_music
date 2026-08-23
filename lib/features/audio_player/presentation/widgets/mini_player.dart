import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/screens/full_player_screen.dart';

/// Floating dock MiniPlayer with gesture controls, synchronized playback progress & haptic feedback
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onExpand;

  const MiniPlayer({
    super.key,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);

    if (track == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = ref.watch(isPlayingProvider);
    final isBuffering = ref.watch(isBufferingProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withValues(alpha: 0.92),
        borderRadius: AppConstants.roundedMedium,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppConstants.roundedMedium,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main MiniPlayer Body with Gestures
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (onExpand != null) {
                    onExpand!();
                  } else {
                    FullPlayerScreen.open(context);
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -300) {
                      // Swipe Left -> Skip Next
                      HapticFeedback.mediumImpact();
                      ref.read(playerProvider.notifier).next();
                    } else if (details.primaryVelocity! > 300) {
                      // Swipe Right -> Skip Previous
                      HapticFeedback.mediumImpact();
                      ref.read(playerProvider.notifier).previous();
                    }
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
                  child: Row(
                    children: [
                      // High-Res Artwork
                      ClipRRect(
                        borderRadius: AppConstants.roundedSmall,
                        child: ImageShimmer(
                          imageUrl: track.artworkUrl,
                          width: 44,
                          height: 44,
                          borderRadius: AppConstants.roundedSmall,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Track Title & Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.title,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Previous Track Button
                      IconButton(
                        icon: const Icon(
                          LucideIcons.skipBack,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(playerProvider.notifier).previous();
                        },
                        tooltip: 'Previous',
                      ),

                      // Play / Pause Button with Buffering state
                      IconButton(
                        icon: isBuffering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: AppColors.accentGreen,
                                ),
                              )
                            : Icon(
                                isPlaying ? LucideIcons.pause : LucideIcons.play,
                                size: 22,
                                color: AppColors.textPrimary,
                              ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(playerProvider.notifier).togglePlayPause();
                        },
                        tooltip: isPlaying ? 'Pause' : 'Play',
                      ),

                      // Skip Next Button
                      IconButton(
                        icon: const Icon(
                          LucideIcons.skipForward,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(playerProvider.notifier).next();
                        },
                        tooltip: 'Next',
                      ),
                    ],
                  ),
                ),
              ),

              // Isolated Progress Bar Indicator at bottom edge
              const _MiniPlayerProgressBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isolated progress bar widget that subscribes to position stream without rebuilding MiniPlayer body
class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerPositionProvider);
    final duration = ref.watch(playerDurationProvider);

    final progressRatio = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LinearProgressIndicator(
      value: progressRatio,
      minHeight: 2.5,
      backgroundColor: AppColors.darkSurfaceVariant,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
    );
  }
}
