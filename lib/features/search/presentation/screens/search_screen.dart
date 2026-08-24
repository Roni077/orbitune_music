import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/widgets/empty_state_view.dart';
import 'package:orbitune/core/widgets/error_view.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/core/widgets/section_header.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/discovery/presentation/widgets/artist_avatar_card.dart';
import 'package:orbitune/features/discovery/presentation/widgets/song_card_horizontal.dart';
import 'package:orbitune/features/search/presentation/providers/search_provider.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/playlist_detail_screen.dart';
import 'package:orbitune/features/search/presentation/widgets/filter_source_bar.dart';
import 'package:orbitune/features/search/presentation/widgets/recent_searches_view.dart';
import 'package:orbitune/features/search/presentation/widgets/search_bar_widget.dart';
import 'package:orbitune/features/search/presentation/widgets/search_cards.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';
import 'package:orbitune/features/search/presentation/widgets/voice_search_dialog.dart';

/// Universal Multi-Source Real-Time Search Screen with debouncing & source filters
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchProvider).query;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onVoiceSearch() {
    VoiceSearchModal.show(
      context,
      onVoiceRecognized: (query) {
        _searchController.text = query;
        ref.read(searchProvider.notifier).searchImmediate(query);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.read(searchProvider.notifier);

    // Keep text controller in sync if query was changed externally (e.g. from history chips)
    if (_searchController.text != searchState.query && !searchState.isDebouncing) {
      _searchController.value = TextEditingValue(
        text: searchState.query,
        selection: TextSelection.collapsed(offset: searchState.query.length),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Search Bar Header with Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: SearchBarWidget(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: 'Search songs, artists, albums, or paste URL...',
                onChanged: (val) => searchNotifier.onQueryChanged(val),
                onSubmitted: (val) => searchNotifier.searchImmediate(val),
                onClear: () => searchNotifier.clearQuery(),
                onVoiceTap: _onVoiceSearch,
              ),
            ),

            // 2. Filter Bar (Streaming Sources & Media Category Pills)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: FilterSourceBar(
                selectedSource: searchState.sourceFilter,
                selectedCategory: searchState.categoryFilter,
                showCategories: searchState.query.trim().isNotEmpty,
                onSourceChanged: (source) => searchNotifier.setSourceFilter(source),
                onCategoryChanged: (category) => searchNotifier.setCategoryFilter(category),
              ),
            ),

            const Divider(color: AppColors.glassBorder, height: 1),

            // 3. Search Results Body / History / Loader / Empty Views
            Expanded(
              child: _buildSearchBody(searchState, searchNotifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody(SearchState state, SearchNotifier notifier) {
    // A. Empty query -> Show Recent Searches & Trending Tags
    if (state.query.trim().isEmpty) {
      return RecentSearchesView(
        recentSearches: state.recentSearches,
        onSelectQuery: (query) {
          _searchController.text = query;
          notifier.searchImmediate(query);
        },
        onDeleteQuery: (query) => notifier.removeRecentSearch(query),
        onClearAll: () => notifier.clearSearchHistory(),
      );
    }

    // B. Loading / Debouncing state -> Show Shimmer Skeleton
    if (state.isLoading || state.isDebouncing) {
      return const _SearchShimmerSkeleton();
    }

    // C. Error State
    if (state.errorMessage != null && (state.result == null || state.result!.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: ErrorView(
          message: state.errorMessage!,
          onRetry: () => notifier.retry(),
        ),
      );
    }

    // D. Empty Search Results
    final result = state.result;
    if (result == null || result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: EmptyStateView(
            icon: LucideIcons.searchX,
            title: 'No Results Found',
            message: 'No music matching "${state.query}" was found. Try different keywords or switch streaming sources above.',
            buttonText: 'Try "All Sources"',
            onAction: () => notifier.setSourceFilter(SearchSourceFilter.all),
          ),
        ),
      );
    }

    // E. Categorized Search Results
    return _buildResultsList(state, notifier);
  }

  Widget _buildResultsList(SearchState state, SearchNotifier notifier) {
    final result = state.result!;

    switch (state.categoryFilter) {
      // 1. Top Results (Aggregated Multi-Category Overview)
      case SearchCategoryFilter.all:
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 130.0),
          children: [
            // Top Result Hero Banner (if songs exist)
            if (result.songs.isNotEmpty)
              TopResultHeroCard(
                item: result.songs.first,
                surroundingTracks: result.songs,
              ),

            // Top Songs Section
            if (result.songs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: SectionHeader(
                  title: 'Songs',
                  onSeeAll: result.songs.length > 5 ? () => notifier.setCategoryFilter(SearchCategoryFilter.songs) : null,
                ),
              ),
              for (int i = 0; i < result.songs.take(5).length; i++)
                TrackTile(
                  track: result.songs[i],
                  index: i + 1,
                  showIndex: true,
                  queueContext: result.songs,
                  initialIndex: i,
                ),
            ],


            // Artists Section
            if (result.artists.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: SectionHeader(
                  title: 'Artists',
                  onSeeAll: result.artists.length > 3 ? () => notifier.setCategoryFilter(SearchCategoryFilter.artists) : null,
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: result.artists.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final artist = result.artists[index];
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
                  },
                ),
              ),
            ],

            // Albums Section
            if (result.albums.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: SectionHeader(
                  title: 'Albums',
                  onSeeAll: result.albums.length > 3 ? () => notifier.setCategoryFilter(SearchCategoryFilter.albums) : null,
                ),
              ),
              SizedBox(
                height: 205,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: result.albums.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final album = result.albums[index];
                    return SongCardHorizontal(
                      title: album.title,
                      subtitle: album.artist,
                      artworkUrl: album.bestArtworkUrl,
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
                      onPlayTap: () {
                        if (album.songs.isNotEmpty) {
                          ref.read(queueProvider.notifier).playPlaylist(
                                album.songs,
                                queueTitle: album.title,
                              );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: album.id,
                                albumTitle: album.title,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],

            // Playlists Section
            if (result.playlists.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                child: SectionHeader(
                  title: 'Playlists',
                  onSeeAll: result.playlists.length > 3 ? () => notifier.setCategoryFilter(SearchCategoryFilter.playlists) : null,
                ),
              ),
              SizedBox(
                height: 205,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: result.playlists.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final playlist = result.playlists[index];
                    return SongCardHorizontal(
                      title: playlist.title,
                      subtitle: playlist.author ?? '${playlist.trackCount} Songs',
                      artworkUrl: playlist.bestArtworkUrl,
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
                      onPlayTap: () {
                        if (playlist.songs.isNotEmpty) {
                          ref.read(queueProvider.notifier).playPlaylist(
                                playlist.songs,
                                queueTitle: playlist.title,
                              );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                playlistId: playlist.id,
                                playlistTitle: playlist.title,
                                source: playlist.source,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        );

      // 2. Songs Tab
      case SearchCategoryFilter.songs:
        if (result.songs.isEmpty) {
          return const Center(child: Text('No songs found for this search.'));
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 130.0),
          itemCount: result.songs.length,
          itemBuilder: (context, index) {
            final track = result.songs[index];
            return TrackTile(
              track: track,
              index: index + 1,
              showIndex: true,
              queueContext: result.songs,
              initialIndex: index,
            );
          },
        );


      // 3. Artists Tab
      case SearchCategoryFilter.artists:
        if (result.artists.isEmpty) {
          return const Center(child: Text('No artists found for this search.'));
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 130.0),
          itemCount: result.artists.length,
          itemBuilder: (context, index) {
            return ArtistSearchCard(artist: result.artists[index]);
          },
        );

      // 4. Albums Tab
      case SearchCategoryFilter.albums:
        if (result.albums.isEmpty) {
          return const Center(child: Text('No albums found for this search.'));
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 130.0),
          itemCount: result.albums.length,
          itemBuilder: (context, index) {
            return AlbumSearchCard(album: result.albums[index]);
          },
        );

      // 5. Playlists Tab
      case SearchCategoryFilter.playlists:
        if (result.playlists.isEmpty) {
          return const Center(child: Text('No playlists found for this search.'));
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 130.0),
          itemCount: result.playlists.length,
          itemBuilder: (context, index) {
            return PlaylistSearchCard(playlist: result.playlists[index]);
          },
        );
    }
  }
}

/// Shimmer skeleton loader when searching
class _SearchShimmerSkeleton extends StatelessWidget {
  const _SearchShimmerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        // Hero Card Shimmer
        ClipRRect(
          borderRadius: AppConstants.roundedLarge,
          child: const ImageShimmer(height: 100, width: double.infinity),
        ),
        const SizedBox(height: 24),

        // Section Title Shimmer
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const ImageShimmer(height: 16, width: 120),
        ),
        const SizedBox(height: 16),

        // Song Rows Shimmer
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
              ],
            ),
          ),
      ],
    );
  }
}
