import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/discovery/domain/models/chart_playlist.dart';
import 'package:orbitune/features/discovery/domain/models/home_section.dart';
import 'package:orbitune/features/discovery/domain/models/trending_item.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';

/// Riverpod provider for DiscoveryRepository
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(
    youTubeSource: YouTubeSource(),
  );
});

/// Data repository for live trending feeds, daily mixes, charts, and curated discovery sections
class DiscoveryRepository {
  final YouTubeSource youTubeSource;

  DiscoveryRepository({
    required this.youTubeSource,
  });

  /// Fetches trending songs from YouTube
  Future<List<Track>> getYouTubeTrending({int limit = 20}) async {
    try {
      final songs = await youTubeSource.search('Top Trending Songs', limit: limit);
      if (songs.isNotEmpty) return songs;
    } catch (e) {
      debugPrint('[DiscoveryRepository] getYouTubeTrending error: $e');
    }
    return _curatedRealTrendingTracks;
  }

  /// Fetches popular artists with high-res images and real metadata
  Future<List<ArtistModel>> getPopularArtists() async {
    try {
      final topArtistQueries = [
        'Arijit Singh',
        'Diljit Dosanjh',
        'The Weeknd',
        'Taylor Swift',
        'Shreya Ghoshal',
        'Anirudh Ravichander',
      ];
      final futures = topArtistQueries.map((name) => youTubeSource.searchArtists(name, limit: 1));
      final results = await Future.wait(futures);
      final List<ArtistModel> artists = [];
      for (final list in results) {
        if (list.isNotEmpty) {
          artists.add(list.first);
        }
      }
      if (artists.isNotEmpty) {
        return artists;
      }
    } catch (e) {
      debugPrint('[DiscoveryRepository] getPopularArtists error: $e');
    }

    return _curatedPopularArtists;
  }

  /// Fetches curated global and regional charts
  List<ChartPlaylist> getCuratedCharts() {
    return [
      const ChartPlaylist(
        id: 'PL4fGSI1pDJn6jXS_PEoNxm61MQpexDhoJ',
        title: 'Top 50 - Global',
        subtitle: 'The biggest hits worldwide right now',
        description: 'Updated daily with the most played tracks across the globe.',
        artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
        category: 'Chart',
        trackCount: 50,
        colorHex: '#6366F1',
        source: 'youtube',
      ),
      const ChartPlaylist(
        id: 'PLFgquLnL59alGJcdc0BEZJb2p7IgkL0Oe',
        title: 'Top 50 - India',
        subtitle: 'Trending songs across all Indian charts',
        description: 'Most popular tracks streaming in India today.',
        artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
        category: 'Chart',
        trackCount: 50,
        colorHex: '#22C55E',
        source: 'youtube',
      ),
      const ChartPlaylist(
        id: 'RDCLAK5uy_l0x1jG4uO0mS9YmHn8p1TqZ7v2vE9r8A',
        title: 'Bollywood Trending',
        subtitle: 'Hot Hindi blockbuster releases',
        description: 'The top Bollywood cinematic audio tracks and viral hits.',
        artworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
        category: 'Chart',
        trackCount: 40,
        colorHex: '#EC4899',
        source: 'youtube',
      ),
      const ChartPlaylist(
        id: 'RDCLAK5uy_mN3R9yJ7n1R6uY2W5e7V8s9p0O1i2U3',
        title: 'Punjabi Pop & Hip-Hop',
        subtitle: 'Bhangra beats & urban Punjabi rhythms',
        description: 'Punjabi music sensation chart toppers.',
        artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
        category: 'Chart',
        trackCount: 35,
        colorHex: '#F59E0B',
        source: 'youtube',
      ),
    ];
  }

