import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/discovery/domain/models/chart_playlist.dart';
import 'package:orbitune/features/discovery/domain/models/home_section.dart';
import 'package:orbitune/features/discovery/domain/models/trending_item.dart';
import 'package:orbitune/features/search/data/jiosaavn_source.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';

/// Riverpod provider for DiscoveryRepository
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(
    jioSaavnSource: JioSaavnSource(),
    youTubeSource: YouTubeSource(),
  );
});

/// Data repository for trending feeds, daily mixes, charts, and curated discovery sections
class DiscoveryRepository {
  final JioSaavnSource jioSaavnSource;
  final YouTubeSource youTubeSource;

  DiscoveryRepository({
    required this.jioSaavnSource,
    required this.youTubeSource,
  });

  /// Fetches trending songs from YouTube
  Future<List<Track>> getYouTubeTrending({int limit = 20}) async {
    try {
      return await youTubeSource.search('Top Trending Songs', limit: limit);
    } catch (e) {
      debugPrint('[DiscoveryRepository] getYouTubeTrending error: $e');
      return const [];
    }
  }

  /// Fetches popular artists with high-res images
  Future<List<ArtistModel>> getPopularArtists() async {
    try {
      // Search for top trending artists
      final res = await jioSaavnSource.searchAll('Arijit Singh Diljit Dosanjh The Weeknd Taylor Swift', limit: 10);
      if (res.artists.isNotEmpty) {
        return res.artists;
      }
    } catch (e) {
      debugPrint('[DiscoveryRepository] getPopularArtists error: $e');
    }

    return _fallbackPopularArtists;
  }

  /// Fetches curated global and regional charts
  List<ChartPlaylist> getCuratedCharts() {
    return [
      const ChartPlaylist(
        id: 'chart_top_50_global',
        title: 'Top 50 - Global',
        subtitle: 'The biggest hits worldwide right now',
        description: 'Updated daily with the most played tracks across the globe.',
        artworkUrl: 'https://c.saavncdn.com/editorial/TopWeeklyHitsHindi_20240101_500x500.jpg',
        category: 'Chart',
        trackCount: 50,
        colorHex: '#6366F1',
      ),
      const ChartPlaylist(
        id: 'chart_top_50_india',
        title: 'Top 50 - India',
        subtitle: 'Trending songs across all Indian charts',
        description: 'Most popular tracks streaming in India today.',
        artworkUrl: 'https://c.saavncdn.com/editorial/TrendingTodayHindi_20240101_500x500.jpg',
        category: 'Chart',
        trackCount: 50,
        colorHex: '#22C55E',
      ),
      const ChartPlaylist(
        id: 'chart_bollywood_trending',
        title: 'Bollywood Trending',
        subtitle: 'Hot Hindi blockbuster releases',
        description: 'The top Bollywood cinematic audio tracks and viral hits.',
        artworkUrl: 'https://c.saavncdn.com/editorial/Let_sPlayArijitSinghHindi_20231222045053_500x500.jpg',
        category: 'Chart',
        trackCount: 40,
        colorHex: '#EC4899',
      ),
      const ChartPlaylist(
        id: 'chart_punjabi_pop',
        title: 'Punjabi Pop & Hip-Hop',
        subtitle: 'Bhangra beats & urban Punjabi rhythms',
        description: 'Punjabi music sensation chart toppers.',
        artworkUrl: 'https://c.saavncdn.com/editorial/Let_sPlayDiljitDosanjhPunjabi_20231222045053_500x500.jpg',
        category: 'Chart',
        trackCount: 35,
        colorHex: '#F59E0B',
      ),
      const ChartPlaylist(
        id: 'chart_viral_hits',
        title: 'Viral Hits 2026',
        subtitle: 'Social media trending & viral sensations',
        description: 'Tracks taking the internet by storm.',
        artworkUrl: 'https://c.saavncdn.com/editorial/ViralHitsHindi_20240101_500x500.jpg',
        category: 'Chart',
        trackCount: 45,
        colorHex: '#06B6D4',
      ),
    ];
  }

  /// Fetches daily mixes and mood playlists
  List<PlaylistModel> getDailyMixes() {
    return [
      PlaylistModel(
        id: 'mix_daily_1',
        title: 'Daily Mix 1',
        description: 'Arijit Singh, Shreya Ghoshal, Pritam & more',
        author: 'Orbitune Music',
        artworkUrl: 'https://c.saavncdn.com/editorial/Let_sPlayArijitSinghHindi_20231222045053_500x500.jpg',
        trackCount: 25,
        source: 'jiosaavn',
      ),
      PlaylistModel(
        id: 'mix_daily_2',
        title: 'Daily Mix 2',
        description: 'The Weeknd, Taylor Swift, Billie Eilish & more',
        author: 'Orbitune Music',
        artworkUrl: 'https://c.saavncdn.com/editorial/TopWeeklyHitsEnglish_20240101_500x500.jpg',
        trackCount: 25,
        source: 'jiosaavn',
      ),
      PlaylistModel(
        id: 'mix_chill_lofi',
        title: 'Lo-Fi Chill & Focus',
        description: 'Relaxing beats to study, chill, or work to',
        author: 'Orbitune Beats',
        artworkUrl: 'https://c.saavncdn.com/editorial/ChillHitsHindi_20240101_500x500.jpg',
        trackCount: 30,
        source: 'jiosaavn',
      ),
      PlaylistModel(
        id: 'mix_workout_energy',
        title: 'High-Energy Workout',
        description: 'Power up your gym session with high-BPM tracks',
        author: 'Orbitune Fitness',
        artworkUrl: 'https://c.saavncdn.com/editorial/WorkoutHindi_20240101_500x500.jpg',
        trackCount: 30,
        source: 'jiosaavn',
      ),
    ];
  }

