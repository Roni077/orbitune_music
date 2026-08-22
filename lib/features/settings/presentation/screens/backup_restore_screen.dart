import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/share_helper.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// Screen for exporting and restoring user playlists, favorites, and settings via JSON
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
  final TextEditingController _importController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

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

  Future<void> _handleImport() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a valid JSON backup string'),
          backgroundColor: AppColors.accentPink,
        ),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid JSON structure: expected object.');
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

      _importController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully restored $importedFavs favorites and $importedPlaylists playlists!',
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final playlists = ref.watch(userPlaylistsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Backup & Restore', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Export Section Card
            ExpressiveCard(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.darkSurfaceVariant.withOpacity(0.55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.download,
                          size: 18,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Export Data Backup',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Export your ${favorites.length} liked songs, ${playlists.length} custom playlists, and settings into portable JSON format.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: AppColors.white.withOpacity(0.15)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final backup = _generateBackupData();
                            final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
                            Clipboard.setData(ClipboardData(text: jsonStr));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup JSON copied to clipboard!'),
                                backgroundColor: AppColors.accentGreen,
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.copy, size: 16),
                          label: const Text('Copy JSON'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final backup = _generateBackupData();
                            final jsonStr = jsonEncode(backup);
                            ShareHelper.shareText(
                              jsonStr,
                              subject: 'Orbitune Data Backup',
                            );
                          },
                          icon: const Icon(LucideIcons.share2, size: 16),
                          label: const Text(
                            'Share File',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Import / Restore Section Card
            ExpressiveCard(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.darkSurfaceVariant.withOpacity(0.55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.upload,
                          size: 18,
                          color: AppColors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Restore from Backup',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Paste a previously exported Orbitune JSON backup string below to restore playlists and favorites.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _importController,
                    maxLines: 4,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste Orbitune JSON backup here...',
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isImporting ? null : _handleImport,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.rotateCcw, size: 18),
                      label: Text(
                        _isImporting ? 'Restoring...' : 'Restore Data',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Reset All Settings
            ExpressiveCard(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.darkSurfaceVariant.withOpacity(0.55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentPink.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.refreshCw,
                          size: 18,
                          color: AppColors.accentPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Factory Reset Settings',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Reset themes, streaming bitrates, audio crossfade, and equalizer settings back to original defaults.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentPink,
                      side: const BorderSide(color: AppColors.accentPink),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _confirmResetSettings(context),
                    icon: const Icon(LucideIcons.alertTriangle, size: 16),
                    label: const Text('Reset All Settings'),
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

  void _confirmResetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text('Reset All Settings?', style: AppTypography.titleMedium),
        content: Text(
          'This will reset your theme, audio bitrates, equalizer presets, and preferences to default. Your playlists and favorites will remain safe.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPink),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(settingsProvider.notifier).resetAllSettings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings have been reset to factory defaults!'),
                    backgroundColor: AppColors.accentGreen,
                  ),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
