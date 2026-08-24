import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.toLowerCase() == selectedFilter.toLowerCase();

          return FilterChip(
            label: Text(
              filter,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (selected) {
              HapticFeedback.selectionClick();
              onFilterSelected(filter);
            },
            selectedColor: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.25),
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
