import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Horizontal filter chip selector for genres, languages, and moods
class TrendingChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final List<String> filters;

  const TrendingChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.filters = const [
      'All',
      'Hindi',
      'English',
      'Punjabi',
      'Pop',
      'Lo-Fi',
      'Hip-Hop',
      'Chill',
      'Workout',
      'Party',
      'Romance',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.toLowerCase() == selectedFilter.toLowerCase();

          return AnimatedContainer(
            duration: AppConstants.fastAnimation,
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppConstants.roundedLarge,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onFilterSelected(filter);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.darkSurfaceVariant,
                    borderRadius: AppConstants.roundedLarge,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGreen
                          : AppColors.divider,
                      width: 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
