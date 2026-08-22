import 'package:flutter/material.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Segmented Storage Breakdown Visualizer Widget
class StorageBreakdownBar extends StatelessWidget {
  final double offlineSongsMb;
  final double audioCacheMb;
  final double lyricsSearchCacheMb;
  final double imageCacheMb;
  final double totalDeviceStorageGb;
  final double freeDeviceStorageGb;

  const StorageBreakdownBar({
    super.key,
    this.offlineSongsMb = 142.5,
    this.audioCacheMb = 230.0,
    this.lyricsSearchCacheMb = 18.4,
    this.imageCacheMb = 64.2,
    this.totalDeviceStorageGb = 128.0,
    this.freeDeviceStorageGb = 45.8,
  });

  @override
  Widget build(BuildContext context) {
    final totalOrbituneMb =
        offlineSongsMb + audioCacheMb + lyricsSearchCacheMb + imageCacheMb;

    final offlineRatio = totalOrbituneMb > 0 ? offlineSongsMb / totalOrbituneMb : 0.0;
    final audioRatio = totalOrbituneMb > 0 ? audioCacheMb / totalOrbituneMb : 0.0;
    final imageRatio = totalOrbituneMb > 0 ? imageCacheMb / totalOrbituneMb : 0.0;
    final cacheRatio = totalOrbituneMb > 0 ? lyricsSearchCacheMb / totalOrbituneMb : 0.0;

    return ExpressiveCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orbitune Footprint',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${totalOrbituneMb.toStringAsFixed(1)} MB used',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (offlineRatio > 0)
                    Expanded(
                      flex: (offlineRatio * 1000).toInt().clamp(1, 1000),
                      child: Container(color: AppColors.accentPurple),
                    ),
                  if (audioRatio > 0)
                    Expanded(
                      flex: (audioRatio * 1000).toInt().clamp(1, 1000),
                      child: Container(color: AppColors.accentCyan),
                    ),
                  if (imageRatio > 0)
                    Expanded(
                      flex: (imageRatio * 1000).toInt().clamp(1, 1000),
                      child: Container(color: AppColors.accentPink),
                    ),
                  if (cacheRatio > 0)
                    Expanded(
                      flex: (cacheRatio * 1000).toInt().clamp(1, 1000),
                      child: Container(color: AppColors.accentYellow),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend Items Wrap
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                AppColors.accentPurple,
                'Offline Songs',
                '${offlineSongsMb.toStringAsFixed(1)} MB',
              ),
              _buildLegendItem(
                AppColors.accentCyan,
                'Audio Cache',
                '${audioCacheMb.toStringAsFixed(1)} MB',
              ),
              _buildLegendItem(
                AppColors.accentPink,
                'Artwork Cache',
                '${imageCacheMb.toStringAsFixed(1)} MB',
              ),
              _buildLegendItem(
                AppColors.accentYellow,
                'Search & Lyrics',
                '${lyricsSearchCacheMb.toStringAsFixed(1)} MB',
              ),
            ],
          ),
          const Divider(color: AppColors.glassBorder, height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Free Device Space',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${freeDeviceStorageGb.toStringAsFixed(1)} GB free of ${totalDeviceStorageGb.toStringAsFixed(0)} GB',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
