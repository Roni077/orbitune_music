import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/expressive_confirmation_sheet.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// Screen for exporting and restoring user playlists, favorites, and settings via direct JSON actions
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
    );
  }

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isExporting = false;
  bool _isRestoring = false;

  Map<String, dynamic> _generateBackupData() {
    final libraryRepo = ref.read(libraryRepositoryProvider);
    final settings = ref.read(settingsProvider);

    final favorites = libraryRepo.getFavorites().map((f) => f.toMap()).toList();
    final playlists =
        libraryRepo.getUserPlaylists().map((p) => p.toMap()).toList();

    return {
      'orbitune_version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'favorites': favorites,
      'playlists': playlists,
      'settings': settings.toMap(),
    };
  }

  Future<void> _handleDirectBackup() async {
    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();

    try {
      final backup = _generateBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(LucideIcons.checkCheck, color: Colors.black, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Backup JSON copied to clipboard successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup creation failed: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleDirectRestore() async {
    HapticFeedback.lightImpact();

    // Read directly from clipboard
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim() ?? '';

    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No backup JSON found in clipboard. Please copy your backup data first.',
            ),
            backgroundColor: AppColors.accentPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
      return;
    }

    setState(() => _isRestoring = true);

    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid JSON format: expected Orbitune backup object.');
      }

      final libraryRepo = ref.read(libraryRepositoryProvider);
      int importedFavs = 0;
      int importedPlaylists = 0;

      // 1. Restore Favorites
      if (decoded['favorites'] is List) {
        for (final item in decoded['favorites'] as List) {
          if (item is Map) {
            try {
              final fav = FavoriteSong.fromMap(item);
              await libraryRepo.addFavorite(fav.track);
              importedFavs++;
            } catch (_) {}
          }
        }
      }

      // 2. Restore Playlists
      if (decoded['playlists'] is List) {
        for (final item in decoded['playlists'] as List) {
          if (item is Map) {
            try {
              final playlist = UserPlaylist.fromMap(item);
              await libraryRepo.saveUserPlaylist(playlist);
              importedPlaylists++;
            } catch (_) {}
          }
        }
      }

      // Refresh providers
      ref.read(favoritesProvider.notifier).refresh();
      ref.read(userPlaylistsProvider.notifier).refresh();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored $importedFavs favorites and $importedPlaylists playlists from JSON!',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppColors.accentPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _confirmResetSettings(BuildContext context) async {
    final confirmed = await ExpressiveConfirmationSheet.show(
      context,
      title: 'Reset All Settings?',
      message:
          'This will reset themes, audio bitrates, equalizer presets, and playback preferences back to factory defaults. Your custom playlists and favorites will remain untouched.',
      confirmLabel: 'Reset Settings',
      icon: LucideIcons.refreshCw,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(settingsProvider.notifier).resetAllSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings have been reset to factory defaults!'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final playlists = ref.watch(userPlaylistsProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Backup & Restore', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Direct Backup Section Card
            ExpressiveCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.download,
                          size: 20,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Backup (JSON)',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${favorites.length} favorites • ${playlists.length} playlists • Settings',
                              style: AppTypography.caption.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Directly generate and copy your complete Orbitune data into JSON format for safe backup.',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isExporting ? null : _handleDirectBackup,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(LucideIcons.copy, size: 18),
                      label: Text(
                        _isExporting ? 'Exporting...' : 'Backup to JSON',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Direct Restore Section Card
            ExpressiveCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.upload,
                          size: 20,
                          color: AppColors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Restore from JSON',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Directly reads and restores playlists, liked tracks, and preferences from your clipboard JSON.',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentCyan.withValues(alpha: 0.18),
                        foregroundColor: AppColors.accentCyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.accentCyan.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      onPressed: _isRestoring ? null : _handleDirectRestore,
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.rotateCcw, size: 18),
                      label: Text(
                        _isRestoring ? 'Restoring...' : 'Restore from JSON (Clipboard)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Reset All Settings Card
            ExpressiveCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentPink.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.refreshCw,
                          size: 20,
                          color: AppColors.accentPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Factory Reset Settings',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Reset themes, streaming bitrates, audio crossfade, and equalizer settings back to original defaults.',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentPink,
                        side: BorderSide(
                          color: AppColors.accentPink.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _confirmResetSettings(context),
                      icon: const Icon(LucideIcons.alertTriangle, size: 18),
                      label: const Text(
                        'Reset All Settings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
