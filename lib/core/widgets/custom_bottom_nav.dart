import 'dart:ui';
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

/// Material 3 Expressive Floating Frosted Bottom Navigation Bar
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
      height: 64.0,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16.0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return _buildNavItem(context, index, item, isSelected);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, CustomBottomNavItem item, bool isSelected) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          onTabSelected(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimation,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          border: isSelected
              ? Border.all(
                  color: primary.withValues(alpha: 0.35),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 21,
              color: isSelected ? primary : onSurfaceVariant,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: AppTypography.bodySmall.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
