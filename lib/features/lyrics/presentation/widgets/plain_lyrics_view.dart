import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Static plain text lyrics view with copy to clipboard functionality
class PlainLyricsView extends StatelessWidget {
  final String lyrics;
  final double fontSize;
  final EdgeInsets? padding;

  const PlainLyricsView({
    super.key,
    required this.lyrics,
    this.fontSize = 18.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: SelectableText(
            lyrics,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              fontFamily: AppTypography.fontFamilyBody,
              color: AppColors.textPrimary,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // Floating Copy Button
        Positioned(
          top: 12,
          right: 16,
          child: ExpressiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: lyrics));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lyrics copied to clipboard'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: AppConstants.roundedSmall,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated.withValues(alpha: 0.85),
                borderRadius: AppConstants.roundedSmall,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.copy,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
