import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/user_avatar.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/screens/about_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/audio_playback_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/content_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/profile_customize_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/storage_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/theme_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/widgets/settings_tile.dart';

/// Central Settings Hub Dashboard routing to dedicated nested sub-screens
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
    final accent = (settings.accentColorIndex >= 0 &&
            settings.accentColorIndex < AppColors.accentPalette.length)
        ? AppColors.accentPalette[settings.accentColorIndex]
        : AppColors.accentGreen;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings', style: AppTypography.brandTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. USER PROFILE / HEADER CARD
          _buildUserProfileCard(context, settings, accent),
          const SizedBox(height: 24),

          // 2. PERSONALIZATION & STYLING
          _buildSectionHeader('Personalization & Style'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.userCircle2,
                  iconColor: AppColors.accentCyan,
                  title: 'Profile & Persona',
                  subtitle: '${settings.username ?? "Orbitune Listener"} • ${settings.profileBadge}',
                  badgeText: settings.profileBadge,
                  badgeColor: AppColors.accentCyan,
                  showChevron: true,
                  onTap: () => ProfileCustomizeScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.palette,
                  iconColor: AppColors.accentPink,
                  title: 'Appearance & UI',
                  subtitle: 'Shapes, visualizer bars, mesh glow & typography',
                  badgeText: '${settings.cornerRadius.toInt()}px',
                  badgeColor: AppColors.accentPink,
                  showChevron: true,
                  onTap: () => AppearanceSettingsScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.sparkles,
                  iconColor: accent,
                  title: 'Theme & Palette',
                  subtitle: _getThemeSubtitle(settings.themeMode),
                  badgeText: _getThemeBadge(settings.themeMode),
                  badgeColor: accent,
                  showChevron: true,
                  onTap: () => ThemeSettingsScreen.open(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. AUDIO & CONTENT ENGINE
          _buildSectionHeader('Audio Engine & Music'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.music,
                  iconColor: AppColors.accentGreen,
                  title: 'Audio & Playback',
                  subtitle: '${settings.streamingQuality.label} • ${settings.crossfadeDurationSeconds}s Crossfade • 10-Band EQ',
                  badgeText: '${settings.streamingQuality.bitrateKbps}kbps',
                  badgeColor: AppColors.accentGreen,
                  showChevron: true,
                  onTap: () => AudioPlaybackSettingsScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.globe,
                  iconColor: AppColors.accentCyan,
                  title: 'Content & Region',
                  subtitle: 'Regional charts (${settings.contentCountry}) • LRCLIB Lyrics',
                  badgeText: settings.contentCountry,
                  badgeColor: AppColors.accentCyan,
                  showChevron: true,
                  onTap: () => ContentSettingsScreen.open(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. STORAGE, DATA & PRIVACY
          _buildSectionHeader('Storage & Privacy'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.hardDrive,
                  iconColor: AppColors.accentPurple,
                  title: 'Storage & Cache',
                  subtitle: 'Storage breakdown, Wi-Fi rules & granular cache clearing',
                  badgeText: '${settings.cacheSizeLimitMb}MB Limit',
                  badgeColor: AppColors.accentPurple,
                  showChevron: true,
                  onTap: () => StorageSettingsScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.shieldCheck,
                  iconColor: AppColors.accentIndigo,
                  title: 'Data & Privacy',
                  subtitle: settings.incognitoMode
                      ? 'Incognito Mode Active • No logs saved'
                      : 'History tracking, search cache & logs',
                  badgeText: settings.incognitoMode ? 'INCOGNITO' : null,
                  badgeColor: AppColors.accentPurple,
                  showChevron: true,
                  onTap: () => PrivacySettingsScreen.open(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. BACKUP & ABOUT
          _buildSectionHeader('System & About'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.hardDriveDownload,
                  iconColor: AppColors.accentEmerald,
                  title: 'Backup & Restore',
                  subtitle: 'Export & restore playlists, favorites and settings as JSON',
                  showChevron: true,
                  onTap: () => BackupRestoreScreen.open(context),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.info,
                  iconColor: AppColors.accentYellow,
                  title: 'About Orbitune',
                  subtitle: 'Version 1.0.0 (Build 1) • System diagnostics & licenses',
                  showChevron: true,
                  onTap: () => AboutScreen.open(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(
    BuildContext context,
    dynamic settings,
    Color accent,
  ) {
    final username = settings.username ?? 'Orbitune Listener';
    final bio = settings.bio ?? 'Listening on Orbitune';
    final avatarAccent = (settings.avatarColorIndex >= 0 &&
            settings.avatarColorIndex < AppColors.accentPalette.length)
        ? AppColors.accentPalette[settings.avatarColorIndex]
        : accent;

    return InkWell(
      onTap: () => ProfileCustomizeScreen.open(context),
      borderRadius: BorderRadius.circular(22),
      child: ExpressiveCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        color: AppColors.darkSurfaceVariant.withValues(alpha: 0.65),
        child: Row(
          children: [
            UserAvatar(
              size: 56,
              customAvatarPath: settings.customAvatarPath,
              avatarIcon: settings.avatarIcon,
              avatarColorIndex: settings.avatarColorIndex,
              accentColor: avatarAccent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.pencil,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bio,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: avatarAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: avatarAccent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                settings.profileBadge.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: avatarAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        );
      },
    );
  }

  String _getThemeSubtitle(String mode) {
    switch (mode) {
      case 'oled':
        return 'Pure OLED Black (#000000)';
      case 'light':
        return 'Light Mode';
      case 'dynamic':
        return 'Material You Dynamic';
      case 'solarized':
        return 'Solarized Amber Warm';
      case 'cyberpunk':
        return 'Cyberpunk Neon Glow';
      case 'dark':
      default:
        return 'Deep Midnight Navy';
    }
  }

  String _getThemeBadge(String mode) {
    switch (mode) {
      case 'oled':
        return 'OLED';
      case 'light':
        return 'LIGHT';
      case 'dynamic':
        return 'DYNAMIC';
      case 'solarized':
        return 'SOLAR';
      case 'cyberpunk':
        return 'NEON';
      case 'dark':
      default:
        return 'DARK';
    }
  }
}
