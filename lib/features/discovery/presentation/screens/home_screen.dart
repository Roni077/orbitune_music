import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/widgets/error_view.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/core/widgets/section_header.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/discovery/domain/models/chart_playlist.dart';
import 'package:orbitune/features/discovery/domain/models/home_section.dart';
import 'package:orbitune/features/discovery/domain/models/trending_item.dart';
import 'package:orbitune/features/discovery/presentation/providers/home_provider.dart';
import 'package:orbitune/features/discovery/presentation/widgets/artist_avatar_card.dart';
import 'package:orbitune/features/discovery/presentation/widgets/banner_carousel.dart';
import 'package:orbitune/features/discovery/presentation/widgets/greeting_header.dart';
import 'package:orbitune/features/discovery/presentation/widgets/quick_picks_grid.dart';
import 'package:orbitune/features/discovery/presentation/widgets/song_card_horizontal.dart';
import 'package:orbitune/features/discovery/presentation/widgets/trending_chips.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/playlist_detail_screen.dart';

/// Main Discovery Home Feed Dashboard with M3 Expressive aesthetics
class HomeScreen extends ConsumerWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accentGreen,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async {
            await ref.read(homeProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Top Greeting Header
              SliverToBoxAdapter(
                child: GreetingHeader(
                  onSearchTap: onSearchTap,
                  onSettingsTap: onSettingsTap,
                ),
              ),

              // 2. Category & Genre Discovery Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: TrendingChips(
                    selectedFilter: homeState.selectedFilter,
                    onFilterSelected: (filter) {
                      ref.read(homeProvider.notifier).setFilter(filter);
                    },
                  ),
                ),
              ),

              // Main Feed Body (Loading Shimmer / Error View / Content)
              if (homeState.isLoading && !homeState.isRefreshing)
                const SliverToBoxAdapter(
                  child: _HomeShimmerLoader(),
                )
              else if (homeState.errorMessage != null && homeState.banners.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: ErrorView(
                      message: homeState.errorMessage!,
                      onRetry: () {
                        ref.read(homeProvider.notifier).loadHomeFeed();
                      },
                    ),
                  ),
                )
              else ...[
                // 3. Hero Trending Banner Carousel
                if (homeState.banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: BannerCarousel(
                      items: homeState.banners,
                      onPlayTap: (item) => _handleBannerPlay(ref, item),
                      onItemTap: (item) => _handleBannerPlay(ref, item),
                    ),
                  ),

                // 4. Quick Picks 2x3 Grid
                if (homeState.quickPicks.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                      child: SectionHeader(
                        title: 'Quick Picks',
                        subtitle: 'Jump back into your favorites',
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: QuickPicksGrid(
                      tracks: homeState.quickPicks,
                      activeTrackId: currentTrack?.id,
                      isPlaying: isPlaying,
                      onTrackTap: (track) => _playTrack(ref, track),
                    ),
                  ),
                ],

                // 5. Dynamic Home Sections
                for (final section in homeState.sections)
                  SliverToBoxAdapter(
                    child: _buildSectionRow(
                      context,
                      ref,
                      section,
                      currentTrack: currentTrack,
                      isPlaying: isPlaying,
                    ),
                  ),

                // 6. Continue Listening Section (if available)
                if (homeState.continueListening.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildContinueListeningSection(
                      context,
                      ref,
                      homeState.continueListening,
                      currentTrack: currentTrack,
                      isPlaying: isPlaying,
                    ),
                  ),

                // Safe bottom padding for floating MiniPlayer & bottom nav
                const SliverToBoxAdapter(
                  child: SizedBox(height: 130),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionRow(
    BuildContext context,
    WidgetRef ref,
    HomeSection section, {
    Track? currentTrack,
    bool isPlaying = false,
  }) {
    if (section.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
          child: SectionHeader(
            title: section.title,
            subtitle: section.subtitle,
          ),
        ),
        SizedBox(
          height: section.sectionType == 'artists' ? 140 : 205,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _getSectionItemCount(section),
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return _buildSectionItem(
                context,
                ref,
                section,
                index,
                currentTrack: currentTrack,
                isPlaying: isPlaying,
              );
            },
          ),
        ),
      ],
    );
  }

  int _getSectionItemCount(HomeSection section) {
    switch (section.sectionType) {
      case 'tracks':
        return section.tracks.length;
      case 'charts':
        return section.charts.length;
      case 'playlists':
        return section.playlists.length;
      case 'artists':
        return section.artists.length;
      case 'albums':
        return section.albums.length;
      default:
        return 0;
    }
  }

  Widget _buildSectionItem(
    BuildContext context,
    WidgetRef ref,
    HomeSection section,
    int index, {
    Track? currentTrack,
    bool isPlaying = false,
  }) {
    switch (section.sectionType) {
      case 'tracks':
        final track = section.tracks[index];
        final isCurrent = track.id == currentTrack?.id;
        return SongCardHorizontal.fromTrack(
          track: track,
          isCurrent: isCurrent,
          isPlaying: isPlaying,
          onTap: () => _playTrack(ref, track),
          onPlayTap: () => _playTrack(ref, track),
        );

      case 'charts':
        final chart = section.charts[index];
        return SongCardHorizontal(
          title: chart.title,
          subtitle: chart.subtitle ?? '${chart.trackCount} Tracks',
          artworkUrl: chart.highResArtworkUrl ?? chart.artworkUrl,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(
                  playlistId: chart.id,
                  playlistTitle: chart.title,
                  source: chart.source,
                ),
              ),
            );
          },
          onPlayTap: () => _handleChartTap(ref, chart),
        );

      case 'playlists':
        final playlist = section.playlists[index];
        return SongCardHorizontal(
          title: playlist.title,
          subtitle: playlist.author ?? '${playlist.trackCount} Songs',
          artworkUrl: playlist.highResArtworkUrl ?? playlist.artworkUrl,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(
                  playlistId: playlist.id,
                  playlistTitle: playlist.title,
                  source: playlist.source,
                ),
              ),
            );
          },
          onPlayTap: () => _handlePlaylistTap(ref, playlist),
        );

      case 'artists':
        final artist = section.artists[index];
        return ArtistAvatarCard(
          artist: artist,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArtistDetailScreen(
                  artistId: artist.id,
                  artistName: artist.name,
                ),
              ),
            );
          },
        );

      case 'albums':
        final album = section.albums[index];
        return SongCardHorizontal(
          title: album.title,
          subtitle: album.artist,
          artworkUrl: album.highResArtworkUrl ?? album.artworkUrl,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(
                  albumId: album.id,
                  albumTitle: album.title,
                ),
              ),
            );
          },
          onPlayTap: () => _handleAlbumTap(ref, album),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContinueListeningSection(
    BuildContext context,
    WidgetRef ref,
    List<Track> tracks, {
    Track? currentTrack,
    bool isPlaying = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
          child: SectionHeader(
            title: 'Continue Listening',
            subtitle: 'Picked up where you left off',
          ),
        ),
        SizedBox(
          height: 205,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tracks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isCurrent = track.id == currentTrack?.id;
              return SongCardHorizontal.fromTrack(
                track: track,
                isCurrent: isCurrent,
                isPlaying: isPlaying,
                onTap: () => _playTrack(ref, track),
                onPlayTap: () => _playTrack(ref, track),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playTrack(WidgetRef ref, Track track) {
    ref.read(queueProvider.notifier).playTrack(track);
  }

  void _handleBannerPlay(WidgetRef ref, TrendingItem item) {
    if (item.track != null) {
      _playTrack(ref, item.track!);
    }
  }

  Future<void> _handleChartTap(WidgetRef ref, ChartPlaylist chart) async {
    if (chart.songs.isNotEmpty) {
      await ref.read(queueProvider.notifier).playPlaylist(
            chart.songs,
            queueTitle: chart.title,
          );
      return;
    }

    try {
      final searchRepo = ref.read(searchRepositoryProvider);
      final details = await searchRepo.getPlaylistDetails(
        chart.id,
        source: chart.source,
        playlistTitle: chart.title,
      );
      if (details != null && details.songs.isNotEmpty) {
        await ref.read(queueProvider.notifier).playPlaylist(
              details.songs,
              queueTitle: chart.title,
            );
        return;
      }

      // Fallback: search songs matching the chart title
      final searchResult = await searchRepo.search(chart.title, limit: 20);
      if (searchResult.songs.isNotEmpty) {
        await ref.read(queueProvider.notifier).playPlaylist(
              searchResult.songs,
              queueTitle: chart.title,
            );
      }
    } catch (e) {
      debugPrint('[HomeScreen] _handleChartTap play error: $e');
    }
  }

  Future<void> _handlePlaylistTap(WidgetRef ref, PlaylistModel playlist) async {
    if (playlist.songs.isNotEmpty) {
      await ref.read(queueProvider.notifier).playPlaylist(
            playlist.songs,
            queueTitle: playlist.title,
          );
      return;
    }

    try {
      final searchRepo = ref.read(searchRepositoryProvider);
      final details = await searchRepo.getPlaylistDetails(
        playlist.id,
        source: playlist.source,
        playlistTitle: playlist.title,
      );
      if (details != null && details.songs.isNotEmpty) {
        await ref.read(queueProvider.notifier).playPlaylist(
              details.songs,
              queueTitle: playlist.title,
            );
        return;
      }

      // Fallback: search songs matching the playlist title
      final searchResult = await searchRepo.search(playlist.title, limit: 20);
      if (searchResult.songs.isNotEmpty) {
        await ref.read(queueProvider.notifier).playPlaylist(
              searchResult.songs,
              queueTitle: playlist.title,
            );
      }
    } catch (e) {
      debugPrint('[HomeScreen] _handlePlaylistTap play error: $e');
    }
  }

  Future<void> _handleAlbumTap(WidgetRef ref, AlbumModel album) async {
    if (album.songs.isNotEmpty) {
      await ref.read(queueProvider.notifier).playPlaylist(
            album.songs,
            queueTitle: album.title,
          );
      return;
    }

    try {
      final searchRepo = ref.read(searchRepositoryProvider);
      final details = await searchRepo.getAlbumDetails(album.id, source: album.source);
      if (details != null && details.songs.isNotEmpty) {
        await ref.read(queueProvider.notifier).playPlaylist(
              details.songs,
              queueTitle: album.title,
            );
        return;
      }

      // Fallback: search songs matching the album title
      final searchResult = await searchRepo.search(album.title, limit: 15);
      if (searchResult.songs.isNotEmpty) {
        await ref.read(queueProvider.notifier).playPlaylist(
              searchResult.songs,
              queueTitle: album.title,
            );
      }
    } catch (e) {
      debugPrint('[HomeScreen] _handleAlbumTap play error: $e');
    }
  }
}

/// Shimmer Skeleton placeholder loader for HomeScreen
class _HomeShimmerLoader extends StatelessWidget {
  const _HomeShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Shimmer
          ClipRRect(
            borderRadius: AppConstants.roundedLarge,
            child: const ImageShimmer(width: double.infinity, height: 190),
          ),
          const SizedBox(height: 24),

          // Quick picks shimmers
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppConstants.roundedSmall,
                  child: const ImageShimmer(height: 56),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppConstants.roundedSmall,
                  child: const ImageShimmer(height: 56),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppConstants.roundedSmall,
                  child: const ImageShimmer(height: 56),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppConstants.roundedSmall,
                  child: const ImageShimmer(height: 56),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Horizontal Cards Shimmer
          Row(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: AppConstants.roundedMedium,
                      child: const ImageShimmer(width: 130, height: 130),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const ImageShimmer(width: 100, height: 12),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const ImageShimmer(width: 60, height: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
