import 'package:flutter/foundation.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// YouTube & YouTube Music data source client powered by `youtube_explode_dart`
class YouTubeSource {
  YoutubeExplode? _yt;

  YoutubeExplode get _client => _yt ??= YoutubeExplode();

  final Map<String, ({String url, DateTime expiresAt})> _streamUrlCache = {};
  static const int _maxStreamCacheSize = 300;

  void _cacheStreamUrl(String videoId, String url) {
    if (_streamUrlCache.length >= _maxStreamCacheSize) {
      _streamUrlCache.remove(_streamUrlCache.keys.first);
    }
    _streamUrlCache[videoId] = (
      url: url,
      expiresAt: DateTime.now().add(const Duration(hours: 6)),
    );
  }

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

  /// Searches for artists / channels matching [query]
  Future<List<ArtistModel>> searchArtists(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return const [];

    final List<ArtistModel> artists = [];

    try {
      try {
        final searchResults = await _client.search.searchContent(
          query.trim(),
          filter: TypeFilters.channel,
        );

        for (final item in searchResults) {
          if (artists.length >= limit) break;
          if (item is SearchChannel) {
            artists.add(ArtistModel(
              id: item.id.value,
              name: AudioDecryptor.cleanHtmlEntities(item.name),
              avatarUrl: item.thumbnails.isNotEmpty ? item.thumbnails.last.url.toString() : null,
              bannerUrl: item.thumbnails.isNotEmpty ? item.thumbnails.last.url.toString() : null,
              bio: AudioDecryptor.cleanBioText(item.description),
              fansCount: item.videoCount,
              source: 'youtube',
            ));
          }
        }
      } catch (innerE) {
        debugPrint('[YouTubeSource] searchContent for channel failed: $innerE');
      }

      // Fallback: If channel search returned nothing, synthesize artist from top search result
      if (artists.isEmpty) {
        final songs = await search(query, limit: 3);
        if (songs.isNotEmpty) {
          final top = songs.first;
          artists.add(ArtistModel(
            id: 'yt_artist_${query.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
            name: top.artist.isNotEmpty ? top.artist : query,
            avatarUrl: top.artworkUrl,
            bannerUrl: top.highResArtworkUrl,
            bio: 'Popular music artist on YouTube Music.',
            topTracks: songs,
            source: 'youtube',
          ));
        }
      }

      return artists;
    } catch (e) {
      debugPrint('[YouTubeSource] searchArtists error: $e');
      return const [];
    }
  }

  /// Searches for albums matching [query]
  Future<List<AlbumModel>> searchAlbums(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return const [];

    try {
      final searchResults = await _client.search.searchContent(
        '$query album',
        filter: TypeFilters.playlist,
      );

      final List<AlbumModel> albums = [];

      for (final item in searchResults) {
        if (albums.length >= limit) break;
        if (item is SearchPlaylist) {
          albums.add(
            AlbumModel(
              id: item.id.value,
              title: AudioDecryptor.cleanHtmlEntities(item.title),
              artist: 'YouTube Music',
              artworkUrl: 'https://img.youtube.com/vi/${item.id.value}/hqdefault.jpg',
              highResArtworkUrl: 'https://img.youtube.com/vi/${item.id.value}/maxresdefault.jpg',
              songs: const [],
              totalTracks: item.videoCount,
              source: 'youtube',
            ),
          );
        }
      }
      return albums;
    } catch (e) {
      debugPrint('[YouTubeSource] searchAlbums error: $e');
      return const [];
    }
  }

  /// Searches YouTube specifically for playlists matching [query]
  Future<List<PlaylistModel>> searchPlaylists(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return const [];

    try {
      final playlists = await _client.search.searchContent(
        query.trim(),
        filter: TypeFilters.playlist,
      );

      final List<PlaylistModel> playlistResults = [];
      for (final item in playlists) {
        if (playlistResults.length >= limit) break;
        if (item is SearchPlaylist) {
          playlistResults.add(
            PlaylistModel(
              id: item.id.value,
              title: AudioDecryptor.cleanHtmlEntities(item.title),
              author: 'YouTube',
              artworkUrl: 'https://img.youtube.com/vi/${item.id.value}/hqdefault.jpg',
              highResArtworkUrl: 'https://img.youtube.com/vi/${item.id.value}/maxresdefault.jpg',
              trackCount: item.videoCount,
              songs: const [],
              source: 'youtube',
            ),
          );
        }
      }
      return playlistResults;
    } catch (e) {
      debugPrint('[YouTubeSource] searchPlaylists error: $e');
      return const [];
    }
  }

