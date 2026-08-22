import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/settings/presentation/dialogs/country_region_dialog.dart';
import 'package:orbitune/features/settings/presentation/dialogs/language_selection_dialog.dart';
import 'package:orbitune/features/settings/presentation/dialogs/lyrics_provider_dialog.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/widgets/settings_tile.dart';

/// Sub-Screen dedicated to Regional Music Discovery, Language, Lyrics Provider, and Search
class ContentSettingsScreen extends ConsumerWidget {
  const ContentSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContentSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final countryInfo = CountryRegionSelectionSheet.getInfo(settings.contentCountry);
    final languageInfo = LanguageSelectionSheet.getInfo(settings.language);
    final lyricsInfo = LyricsProviderSelectionSheet.getInfo(settings.lyricsSource);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Content & Region', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. REGION & CHARTS
          _buildSectionHeader('Discovery & Regional Charts'),
          _buildCard(
            child: Column(
              children: [
                // Music Country / Region
                SettingsTile(
                  icon: LucideIcons.globe,
                  iconColor: AppColors.accentCyan,
                  title: 'Music Country / Region',
                  subtitle: '${countryInfo.flag} ${countryInfo.name} • ${countryInfo.chartDescription}',
                  badgeText: countryInfo.code,
                  badgeColor: AppColors.accentCyan,
                  showChevron: true,
                  onTap: () => CountryRegionSelectionSheet.show(
                    context,
                    currentCountryCode: settings.contentCountry,
                    onCountrySelected: (c) => notifier.setContentCountry(c),
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // App Interface Language
                SettingsTile(
                  icon: LucideIcons.languages,
                  iconColor: AppColors.accentIndigo,
                  title: 'App Interface Language',
                  subtitle: '${languageInfo.flag} ${languageInfo.nativeName} (${languageInfo.englishName})',
                  badgeText: languageInfo.code.toUpperCase(),
                  badgeColor: AppColors.accentIndigo,
                  showChevron: true,
                  onTap: () => LanguageSelectionSheet.show(
                    context,
                    currentLanguageCode: settings.language,
                    onLanguageSelected: (l) => notifier.setLanguage(l),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. LYRICS & METADATA
          _buildSectionHeader('Lyrics & Metadata Providers'),
          _buildCard(
            child: Column(
              children: [
                // Synchronized Lyrics Source
                SettingsTile(
                  icon: LucideIcons.mic,
                  iconColor: AppColors.accentYellow,
                  title: 'Synchronized Lyrics Source',
                  subtitle: '${lyricsInfo.title} • ${lyricsInfo.subtitle}',
                  badgeText: lyricsInfo.badgeText,
                  badgeColor: lyricsInfo.accentColor,
                  showChevron: true,
                  onTap: () => LyricsProviderSelectionSheet.show(
                    context,
                    currentProviderKey: settings.lyricsSource,
                    onProviderSelected: (src) => notifier.setLyricsSource(src),
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // Explicit Content Filter
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.shieldAlert, size: 20, color: AppColors.accentPink),
                  ),
                  title: Text('Explicit Content Filter', style: AppTypography.titleSmall),
                  subtitle: Text(
                    'Filter out explicit lyrics and songs in search and home recommendations',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  value: settings.explicitFilter,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setExplicitFilter(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.accentGreen,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return ExpressiveCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.55),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
