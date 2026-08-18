import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// 2x3 Quick Picks launch grid for quick access to recently played & top recommended tracks
class QuickPicksGrid extends StatelessWidget {
  final List<Track> tracks;
  final ValueChanged<Track> onTrackTap;
  final String? activeTrackId;
  final bool isPlaying;

  const QuickPicksGrid({
    super.key,
    required this.tracks,
    required this.onTrackTap,
    this.activeTrackId,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    // Show up to 6 tracks in 2 rows of 3
    final displayTracks = tracks.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          mainAxisExtent: 56.0,
        ),
        itemCount: displayTracks.length,
        itemBuilder: (context, index) {
          final track = displayTracks[index];
          final isCurrent = track.id == activeTrackId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppConstants.roundedSmall,
              onTap: () {
                HapticFeedback.lightImpact();
                onTrackTap(track);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.accentGreen.withValues(alpha: 0.12)
                      : AppColors.darkSurfaceVariant,
                  borderRadius: AppConstants.roundedSmall,
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.accentGreen.withValues(alpha: 0.5)
                        : AppColors.divider,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        bottomLeft: Radius.circular(8.0),
                      ),
                      child: ImageShimmer(
                        imageUrl: track.artworkUrl,
                        width: 54,
                        height: 54,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Title & Artist
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.title,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 12.5,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                color: isCurrent ? AppColors.accentGreen : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Mini Play indicator / icon
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        isCurrent && isPlaying ? LucideIcons.volume2 : LucideIcons.play,
                        size: 16,
                        color: isCurrent ? AppColors.accentGreen : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
