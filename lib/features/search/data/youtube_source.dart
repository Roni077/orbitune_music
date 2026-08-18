import 'package:flutter/foundation.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// YouTube & YouTube Music data source client powered by `youtube_explode_dart`
class YouTubeSource {
  YoutubeExplode? _yt;

  YoutubeExplode get _client => _yt ??= YoutubeExplode();

  /// Cache for resolved audio stream URLs to reduce redundant manifest fetches
  final Map<String, ({String url, DateTime expiresAt})> _streamUrlCache = {};

  /// Searches YouTube for songs matching [query]
  Future<List<Track>> search(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return const [];

    try {
      final searchResults = await _client.search.search(query.trim());
      final List<Track> tracks = [];

      for (final video in searchResults) {
        if (tracks.length >= limit) break;
        tracks.add(_convertVideoToTrack(video));
      }

      return tracks;
    } catch (e) {
      debugPrint('[YouTubeSource] search error: $e');
      return const [];
    }
  }

  /// Searches for playlists matching [query]
  Future<List<PlaylistModel>> searchPlaylists(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return const [];

    try {
      final searchResults = await _client.search.searchContent(
        query.trim(),
        filter: TypeFilters.playlist,
      );

      final List<PlaylistModel> playlists = [];

      for (final item in searchResults) {
        if (playlists.length >= limit) break;
        if (item is SearchPlaylist) {
          playlists.add(PlaylistModel(
            id: item.id.value,
            title: AudioDecryptor.cleanHtmlEntities(item.title),
            author: 'YouTube',
            trackCount: item.videoCount,
            artworkUrl: item.thumbnails.isNotEmpty ? item.thumbnails.first.url.toString() : null,
            highResArtworkUrl: item.thumbnails.isNotEmpty ? item.thumbnails.last.url.toString() : null,
            source: 'youtube',
          ));
        }
      }

      return playlists;
    } catch (e) {
      debugPrint('[YouTubeSource] searchPlaylists error: $e');
      return const [];
    }
  }

  /// Fetches the direct high-bitrate audio stream URL for a given YouTube [videoId]
  Future<String?> getAudioStreamUrl(
    String videoId, {
    AudioQuality quality = AudioQuality.high320k,
  }) async {
    // Check in-memory cache first (cached URLs are typically valid for ~6 hours)
    final cached = _streamUrlCache[videoId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    try {
      final manifest = await _client.videos.streamsClient.getManifest(VideoId(videoId));
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        // Fallback to muxed streams if audio-only is unavailable
        final muxed = manifest.muxed.withHighestBitrate();
        return muxed.url.toString();
      }

      AudioStreamInfo bestAudio;
      if (quality == AudioQuality.low96k) {
        bestAudio = audioStreams.reduce(
          (a, b) => a.bitrate.bitsPerSecond < b.bitrate.bitsPerSecond ? a : b,
        );
      } else {
        bestAudio = audioStreams.withHighestBitrate();
      }

      final streamUrl = bestAudio.url.toString();

      // Cache for 4 hours
      _streamUrlCache[videoId] = (
        url: streamUrl,
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
      );

      return streamUrl;
    } catch (e) {
      debugPrint('[YouTubeSource] getAudioStreamUrl error for $videoId: $e');
      return null;
    }
  }

  /// Fetches complete metadata for a single video by ID
  Future<Track?> getVideoDetails(String videoId) async {
    try {
      final video = await _client.videos.get(VideoId(videoId));
      return _convertVideoToTrack(video);
    } catch (e) {
      debugPrint('[YouTubeSource] getVideoDetails error: $e');
      return null;
    }
  }

  /// Fetches playlist details along with all its tracks
  Future<PlaylistModel?> getPlaylistDetails(String playlistId) async {
    try {
      final playlist = await _client.playlists.get(PlaylistId(playlistId));
      final List<Track> tracks = [];

      await for (final video in _client.playlists.getVideos(PlaylistId(playlistId))) {
        tracks.add(_convertVideoToTrack(video));
      }

      return PlaylistModel(
        id: playlist.id.value,
        title: AudioDecryptor.cleanHtmlEntities(playlist.title),
        author: playlist.author,
        description: playlist.description,
        trackCount: tracks.length,
        artworkUrl: playlist.thumbnails.lowResUrl,
        highResArtworkUrl: playlist.thumbnails.highResUrl,
        songs: tracks,
        source: 'youtube',
      );
    } catch (e) {
      debugPrint('[YouTubeSource] getPlaylistDetails error: $e');
      return null;
    }
  }

  /// Fetches recommended / related videos for a given [videoId]
  Future<List<Track>> getRelatedSongs(String videoId, {int limit = 15}) async {
    try {
      final video = await _client.videos.get(VideoId(videoId));
      final related = await _client.videos.getRelatedVideos(video);
      if (related == null) return const [];

      final List<Track> tracks = [];
      for (final item in related) {
        if (tracks.length >= limit) break;
        tracks.add(_convertVideoToTrack(item));
      }

      return tracks;
    } catch (e) {
      debugPrint('[YouTubeSource] getRelatedSongs error: $e');
      return const [];
    }
  }

  Track _convertVideoToTrack(Video video) {
    final rawTitle = video.title;
    final cleanedTitle = AudioDecryptor.cleanTrackTitle(rawTitle);
    final artist = AudioDecryptor.cleanHtmlEntities(video.author);
    final duration = video.duration ?? Duration.zero;

    // Highest available thumbnail
    final artwork = video.thumbnails.highResUrl;
    final maxRes = video.thumbnails.maxResUrl;

    return Track(
      id: video.id.value,
      title: cleanedTitle.isNotEmpty ? cleanedTitle : rawTitle,
      artist: artist.isNotEmpty ? artist : 'YouTube Artist',
      album: 'YouTube Music',
      duration: duration,
      artworkUrl: artwork,
      highResArtworkUrl: maxRes.isNotEmpty ? maxRes : artwork,
      source: 'youtube',
      bitrate: 160, // Standard Opus/M4A max streaming quality on YouTube
      audioQuality: AudioQuality.medium160k,
      releaseDate: video.uploadDate?.toIso8601String(),
      extra: {
        'viewCount': video.engagement.viewCount,
        'likeCount': video.engagement.likeCount,
        'channelId': video.channelId.value,
        'youtubeUrl': video.url,
      },
    );
  }

  /// Closes the HTTP client and frees resources
  void close() {
    _yt?.close();
    _yt = null;
    _streamUrlCache.clear();
  }
}
