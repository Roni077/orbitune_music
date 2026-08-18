import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_typography.dart';
import 'expressive_card.dart';

/// Clean Empty State placeholder with icon, message, and action
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    this.icon = LucideIcons.music,
    required this.title,
    required this.message,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkSurfaceVariant,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.accentIndigo, size: 36),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ExpressiveCard(
                onTap: onAction,
                color: AppColors.accentGreen,
                borderRadius: AppConstants.roundedPill,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  buttonText!,
                  style: AppTypography.titleSmall.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
