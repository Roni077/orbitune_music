import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';

/// Circular avatar card for Popular Artists section
class ArtistAvatarCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback onTap;
  final double radius;

  const ArtistAvatarCard({
    super.key,
    required this.artist,
    required this.onTap,
    this.radius = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = artist.avatarUrl ?? artist.bannerUrl;

    return SizedBox(
      width: radius * 2 + 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Container(
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: ImageShimmer(
                    imageUrl: avatarUrl,
                    width: radius * 2,
                    height: radius * 2,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Artist Name
          Text(
            artist.name,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Subtitle (Fans or 'Artist')
          Text(
            artist.fansCount > 0
                ? '${Formatters.formatPlayCount(artist.fansCount)} fans'
                : 'Artist',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