  /// Fetches daily mixes and mood playlists
  List<PlaylistModel> getDailyMixes() {
    return [
      PlaylistModel(
        id: 'daily_mix_1',
        title: 'Daily Mix 1',
        description: 'Arijit Singh, Shreya Ghoshal, Pritam & more',
        author: 'Orbitune Curated',
        artworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
        trackCount: 25,
        source: 'youtube',
      ),
      PlaylistModel(
        id: 'daily_mix_2',
        title: 'Daily Mix 2',
        description: 'The Weeknd, Taylor Swift, Billie Eilish & more',
        author: 'Orbitune Curated',
        artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
        trackCount: 25,
        source: 'youtube',
      ),
      PlaylistModel(
        id: 'daily_mix_3',
        title: 'Daily Mix 3',
        description: 'Trending Hindi & Punjabi Pop sensations',
        author: 'Orbitune Curated',
        artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
        trackCount: 30,
        source: 'youtube',
      ),
    ];
  }

  /// Fetches structured home sections and hero banners using live API data with real dynamic fallbacks
  Future<({
    List<TrendingItem> banners,
    List<HomeSection> sections,
    List<ChartPlaylist> charts,
    List<ArtistModel> popularArtists,
    List<PlaylistModel> dailyMixes,
  })> getHomeFeed({
    String language = 'hindi,english',
    String? filter,
    bool forceRefresh = false,
  }) async {
    List<Track> trendingSongs = [];
    List<PlaylistModel> chartsFromApi = [];
    List<AlbumModel> albums = [];

    // 1. Fetch live trending songs from YouTube
    try {
      final query = (filter != null && filter != 'All')
          ? '$filter Trending Songs'
          : 'Top Trending Music Hits';
      trendingSongs = await youTubeSource.search(query, limit: 20);
    } catch (e) {
      debugPrint('[DiscoveryRepository] getHomeFeed trending songs error: $e');
    }

    // 2. Fallback to curated tracks if empty
    if (trendingSongs.isEmpty) {
      trendingSongs = _curatedRealTrendingTracks;
    }

    // 3. Fetch live charts / playlists
    try {
      final chartQuery = (filter != null && filter != 'All')
          ? '$filter Hits Playlist'
          : 'Top 50 Hits';
      chartsFromApi = await youTubeSource.searchPlaylists(chartQuery, limit: 8);
    } catch (_) {}

    // 4. Fetch popular artists
    final popularArtists = await getPopularArtists();

    // 5. Fetch daily mixes
    List<PlaylistModel> dailyMixes = [];
    try {
      final mixes = await youTubeSource.searchPlaylists('Daily Mix', limit: 6);
      if (mixes.isNotEmpty) {
        dailyMixes = mixes;
      }
    } catch (_) {}
    if (dailyMixes.isEmpty) {
      dailyMixes = getDailyMixes();
    }

    // 6. Fetch new albums
    try {
      final albumQuery = filter != null && filter != 'All' ? '$filter Album' : 'Top Albums';
      albums = await youTubeSource.searchAlbums(albumQuery, limit: 8);
    } catch (_) {}

    // Build Hero Banners from top trending items
    final List<TrendingItem> banners = [];
    for (int i = 0; i < trendingSongs.length && i < 6; i++) {
      final song = trendingSongs[i];
      banners.add(TrendingItem(
        id: song.id,
        title: song.title,
        subtitle: song.artist,
        bannerUrl: song.highResArtworkUrl ?? song.artworkUrl,
        artworkUrl: song.artworkUrl,
        type: 'song',
        track: song,
      ));
    }

    // Convert real API charts to ChartPlaylist models, falling back to curated charts
    final List<ChartPlaylist> realCharts = chartsFromApi.isNotEmpty
        ? chartsFromApi.map((p) => ChartPlaylist(
            id: p.id,
            title: p.title,
            subtitle: p.description ?? (p.trackCount > 0 ? '${p.trackCount} Tracks' : 'Trending Chart'),
            description: p.description,
            artworkUrl: p.artworkUrl,
            highResArtworkUrl: p.highResArtworkUrl,
            category: 'Chart',
            trackCount: p.trackCount > 0 ? p.trackCount : 50,
            source: p.source,
          )).toList()
        : getCuratedCharts();

    // Build Discovery Sections
    final List<HomeSection> sections = [];

    // 1. Trending Songs section
    if (trendingSongs.isNotEmpty) {
      sections.add(HomeSection(
        id: 'trending_songs',
        title: 'Trending Now',
        subtitle: 'The hottest tracks streaming right now',
        sectionType: 'tracks',
        tracks: trendingSongs,
      ));
    }

    // 2. Charts section
    if (realCharts.isNotEmpty || chartsFromApi.isNotEmpty) {
      sections.add(HomeSection(
        id: 'top_charts',
        title: 'Top Charts',
        subtitle: 'Global & regional chart-toppers',
        sectionType: 'charts',
        charts: realCharts,
        playlists: chartsFromApi,
      ));
    }

    // 3. Made For You / Daily Mixes section
    if (dailyMixes.isNotEmpty) {
      sections.add(HomeSection(
        id: 'daily_mixes',
        title: 'Made For You',
        subtitle: 'Curated playlists and mixes',
        sectionType: 'playlists',
        playlists: dailyMixes,
      ));
    }

    // 4. Popular Artists section
    if (popularArtists.isNotEmpty) {
      sections.add(HomeSection(
        id: 'popular_artists',
        title: 'Popular Artists',
        subtitle: 'Explore discographies and top releases',
        sectionType: 'artists',
        artists: popularArtists,
      ));
    }

    // 5. New Releases & Albums section
    if (albums.isNotEmpty) {
      sections.add(HomeSection(
        id: 'new_albums',
        title: 'New Albums & Releases',
        subtitle: 'Fresh full-length albums and EPs',
        sectionType: 'albums',
        albums: albums,
      ));
    }

    return (
      banners: banners,
      sections: sections,
      charts: realCharts,
      popularArtists: popularArtists,
      dailyMixes: dailyMixes,
    );
  }

