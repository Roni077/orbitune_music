import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Live interactive Material 3 Expressive Component Preview for theme & appearance settings
class LiveThemePreview extends StatelessWidget {
  final String themeMode;
  final int accentColorIndex;
  final double cornerRadius;
  final bool enableGlassmorphism;
  final bool showBitrateBadge;

  const LiveThemePreview({
    super.key,
    required this.themeMode,
    required this.accentColorIndex,
    this.cornerRadius = 20.0,
    this.enableGlassmorphism = true,
    this.showBitrateBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = (accentColorIndex >= 0 && accentColorIndex < AppColors.accentPalette.length)
        ? AppColors.accentPalette[accentColorIndex]
        : AppColors.accentGreen;

    final isOled = themeMode == 'oled';
    final isLight = themeMode == 'light';
    final isSolarized = themeMode == 'solarized';
    final isCyberpunk = themeMode == 'cyberpunk';

    Color cardBg;
    Color previewBg;
    Color textColor;
    Color subtitleColor;

    if (isOled) {
      previewBg = const Color(0xFF000000);
      cardBg = const Color(0xFF0E0E12);
      textColor = const Color(0xFFF8FAFC);
      subtitleColor = const Color(0xFF94A3B8);
    } else if (isLight) {
      previewBg = const Color(0xFFF1F5F9);
      cardBg = const Color(0xFFFFFFFF);
      textColor = const Color(0xFF0F172A);
      subtitleColor = const Color(0xFF64748B);
    } else if (isSolarized) {
      previewBg = const Color(0xFF14120E);
      cardBg = const Color(0xFF1E1A16);
      textColor = const Color(0xFFEDE0D4);
      subtitleColor = const Color(0xFFB5A599);
    } else if (isCyberpunk) {
      previewBg = const Color(0xFF08090E);
      cardBg = const Color(0xFF0F111A);
      textColor = const Color(0xFFE2E8F0);
      subtitleColor = const Color(0xFF94A3B8);
    } else {
      previewBg = const Color(0xFF0B0B14);
      cardBg = const Color(0xFF1E1E38);
      textColor = const Color(0xFFF8FAFC);
      subtitleColor = const Color(0xFF94A3B8);
    }

    return Container(
      decoration: BoxDecoration(
        color: previewBg,
        borderRadius: BorderRadius.circular(cornerRadius.clamp(8.0, 28.0)),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE PREVIEW',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (showBitrateBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Text(
                    '320k Opus',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Player Component Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(cornerRadius.clamp(8.0, 20.0)),
              border: Border.all(
                color: enableGlassmorphism
                    ? accent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Artwork Mockup
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius.clamp(6.0, 14.0)),
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.music, size: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),

                // Track title & artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Midnight Odyssey',
                        style: AppTypography.titleSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Orbitune Soundscape',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Playback button mockup
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.play_arrow_rounded, size: 22, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Progress Bar Slider Preview
          Row(
            children: [
              Text(
                '1:42',
                style: AppTypography.caption.copyWith(color: subtitleColor, fontSize: 10),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.45,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '3:50',
                style: AppTypography.caption.copyWith(color: subtitleColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Chips Preview
          Row(
            children: [
              _buildChip(
                label: 'Equalizer ON',
                icon: LucideIcons.slidersHorizontal,
                color: accent,
                isSelected: true,
                radius: cornerRadius,
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'AutoPlay',
                icon: LucideIcons.sparkles,
                color: accent,
                isSelected: false,
                textColor: subtitleColor,
                radius: cornerRadius,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    Color? textColor,
    required double radius,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(radius.clamp(6.0, 999.0)),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isSelected ? color : textColor ?? Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? color : textColor ?? Colors.white70,
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
