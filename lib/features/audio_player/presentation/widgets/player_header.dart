import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/share_helper.dart';
import 'package:orbitune/core/widgets/audio_badge.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/screens/sleep_timer_sheet.dart';
import 'package:orbitune/features/downloader/data/download_service.dart';
import 'package:orbitune/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';

/// Top app bar header for FullPlayer with source indicator, share, and track context options
class PlayerHeader extends ConsumerWidget {
  final Track? track;
  final VoidCallback? onCollapse;

  const PlayerHeader({
    super.key,
    this.track,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Collapse Down Chevron
          IconButton(
            icon: const Icon(
              LucideIcons.chevronDown,
              size: 28,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (onCollapse != null) {
                onCollapse!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            tooltip: 'Minimize',
          ),

          // Center Playing From Header & Badge
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NOW PLAYING',
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 1.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                if (track != null)
                  AudioBadge.fromTrack(track!),
              ],
            ),
          ),

          // Share Button
          IconButton(
            icon: const Icon(
              LucideIcons.share2,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (track != null) {
                HapticFeedback.lightImpact();
                ShareHelper.shareTrack(track!);
              }
            },
            tooltip: 'Share',
          ),

          // More Options 3-Dots Menu
          IconButton(
            icon: const Icon(
              LucideIcons.ellipsisVertical,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed: () => _showMoreOptionsModal(context, ref, track),
            tooltip: 'More Options',
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsModal(BuildContext context, WidgetRef ref, Track? currentTrack) {
    if (currentTrack == null) return;
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xF0141424),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track summary header in modal
              ListTile(
                leading: ClipRRect(
                  borderRadius: AppConstants.roundedSmall,
                  child: currentTrack.artworkUrl != null
                      ? Image.network(
                          currentTrack.artworkUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(LucideIcons.music),
                        )
                      : const Icon(LucideIcons.music),
                ),
                title: Text(
                  currentTrack.title,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  currentTrack.artist,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    currentTrack.isFavorite ? LucideIcons.heart : LucideIcons.heart,
                    color: currentTrack.isFavorite ? AppColors.accentPink : AppColors.textMuted,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(playerProvider.notifier).toggleFavorite();
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(color: AppColors.glassBorder),

              // View Artist
              ListTile(
                leading: const Icon(LucideIcons.user, color: AppColors.accentNeonBlue),
                title: Text('View Artist: ${currentTrack.artist}', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(
                        artistId: currentTrack.artist,
                        artistName: currentTrack.artist,
                      ),
                    ),
                  );
                },
              ),

              // View Album if available
              if (currentTrack.album != null && currentTrack.album!.isNotEmpty)
                ListTile(
                  leading: const Icon(LucideIcons.disc, color: AppColors.accentGreen),
                  title: Text('View Album: ${currentTrack.album}', style: AppTypography.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(
                          albumId: currentTrack.album!,
                          albumTitle: currentTrack.album!,
                        ),
                      ),
                    );
                  },
                ),

              // Download Song
              ListTile(
                leading: const Icon(LucideIcons.download, color: AppColors.accentNeonBlue),
                title: const Text('Download Song'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(downloadServiceProvider).startDownload(currentTrack);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading "${currentTrack.title}"...'),
                      backgroundColor: AppColors.darkSurfaceVariant,
                    ),
                  );
                },
              ),

              // Sleep Timer
              ListTile(
                leading: const Icon(LucideIcons.timer, color: AppColors.accentPink),
                title: const Text('Sleep Timer'),
                onTap: () {
                  Navigator.pop(context);
                  SleepTimerSheet.show(context);
                },
              ),

              // Equalizer & DSP
              ListTile(
                leading: const Icon(LucideIcons.slidersHorizontal, color: AppColors.accentGreen),
                title: const Text('Equalizer & Sound Effects'),
                onTap: () {
                  Navigator.pop(context);
                  EqualizerScreen.open(context);
                },
              ),

              // Share Card
              ListTile(
                leading: const Icon(LucideIcons.share2, color: AppColors.textPrimary),
                title: const Text('Share Song'),
                onTap: () {
                  Navigator.pop(context);
                  ShareHelper.shareTrack(currentTrack);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