  /// Fetches structured home sections and hero banners
  Future<({
    List<TrendingItem> banners,
    List<HomeSection> sections,
    List<ChartPlaylist> charts,
    List<ArtistModel> popularArtists,
    List<PlaylistModel> dailyMixes,
  })> getHomeFeed({
    String language = 'hindi,english',
    String? filter,
  }) async {
    List<Track> trendingSongs = [];
    List<PlaylistModel> chartsFromApi = [];
    List<AlbumModel> albums = [];

    try {
      final modules = await jioSaavnSource.getTrendingModules(language: language);
      trendingSongs = List<Track>.from(modules['trendingSongs'] as List? ?? []);
      chartsFromApi = List<PlaylistModel>.from(modules['charts'] as List? ?? []);
      albums = List<AlbumModel>.from(modules['albums'] as List? ?? []);
    } catch (e) {
      debugPrint('[DiscoveryRepository] getHomeFeed error: $e');
    }

    // If API returned empty songs, search fallback trending songs
    if (trendingSongs.isEmpty) {
      try {
        final query = (filter != null && filter != 'All') ? '$filter Hits' : 'Trending Hits 2026';
        trendingSongs = await jioSaavnSource.searchSongs(query, limit: 15);
      } catch (_) {}
    }

    // If still empty, use curated fallback tracks
    if (trendingSongs.isEmpty) {
      trendingSongs = _fallbackTrendingTracks;
    }

    // Build Hero Banners from top trending items
    final List<TrendingItem> banners = [];
    for (int i = 0; i < trendingSongs.length && i < 5; i++) {
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

    final curatedCharts = getCuratedCharts();
    final popularArtists = await getPopularArtists();
    final dailyMixes = getDailyMixes();

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
    sections.add(HomeSection(
      id: 'top_charts',
      title: 'Top Charts',
      subtitle: 'Global & regional chart-toppers',
      sectionType: 'charts',
      charts: curatedCharts,
      playlists: chartsFromApi,
    ));

    // 3. Daily Mixes section
    sections.add(HomeSection(
      id: 'daily_mixes',
      title: 'Made For You',
      subtitle: 'Personalized mixes and playlists',
      sectionType: 'playlists',
      playlists: dailyMixes,
    ));

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
      charts: curatedCharts,
      popularArtists: popularArtists,
      dailyMixes: dailyMixes,
    );
  }

  // Curated Fallback Data for offline / instant-render resilience
  static final List<Track> _fallbackTrendingTracks = [
    Track(
      id: 'track_orbit_1',
      title: 'Midnight Odyssey',
      artist: 'Arijit Singh, Sachin-Jigar',
      album: 'Orbitune Originals',
      duration: const Duration(seconds: 215),
      artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1000&q=80',
      source: 'jiosaavn',
      bitrate: 320,
      audioQuality: AudioQuality.high320k,
    ),
    Track(
      id: 'track_orbit_2',
      title: 'Neon Skyline',
      artist: 'Diljit Dosanjh',
      album: 'Urban Vibes',
      duration: const Duration(seconds: 198),
      artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1000&q=80',
      source: 'jiosaavn',
      bitrate: 320,
      audioQuality: AudioQuality.high320k,
    ),
    Track(
      id: 'track_orbit_3',
      title: 'Starry Echoes',
      artist: 'The Weeknd',
      album: 'After Midnight',
      duration: const Duration(seconds: 234),
      artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1000&q=80',
      source: 'youtube',
      bitrate: 320,
      audioQuality: AudioQuality.high320k,
    ),
    Track(
      id: 'track_orbit_4',
      title: 'Soul Resonance',
      artist: 'Shreya Ghoshal',
      album: 'Acoustic Sessions',
      duration: const Duration(seconds: 245),
      artworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&q=80',
      highResArtworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1000&q=80',
      source: 'jiosaavn',
      bitrate: 320,
      audioQuality: AudioQuality.high320k,
    ),
  ];

  static final List<ArtistModel> _fallbackPopularArtists = [
    ArtistModel(
      id: 'artist_arijit',
      name: 'Arijit Singh',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=1000&q=80',
      bio: 'Leading Indian playback singer and music composer.',
      fansCount: 42000000,
      source: 'jiosaavn',
    ),
    ArtistModel(
      id: 'artist_diljit',
      name: 'Diljit Dosanjh',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1000&q=80',
      bio: 'Global Punjabi music icon and performer.',
      fansCount: 22000000,
      source: 'jiosaavn',
    ),
    ArtistModel(
      id: 'artist_the_weeknd',
      name: 'The Weeknd',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=1000&q=80',
      bio: 'Canadian singer, songwriter, and record producer.',
      fansCount: 65000000,
      source: 'youtube',
    ),
    ArtistModel(
      id: 'artist_shreya',
      name: 'Shreya Ghoshal',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1000&q=80',
      bio: 'Prolific melody queen and award-winning vocalist.',
      fansCount: 28000000,
      source: 'jiosaavn',
    ),
    ArtistModel(
      id: 'artist_taylor',
      name: 'Taylor Swift',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=1000&q=80',
      bio: 'Global pop superstar and songwriter.',
      fansCount: 95000000,
      source: 'youtube',
    ),
  ];
}
