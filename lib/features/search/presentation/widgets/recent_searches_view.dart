import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Search history chips & curated trending search tags view
class RecentSearchesView extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onSelectQuery;
  final ValueChanged<String> onDeleteQuery;
  final VoidCallback onClearAll;

  static const List<String> trendingKeywords = [
    'Arijit Singh',
    'Taylor Swift',
    'Anirudh Ravichander',
    'Top 50 Global',
    'Karan Aujla',
    'Lofi Chillout',
    'Coldplay',
    'Bollywood 2026',
    'Shreya Ghoshal',
    'Synthwave & Retrowave',
    'AP Dhillon',
    'Deep Focus Study',
  ];

  const RecentSearchesView({
    super.key,
    required this.recentSearches,
    required this.onSelectQuery,
    required this.onDeleteQuery,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 32.0),
      children: [
        // 1. Recent Searches Section (if any history exists)
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onClearAll();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear All',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: recentSearches.map((query) {
              return _buildHistoryChip(query);
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],

        // 2. Trending Music Searches / Discover Tags
        Row(
          children: [
            const Icon(
              LucideIcons.flame,
              size: 18,
              color: Color(0xFFFF7A00),
            ),
            const SizedBox(width: 8),
            Text(
              'Trending Searches',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: trendingKeywords.map((tag) {
            return _buildTrendingChip(tag);
          }).toList(),
        ),

        const SizedBox(height: 28),

        // 3. Search Tips & Direct URL hints
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
            borderRadius: AppConstants.roundedLarge,
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: AppColors.accentIndigo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search Anywhere',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type song names, artists, or paste YouTube and online media links directly into the search bar for instant extraction & high-fidelity streaming.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryChip(String query) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedPill,
        onTap: () {
          HapticFeedback.lightImpact();
          onSelectQuery(query);
        },
        child: Container(
          padding: const EdgeInsets.only(left: 12.0, right: 6.0, top: 6.0, bottom: 6.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: AppConstants.roundedPill,
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.history,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  query,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDeleteQuery(query);
                },
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: const Icon(
                    LucideIcons.x,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingChip(String tag) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedPill,
        onTap: () {
          HapticFeedback.lightImpact();
          onSelectQuery(tag);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceVariant.withValues(alpha: 0.7),
            borderRadius: AppConstants.roundedPill,
            border: Border.all(
              color: AppColors.glassBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.search,
                size: 12,
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
