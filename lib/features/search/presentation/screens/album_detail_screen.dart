import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/audio_badge.dart';
import 'package:orbitune/core/widgets/error_view.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/search/presentation/providers/album_detail_provider.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';
import 'package:share_plus/share_plus.dart';

/// Immersive Album View Screen with high-res artwork, dynamic background glow, full tracklist, and queue actions
class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  final String? albumTitle;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.albumTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumState = ref.watch(albumDetailProvider(albumId));
    final albumNotifier = ref.read(albumDetailProvider(albumId).notifier);
    final album = albumState.album;

    final displayTitle = album?.title ?? albumTitle ?? 'Album Details';
    final artworkUrl = album?.bestArtworkUrl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. SliverAppBar with Back Button & Share Action
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.darkSurface,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, size: 20, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.share2, size: 18, color: Colors.white),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Share.share('Listen to "$displayTitle" on Orbitune!');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Album Hero Header: Artwork, Title, Artist, Metadata, and Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
              child: Column(
                children: [
                  // High-res Album Artwork with ambient shadow
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: AppConstants.roundedLarge,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppConstants.roundedLarge,
                      child: ImageShimmer(
                        imageUrl: artworkUrl,
                        width: 200,
                        height: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Album Title
                  Text(
                    displayTitle,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Artist Name (Tappable to open Artist Profile)
                  if (album != null && album.artist.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        if (album.artistId != null && album.artistId!.isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtistDetailScreen(
                                artistId: album.artistId!,
                                artistName: album.artist,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        album.artist,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Album Metadata: Release Year • Total Songs • Total Runtime Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AudioBadge(type: AudioBadgeType.highQuality320),
                      const SizedBox(width: 8),
                      Text(
                        '${album?.releaseYear ?? "2026"} • ${album?.songs.length ?? album?.totalTracks ?? 0} Songs',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (albumState.totalDuration > Duration.zero) ...[
                        Text(
                          ' • ${Formatters.formatDuration(albumState.totalDuration)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons: Play All, Shuffle, Favorite, Add to Queue
                  Row(
                    children: [
                      // Play All Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            albumNotifier.playAll();
                          },
                          icon: const Icon(LucideIcons.play, size: 18, color: Colors.black),
                          label: const Text('Play All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppConstants.roundedPill,
                            ),
                            textStyle: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Shuffle Button
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          albumNotifier.shuffleAll();
                        },
                        icon: const Icon(LucideIcons.shuffle, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkSurfaceVariant,
                          foregroundColor: Colors.white,
                        ),
                        tooltip: 'Shuffle Album',
                      ),
                      const SizedBox(width: 8),

                      // Favorite Album Button
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          albumNotifier.toggleFavorite();
                        },
                        icon: Icon(
                          albumState.isFavorite ? LucideIcons.heartCrack : LucideIcons.heart,
                          size: 18,
                          color: albumState.isFavorite ? const Color(0xFFFF4D6D) : Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkSurfaceVariant,
                        ),
                        tooltip: albumState.isFavorite ? 'Remove Favorite' : 'Favorite Album',
                      ),
                      const SizedBox(width: 8),

                      // Add to Queue Button
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          albumNotifier.addAllToQueue();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "$displayTitle" tracks to Queue'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.darkSurfaceVariant,
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.listPlus, size: 18, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkSurfaceVariant,
                        ),
                        tooltip: 'Add all to queue',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(color: AppColors.glassBorder, height: 1),
          ),

          // 3. Tracklist Body / Loading / Error
          if (albumState.isLoading) ...[
            const SliverToBoxAdapter(
              child: _AlbumShimmerLoader(),
            ),
          ] else if (albumState.errorMessage != null && (album == null || album.songs.isEmpty)) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: ErrorView(
                  message: albumState.errorMessage!,
                  onRetry: () => albumNotifier.loadAlbumDetails(isRefresh: true),
                ),
              ),
            ),
          ] else if (album != null && album.songs.isNotEmpty) ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = album.songs[index];
                  return TrackTile(
                    track: track,
                    index: index + 1,
                    showIndex: true,
                    showArtwork: false,
                    onTap: () => albumNotifier.playTrackAtIndex(index),
                  );
                },
                childCount: album.songs.length,
              ),
            ),

            // Bottom Spacing for floating player & navigation
            const SliverToBoxAdapter(
              child: SizedBox(height: 130),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton loader for Album tracklist
class _AlbumShimmerLoader extends StatelessWidget {
  const _AlbumShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (int i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const ImageShimmer(height: 14, width: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const ImageShimmer(height: 14, width: 180),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const ImageShimmer(height: 10, width: 100),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const ImageShimmer(height: 12, width: 36),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
