import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/downloader/presentation/screens/downloads_screen.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/stats_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/library/presentation/screens/favorites_screen.dart';
import 'package:orbitune/features/library/presentation/screens/history_screen.dart';
import 'package:orbitune/features/library/presentation/screens/playlist_view_screen.dart';
import 'package:orbitune/features/library/presentation/screens/stats_screen.dart';
import 'package:orbitune/features/library/presentation/widgets/create_playlist_dialog.dart';
import 'package:orbitune/features/library/presentation/widgets/library_card.dart';
import 'package:orbitune/features/library/presentation/widgets/playlist_share_dialog.dart';

/// Main Library tab dashboard with Liked Songs, Downloads, History, Stats, and Custom Playlists
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final downloads = ref.watch(downloadListProvider);
    final history = ref.watch(historyProvider);
    final stats = ref.watch(statsProvider);
    final playlists = ref.watch(userPlaylistsProvider);

    final completedDownloads = downloads.where((d) => d.isCompleted).length;
    final totalListeningMins = stats.totalListeningTime.inMinutes;
    final statsSubtitle = totalListeningMins > 60
        ? '${(totalListeningMins / 60).toStringAsFixed(1)} hours logged'
        : '$totalListeningMins mins logged';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Your Library', style: AppTypography.brandTitle),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.barChart2, color: AppColors.accentPurple, size: 20),
            tooltip: 'Listening Insights',
            onPressed: () => StatsScreen.open(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.accentGreen, size: 22),
            tooltip: 'New Playlist',
            onPressed: () => CreatePlaylistDialog.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(favoritesProvider.notifier).refresh();
          ref.read(downloadListProvider.notifier).refresh();
          ref.read(historyProvider.notifier).refresh();
          ref.read(statsProvider.notifier).refresh();
        },
        color: AppColors.accentGreen,
        backgroundColor: AppColors.darkSurface,
        child: CustomScrollView(
          slivers: [
            // 1. Quick Access Shortcuts
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    LibraryCard(
                      icon: LucideIcons.heart,
                      accentColor: AppColors.accentPink,
                      title: 'Liked Songs',
                      subtitle: '${favorites.length} songs saved',
                      onTap: () => FavoritesScreen.open(context),
                    ),
                    const SizedBox(height: 10),
                    LibraryCard(
                      icon: LucideIcons.downloadCloud,
                      accentColor: AppColors.accentGreen,
                      title: 'Offline Downloads',
                      subtitle: '$completedDownloads songs available offline',
                      onTap: () => DownloadsScreen.open(context),
                    ),
                    const SizedBox(height: 10),
                    LibraryCard(
                      icon: LucideIcons.history,
                      accentColor: AppColors.accentCyan,
                      title: 'Listening History',
                      subtitle: '${history.length} recently played tracks',
                      onTap: () => HistoryScreen.open(context),
                    ),
                    const SizedBox(height: 10),
                    LibraryCard(
                      icon: LucideIcons.sparkles,
                      accentColor: AppColors.accentPurple,
                      title: 'Listening Insights & Stats',
                      subtitle: statsSubtitle,
                      onTap: () => StatsScreen.open(context),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Playlists Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Playlists (${playlists.length})',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: () => CreatePlaylistDialog.show(context),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Create'),
                    ),
                  ],
                ),
              ),
            ),

            // 3. User Playlists List / Empty state
            if (playlists.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurfaceVariant.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.listPlus,
                            color: AppColors.accentGreen,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Create Your First Playlist',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Save your favorite tracks together and share them via QR code.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => CreatePlaylistDialog.show(context),
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text(
                            'Create Playlist',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final playlist = playlists[index];
                    return _buildPlaylistTile(context, ref, playlist);
                  },
                  childCount: playlists.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    WidgetRef ref,
    UserPlaylist playlist,
  ) {
    return ExpressiveCard(
      onTap: () => PlaylistViewScreen.open(context, playlist.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(16),
      color: AppColors.darkSurface.withOpacity(0.6),
      child: Row(
        children: [
          // Cover artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 54,
              height: 54,
              child: playlist.coverArtworkUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverArtworkUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ImageShimmer(),
                      errorWidget: (_, __, ___) => _buildDefaultPlaylistIcon(),
                    )
                  : _buildDefaultPlaylistIcon(),
            ),
          ),
          const SizedBox(width: 14),

          // Title & song count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (playlist.isPinned) ...[
                      const Icon(LucideIcons.pin, size: 13, color: AppColors.accentYellow),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        playlist.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${playlist.songCount} songs • ${Formatters.formatDuration(playlist.totalDuration)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Actions popup menu
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary, size: 18),
            color: AppColors.darkSurfaceVariant,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'pin') {
                ref.read(userPlaylistsProvider.notifier).togglePin(playlist.id);
              } else if (val == 'edit') {
                CreatePlaylistDialog.show(context, initialPlaylist: playlist);
              } else if (val == 'share') {
                PlaylistShareDialog.show(context, playlist);
              } else if (val == 'delete') {
                ref.read(userPlaylistsProvider.notifier).deletePlaylist(playlist.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      playlist.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(playlist.isPinned ? 'Unpin' : 'Pin to top'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(LucideIcons.pencil, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Edit Playlist'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(LucideIcons.qrCode, size: 16, color: AppColors.accentCyan),
                    SizedBox(width: 8),
                    Text('Share (QR / JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: AppColors.accentPink),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.accentPink)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlaylistIcon() {
    return Container(
      color: AppColors.darkSurfaceVariant,
      child: const Center(
        child: Icon(LucideIcons.listMusic, color: AppColors.accentGreen, size: 22),
      ),
    );
  }
}
