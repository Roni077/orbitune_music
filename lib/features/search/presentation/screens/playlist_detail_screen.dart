import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/error_view.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';
import 'package:share_plus/share_plus.dart';

/// Provider for loading online playlist details with title search fallback
final onlinePlaylistProvider = FutureProvider.family<PlaylistModel?, (String, String, String?)>(
  (ref, args) async {
    final searchRepo = ref.watch(searchRepositoryProvider);
    final (playlistId, source, playlistTitle) = args;
    return searchRepo.getPlaylistDetails(
      playlistId,
      source: source,
      playlistTitle: playlistTitle,
    );
  },
);

/// Detailed view screen for online playlists
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final String? playlistTitle;
  final String source;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.playlistTitle,
    this.source = 'youtube',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(onlinePlaylistProvider((playlistId, source, playlistTitle)));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. SliverAppBar with Back & Share buttons
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
                  Share.share('Listen to "${playlistTitle ?? "Playlist"}" on Orbitune!');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Playlist Header & Tracklist
          playlistAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: _PlaylistShimmerLoader(),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: ErrorView(
                  message: 'Failed to load playlist: $err',
                  onRetry: () => ref.refresh(onlinePlaylistProvider((playlistId, source, playlistTitle))),
                ),
              ),
            ),
            data: (playlist) {
              if (playlist == null) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Playlist not found.'),
                    ),
                  ),
                );
              }

              return SliverMainAxisGroup(
                slivers: [
                  // Header Info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
                      child: Column(
                        children: [
                          // Artwork
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: AppConstants.roundedLarge,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                                  blurRadius: 28,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: AppConstants.roundedLarge,
                              child: ImageShimmer(
                                imageUrl: playlist.bestArtworkUrl,
                                width: 180,
                                height: 180,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Title
                          Text(
                            playlist.title,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Creator / Subtitle
                          if (playlist.author != null && playlist.author!.isNotEmpty)
                            Text(
                              'Curated by ${playlist.author}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                          const SizedBox(height: 6),
                          Text(
                            '${playlist.songs.length} Tracks',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              // Play All
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    if (playlist.songs.isNotEmpty) {
                                      ref.read(queueProvider.notifier).playPlaylist(
                                            playlist.songs,
                                            queueTitle: playlist.title,
                                          );
                                    }
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

                              // Shuffle
                              IconButton.filledTonal(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  if (playlist.songs.isNotEmpty) {
                                    final shuffled = List.of(playlist.songs)..shuffle();
                                    ref.read(queueProvider.notifier).playPlaylist(
                                          shuffled,
                                          queueTitle: '${playlist.title} (Shuffled)',
                                        );
                                  }
                                },
                                icon: const Icon(LucideIcons.shuffle, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.darkSurfaceVariant,
                                  foregroundColor: Colors.white,
                                ),
                                tooltip: 'Shuffle Playlist',
                              ),
                              const SizedBox(width: 8),

                              // Add to Queue
                              IconButton.filledTonal(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  for (final s in playlist.songs) {
                                    ref.read(queueProvider.notifier).addToQueue(s);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added "${playlist.title}" to Queue'),
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

                  // Tracklist
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = playlist.songs[index];
                        return TrackTile(
                          track: track,
                          index: index + 1,
                          showIndex: true,
                          onTap: () {
                            ref.read(queueProvider.notifier).playPlaylist(
                                  playlist.songs,
                                  initialIndex: index,
                                  queueTitle: playlist.title,
                                );
                          },
                        );
                      },
                      childCount: playlist.songs.length,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 130),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for playlist details
class _PlaylistShimmerLoader extends StatelessWidget {
  const _PlaylistShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: AppConstants.roundedLarge,
            child: const ImageShimmer(width: 180, height: 180),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const ImageShimmer(width: 160, height: 18),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const ImageShimmer(width: 100, height: 14),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppConstants.roundedSmall,
                    child: const ImageShimmer(height: 48, width: 48),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const ImageShimmer(height: 14, width: 140),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const ImageShimmer(height: 10, width: 80),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
