import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Reusable Material 3 Expressive Settings Tile
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry? contentPadding;
  final Color? titleColor;
  final Color? subtitleColor;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.contentPadding,
    this.titleColor,
    this.subtitleColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconBg = iconBgColor ?? iconColor.withValues(alpha: 0.15);
    final effectiveTitleColor = isDestructive
        ? AppColors.accentPink
        : (titleColor ?? AppColors.textPrimary);
    final effectiveSubtitleColor =
        subtitleColor ?? AppColors.textSecondary;

    return ListTile(
      contentPadding: contentPadding ?? EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveIconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: effectiveTitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.accentGreen).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (badgeColor ?? AppColors.accentGreen).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                badgeText!,
                style: AppTypography.labelSmall.copyWith(
                  color: badgeColor ?? AppColors.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: effectiveSubtitleColor,
                ),
              ),
            )
          : null,
      trailing: trailing ??
          (showChevron || onTap != null
              ? const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textTertiary,
                )
              : null),
    );
  }
}
