import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/downloader/presentation/screens/downloads_screen.dart';
import 'package:orbitune/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/screens/about_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/backup_restore_screen.dart';

/// Central Settings Screen with Audio Quality, Equalizer, Theming, Cache, and Privacy
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings', style: AppTypography.brandTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. AUDIO & PLAYBACK SECTION
          _buildSectionHeader('Audio & Playback'),
          _buildSettingCard(
            child: Column(
              children: [
                // Streaming Quality
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.radio, color: AppColors.accentCyan),
                  title: Text('Streaming Quality', style: AppTypography.titleSmall),
                  subtitle: Text(
                    '${settings.streamingQuality.label} • ${settings.streamingQuality.bitrateKbps}kbps',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: DropdownButton<AudioQuality>(
                    value: settings.streamingQuality,
                    dropdownColor: AppColors.darkSurfaceVariant,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
                    items: AudioQuality.values.map((q) {
                      return DropdownMenuItem(
                        value: q,
                        child: Text(
                          q.label,
                          style: TextStyle(
                            color: q == settings.streamingQuality
                                ? AppColors.accentGreen
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setStreamingQuality(val);
                    },
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),

                // Download Quality
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.downloadCloud, color: AppColors.accentGreen),
                  title: Text('Download Quality', style: AppTypography.titleSmall),
                  subtitle: Text(
                    '${settings.downloadQuality.label} • ${settings.downloadQuality.bitrateKbps}kbps',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: DropdownButton<AudioQuality>(
                    value: settings.downloadQuality,
                    dropdownColor: AppColors.darkSurfaceVariant,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
                    items: AudioQuality.values.map((q) {
                      return DropdownMenuItem(
                        value: q,
                        child: Text(
                          q.label,
                          style: TextStyle(
                            color: q == settings.downloadQuality
                                ? AppColors.accentGreen
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setDownloadQuality(val);
                    },
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),

                // 10-Band Equalizer shortcut
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.slidersHorizontal, color: AppColors.accentPink),
                  title: Text('10-Band DSP Equalizer', style: AppTypography.titleSmall),
                  subtitle: Text(
                    settings.equalizerEnabled
                        ? 'Active Preset: ${settings.equalizerPreset}'
                        : 'Custom bands, Bass Boost & 3D Virtualizer',
                    style: AppTypography.bodySmall.copyWith(
                      color: settings.equalizerEnabled
                          ? AppColors.accentGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => EqualizerScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),

                // Crossfade slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.gitFork, color: AppColors.accentOrange, size: 20),
                            const SizedBox(width: 12),
                            Text('Crossfade Tracks', style: AppTypography.titleSmall),
                          ],
                        ),
                        Text(
                          settings.crossfadeDurationSeconds == 0
                              ? 'Off'
                              : '${settings.crossfadeDurationSeconds}s',
                          style: AppTypography.labelMedium.copyWith(
                            color: settings.crossfadeDurationSeconds > 0
                                ? AppColors.accentGreen
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.crossfadeDurationSeconds.toDouble(),
                      min: 0,
                      max: 12,
                      divisions: 12,
                      activeColor: AppColors.accentGreen,
                      inactiveColor: AppColors.white.withOpacity(0.1),
                      onChanged: (val) => notifier.setCrossfadeDuration(val.toInt()),
                    ),
                  ],
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // Gapless Playback Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(LucideIcons.music, color: AppColors.accentPurple),
                  title: Text('Gapless Playback', style: AppTypography.titleSmall),
                  subtitle: Text('Seamless transitions between album tracks',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.gaplessPlayback,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setGaplessPlayback(val),
                ),

                // AutoPlay Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(LucideIcons.sparkles, color: AppColors.accentYellow),
                  title: Text('AutoPlay Similar Music', style: AppTypography.titleSmall),
                  subtitle: Text('Keep the music playing when queue ends',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.autoPlay,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setAutoPlay(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. APPEARANCE & THEME
          _buildSectionHeader('Appearance & Theming'),
          _buildSettingCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.palette, color: AppColors.accentPink),
                  title: Text('Theme Style', style: AppTypography.titleSmall),
                  subtitle: Text(
                    _getThemeName(settings.themeMode),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.themeMode,
                    dropdownColor: AppColors.darkSurfaceVariant,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
                    items: const [
                      DropdownMenuItem(value: 'dark', child: Text('Deep Midnight')),
                      DropdownMenuItem(value: 'oled', child: Text('Pure OLED Black')),
                      DropdownMenuItem(value: 'dynamic', child: Text('Dynamic Material You')),
                      DropdownMenuItem(value: 'light', child: Text('Light Mode')),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.setThemeMode(val);
                    },
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(LucideIcons.sparkles, color: AppColors.accentCyan),
                  title: Text('Dynamic Artwork Colors', style: AppTypography.titleSmall),
                  subtitle: Text('Adapt player background to album cover',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.dynamicColorEnabled,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setDynamicColorEnabled(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. NETWORK & STORAGE
          _buildSectionHeader('Network & Offline Storage'),
          _buildSettingCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(LucideIcons.wifi, color: AppColors.accentCyan),
                  title: Text('Stream on Wi-Fi Only', style: AppTypography.titleSmall),
                  subtitle: Text('Prevent streaming audio over mobile data',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.wifiOnlyStreaming,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setWifiOnlyStreaming(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(LucideIcons.downloadCloud, color: AppColors.accentGreen),
                  title: Text('Download on Wi-Fi Only', style: AppTypography.titleSmall),
                  subtitle: Text('Save mobile data during offline downloads',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.wifiOnlyDownloads,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setWifiOnlyDownloads(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.folderHeart, color: AppColors.accentPurple),
                  title: Text('Manage Offline Downloads', style: AppTypography.titleSmall),
                  subtitle: Text('View downloaded songs and free up device space',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => DownloadsScreen.open(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. DATA, PRIVACY & BACKUP
          _buildSectionHeader('Data, History & Backup'),
          _buildSettingCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(LucideIcons.history, color: AppColors.accentCyan),
                  title: Text('Keep Listening History', style: AppTypography.titleSmall),
                  subtitle: Text('Log listened songs for statistics & history tab',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.listeningHistoryEnabled,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setListeningHistoryEnabled(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.hardDriveDownload, color: AppColors.accentGreen),
                  title: Text('Backup & Restore', style: AppTypography.titleSmall),
                  subtitle: Text('Export and import playlists & favorites as JSON',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () => BackupRestoreScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.trash2, color: AppColors.accentPink),
                  title: Text('Clear All Cache', style: AppTypography.titleSmall.copyWith(color: AppColors.accentPink)),
                  subtitle: Text('Clear search cache, lyrics cache, and temp files',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  onTap: () async {
                    await ref.read(searchCacheRepositoryProvider).clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Temporary cache cleared successfully!'),
                          backgroundColor: AppColors.accentGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. ABOUT & VERSION
          _buildSectionHeader('About'),
          _buildSettingCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.info, color: AppColors.accentYellow),
              title: Text('About Orbitune', style: AppTypography.titleSmall),
              subtitle: Text('Version 1.0.0 (Build 1) • Open source licenses',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () => AboutScreen.open(context),
            ),
          ),

          const SizedBox(height: 120),
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

  Widget _buildSettingCard({required Widget child}) {
    return ExpressiveCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.55),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  String _getThemeName(String mode) {
    switch (mode) {
      case 'oled':
        return 'Pure OLED Black';
      case 'dynamic':
        return 'Dynamic Material You';
      case 'light':
        return 'Light Mode';
      case 'dark':
      default:
        return 'Deep Midnight';
    }
  }
}