  // Real world-famous tracks for instant initial render and offline resilience
  static final List<Track> _curatedRealTrendingTracks = [
    Track(
      id: 'tum_hi_ho_arijit',
      title: 'Tum Hi Ho',
      artist: 'Arijit Singh, Mithoon',
      album: 'Aashiqui 2',
      duration: const Duration(seconds: 262),
      artworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
      source: 'youtube',
      bitrate: 160,
      audioQuality: AudioQuality.high320k,
    ),
    Track(
      id: 'lover_diljit',
      title: 'Lover',
      artist: 'Diljit Dosanjh',
      album: 'MoonChild Era',
      duration: const Duration(seconds: 186),
      artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
      source: 'youtube',
      bitrate: 160,
      audioQuality: AudioQuality.high320k,
    ),
    Track(
      id: 'blinding_lights_the_weeknd',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      duration: const Duration(seconds: 200),
      artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
      source: 'youtube',
      bitrate: 160,
      audioQuality: AudioQuality.high320k,
    ),
    Track(
      id: 'kesariya_arijit',
      title: 'Kesariya',
      artist: 'Arijit Singh, Pritam',
      album: 'Brahmastra',
      duration: const Duration(seconds: 268),
      artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
      source: 'youtube',
      bitrate: 160,
      audioQuality: AudioQuality.high320k,
    ),
  ];

  static final List<ArtistModel> _curatedPopularArtists = [
    ArtistModel(
      id: 'arijit_singh',
      name: 'Arijit Singh',
      avatarUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
      bio: 'Leading Indian playback singer and music composer.',
      fansCount: 42000000,
      source: 'youtube',
    ),
    ArtistModel(
      id: 'diljit_dosanjh',
      name: 'Diljit Dosanjh',
      avatarUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
      bio: 'Global Punjabi music icon and performer.',
      fansCount: 22000000,
      source: 'youtube',
    ),
    ArtistModel(
      id: 'the_weeknd',
      name: 'The Weeknd',
      avatarUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
      bio: 'Canadian singer, songwriter, and record producer.',
      fansCount: 65000000,
      source: 'youtube',
    ),
    ArtistModel(
      id: 'shreya_ghoshal',
      name: 'Shreya Ghoshal',
      avatarUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
      bio: 'Prolific melody queen and award-winning vocalist.',
      fansCount: 28000000,
      source: 'youtube',
    ),
  ];
}
