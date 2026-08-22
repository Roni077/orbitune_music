import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
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
    youTubeSource: YouTubeSource(),
    extractorService: ExtractorService.instance,
    cacheRepository: cacheRepo,
  );
});

/// Central YouTube and Extractor search aggregator and stream resolver
class SearchRepository {
  final YouTubeSource youTubeSource;
  final ExtractorService extractorService;
  final SearchCacheRepository cacheRepository;

  SearchRepository({
    required this.youTubeSource,
    required this.extractorService,
    required this.cacheRepository,
  });

  /// Universal multi-source search
  /// [source] can be: 'all', 'youtube', 'extractor'
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

      // Fallback: If native extractor is unavailable, parse direct YouTube link
      final directYtId = _extractYouTubeVideoId(trimmed);
      if (directYtId != null) {
        final directTrack = await youTubeSource.getVideoDetails(directYtId);
        if (directTrack != null) {
          return SearchResult(
            query: trimmed,
            source: 'youtube',
            songs: [directTrack],
          );
        }
      }
    }

    switch (source.toLowerCase()) {
      case 'extractor':
        final track = await extractorService.extractTrackInfo(trimmed);
        return SearchResult(
          query: trimmed,
          source: 'extractor',
          songs: track != null ? [track] : const [],
        );

      case 'youtube':
      case 'all':
      default:
        return _searchYouTube(trimmed, limit: limit);
    }
  }

  /// Searches YouTube Music for songs, artists, albums, and playlists
  Future<SearchResult> _searchYouTube(String query, {int limit = 25}) async {
    try {
      final futures = await Future.wait([
        youTubeSource.search(query, limit: limit),
        youTubeSource.searchPlaylists(query, limit: 5),
        youTubeSource.searchArtists(query, limit: 4),
        youTubeSource.searchAlbums(query, limit: 4),
      ]);

      final songs = futures[0] as List<Track>;
      final playlists = futures[1] as List<PlaylistModel>;
      final artists = futures[2] as List<ArtistModel>;
      final albums = futures[3] as List<AlbumModel>;

      return SearchResult(
        query: query,
        source: 'youtube',
        songs: songs,
        albums: albums,
        artists: artists,
        playlists: playlists,
      );
    } catch (e) {
      debugPrint('[SearchRepository] _searchYouTube error: $e');
      final songs = await youTubeSource.search(query, limit: limit);
      return SearchResult(
        query: query,
        source: 'youtube',
        songs: songs,
      );
    }
  }

  /// Resolves direct, playable audio stream URL for any [Track] in pure audio formats
  Future<String?> resolveStreamUrl(
    Track track, {
    AudioQuality quality = AudioQuality.high320k,
  }) async {
    // 1. If local file exists, play local
    if (track.isOfflineAvailable) {
      return track.localFilePath;
    }

    // 2. Extractor source: Extract direct audio stream
    if (track.source == 'extractor') {
      final originalUrl = track.extra['originalUrl']?.toString() ?? track.streamUrl;
      if (originalUrl != null && (originalUrl.startsWith('http://') || originalUrl.startsWith('https://'))) {
        final stream = await extractorService.getBestAudioStreamUrl(originalUrl);
        if (stream != null) return stream;
      }

      // Fallback: Search YouTube
      try {
        final ytResults = await youTubeSource.search('${track.title} ${track.artist}', limit: 1);
        if (ytResults.isNotEmpty) {
          final stream = await youTubeSource.getAudioStreamUrl(ytResults.first.id, quality: quality);
          if (stream != null) return stream;
        }
      } catch (_) {}
    }

    // 3. YouTube source: Fetch audio-only stream via YouTube Explode
    final ytStream = await youTubeSource.getAudioStreamUrl(track.id, quality: quality);
    if (ytStream != null && ytStream.isNotEmpty) return ytStream;

    // Fallback: Search YouTube by Title + Artist (alternate video match)
    try {
      final ytResults = await youTubeSource.search('${track.title} ${track.artist}', limit: 2);
      for (final candidate in ytResults) {
        if (candidate.id != track.id) {
          final stream = await youTubeSource.getAudioStreamUrl(candidate.id, quality: quality);
          if (stream != null && stream.isNotEmpty) return stream;
        }
      }
    } catch (_) {}

    if (track.streamUrl != null && (track.streamUrl!.startsWith('http://') || track.streamUrl!.startsWith('https://'))) {
      return track.streamUrl;
    }

    return null;
  }

  /// Fetches details of a specific album
  Future<AlbumModel?> getAlbumDetails(String albumId, {String source = 'youtube'}) async {
    return youTubeSource.getAlbumDetails(albumId);
  }

  /// Fetches details of a specific artist
  Future<ArtistModel?> getArtistDetails(String artistId, {String? artistName, String source = 'youtube'}) async {
    return youTubeSource.getArtistDetails(artistId, artistName: artistName);
  }

  /// Fetches details of a specific playlist with fallback search
  Future<PlaylistModel?> getPlaylistDetails(
    String playlistId, {
    String source = 'youtube',
    String? playlistTitle,
  }) async {
    final playlist = await youTubeSource.getPlaylistDetails(playlistId);
    if (playlist != null && playlist.songs.isNotEmpty) {
      return playlist;
    }

    // Fallback: If direct playlist is not found or empty, search by title
    final query = playlistTitle ?? playlist?.title ?? playlistId;
    if (query.isNotEmpty) {
      try {
        final searchResult = await search(query, limit: 10);
        for (final pl in searchResult.playlists) {
          if (pl.id != playlistId && pl.id.isNotEmpty) {
            final details = await youTubeSource.getPlaylistDetails(pl.id);
            if (details != null && details.songs.isNotEmpty) {
              return details.copyWith(
                title: playlistTitle ?? details.title,
              );
            }
          }
        }

        // Secondary fallback: synthesize a playlist from top matching tracks
        if (searchResult.songs.isNotEmpty) {
          return PlaylistModel(
            id: playlistId,
            title: playlistTitle ?? query,
            description: playlist?.description ?? 'Curated selection of popular tracks.',
            artworkUrl: playlist?.artworkUrl ?? searchResult.songs.first.artworkUrl,
            highResArtworkUrl: playlist?.highResArtworkUrl ?? searchResult.songs.first.highResArtworkUrl,
            trackCount: searchResult.songs.length,
            songs: searchResult.songs,
            source: 'youtube',
          );
        }
      } catch (e) {
        debugPrint('[SearchRepository] getPlaylistDetails fallback search error: $e');
      }
    }

    return playlist;
  }

  /// Fetches song recommendations / Radio for [track]
  Future<List<Track>> getRecommendations(Track track) async {
    final recos = await youTubeSource.getRelatedSongs(track.id);
    if (recos.isNotEmpty) return recos;

    // Fallback: search by artist
    return youTubeSource.search(track.artist, limit: 10);
  }

  /// Helper to extract YouTube video ID from various URL formats
  String? _extractYouTubeVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|v\/|shorts\/))([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    return match?.group(1);
  }

  /// Closes all underlying source clients
  void close() {
    youTubeSource.close();
  }
}
