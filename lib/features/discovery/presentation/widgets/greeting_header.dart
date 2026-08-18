import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/theme/theme_provider.dart';

/// Top greeting header with brand title, time-aware greeting, and quick action icons
class GreetingHeader extends ConsumerWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;

  const GreetingHeader({
    super.key,
    this.onSearchTap,
    this.onSettingsTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening';
    } else {
      return 'Late Night Beats';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting & App Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Orbitune',
                  style: AppTypography.brandTitle.copyWith(
                    fontSize: 28,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Action Icons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search shortcut
              IconButton(
                icon: const Icon(LucideIcons.search, size: 22),
                color: AppColors.textPrimary,
                tooltip: 'Search',
                onPressed: onSearchTap,
              ),

              // Theme Switcher Button
              IconButton(
                icon: Icon(
                  themeNotifier.isDarkMode ? LucideIcons.sunMedium : LucideIcons.moon,
                  size: 22,
                ),
                color: AppColors.textPrimary,
                tooltip: 'Switch Theme',
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),

              // Settings / Profile avatar
              IconButton(
                icon: const Icon(LucideIcons.settings, size: 22),
                color: AppColors.textPrimary,
                tooltip: 'Settings',
                onPressed: onSettingsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
