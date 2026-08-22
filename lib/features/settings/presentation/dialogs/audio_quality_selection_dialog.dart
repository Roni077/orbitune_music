import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';

/// Material 3 Expressive Selection Sheet & Dialog for Streaming and Download Audio Quality
class AudioQualitySelectionSheet extends StatelessWidget {
  final AudioQuality currentQuality;
  final ValueChanged<AudioQuality> onQualitySelected;
  final bool isDownload;

  const AudioQualitySelectionSheet({
    super.key,
    required this.currentQuality,
    required this.onQualitySelected,
    this.isDownload = false,
  });

  /// Presents the Audio Quality selection as a Material 3 Expressive Modal Bottom Sheet
  static Future<AudioQuality?> show(
    BuildContext context, {
    required AudioQuality currentQuality,
    required ValueChanged<AudioQuality> onQualitySelected,
    bool isDownload = false,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<AudioQuality>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudioQualitySelectionSheet(
        currentQuality: currentQuality,
        onQualitySelected: onQualitySelected,
        isDownload: isDownload,
      ),
    );
  }

  /// Presents the Audio Quality selection as an AlertDialog
  static Future<AudioQuality?> showAsDialog(
    BuildContext context, {
    required AudioQuality currentQuality,
    required ValueChanged<AudioQuality> onQualitySelected,
    bool isDownload = false,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<AudioQuality>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: AppColors.darkSurfaceElevated,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _AudioQualityContent(
                currentQuality: currentQuality,
                isDownload: isDownload,
                onSelect: (q) {
                  onQualitySelected(q);
                  Navigator.of(context).pop(q);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
          left: BorderSide(color: AppColors.glassBorder, width: 0.5),
          right: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              _AudioQualityContent(
                currentQuality: currentQuality,
                isDownload: isDownload,
                onSelect: (q) {
                  onQualitySelected(q);
                  Navigator.of(context).pop(q);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioQualityContent extends StatelessWidget {
  final AudioQuality currentQuality;
  final bool isDownload;
  final ValueChanged<AudioQuality> onSelect;

  const _AudioQualityContent({
    required this.currentQuality,
    required this.isDownload,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final title = isDownload ? 'Download Quality' : 'Streaming Quality';
    final subtitle = isDownload
        ? 'Choose offline audio fidelity and storage footprint per song'
        : 'Choose audio playback fidelity and mobile data usage';
    final headerIcon = isDownload ? LucideIcons.downloadCloud : LucideIcons.radio;
    final headerColor = isDownload ? AppColors.accentGreen : AppColors.accentCyan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: headerColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(headerIcon, color: headerColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Quality Options List (Reversed to show highest fidelity first)
        ...[
          AudioQuality.lossless,
          AudioQuality.high320k,
          AudioQuality.medium160k,
          AudioQuality.low96k,
        ].map((quality) {
          final isSelected = quality == currentQuality;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _QualityOptionCard(
              quality: quality,
              isSelected: isSelected,
              isDownload: isDownload,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(quality);
              },
            ),
          );
        }),
      ],
    );
  }
}

class _QualityOptionCard extends StatelessWidget {
  final AudioQuality quality;
  final bool isSelected;
  final bool isDownload;
  final VoidCallback onTap;

  const _QualityOptionCard({
    required this.quality,
    required this.isSelected,
    required this.isDownload,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _getQualitySpec(quality, isDownload);

    return ExpressiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14.0),
      borderRadius: BorderRadius.circular(18),
      color: isSelected
          ? spec.accentColor.withValues(alpha: 0.12)
          : AppColors.darkSurfaceVariant.withValues(alpha: 0.45),
      borderColor: isSelected
          ? spec.accentColor
          : AppColors.glassBorder.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? spec.accentColor.withValues(alpha: 0.22)
                  : AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? spec.accentColor
                    : AppColors.glassBorder,
                width: 1,
              ),
            ),
            child: Icon(
              spec.icon,
              size: 20,
              color: isSelected ? spec.accentColor : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        spec.title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? spec.accentColor
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bitrate / Format Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: spec.accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: spec.accentColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        spec.badgeText,
                        style: AppTypography.labelSmall.copyWith(
                          color: spec.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  spec.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                // Estimation Tag (Data rate or file size)
                Row(
                  children: [
                    Icon(
                      isDownload ? LucideIcons.hardDrive : LucideIcons.activity,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      spec.metricText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Radio Selection Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? spec.accentColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? spec.accentColor : AppColors.textMuted,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: spec.accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    LucideIcons.check,
                    size: 14,
                    color: Colors.black,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  _QualitySpec _getQualitySpec(AudioQuality quality, bool isDownload) {
    switch (quality) {
      case AudioQuality.lossless:
        return _QualitySpec(
          title: 'Lossless Studio Audio',
          badgeText: 'FLAC 1411k',
          description: isDownload
              ? 'Studio master quality bit-perfect uncompressed FLAC'
              : 'Bit-perfect uncompressed audio for audiophile DACs & Wi-Fi',
          metricText: isDownload ? '~35 MB / song' : '~10.5 MB / min data',
          icon: LucideIcons.sparkles,
          accentColor: AppColors.accentCyan,
        );
      case AudioQuality.high320k:
        return _QualitySpec(
          title: 'Ultra High Definition',
          badgeText: '320 KBPS',
          description: isDownload
              ? 'Exceptional clarity and punch with compact file storage'
              : 'Crisp dynamic range & studio clarity with Opus compression',
          metricText: isDownload ? '~8 MB / song' : '~2.4 MB / min data',
          icon: LucideIcons.zap,
          accentColor: AppColors.accentGreen,
        );
      case AudioQuality.medium160k:
        return _QualitySpec(
          title: 'High Definition',
          badgeText: '160 KBPS',
          description: isDownload
              ? 'Balanced audio quality with minimal disk storage'
              : 'Great clarity optimized for everyday cellular streaming',
          metricText: isDownload ? '~4 MB / song' : '~1.2 MB / min data',
          icon: LucideIcons.music,
          accentColor: AppColors.accentIndigo,
        );
      case AudioQuality.low96k:
        return _QualitySpec(
          title: 'Data Saver',
          badgeText: '96 KBPS',
          description: isDownload
              ? 'Maximum storage savings, stores thousands of songs'
              : 'Ultra-lightweight audio stream for low bandwidth & data caps',
          metricText: isDownload ? '~2.5 MB / song' : '~0.7 MB / min data',
          icon: LucideIcons.leaf,
          accentColor: AppColors.accentAmber,
        );
    }
  }
}

class _QualitySpec {
  final String title;
  final String badgeText;
  final String description;
  final String metricText;
  final IconData icon;
  final Color accentColor;

  const _QualitySpec({
    required this.title,
    required this.badgeText,
    required this.description,
    required this.metricText,
    required this.icon,
    required this.accentColor,
  });
}
