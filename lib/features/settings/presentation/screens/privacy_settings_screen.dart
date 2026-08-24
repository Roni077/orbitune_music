import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_confirmation_sheet.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/widgets/settings_tile.dart';

/// Sub-Screen dedicated to Listening History, Search History, Incognito Mode & Privacy
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
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
        title: Text('Data & Privacy', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. INCOGNITO & LOGGING POLICIES
          _buildSectionHeader('History & Activity Logging'),
          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.glasses, size: 20, color: AppColors.accentPurple),
                  ),
                  title: Text('Incognito Private Session', style: AppTypography.titleSmall),
                  subtitle: Text('Do not record played tracks or searches into history or listening stats',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.incognitoMode,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setIncognitoMode(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.history, size: 20, color: AppColors.accentCyan),
                  ),
                  title: Text('Keep Listening History', style: AppTypography.titleSmall),
                  subtitle: Text('Log listened tracks for history timeline & stats calculation',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.listeningHistoryEnabled,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setListeningHistoryEnabled(val),
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
                    child: const Icon(LucideIcons.search, size: 20, color: AppColors.accentYellow),
                  ),
                  title: Text('Keep Search History', style: AppTypography.titleSmall),
                  subtitle: Text('Save recent search queries for instant recommendations',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.searchHistoryEnabled,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setSearchHistoryEnabled(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. CLEAR DATA ACTIONS
          _buildSectionHeader('Clear Activity Logs'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.trash2,
                  iconColor: AppColors.accentPink,
                  title: 'Clear Listening History',
                  subtitle: 'Purge all played tracks from history timeline',
                  isDestructive: true,
                  onTap: () => _confirmClearHistory(context, ref),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.eraser,
                  iconColor: AppColors.accentPink,
                  title: 'Clear Search History',
                  subtitle: 'Erase all stored recent search entries',
                  isDestructive: true,
                  onTap: () => _confirmClearSearch(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await ExpressiveConfirmationSheet.show(
      context,
      title: 'Clear Listening History?',
      message: 'This will remove all recorded songs from your history and cannot be undone.',
      confirmLabel: 'Clear History',
      icon: LucideIcons.history,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(historyProvider.notifier).clearHistory();
      if (context.mounted) {
        _showFeedback(context, 'Listening history cleared!');
      }
    }
  }

  void _confirmClearSearch(BuildContext context, WidgetRef ref) async {
    final confirmed = await ExpressiveConfirmationSheet.show(
      context,
      title: 'Clear Search History?',
      message: 'All past search terms will be permanently erased.',
      confirmLabel: 'Clear Search',
      icon: LucideIcons.searchX,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(searchCacheRepositoryProvider).clearCache();
      if (context.mounted) {
        _showFeedback(context, 'Search history cleared!');
      }
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: child,
          ),
        );
      },
    );
  }
}
