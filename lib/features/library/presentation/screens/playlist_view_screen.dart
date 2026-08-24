import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/empty_state_view.dart';
import 'package:orbitune/core/widgets/expressive_confirmation_sheet.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/library/presentation/widgets/create_playlist_dialog.dart';
import 'package:orbitune/features/library/presentation/widgets/playlist_share_dialog.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';

/// Detail view for a user-created custom playlist with reordering, editing, and QR sharing
class PlaylistViewScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistViewScreen({
    super.key,
    required this.playlistId,
  });

  static Future<void> open(BuildContext context, String playlistId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistViewScreen(playlistId: playlistId),
      ),
    );
  }

  @override
  ConsumerState<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends ConsumerState<PlaylistViewScreen> {
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final playlist = ref.watch(userPlaylistByIdProvider(widget.playlistId));

    if (playlist == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Playlist not found', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final songs = playlist.songs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              playlist.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
              color: playlist.isPinned ? AppColors.accentYellow : AppColors.textSecondary,
              size: 20,
            ),
            tooltip: playlist.isPinned ? 'Unpin playlist' : 'Pin to top',
            onPressed: () =>
                ref.read(userPlaylistsProvider.notifier).togglePin(playlist.id),
          ),
          IconButton(
            icon: const Icon(LucideIcons.qrCode, color: AppColors.accentCyan, size: 20),
            tooltip: 'Share via QR / JSON',
            onPressed: () => PlaylistShareDialog.show(context, playlist),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary),
            color: AppColors.darkSurfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'edit') {
                CreatePlaylistDialog.show(context, initialPlaylist: playlist);
              } else if (val == 'reorder') {
                setState(() => _isReorderMode = !_isReorderMode);
              } else if (val == 'delete') {
                _confirmDeletePlaylist(context, playlist);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(LucideIcons.pencil, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Edit Name & Details'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reorder',
                child: Row(
                  children: [
                    Icon(
                      _isReorderMode ? LucideIcons.check : LucideIcons.arrowUpDown,
                      size: 16,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(_isReorderMode ? 'Done Reordering' : 'Reorder Songs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: AppColors.accentPink),
                    SizedBox(width: 8),
                    Text('Delete Playlist', style: TextStyle(color: AppColors.accentPink)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Playlist Header Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  // Cover Artwork
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withOpacity(0.2),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: playlist.coverArtworkUrl != null
                            ? CachedNetworkImage(
                                imageUrl: playlist.coverArtworkUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const ImageShimmer(),
                                errorWidget: (_, __, ___) => _buildDefaultCover(),
                              )
                            : _buildDefaultCover(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Playlist Name
                  Text(
                    playlist.name,
                    style: AppTypography.brandTitle.copyWith(
                      fontSize: 22,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (playlist.description != null && playlist.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      playlist.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Song count and runtime
                  Text(
                    '${playlist.songCount} songs • ${Formatters.formatDuration(playlist.totalDuration)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons: Play All & Shuffle
                  if (songs.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              ref.read(queueProvider.notifier).playPlaylist(
                                    songs,
                                    initialIndex: 0,
                                  );
                            },
                            icon: const Icon(LucideIcons.play, size: 18),
                            label: Text(
                              'Play All (${songs.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            final shuffled = List<Track>.from(songs)..shuffle();
                            ref.read(queueProvider.notifier).playPlaylist(
                                  shuffled,
                                  initialIndex: 0,
                                );
                          },
                          icon: const Icon(LucideIcons.shuffle, size: 18),
                          label: const Text('Shuffle'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Track List or Reorderable list
          if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: LucideIcons.music,
                title: 'This Playlist is Empty',
                message:
                    'Add tracks to this playlist from search results, liked songs, or album pages.',
              ),
            )
          else if (_isReorderMode)
            SliverToBoxAdapter(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: songs.length,
                onReorder: (oldIdx, newIdx) {
                  ref.read(userPlaylistsProvider.notifier).reorderTracks(
                        playlist.id,
                        oldIdx,
                        newIdx,
                      );
                },
                itemBuilder: (context, index) {
                  final track = songs[index];
                  return ListTile(
                    key: ValueKey(track.id),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: track.bestArtworkUrl != null
                            ? CachedNetworkImage(
                                imageUrl: track.bestArtworkUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: AppColors.darkSurfaceVariant),
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.minusCircle,
                              color: AppColors.accentPink, size: 20),
                          onPressed: () {
                            ref.read(userPlaylistsProvider.notifier).removeTrackFromPlaylist(
                                  playlist.id,
                                  track.id,
                                );
                          },
                        ),
                        const Icon(LucideIcons.gripVertical,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = songs[index];
                  return Dismissible(
                    key: ValueKey(track.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.accentPink.withOpacity(0.8),
                      child: const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref.read(userPlaylistsProvider.notifier).removeTrackFromPlaylist(
                            playlist.id,
                            track.id,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${track.title}" from playlist'),
                          backgroundColor: AppColors.darkSurfaceVariant,
                        ),
                      );
                    },
                    child: TrackTile(
                      track: track,
                      index: index + 1,
                      showIndex: true,
                      onTap: () {
                        ref.read(queueProvider.notifier).playPlaylist(
                              songs,
                              initialIndex: index,
                            );
                      },
                    ),
                  );
                },
                childCount: songs.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      color: AppColors.darkSurfaceVariant,
      child: const Center(
        child: Icon(
          LucideIcons.listMusic,
          size: 64,
          color: AppColors.accentCyan,
        ),
      ),
    );
  }

  void _confirmDeletePlaylist(BuildContext context, UserPlaylist playlist) async {
    final confirmed = await ExpressiveConfirmationSheet.show(
      context,
      title: 'Delete Playlist?',
      message: 'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      icon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(userPlaylistsProvider.notifier).deletePlaylist(playlist.id);
      if (mounted) {
        Navigator.of(context).pop(); // Go back from playlist view
      }
    }
  }
}
