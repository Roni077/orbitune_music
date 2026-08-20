import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/search/presentation/providers/search_provider.dart';

/// Horizontal M3 Expressive filter bars for Streaming Source & Media Category
class FilterSourceBar extends StatelessWidget {
  final SearchSourceFilter selectedSource;
  final SearchCategoryFilter selectedCategory;
  final ValueChanged<SearchSourceFilter> onSourceChanged;
  final ValueChanged<SearchCategoryFilter> onCategoryChanged;
  final bool showCategories;

  const FilterSourceBar({
    super.key,
    required this.selectedSource,
    required this.selectedCategory,
    required this.onSourceChanged,
    required this.onCategoryChanged,
    this.showCategories = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Source Filters Row (All / YouTube Music / Extractor)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildSourceChip(
                filter: SearchSourceFilter.all,
                icon: LucideIcons.layers,
              ),
              const SizedBox(width: 8),
              _buildSourceChip(
                filter: SearchSourceFilter.youTube,
                icon: LucideIcons.playCircle,
                accentColor: const Color(0xFFFF4D4D),
              ),
              const SizedBox(width: 8),
              _buildSourceChip(
                filter: SearchSourceFilter.extractor,
                icon: LucideIcons.link,
                accentColor: AppColors.accentGreen,
              ),
            ],
          ),
        ),

        // 2. Media Type Category Filter (Top Results / Songs / Artists / Albums / Playlists)
        if (showCategories) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildCategoryChip(
                  filter: SearchCategoryFilter.all,
                  icon: LucideIcons.sparkles,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  filter: SearchCategoryFilter.songs,
                  icon: LucideIcons.music,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  filter: SearchCategoryFilter.artists,
                  icon: LucideIcons.user,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  filter: SearchCategoryFilter.albums,
                  icon: LucideIcons.disc,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  filter: SearchCategoryFilter.playlists,
                  icon: LucideIcons.listMusic,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceChip({
    required SearchSourceFilter filter,
    required IconData icon,
    Color? accentColor,
  }) {
    final isSelected = selectedSource == filter;
    final activeColor = accentColor ?? AppColors.accentGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedPill,
        onTap: () {
          HapticFeedback.selectionClick();
          onSourceChanged(filter);
        },
        child: AnimatedContainer(
          duration: AppConstants.fastAnimation,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.16)
                : AppColors.darkSurfaceVariant.withValues(alpha: 0.6),
            borderRadius: AppConstants.roundedPill,
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.8)
                  : AppColors.glassBorder.withValues(alpha: 0.5),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                filter.label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required SearchCategoryFilter filter,
    required IconData icon,
  }) {
    final isSelected = selectedCategory == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedPill,
        onTap: () {
          HapticFeedback.selectionClick();
          onCategoryChanged(filter);
        },
        child: AnimatedContainer(
          duration: AppConstants.fastAnimation,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.darkSurfaceElevated
                : Colors.transparent,
            borderRadius: AppConstants.roundedPill,
            border: Border.all(
              color: isSelected
                  ? AppColors.textSecondary
                  : AppColors.glassBorder.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                filter.label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
