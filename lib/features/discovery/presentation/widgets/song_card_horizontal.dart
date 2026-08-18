import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/audio_badge.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Material 3 Expressive rounded card for horizontally scrolling items
class SongCardHorizontal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final double width;
  final double imageHeight;
  final bool isPlaying;
  final bool isCurrent;
  final AudioBadgeType? badgeType;

  const SongCardHorizontal({
    super.key,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    required this.onTap,
    this.onPlayTap,
    this.width = 140.0,
    this.imageHeight = 140.0,
    this.isPlaying = false,
    this.isCurrent = false,
    this.badgeType,
  });

  factory SongCardHorizontal.fromTrack({
    required Track track,
    required VoidCallback onTap,
    VoidCallback? onPlayTap,
    bool isPlaying = false,
    bool isCurrent = false,
    double width = 140.0,
  }) {
    return SongCardHorizontal(
      title: track.title,
      subtitle: track.artist,
      artworkUrl: track.highResArtworkUrl ?? track.artworkUrl,
      onTap: onTap,
      onPlayTap: onPlayTap,
      isPlaying: isPlaying,
      isCurrent: isCurrent,
      width: width,
      badgeType: track.source == 'jiosaavn'
          ? AudioBadgeType.highQuality320
          : (track.source == 'youtube' ? AudioBadgeType.youtube : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Artwork Container with Spring Touch
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppConstants.roundedMedium,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Stack(
                children: [
                  // Image
                  ImageShimmer(
                    imageUrl: artworkUrl,
                    width: width,
                    height: imageHeight,
                    borderRadius: AppConstants.roundedMedium,
                  ),

                  // Subtle dark gradient at the bottom of the image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppConstants.roundedMedium,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Optional Badge on top left
                  if (badgeType != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: AudioBadge(type: badgeType!),
                    ),

                  // Play Button on bottom right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (onPlayTap != null) {
                          onPlayTap!();
                        } else {
                          onTap();
                        }
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isCurrent && isPlaying
                              ? AppColors.accentGreen
                              : Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent ? AppColors.accentGreen : AppColors.divider,
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isCurrent && isPlaying ? LucideIcons.pause : LucideIcons.play,
                            size: 15,
                            color: isCurrent && isPlaying ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              color: isCurrent ? AppColors.accentGreen : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
