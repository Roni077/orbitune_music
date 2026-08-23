import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/downloader/presentation/screens/downloads_screen.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/providers/storage_analyzer_provider.dart';
import 'package:orbitune/features/settings/presentation/widgets/settings_tile.dart';
import 'package:orbitune/features/settings/presentation/widgets/storage_breakdown_bar.dart';

/// Sub-Screen dedicated to Storage Breakdown, Wi-Fi data policies, Cache Limits, and Cache Flushes
class StorageSettingsScreen extends ConsumerWidget {
  const StorageSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StorageSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final storageStats = ref.watch(storageStatsProvider);

    final downloadsPath = storageStats.downloadsDirectoryPath.isNotEmpty
        ? storageStats.downloadsDirectoryPath
        : '/storage/emulated/0/Download/Orbitune_Downloads';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Storage & Cache', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. Live Real-time Storage Breakdown Bar
          StorageBreakdownBar(stats: storageStats),
          const SizedBox(height: 24),

          // 2. NETWORK DATA POLICIES & OFFLINE
          _buildSectionHeader('Data Saver & Offline Tracks'),
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
                    child: const Icon(LucideIcons.wifi, size: 20, color: AppColors.accentCyan),
                  ),
                  title: Text('Stream on Wi-Fi Only', style: AppTypography.titleSmall),
                  subtitle: Text('Prevent audio streaming over mobile cellular data',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.wifiOnlyStreaming,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setWifiOnlyStreaming(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.downloadCloud, size: 20, color: AppColors.accentGreen),
                  ),
                  title: Text('Download on Wi-Fi Only', style: AppTypography.titleSmall),
                  subtitle: Text('Save mobile data during offline downloads',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.wifiOnlyDownloads,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setWifiOnlyDownloads(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.folderDown,
                  iconColor: AppColors.accentCyan,
                  title: 'Download Storage Location',
                  subtitle: downloadsPath,
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18, color: AppColors.accentCyan),
                    tooltip: 'Copy Path',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: downloadsPath));
                      HapticFeedback.lightImpact();
                      _showFeedback(context, 'Storage directory path copied to clipboard!');
                    },
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 20),
                SettingsTile(
                  icon: LucideIcons.folderHeart,
                  iconColor: AppColors.accentPurple,
                  title: 'Manage Offline Downloads',
                  subtitle: 'View offline library, delete tracks, and free disk space',
                  showChevron: true,
                  onTap: () => DownloadsScreen.open(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. CACHE SIZE LIMITS
          _buildSectionHeader('Cache Allocation Limit'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Maximum Temp Cache Size', style: AppTypography.titleSmall),
                    Text(
                      '${settings.cacheSizeLimitMb} MB',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings.cacheSizeLimitMb.toDouble().clamp(256.0, 5120.0),
                  min: 256.0,
                  max: 5120.0,
                  divisions: 19,
                  activeColor: AppColors.accentGreen,
                  inactiveColor: AppColors.white.withValues(alpha: 0.1),
                  onChanged: (val) => notifier.setCacheSizeLimit(val.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. GRANULAR CACHE CLEANING
          _buildSectionHeader('Clean Temporary Files'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.search,
                  iconColor: AppColors.accentYellow,
                  title: 'Clear Search History & Suggestions',
                  subtitle: 'Flush cached autocomplete queries',
                  onTap: () async {
                    await ref.read(searchCacheRepositoryProvider).clearCache();
                    ref.read(storageStatsProvider.notifier).refresh();
                    if (context.mounted) {
                      _showFeedback(context, 'Search cache cleared!');
                    }
                  },
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.mic,
                  iconColor: AppColors.accentPink,
                  title: 'Clear Lyrics Cache',
                  subtitle: 'Remove cached synced LRCLIB files',
                  onTap: () async {
                    await HiveService.instance.clearBox('lyrics_cache');
                    ref.read(storageStatsProvider.notifier).refresh();
                    if (context.mounted) {
                      _showFeedback(context, 'Lyrics cache cleared!');
                    }
                  },
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.trash2,
                  iconColor: AppColors.accentPink,
                  title: 'Clear All Application Cache',
                  subtitle: 'Purge search, lyrics, temp stream buffers & images',
                  isDestructive: true,
                  onTap: () async {
                    await HiveService.instance.clearCache();
                    await ref.read(searchCacheRepositoryProvider).clearCache();
                    ref.read(storageStatsProvider.notifier).refresh();
                    if (context.mounted) {
                      _showFeedback(context, 'All temporary cache flushed successfully!');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