  /// Ultra-fast stream manifest extraction:
  /// 1. Fast-path: Directly queries Android Sdkless API without downloading HTML watch page (~250ms).
  /// 2. Resilient fallback: Queries iOS & Android Sdkless with watch page if fast path fails.
  /// 3. Ultimate fallback: Default client extraction.
  Future<StreamManifest> _getResilientManifest(String videoId) async {
    // 1. Fast Path (~250ms latency)
    try {
      return await _client.videos.streamsClient.getManifest(
        VideoId(videoId),
        ytClients: [YoutubeApiClient.androidSdkless],
        requireWatchPage: false,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[YouTubeSource] Fast-path getManifest failed for $videoId ($e). Trying secondary fallback...');
    }

    // 2. Secondary Resilient Fallback
    try {
      return await _client.videos.streamsClient.getManifest(
        VideoId(videoId),
        ytClients: [
          YoutubeApiClient.androidSdkless,
          YoutubeApiClient.ios,
        ],
        requireWatchPage: true,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[YouTubeSource] Secondary fallback getManifest failed for $videoId ($e). Retrying with default client...');
      return await _client.videos.streamsClient
          .getManifest(VideoId(videoId))
          .timeout(const Duration(seconds: 8));
    }
  }

  /// Filters out broken/unplayable OTF streams (e.g. itags 599 & 600)
  List<AudioStreamInfo> _filterStableAudioStreams(Iterable<AudioStreamInfo> streams) {
    return streams.where((s) {
      final itag = s.tag;
      // Exclude itag 599 (32k AAC live/OTF) and 600 (32k WebM live/OTF) which return 403 on ExoPlayer
      if (itag == 599 || itag == 600) return false;
      return true;
    }).toList();
  }

  /// Platform-aware audio stream sorting:
  /// - Windows Media Foundation natively plays AAC/MP4 (itag 140 ~128k) out-of-the-box without WebM/Opus codec stalls.
  /// - Android/iOS/macOS natively support Opus in WebM (itag 251 ~160k).
  List<AudioStreamInfo> _sortAudioStreamsForPlatform(List<AudioStreamInfo> streams) {
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    if (isWindows) {
      final mp4Aac = streams
          .where((s) => s.container.name.toLowerCase().contains('mp4') || s.tag == 140 || s.tag == 139)
          .toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
      final others = streams
          .where((s) => !s.container.name.toLowerCase().contains('mp4') && s.tag != 140 && s.tag != 139)
          .toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
      return [...mp4Aac, ...others];
    } else {
      return streams.sortByBitrate().toList();
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
      final manifest = await _getResilientManifest(videoId);

      // 1. Prioritize pure Audio-only streams with platform-aware codec ordering
      final stableAudio = _filterStableAudioStreams(manifest.audioOnly);
      if (stableAudio.isNotEmpty) {
        final sorted = _sortAudioStreamsForPlatform(stableAudio);
        final AudioStreamInfo selectedAudio;

        if (quality == AudioQuality.low96k) {
          // Select standard low-data stable stream (e.g. 48-64k AAC/Opus) without using broken 32k OTF streams
          selectedAudio = sorted.last;
        } else {
          // Default: highest bitrate stable audio stream matching platform
          selectedAudio = sorted.first;
        }

        final streamUrl = selectedAudio.url.toString();
        _cacheStreamUrl(videoId, streamUrl);
        return streamUrl;
      }

      // 2. Fallback to unthrottled Muxed MP4 if audioOnly is empty
      if (manifest.muxed.isNotEmpty) {
        final muxed = manifest.muxed.sortByBitrate().toList();
        final streamUrl = muxed.first.url.toString();
        _cacheStreamUrl(videoId, streamUrl);
        return streamUrl;
      }

      return null;
    } catch (e) {
      debugPrint('[YouTubeSource] getAudioStreamUrl error for $videoId: $e');
      return null;
    }
  }

  /// Fetches candidate audio stream URLs (pure audio first from highest to lowest, then muxed)
  Future<List<String>> getAudioStreamCandidates(
    String videoId, {
    AudioQuality quality = AudioQuality.high320k,
  }) async {
    try {
      final manifest = await _getResilientManifest(videoId);
      final List<String> candidates = [];

      // 1. Filter out broken OTF streams and apply platform-aware sorting (MP4/AAC first on Windows)
      final stableAudio = _filterStableAudioStreams(manifest.audioOnly);
      final sortedAudio = _sortAudioStreamsForPlatform(stableAudio);

      if (sortedAudio.isNotEmpty) {
        // Candidate 0: Primary platform-optimized audio stream
        candidates.add(sortedAudio.first.url.toString());

        // Candidate 1: Next best audio-only stream
        if (sortedAudio.length > 1) {
          candidates.add(sortedAudio[1].url.toString());
        }

        // Candidate 2: Additional audio fallback if available
        if (sortedAudio.length > 2) {
          candidates.add(sortedAudio[2].url.toString());
        }
      }

      // 2. Unthrottled Muxed MP4 streams as secondary fallback if pure audio fails
      final sortedMuxed = manifest.muxed.sortByBitrate().toList();
      if (sortedMuxed.isNotEmpty) {
        candidates.add(sortedMuxed.first.url.toString());
      }

      return candidates;
    } catch (e) {
      debugPrint('[YouTubeSource] getAudioStreamCandidates error for $videoId: $e');
      return const [];
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

  /// Fetches playlist details along with all its tracks (capped to first 100 tracks for responsive UI)
  Future<PlaylistModel?> getPlaylistDetails(String playlistId, {int limit = 100}) async {
    try {
      final playlist = await _client.playlists.get(PlaylistId(playlistId));
      final List<Track> tracks = [];

      await for (final video in _client.playlists.getVideos(PlaylistId(playlistId)).take(limit)) {
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

  /// Fetches artist details, top songs, and albums
  Future<ArtistModel?> getArtistDetails(String artistId, {String? artistName}) async {
    final queryName = artistName ?? artistId;
    try {
      if (artistId.startsWith('UC') && artistId.length > 20) {
        final channel = await _client.channels.get(ChannelId(artistId));
        final List<Track> uploads = [];
        await for (final video in _client.channels.getUploads(ChannelId(artistId)).take(25)) {
          uploads.add(_convertVideoToTrack(video));
        }

        final playlists = await searchPlaylists('$queryName album', limit: 6);
        final albums = playlists.map((p) => AlbumModel(
          id: p.id,
          title: p.title,
          artist: channel.title,
          artworkUrl: p.artworkUrl,
          highResArtworkUrl: p.highResArtworkUrl,
          totalTracks: p.trackCount,
          source: 'youtube',
        )).toList();

        return ArtistModel(
          id: channel.id.value,
          name: AudioDecryptor.cleanHtmlEntities(channel.title),
          avatarUrl: channel.logoUrl,
          bannerUrl: channel.bannerUrl,
          bio: 'Verified Artist on YouTube Music',
          fansCount: uploads.length * 1000,
          topTracks: uploads,
          albums: albums,
          source: 'youtube',
        );
      }

      // Search-based resolution for artist by name
      final topSongs = await search(queryName, limit: 20);
      final albums = await searchAlbums(queryName, limit: 6);

      if (topSongs.isNotEmpty) {
        final firstSong = topSongs.first;
        return ArtistModel(
          id: artistId,
          name: queryName,
          avatarUrl: firstSong.artworkUrl,
          bannerUrl: firstSong.highResArtworkUrl,
          bio: 'Top trending tracks and releases on YouTube Music.',
          fansCount: 1500000,
          topTracks: topSongs,
          albums: albums,
          source: 'youtube',
        );
      }
    } catch (e) {
      debugPrint('[YouTubeSource] getArtistDetails error: $e');
    }

    return null;
  }

  /// Fetches album details along with tracklist
  Future<AlbumModel?> getAlbumDetails(String albumId) async {
    try {
      final playlist = await getPlaylistDetails(albumId);
      if (playlist != null) {
        return AlbumModel(
          id: playlist.id,
          title: playlist.title,
          artist: playlist.author ?? 'YouTube Music',
          artworkUrl: playlist.artworkUrl,
          highResArtworkUrl: playlist.highResArtworkUrl,
          totalTracks: playlist.trackCount,
          songs: playlist.songs,
          description: playlist.description,
          source: 'youtube',
        );
      }
    } catch (e) {
      debugPrint('[YouTubeSource] getAlbumDetails error: $e');
    }
    return null;
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
    String cleanedTitle = AudioDecryptor.cleanTrackTitle(rawTitle);
    String artist = AudioDecryptor.cleanHtmlEntities(video.author);
    
    // Heuristic: Split "Artist - Title" formats common on YouTube
    if (cleanedTitle.contains(' - ')) {
      final parts = cleanedTitle.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        cleanedTitle = parts.sublist(1).join(' - ').trim();
      }
    }
    
    final duration = video.duration ?? Duration.zero;

    // Reliable high-res thumbnails (standard/high res are guaranteed to exist on YouTube CDN)
    final artwork = video.thumbnails.highResUrl.isNotEmpty
        ? video.thumbnails.highResUrl
        : (video.thumbnails.mediumResUrl.isNotEmpty
            ? video.thumbnails.mediumResUrl
            : video.thumbnails.standardResUrl);
    final highResArtwork = video.thumbnails.standardResUrl.isNotEmpty
        ? video.thumbnails.standardResUrl
        : artwork;

    return Track(
      id: video.id.value,
      title: cleanedTitle.isNotEmpty ? cleanedTitle : rawTitle,
      artist: artist.isNotEmpty ? artist : 'YouTube Artist',
      album: 'YouTube Music',
      duration: duration,
      artworkUrl: artwork,
      highResArtworkUrl: highResArtwork,
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
