import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
import 'package:orbitune/features/search/data/jiosaavn_source.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/domain/models/search_result.dart';

/// Riverpod provider for SearchRepository
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final cacheRepo = ref.watch(searchCacheRepositoryProvider);
  return SearchRepository(
    jioSaavnSource: JioSaavnSource(),
    youTubeSource: YouTubeSource(),
    extractorService: ExtractorService.instance,
    cacheRepository: cacheRepo,
  );
});

/// Central multi-source search aggregator, deduplicator, and stream resolver
class SearchRepository {
  final JioSaavnSource jioSaavnSource;
  final YouTubeSource youTubeSource;
  final ExtractorService extractorService;
  final SearchCacheRepository cacheRepository;

  SearchRepository({
    required this.jioSaavnSource,
    required this.youTubeSource,
    required this.extractorService,
    required this.cacheRepository,
  });

  /// Universal multi-source search
  /// [source] can be: 'all', 'jiosaavn', 'youtube', 'extractor'
  Future<SearchResult> search(
    String query, {
    String source = 'all',
    int page = 1,
    int limit = 25,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return SearchResult(query: query, source: source);
    }

    // Save to search history cache
    await cacheRepository.addSearchQuery(trimmed);

    // If the search query is a direct media URL, extract it immediately via Extractor
    if (extractorService.isSupportedMediaUrl(trimmed)) {
      final extractedTrack = await extractorService.extractTrackInfo(trimmed);
      if (extractedTrack != null) {
        return SearchResult(
          query: trimmed,
          source: 'extractor',
          songs: [extractedTrack],
        );
      }
    }

    switch (source.toLowerCase()) {
      case 'jiosaavn':
        return jioSaavnSource.searchAll(trimmed, page: page, limit: limit);

      case 'youtube':
        final ytSongs = await youTubeSource.search(trimmed, limit: limit);
        final ytPlaylists = await youTubeSource.searchPlaylists(trimmed, limit: 5);
        return SearchResult(
          query: trimmed,
          source: 'youtube',
          songs: ytSongs,
          playlists: ytPlaylists,
        );

      case 'extractor':
        final track = await extractorService.extractTrackInfo(trimmed);
        return SearchResult(
          query: trimmed,
          source: 'extractor',
          songs: track != null ? [track] : const [],
        );

      case 'all':
      default:
        return _searchAggregated(trimmed, page: page, limit: limit);
    }
  }

  /// Aggregates search results from JioSaavn and YouTube concurrently, deduplicates, and ranks
  Future<SearchResult> _searchAggregated(String query, {int page = 1, int limit = 25}) async {
    try {
      final futures = await Future.wait([
        jioSaavnSource.searchAll(query, page: page, limit: limit),
        youTubeSource.search(query, limit: limit),
        youTubeSource.searchPlaylists(query, limit: 5),
      ]);

      final saavnResult = futures[0] as SearchResult;
      final ytSongs = futures[1] as List<Track>;
      final ytPlaylists = futures[2] as List<PlaylistModel>;

      // Deduplicate songs (favor 320kbps JioSaavn versions, append unique YouTube tracks)
      final mergedSongs = _deduplicateSongs(saavnResult.songs, ytSongs);

      // Merge playlists
      final mergedPlaylists = <PlaylistModel>[
        ...saavnResult.playlists,
        ...ytPlaylists,
      ];

      return SearchResult(
        query: query,
        source: 'all',
        songs: mergedSongs,
        albums: saavnResult.albums,
        artists: saavnResult.artists,
        playlists: mergedPlaylists,
      );
    } catch (e) {
      debugPrint('[SearchRepository] _searchAggregated error: $e');
      // Fallback to JioSaavn if YouTube fails
      return jioSaavnSource.searchAll(query, page: page, limit: limit);
    }
  }

