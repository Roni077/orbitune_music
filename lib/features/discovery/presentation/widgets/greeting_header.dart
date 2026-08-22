import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// Top greeting header with brand title, time-aware greeting, and quick action icons
class GreetingHeader extends ConsumerWidget {
  final VoidCallback? onSettingsTap;

  const GreetingHeader({
    super.key,
    this.onSettingsTap,
  });

  String _getGreeting(String username) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Late Night Beats';
    }
    
    if (username.isNotEmpty && username != 'Music Lover') {
      return '$greeting, $username';
    }
    return greeting;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final username = settings.username ?? '';

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
                  _getGreeting(username),
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
          // Actions
          if (onSettingsTap != null)
            GestureDetector(
              onTap: onSettingsTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      (settings.avatarColorIndex >= 0 &&
                              settings.avatarColorIndex < AppColors.accentPalette.length)
                          ? AppColors.accentPalette[settings.avatarColorIndex]
                          : AppColors.accentGreen,
                      ((settings.avatarColorIndex >= 0 &&
                              settings.avatarColorIndex < AppColors.accentPalette.length)
                          ? AppColors.accentPalette[settings.avatarColorIndex]
                          : AppColors.accentGreen).withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ((settings.avatarColorIndex >= 0 &&
                              settings.avatarColorIndex < AppColors.accentPalette.length)
                          ? AppColors.accentPalette[settings.avatarColorIndex]
                          : AppColors.accentGreen).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getAvatarIcon(settings.avatarIcon),
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getAvatarIcon(String? iconName) {
    switch (iconName) {
      case 'headphones':
        return LucideIcons.headphones;
      case 'music':
        return LucideIcons.music;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'disc':
        return LucideIcons.disc;
      case 'flame':
        return LucideIcons.flame;
      case 'heart':
        return LucideIcons.heart;
      case 'zap':
        return LucideIcons.zap;
      case 'rocket':
        return LucideIcons.rocket;
      case 'star':
        return LucideIcons.star;
      case 'radio':
        return LucideIcons.radio;
      case 'mic':
        return LucideIcons.mic;
      case 'user':
      default:
        return LucideIcons.user;
    }
  }
}
