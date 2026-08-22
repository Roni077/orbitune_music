import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/audio_badge.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/downloader/data/download_service.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';

/// Premium song list item tile with source badges, active equalizer, and context actions
class TrackTile extends ConsumerWidget {
  final Track track;
  final int? index;
  final VoidCallback? onTap;
  final bool showArtwork;
  final bool showIndex;
  final bool showSourceBadge;
  final bool showDuration;

  const TrackTile({
    super.key,
    required this.track,
    this.index,
    this.onTap,
    this.showArtwork = true,
    this.showIndex = false,
    this.showSourceBadge = true,
    this.showDuration = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isCurrent = currentTrack?.id == track.id;
    final isFavorite = ref.watch(isFavoriteProvider(track.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedMedium,
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            ref.read(queueProvider.notifier).playTrack(track);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // 1. Optional Track Index Number (1..N) or Animated Playing Indicator
              if (showIndex && index != null) ...[
                SizedBox(
                  width: 28,
                  child: isCurrent && isPlaying
                      ? const SpinKitWave(
                          color: AppColors.accentGreen,
                          size: 14,
                          itemCount: 4,
                          type: SpinKitWaveType.start,
                        )
                      : Text(
                          '$index',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isCurrent ? AppColors.accentGreen : AppColors.textMuted,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(width: 8),
              ],

              // 2. High-res Artwork with Rounded Corners
              if (showArtwork) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: AppConstants.roundedSmall,
                      child: ImageShimmer(
                        imageUrl: track.bestArtworkUrl,
                        width: 48,
                        height: 48,
                      ),
                    ),
                    if (isCurrent && !showIndex)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: AppConstants.roundedSmall,
                        ),
                        child: isPlaying
                            ? const SpinKitWave(
                                color: AppColors.accentGreen,
                                size: 16,
                                itemCount: 4,
                                type: SpinKitWaveType.start,
                              )
                            : const Icon(
                                LucideIcons.pause,
                                color: AppColors.accentGreen,
                                size: 20,
                              ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
              ],

              // 3. Track Details: Title & Subtitle (Artist • Source Badge)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isCurrent ? AppColors.accentGreen : Colors.white,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (showSourceBadge) ...[
                          _buildSourceBadge(track.source),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            track.artist,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 4. Track Duration (e.g. 03:45)
              if (showDuration && track.duration > Duration.zero) ...[
                Text(
                  Formatters.formatDuration(track.duration),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // 5. Context Menu Action (3-Dots)
              IconButton(
                icon: const Icon(
                  LucideIcons.ellipsisVertical,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                splashRadius: 20,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showTrackContextMenu(context, ref, track, isFavorite);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    switch (source.toLowerCase()) {
      case 'extractor':
        return const AudioBadge(type: AudioBadgeType.hiRes, customLabel: 'EXTRACTOR');
      case 'local':
        return const AudioBadge(type: AudioBadgeType.offline);
      case 'youtube':
      default:
        return const AudioBadge(type: AudioBadgeType.youtube);
    }
  }

  void _showTrackContextMenu(
    BuildContext context,
    WidgetRef ref,
    Track track,
    bool isFavorite,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track header summary in bottom sheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppConstants.roundedSmall,
                      child: ImageShimmer(
                        imageUrl: track.bestArtworkUrl,
                        width: 50,
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.glassBorder, height: 24),

              // Action: Play Now
              ListTile(
                leading: const Icon(LucideIcons.play, color: AppColors.accentGreen, size: 20),
                title: Text('Play Now', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(queueProvider.notifier).playTrack(track);
                },
              ),

              // Action: Play Next
              ListTile(
                leading: const Icon(LucideIcons.fastForward, color: Colors.white, size: 20),
                title: Text('Play Next', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(queueProvider.notifier).playNext(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing "${track.title}" next'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.darkSurfaceVariant,
                    ),
                  );
                },
              ),

              // Action: Add to Queue
              ListTile(
                leading: const Icon(LucideIcons.listPlus, color: Colors.white, size: 20),
                title: Text('Add to Queue', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(queueProvider.notifier).addToQueue(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${track.title}" to Up Next'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.darkSurfaceVariant,
                    ),
                  );
                },
              ),

              // Action: Favorite / Liked Song
              ListTile(
                leading: Icon(
                  isFavorite ? LucideIcons.heartCrack : LucideIcons.heart,
                  color: isFavorite ? const Color(0xFFFF4D6D) : Colors.white,
                  size: 20,
                ),
                title: Text(
                  isFavorite ? 'Remove from Liked Songs' : 'Save to Liked Songs',
                  style: AppTypography.bodyMedium,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(favoritesProvider.notifier).toggleFavorite(track);
                },
              ),

              // Action: Download
              ListTile(
                leading: const Icon(LucideIcons.download, color: AppColors.accentNeonBlue, size: 20),
                title: Text('Download', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(downloadServiceProvider).startDownload(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading "${track.title}"...'),
                      backgroundColor: AppColors.darkSurfaceVariant,
                    ),
                  );
                },
              ),

              // Action: View Artist (if artistId or artist available)
              () {
                final artistId = track.extra['artistId']?.toString() ??
                    track.extra['primary_artist_id']?.toString();
                if (artistId != null && artistId.isNotEmpty) {
                  return ListTile(
                    leading: const Icon(LucideIcons.user, color: Colors.white, size: 20),
                    title: Text('View Artist (${track.artist})', style: AppTypography.bodyMedium),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArtistDetailScreen(
                            artistId: artistId,
                            artistName: track.artist,
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              }(),

              // Action: View Album (if albumId or album available)
              () {
                final albumId = track.extra['albumId']?.toString() ??
                    track.extra['album_id']?.toString();
                if (albumId != null && albumId.isNotEmpty) {
                  return ListTile(
                    leading: const Icon(LucideIcons.disc, color: Colors.white, size: 20),
                    title: Text('View Album (${track.album ?? "Album"})', style: AppTypography.bodyMedium),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AlbumDetailScreen(
                            albumId: albumId,
                            albumTitle: track.album,
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              }(),
            ],
          ),
        );
      },
    );
  }
}