  /// Resolves direct, playable audio stream URL for any [Track] based on its origin source
  Future<String?> resolveStreamUrl(
    Track track, {
    AudioQuality quality = AudioQuality.high320k,
  }) async {
    // 1. If local file exists, play local
    if (track.isOfflineAvailable) {
      return track.localFilePath;
    }

    // 2. JioSaavn source: Decrypt DES-ECB or format bitrate
    if (track.source == 'jiosaavn') {
      if (track.streamUrl != null && track.streamUrl!.isNotEmpty) {
        return AudioDecryptor.formatQualityUrl(track.streamUrl!, quality);
      }
      final encryptedUrl = track.extra['encrypted_media_url']?.toString();
      if (encryptedUrl != null && encryptedUrl.isNotEmpty) {
        final decrypted = AudioDecryptor.decryptMediaUrl(encryptedUrl, quality: quality);
        if (decrypted != null) return decrypted;
      }
      // Re-fetch song details if URL is missing
      final fresh = await jioSaavnSource.getSongDetails(track.id);
      if (fresh?.streamUrl != null) {
        return AudioDecryptor.formatQualityUrl(fresh!.streamUrl!, quality);
      }
    }

    // 3. YouTube source: Fetch stream manifest & extract high bitrate audio stream
    if (track.source == 'youtube') {
      return youTubeSource.getAudioStreamUrl(track.id, quality: quality);
    }

    // 4. Extractor source: Extract direct audio stream
    if (track.source == 'extractor') {
      final originalUrl = track.extra['originalUrl']?.toString() ?? track.streamUrl;
      if (originalUrl != null) {
        return extractorService.getBestAudioStreamUrl(originalUrl);
      }
    }

    return track.streamUrl;
  }

  /// Fetches details of a specific album
  Future<AlbumModel?> getAlbumDetails(String albumId, {String source = 'jiosaavn'}) async {
    if (source == 'jiosaavn') {
      return jioSaavnSource.getAlbumDetails(albumId);
    }
    return null;
  }

  /// Fetches details of a specific artist
  Future<ArtistModel?> getArtistDetails(String artistId, {String source = 'jiosaavn'}) async {
    if (source == 'jiosaavn') {
      return jioSaavnSource.getArtistDetails(artistId);
    }
    return null;
  }

  /// Fetches details of a specific playlist
  Future<PlaylistModel?> getPlaylistDetails(String playlistId, {String source = 'jiosaavn'}) async {
    if (source == 'youtube') {
      return youTubeSource.getPlaylistDetails(playlistId);
    }
    return jioSaavnSource.getPlaylistDetails(playlistId);
  }

  /// Fetches song recommendations / Radio for [track]
  Future<List<Track>> getRecommendations(Track track) async {
    if (track.source == 'youtube') {
      return youTubeSource.getRelatedSongs(track.id);
    }
    final recos = await jioSaavnSource.getSongRecommendations(track.id);
    if (recos.isNotEmpty) return recos;

    // Fallback: search by artist
    return jioSaavnSource.searchSongs(track.artist, limit: 10);
  }

  /// Fetches trending charts & discovery sections
  Future<Map<String, dynamic>> getTrending({String language = 'hindi,english'}) async {
    return jioSaavnSource.getTrendingModules(language: language);
  }

  /// Smart song deduplication algorithm
  List<Track> _deduplicateSongs(List<Track> primaryTracks, List<Track> secondaryTracks) {
    final Set<String> seenSignatures = {};
    final List<Track> result = [];

    // Add primary tracks (JioSaavn 320kbps) first
    for (final track in primaryTracks) {
      final sig = _generateSongSignature(track.title, track.artist);
      if (!seenSignatures.contains(sig)) {
        seenSignatures.add(sig);
        result.add(track);
      }
    }

    // Add secondary tracks (YouTube) if not duplicate
    for (final track in secondaryTracks) {
      final sig = _generateSongSignature(track.title, track.artist);
      if (!seenSignatures.contains(sig)) {
        seenSignatures.add(sig);
        result.add(track);
      }
    }

    return result;
  }

  String _generateSongSignature(String title, String artist) {
    final cleanT = _simplifyString(AudioDecryptor.cleanTrackTitle(title));
    final cleanA = _simplifyString(artist);
    // Take first 2 words of title and first word of artist for robust fuzzy matching
    final tParts = cleanT.split(' ').take(3).join('');
    final aParts = cleanA.split(' ').take(1).join('');
    return '$tParts|$aParts';
  }

  String _simplifyString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Closes all underlying source clients
  void close() {
    jioSaavnSource.close();
    youTubeSource.close();
  }
}
