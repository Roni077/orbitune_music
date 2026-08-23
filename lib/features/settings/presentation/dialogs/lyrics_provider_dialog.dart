import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Lyrics and Metadata Provider Spec
class LyricsProviderInfo {
  final String key;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color accentColor;
  final IconData icon;
  final List<String> features;

  const LyricsProviderInfo({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.accentColor,
    required this.icon,
    required this.features,
  });
}

/// Material 3 Expressive Selection Dialog for Lyrics & Metadata Providers
class LyricsProviderSelectionDialog extends StatelessWidget {
  final String currentProviderKey;
  final ValueChanged<String> onProviderSelected;

  const LyricsProviderSelectionDialog({
    super.key,
    required this.currentProviderKey,
    required this.onProviderSelected,
  });

  static const List<LyricsProviderInfo> providers = [
    LyricsProviderInfo(
      key: 'lrclib',
      title: 'LRCLIB Cloud Lyrics',
      subtitle:
          'Real-time word-by-word and line-synchronized lyrics from the global open lyrics archive.',
      badgeText: 'RECOMMENDED',
      accentColor: AppColors.accentGreen,
      icon: LucideIcons.sparkles,
      features: [
        'Word-by-Word Sync',
        'Millisecond Timecodes',
        'Auto Match',
        'Open Cloud API',
      ],
    ),
    LyricsProviderInfo(
      key: 'embedded',
      title: 'Embedded Tags & Local LRC',
      subtitle:
          'Extract synchronized lyrics from audio metadata (ID3v2 SYLT/USLT, Vorbis comments) and local .lrc sidecars.',
      badgeText: 'OFFLINE FIRST',
      accentColor: AppColors.accentCyan,
      icon: LucideIcons.fileAudio,
      features: [
        '100% Offline',
        'Zero Cellular Data',
        'ID3v2 Tags',
        'Local .lrc Files',
      ],
    ),
    LyricsProviderInfo(
      key: 'genius_netease',
      title: 'Genius & NetEase Cloud',
      subtitle:
          'Crowdsourced annotations, multi-lingual romanized phonetics (Romaji/Pinyin/Hangul), and translated lyrics.',
      badgeText: 'MULTI-LANGUAGE',
      accentColor: AppColors.accentPurple,
      icon: LucideIcons.languages,
      features: [
        'Romanization',
        'Lyric Translations',
        'Verified Annotations',
        'Global Hits',
      ],
    ),
    LyricsProviderInfo(
      key: 'ai_alignment',
      title: 'Orbitune AI Neural Timecoder',
      subtitle:
          'On-device neural speech-to-lyric aligner that automatically generates synced timestamps for plain unsynced text.',
      badgeText: 'EXPERIMENTAL AI',
      accentColor: AppColors.accentPink,
      icon: LucideIcons.bot,
      features: [
        'On-Device Neural Net',
        'Plain-to-Synced Sync',
        'Adaptive Alignment',
        'Fast Cache',
      ],
    ),
  ];

  static LyricsProviderInfo getInfo(String key) {
    return providers.firstWhere(
      (p) => p.key == key,
      orElse: () => providers.first,
    );
  }

  /// Shows the Lyrics Provider Selection Dialog
  static Future<String?> show(
    BuildContext context, {
    required String currentProviderKey,
    required ValueChanged<String> onProviderSelected,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: _LyricsProviderContent(
                currentProviderKey: currentProviderKey,
                onSelect: (k) {
                  onProviderSelected(k);
                  Navigator.of(ctx).pop(k);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the dialog version
  static Future<String?> showAsDialog(
    BuildContext context, {
    required String currentProviderKey,
    required ValueChanged<String> onProviderSelected,
  }) =>
      show(
        context,
        currentProviderKey: currentProviderKey,
        onProviderSelected: onProviderSelected,
      );

  @override
  Widget build(BuildContext context) {
    return _LyricsProviderContent(
      currentProviderKey: currentProviderKey,
      onSelect: onProviderSelected,
    );
  }
}

/// Backward compatibility alias
typedef LyricsProviderSelectionSheet = LyricsProviderSelectionDialog;

class _LyricsProviderContent extends StatelessWidget {
  final String currentProviderKey;
  final ValueChanged<String> onSelect;

  const _LyricsProviderContent({
    required this.currentProviderKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentYellow.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                LucideIcons.mic,
                color: AppColors.accentYellow,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lyrics & Metadata Engine',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Choose provider for synchronized lyric scroll and track tags',
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

        // Providers List
        ...LyricsProviderSelectionDialog.providers.map((provider) {
          final isSelected = provider.key == currentProviderKey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _ProviderCard(
              provider: provider,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(provider.key);
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final LyricsProviderInfo provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14.0),
      borderRadius: BorderRadius.circular(18),
      color: isSelected
          ? provider.accentColor.withValues(alpha: 0.12)
          : AppColors.darkSurfaceVariant.withValues(alpha: 0.45),
      borderColor: isSelected
          ? provider.accentColor
          : AppColors.glassBorder.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? provider.accentColor.withValues(alpha: 0.22)
                      : AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? provider.accentColor
                        : AppColors.glassBorder,
                  ),
                ),
                child: Icon(
                  provider.icon,
                  size: 18,
                  color: isSelected
                      ? provider.accentColor
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? provider.accentColor
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: provider.accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: provider.accentColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            provider.badgeText,
                            style: AppTypography.labelSmall.copyWith(
                              color: provider.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Radio Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? provider.accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? provider.accentColor
                        : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        LucideIcons.check,
                        size: 13,
                        color: Colors.black,
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Features tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: provider.features.map((feat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? provider.accentColor.withValues(alpha: 0.15)
                      : AppColors.darkSurfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  feat,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: isSelected
                        ? provider.accentColor
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
