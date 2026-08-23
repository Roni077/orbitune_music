import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import 'package:orbitune/core/services/storage_permission_service.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// Summary result of an exported .orb backup
class BackupResult {
  final File file;
  final int favoritesCount;
  final int playlistsCount;
  final int historyCount;
  final DateTime timestamp;

  const BackupResult({
    required this.file,
    required this.favoritesCount,
    required this.playlistsCount,
    required this.historyCount,
    required this.timestamp,
  });
}

/// Summary result of a restored .orb backup
class RestoreResult {
  final bool success;
  final int favoritesRestored;
  final int playlistsRestored;
  final int historyRestored;
  final bool settingsRestored;
  final String? errorMessage;

  const RestoreResult({
    required this.success,
    this.favoritesRestored = 0,
    this.playlistsRestored = 0,
    this.historyRestored = 0,
    this.settingsRestored = false,
    this.errorMessage,
  });
}

/// Service providing standalone orbitune.orb file backup and restore operations
class BackupRestoreService {
  final Ref _ref;

  BackupRestoreService(this._ref);

  /// Resolves the dedicated storage directory for Orbitune backups (/storage/emulated/0/Download/Orbitune/Backup)
  static Future<Directory> resolveBackupDirectory() async {
    if (kIsWeb) {
      return Directory.systemTemp;
    }

    if (Platform.isAndroid) {
      final publicBackupDir = Directory('/storage/emulated/0/Download/Orbitune/Backup');
      try {
        if (!await publicBackupDir.exists()) {
          await publicBackupDir.create(recursive: true);
        }
        return publicBackupDir;
      } catch (e) {
        debugPrint('[BackupRestoreService] Android public Backup directory fallback: $e');
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final sysDownloads = await path_provider.getDownloadsDirectory();
        if (sysDownloads != null) {
          final dir = Directory('${sysDownloads.path}/Orbitune/Backup');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (e) {
        debugPrint('[BackupRestoreService] Desktop getDownloadsDirectory fallback: $e');
      }
    }

    // Default fallback (e.g. iOS or sandboxed environments)
    Directory baseDir;
    try {
      baseDir = await path_provider.getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }
    final dir = Directory('${baseDir.path}/Orbitune/Backup');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Generates the complete backup JSON payload containing all playlists, favorites, history, and settings
  Map<String, dynamic> generateBackupPayload() {
    final libraryRepo = _ref.read(libraryRepositoryProvider);
    final settings = _ref.read(settingsProvider);

    final favorites = libraryRepo.getFavorites().map((f) => f.toMap()).toList();
    final playlists = libraryRepo.getUserPlaylists().map((p) => p.toMap()).toList();
    final history = libraryRepo.getHistory().map((h) => h.toMap()).toList();

    return {
      'orbitune_format': 'orbitune.orb',
      'orbitune_version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'favorites': favorites,
      'playlists': playlists,
      'history': history,
      'settings': settings.toMap(),
    };
  }

  /// Creates and saves a dedicated 'orbitune.orb' file into /storage/emulated/0/Download/Orbitune/Backup
  Future<BackupResult> createBackupFile({String fileName = 'orbitune.orb'}) async {
    // 1. Check and request storage permission
    await StoragePermissionService().requestStoragePermission();

    // 2. Resolve destination directory
    final backupDir = await resolveBackupDirectory();
    final cleanFileName = fileName.endsWith('.orb') ? fileName : '$fileName.orb';
    final targetFile = File('${backupDir.path}/$cleanFileName');

    // 3. Compile payload and write formatted JSON to .orb file
    final payload = generateBackupPayload();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    await targetFile.writeAsString(jsonStr, flush: true);

    return BackupResult(
      file: targetFile,
      favoritesCount: (payload['favorites'] as List).length,
      playlistsCount: (payload['playlists'] as List).length,
      historyCount: (payload['history'] as List).length,
      timestamp: DateTime.now(),
    );
  }

  /// Shares the generated orbitune.orb file via system share sheet
  Future<void> shareBackupFile(File file) async {
    if (!await file.exists()) return;
    await Share.shareXFiles(
      [XFile(file.path, name: 'orbitune.orb', mimeType: 'application/octet-stream')],
      subject: 'Orbitune Music Player Backup (.orb)',
    );
  }

  /// Restores data from a given .orb File
  Future<RestoreResult> restoreFromFile(File file) async {
    try {
      if (!await file.exists()) {
        return const RestoreResult(success: false, errorMessage: 'Selected file does not exist.');
      }

      final content = await file.readAsString();
      final dynamic decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        return const RestoreResult(
          success: false,
          errorMessage: 'Invalid file format. Expected a valid Orbitune (.orb) backup.',
        );
      }

      final libraryRepo = _ref.read(libraryRepositoryProvider);
      final settingsRepo = _ref.read(settingsRepositoryProvider);

      int restoredFavs = 0;
      int restoredPlaylists = 0;
      int restoredHistory = 0;

      // 1. Restore Favorites
      if (decoded['favorites'] is List) {
        for (final item in decoded['favorites'] as List) {
          if (item is Map) {
            try {
              final fav = FavoriteSong.fromMap(item);
              await libraryRepo.addFavorite(fav.track);
              restoredFavs++;
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
              restoredPlaylists++;
            } catch (_) {}
          }
        }
      }

      // 3. Restore History
      if (decoded['history'] is List) {
        for (final item in decoded['history'] as List) {
          if (item is Map) {
            try {
              final histItem = HistoryItem.fromMap(item);
              await libraryRepo.addHistoryItem(histItem.track);
              restoredHistory++;
            } catch (_) {}
          }
        }
      }

      // 4. Restore Settings
      bool settingsRestored = false;
      if (decoded['settings'] is Map) {
        try {
          final settings = AppSettings.fromMap(decoded['settings'] as Map<dynamic, dynamic>);
          await settingsRepo.saveSettings(settings);
          settingsRestored = true;
        } catch (_) {}
      }

      // 5. Refresh all active Riverpod providers
      _ref.read(favoritesProvider.notifier).refresh();
      _ref.read(userPlaylistsProvider.notifier).refresh();
      _ref.read(historyProvider.notifier).refresh();
      _ref.read(settingsProvider.notifier).refresh();

      return RestoreResult(
        success: true,
        favoritesRestored: restoredFavs,
        playlistsRestored: restoredPlaylists,
        historyRestored: restoredHistory,
        settingsRestored: settingsRestored,
      );
    } catch (e) {
      return RestoreResult(success: false, errorMessage: 'Failed to restore backup: $e');
    }
  }

  /// Launches the native file picker to select and restore an orbitune.orb file from storage
  Future<RestoreResult?> pickAndRestoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['orb', 'json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null; // User cancelled
    }

    final path = result.files.single.path;
    if (path == null) {
      return const RestoreResult(
        success: false,
        errorMessage: 'Unable to access the selected file path.',
      );
    }

    return restoreFromFile(File(path));
  }
}

/// Riverpod provider for BackupRestoreService
final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  return BackupRestoreService(ref);
});
