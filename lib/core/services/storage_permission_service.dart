import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';

/// Service managing runtime storage and media permissions across Android SDKs
class StoragePermissionService {
  static final StoragePermissionService _instance = StoragePermissionService._internal();
  factory StoragePermissionService() => _instance;
  StoragePermissionService._internal();

  /// Requests storage/media permissions required to write and read files in internal storage
  Future<bool> requestStoragePermission({BuildContext? context}) async {
    if (kIsWeb) return true;

    if (!Platform.isAndroid && !Platform.isIOS) {
      // Desktop platforms (Windows, macOS, Linux) do not require mobile runtime permissions
      return true;
    }

    if (Platform.isAndroid) {
      try {
        // 1. Check if audio / media permission is granted (Android 13+ / API 33+)
        final audioStatus = await Permission.audio.status;
        if (audioStatus.isGranted) return true;

        // 2. Check general storage status (Android <= 12)
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;

        // 3. Request permissions in sequence based on what's applicable
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.audio,
        ].request();

        final granted = statuses[Permission.storage]?.isGranted == true ||
            statuses[Permission.audio]?.isGranted == true;

        if (granted) return true;

        // If permanently denied and context is provided, prompt user to open app settings
        final permanentlyDenied = statuses[Permission.storage]?.isPermanentlyDenied == true ||
            statuses[Permission.audio]?.isPermanentlyDenied == true;

        if (permanentlyDenied && context != null && context.mounted) {
          await showPermissionRationaleDialog(context);
        }

        return false;
      } catch (e) {
        debugPrint('[StoragePermissionService] Permission request warning: $e');
        return true; // Fallback to attempting direct file write
      }
    }

    return true;
  }

  /// Checks if storage/audio permission is currently granted
  Future<bool> hasStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final audioStatus = await Permission.audio.status;
      final storageStatus = await Permission.storage.status;
      return audioStatus.isGranted || storageStatus.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Displays an expressive Material 3 dialog explaining why storage access is required
  static Future<void> showPermissionRationaleDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(LucideIcons.folderLock, color: AppColors.accentPink, size: 36),
        title: Text(
          'Storage Permission Required',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Orbitune requires storage access to save downloaded songs and .orb backup files to your device. Please grant permission in App Settings.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            icon: const Icon(LucideIcons.settings, size: 16),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
