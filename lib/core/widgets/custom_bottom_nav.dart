import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Item definition for custom bottom navigation
class CustomBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const CustomBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Material 3 Solid Floating Bottom Navigation Bar
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<CustomBottomNavItem> items;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.items = const [
      CustomBottomNavItem(
        icon: LucideIcons.house,
        activeIcon: LucideIcons.house,
        label: 'Home',
      ),
      CustomBottomNavItem(
        icon: LucideIcons.search,
        activeIcon: LucideIcons.search,
        label: 'Search',
      ),
      CustomBottomNavItem(
        icon: LucideIcons.library,
        activeIcon: LucideIcons.library,
        label: 'Library',
      ),
      CustomBottomNavItem(
        icon: LucideIcons.settings,
        activeIcon: LucideIcons.settings,
        label: 'Settings',
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        height: 64.0,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(32.0),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.selectionClick();
                        onTabSelected(index);
                      }
                    },
                    borderRadius: BorderRadius.circular(26.0),
                    child: Center(
                      child: AnimatedContainer(
                        duration: AppConstants.fastAnimation,
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 16.0 : 8.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24.0),
                          border: isSelected
                              ? Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.40),
                                  width: 1.0,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                              size: 20,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 7),
                              Text(
                                item.label,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
