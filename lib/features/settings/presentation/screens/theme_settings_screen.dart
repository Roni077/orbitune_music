import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/widgets/live_theme_preview.dart';

/// Sub-Screen dedicated to Theme Presets, Accent Color Selection, and AMOLED Tuning
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final themeOptions = [
      {
        'key': 'dark',
        'title': 'Deep Midnight',
        'subtitle': 'Rich navy dark tone',
        'bg': const Color(0xFF0B0B14),
        'accent': AppColors.accentGreen,
        'icon': LucideIcons.moon,
      },
      {
        'key': 'oled',
        'title': 'Pure OLED',
        'subtitle': '0% pixel battery saver',
        'bg': const Color(0xFF000000),
        'accent': AppColors.accentGreen,
        'icon': LucideIcons.smartphone,
      },
      {
        'key': 'light',
        'title': 'Light Mode',
        'subtitle': 'High contrast clean slate',
        'bg': const Color(0xFFF8FAFC),
        'accent': const Color(0xFF15803D),
        'icon': LucideIcons.sun,
      },
      {
        'key': 'dynamic',
        'title': 'Material You',
        'subtitle': 'Dynamic system colors',
        'bg': const Color(0xFF1E1B4B),
        'accent': AppColors.accentIndigo,
        'icon': LucideIcons.sparkles,
      },
      {
        'key': 'solarized',
        'title': 'Solarized Amber',
        'subtitle': 'Warm golden dusk tone',
        'bg': const Color(0xFF14120E),
        'accent': AppColors.accentAmber,
        'icon': LucideIcons.flame,
      },
      {
        'key': 'cyberpunk',
        'title': 'Cyberpunk Neon',
        'subtitle': 'Electric cyan & pink synth',
        'bg': const Color(0xFF08090E),
        'accent': AppColors.accentCyan,
        'icon': LucideIcons.zap,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Theme & Palette', style: AppTypography.titleLarge),
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

          // 2. THEME PRESETS GRID
          _buildSectionHeader('Theme Style Presets'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: themeOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final opt = themeOptions[index];
              final key = opt['key'] as String;
              final isSelected = settings.themeMode == key;
              final bg = opt['bg'] as Color;
              final accent = opt['accent'] as Color;
              final icon = opt['icon'] as IconData;

              return ExpressiveCard(
                onTap: () => notifier.setThemeMode(key),
                borderRadius: BorderRadius.circular(18),
                color: bg,
                borderColor: isSelected ? accent : AppColors.glassBorder,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 16, color: accent),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.black),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['title'] as String,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: key == 'light' ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                        Text(
                          opt['subtitle'] as String,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            color: key == 'light' ? const Color(0xFF475569) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. PRIMARY ACCENT COLOR SWATCHES
          _buildSectionHeader('Primary Accent Color'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Accent: ${AppColors.accentColorNames[settings.accentColorIndex.clamp(0, AppColors.accentColorNames.length - 1)]}',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(AppColors.accentPalette.length, (i) {
                    final color = AppColors.accentPalette[i];
                    final isSelected = settings.accentColorIndex == i;

                    return GestureDetector(
                      onTap: () => notifier.setAccentColorIndex(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 22, color: Colors.black)
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. AMOLED TUNING
          _buildSectionHeader('AMOLED Battery Saver'),
          _buildCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.batteryCharging, size: 20, color: Colors.white),
              ),
              title: Text('True Black OLED Surface', style: AppTypography.titleSmall),
              subtitle: Text('Forces deep #000000 black on all cards and sheets',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              value: settings.amoledModeEnabled,
              activeTrackColor: AppColors.accentGreen,
              onChanged: (val) => notifier.setAmoledModeEnabled(val),
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
