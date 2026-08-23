import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/widgets/live_theme_preview.dart';

/// Sub-Screen dedicated to Visual Styling, Typography, and Player Appearance
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Appearance & UI', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. Live Interactive Preview
          LiveThemePreview(
            themeMode: settings.themeMode,
            accentColorIndex: settings.accentColorIndex,
            cornerRadius: settings.cornerRadius,
            enableGlassmorphism: settings.enableGlassmorphism,
            showBitrateBadge: settings.showBitrateBadge,
          ),
          const SizedBox(height: 24),

          // 2. PLAYER & DYNAMIC VISUALS
          _buildSectionHeader(context, 'Player & Visual Effects'),
          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.sparkles, size: 20, color: AppColors.accentCyan),
                  ),
                  title: Text('Dynamic Artwork Colors', style: AppTypography.titleSmall),
                  subtitle: Text('Adapt player mesh background to album cover',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.dynamicColorEnabled,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setDynamicColorEnabled(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.activity, size: 20, color: AppColors.accentPink),
                  ),
                  title: Text('Animated Visualizer', style: AppTypography.titleSmall),
                  subtitle: Text('Render dancing frequency bars on playback',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.enableVisualizer,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setVisualizerEnabled(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.badgeCheck, size: 20, color: AppColors.accentYellow),
                  ),
                  title: Text('Audio Quality Badges', style: AppTypography.titleSmall),
                  subtitle: Text('Show 320k Opus & Lossless badges on tracks',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.showBitrateBadge,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setShowBitrateBadge(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. UI SHAPES & CORNERS
          _buildSectionHeader(context, 'Shapes & Glassmorphism'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.box, size: 20, color: AppColors.accentGreen),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Corner Roundness', style: AppTypography.titleSmall),
                            Text('${settings.cornerRadius.toInt()}px radius',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Slider(
                  value: settings.cornerRadius.clamp(4.0, 28.0),
                  min: 4.0,
                  max: 28.0,
                  divisions: 6,
                  activeColor: AppColors.accentGreen,
                  inactiveColor: AppColors.white.withValues(alpha: 0.1),
                  onChanged: (val) => notifier.setCornerRadius(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.layers, size: 20, color: AppColors.accentOrange),
                  ),
                  title: Text('Glassmorphic Blur Container', style: AppTypography.titleSmall),
                  subtitle: Text('Subtle translucent frosted glass card surfaces',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.enableGlassmorphism,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setGlassmorphism(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. TYPOGRAPHY & FONT PAIRINGS
          _buildSectionHeader(context, 'Typography'),
          _buildCard(
            child: Column(
              children: [
                _buildFontOption(
                  context: context,
                  title: 'System Default Font',
                  subtitle: 'Native device system font for peak familiarity and performance',
                  fontKey: 'system',
                  currentFont: settings.fontFamily,
                  onSelect: () => notifier.setFontFamily('system'),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                _buildFontOption(
                  context: context,
                  title: 'Righteous & Poppins (Default)',
                  subtitle: 'Bold expressive headlines with ultra-readable body text',
                  fontKey: 'righteous_poppins',
                  currentFont: settings.fontFamily,
                  onSelect: () => notifier.setFontFamily('righteous_poppins'),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                _buildFontOption(
                  context: context,
                  title: 'Inter System Clean',
                  subtitle: 'Modern neo-grotesque geometric font for maximum precision',
                  fontKey: 'inter',
                  currentFont: settings.fontFamily,
                  onSelect: () => notifier.setFontFamily('inter'),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                _buildFontOption(
                  context: context,
                  title: 'Outfit & Plus Jakarta',
                  subtitle: 'Futuristic warm curves designed for high-density music feeds',
                  fontKey: 'outfit',
                  currentFont: settings.fontFamily,
                  onSelect: () => notifier.setFontFamily('outfit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFontOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String fontKey,
    required String currentFont,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSelected = fontKey == currentFont;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, color: primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: primary,
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
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
