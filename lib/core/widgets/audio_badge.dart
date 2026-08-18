import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_typography.dart';

enum AudioBadgeType {
  hiRes,
  lossless,
  highQuality320,
  mediumQuality160,
  youtube,
  jioSaavn,
  offline,
}

/// Pill badge displaying audio streaming source, format, and bitrate
class AudioBadge extends StatelessWidget {
  final AudioBadgeType type;
  final String? customLabel;

  const AudioBadge({
    super.key,
    required this.type,
    this.customLabel,
  });

  /// Convenience factory creating an AudioBadge tailored to [Track] properties
  factory AudioBadge.fromTrack(dynamic track) {
    if (track == null) {
      return const AudioBadge(type: AudioBadgeType.highQuality320);
    }
    final source = track.source?.toString().toLowerCase();
    final bitrate = (track.bitrate as num?)?.toInt() ?? 320;
    final isOffline = track.isOfflineAvailable == true;

    if (isOffline) {
      return const AudioBadge(type: AudioBadgeType.offline);
    }
    if (source == 'youtube') {
      return const AudioBadge(type: AudioBadgeType.youtube);
    }
    if (bitrate >= 320) {
      return const AudioBadge(type: AudioBadgeType.highQuality320);
    }
    if (source == 'jiosaavn') {
      return const AudioBadge(type: AudioBadgeType.jioSaavn);
    }
    return const AudioBadge(type: AudioBadgeType.highQuality320);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (type) {
      case AudioBadgeType.hiRes:
        bg = const Color(0xFFD97706);
        text = Colors.white;
        label = 'HI-RES';
        break;
      case AudioBadgeType.lossless:
        bg = const Color(0xFF2563EB);
        text = Colors.white;
        label = 'LOSSLESS';
        break;
      case AudioBadgeType.highQuality320:
        bg = AppColors.accentGreen.withValues(alpha: 0.2);
        text = AppColors.accentGreen;
        label = '320 KBPS';
        break;
      case AudioBadgeType.mediumQuality160:
        bg = AppColors.accentIndigo.withValues(alpha: 0.2);
        text = AppColors.accentIndigo;
        label = '160 KBPS';
        break;
      case AudioBadgeType.youtube:
        bg = const Color(0xFFFF0000).withValues(alpha: 0.15);
        text = const Color(0xFFFF4D4D);
        label = 'YT MUSIC';
        break;
      case AudioBadgeType.jioSaavn:
        bg = const Color(0xFF00B0FF).withValues(alpha: 0.15);
        text = const Color(0xFF00E5FF);
        label = 'SAAVN';
        break;
      case AudioBadgeType.offline:
        bg = Colors.white.withValues(alpha: 0.15);
        text = Colors.white70;
        label = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppConstants.roundedSmall,
      ),
      child: Text(
        customLabel ?? label,
        style: AppTypography.bodySmall.copyWith(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
