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

/// Material 3 Expressive Selection Sheet & Dialog for Lyrics & Metadata Providers
class LyricsProviderSelectionSheet extends StatelessWidget {
  final String currentProviderKey;
  final ValueChanged<String> onProviderSelected;

  const LyricsProviderSelectionSheet({
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

  /// Shows the Lyrics Provider Selection Sheet
  static Future<String?> show(
    BuildContext context, {
    required String currentProviderKey,
    required ValueChanged<String> onProviderSelected,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LyricsProviderSelectionSheet(
        currentProviderKey: currentProviderKey,
        onProviderSelected: onProviderSelected,
      ),
    );
  }

  /// Shows the dialog version
  static Future<String?> showAsDialog(
    BuildContext context, {
    required String currentProviderKey,
    required ValueChanged<String> onProviderSelected,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
            color: AppColors.darkSurfaceElevated,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _LyricsProviderContent(
                currentProviderKey: currentProviderKey,
                onSelect: (k) {
                  onProviderSelected(k);
                  Navigator.of(context).pop(k);
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
              _LyricsProviderContent(
                currentProviderKey: currentProviderKey,
                onSelect: (k) {
                  onProviderSelected(k);
                  Navigator.of(context).pop(k);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
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
                  Text(
                    'Lyrics & Metadata Engine',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
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
        ...LyricsProviderSelectionSheet.providers.map((provider) {
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
          // Top Row: Icon + Title + Badge + Radio
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
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                provider.accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  provider.accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            provider.badgeText,
                            style: AppTypography.caption.copyWith(
                              color: provider.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Radio Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
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
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: provider.accentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
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
          const SizedBox(height: 8),

          // Subtitle Description
          Text(
            provider.subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Feature Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: provider.features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? provider.accentColor.withValues(alpha: 0.10)
                      : AppColors.darkSurfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? provider.accentColor.withValues(alpha: 0.25)
                        : AppColors.glassBorder.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  feature,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? provider.accentColor
                        : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
