import 'package:extractor/extractor.dart';
import 'package:flutter/foundation.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Service wrapper around the `extractor` (yt-dlp / YouTubeDLFlutter) media engine
class ExtractorService {
  static final ExtractorService _instance = ExtractorService._internal();
  static ExtractorService get instance => _instance;

  ExtractorService();
  ExtractorService._internal();

  bool _isInitialized = false;

  /// Initializes the underlying extractor engine
  Future<bool> initialize({bool enableFFmpeg = true}) async {
    if (_isInitialized) return true;

    try {
      final result = await YoutubeDLFlutter.instance.initialize(
        enableFFmpeg: enableFFmpeg,
        enableAria2c: false,
      );
      _isInitialized = result.success;
      return _isInitialized;
    } catch (e) {
      debugPrint('[ExtractorService] Initialization failed/unsupported: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Checks if a string is a valid URL that can be parsed by Extractor
  bool isSupportedMediaUrl(String url) {
    if (url.trim().isEmpty) return false;
    final trimmed = url.trim().toLowerCase();

    final validProtocols = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    if (!validProtocols) return false;

    // Supported platforms & direct media files
    final matchers = [
      'youtube.com',
      'youtu.be',
      'instagram.com',
      'tiktok.com',
      'soundcloud.com',
      'vimeo.com',
      'twitter.com',
      'x.com',
      'facebook.com',
      'fb.watch',
      'spotify.com',
      'audiomack.com',
      '.mp3',
      '.m4a',
      '.aac',
      '.flac',
      '.wav',
      '.mp4',
      '.webm',
    ];

    return matchers.any((m) => trimmed.contains(m));
  }

  /// Extracts comprehensive metadata and streaming audio URL from any supported media link
  Future<Track?> extractTrackInfo(String url, {AudioQuality quality = AudioQuality.high320k}) async {
    if (!isSupportedMediaUrl(url)) return null;

    try {
      final videoInfo = await YoutubeDLFlutter.instance.getVideoInfo(url);
      return _convertVideoInfoToTrack(videoInfo, url, quality);
    } catch (e) {
      debugPrint('[ExtractorService] extractTrackInfo error: $e');
      return null;
    }
  }

  /// Extracts direct audio stream URL with the highest possible bitrate
  Future<String?> getBestAudioStreamUrl(String url) async {
    try {
      final videoInfo = await YoutubeDLFlutter.instance.getVideoInfo(url);
      final formats = videoInfo.formats;
      if (formats == null || formats.isEmpty) {
        return videoInfo.url;
      }

      // Filter for audio streams
      final audioFormats = formats.where((f) {
        final acodec = f?.acodec?.toLowerCase() ?? '';
        final vcodec = f?.vcodec?.toLowerCase() ?? '';
        return acodec.isNotEmpty && acodec != 'none' && (vcodec.isEmpty || vcodec == 'none');
      }).toList();

      if (audioFormats.isNotEmpty) {
        // Sort descending by total bitrate (tbr) or filesize
        audioFormats.sort((a, b) {
          final tbrA = a?.tbr ?? 0.0;
          final tbrB = b?.tbr ?? 0.0;
          return tbrB.compareTo(tbrA);
        });
        return audioFormats.first?.url ?? videoInfo.url;
      }

      // Fallback: any format with audio
      final anyAudio = formats.where((f) {
        final acodec = f?.acodec?.toLowerCase() ?? '';
        return acodec.isNotEmpty && acodec != 'none';
      }).toList();

      if (anyAudio.isNotEmpty) {
        anyAudio.sort((a, b) => (b?.tbr ?? 0.0).compareTo(a?.tbr ?? 0.0));
        return anyAudio.first?.url ?? videoInfo.url;
      }

      return videoInfo.url;
    } catch (e) {
      debugPrint('[ExtractorService] getBestAudioStreamUrl error: $e');
      return null;
    }
  }

  Track _convertVideoInfoToTrack(VideoInfo info, String originalUrl, AudioQuality quality) {
    final title = info.title ?? 'Extracted Audio';
    final artist = info.uploader ?? 'Unknown Artist';
    final durationSeconds = info.duration ?? 0;
    final duration = Duration(seconds: durationSeconds);
    final artwork = info.thumbnail;

    String? directStreamUrl;
    int bitrate = 160;

    final formats = info.formats;
    if (formats != null && formats.isNotEmpty) {
      // Find highest bitrate audio format
      final audioFormats = formats.where((f) => (f?.acodec ?? 'none') != 'none').toList();
      if (audioFormats.isNotEmpty) {
        audioFormats.sort((a, b) => (b?.tbr ?? 0.0).compareTo(a?.tbr ?? 0.0));
        directStreamUrl = audioFormats.first?.url;
        final tbr = audioFormats.first?.tbr?.toInt();
        if (tbr != null && tbr > 0) {
          bitrate = tbr;
        }
      }
    }

    directStreamUrl ??= info.url ?? originalUrl;

    return Track(
      id: info.id ?? originalUrl.hashCode.toString(),
      title: title,
      artist: artist,
      album: 'Extractor Stream',
      duration: duration,
      artworkUrl: artwork,
      highResArtworkUrl: artwork,
      streamUrl: directStreamUrl,
      downloadUrl: directStreamUrl,
      source: 'extractor',
      bitrate: bitrate,
      audioQuality: quality,
      extra: {
        'originalUrl': originalUrl,
        'extractor': 'youtube_dl',
        'viewCount': info.viewCount,
        'likeCount': info.likeCount,
      },
    );
  }
}
