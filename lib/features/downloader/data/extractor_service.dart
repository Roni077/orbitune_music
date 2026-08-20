import 'dart:async';
import 'package:extractor/extractor.dart';
import 'package:flutter/foundation.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Service wrapper around the official `extractor` (^1.0.0 / YoutubeDLFlutter) media engine
class ExtractorService {
  static final ExtractorService _instance = ExtractorService._internal();
  static ExtractorService get instance => _instance;

  ExtractorService();
  ExtractorService._internal();

  bool _isInitialized = false;
  bool _initFailed = false;

  /// Whether the native extractor engine is available on this device
  bool get isAvailable => _isInitialized && !_initFailed;

  /// Reactive download event streams provided by extractor
  Stream<DownloadProgress> get onProgress => YoutubeDLFlutter.instance.onProgress;
  Stream<DownloadState> get onStateChanged => YoutubeDLFlutter.instance.onStateChanged;
  Stream<DownloadError> get onError => YoutubeDLFlutter.instance.onError;
  Stream<LogMessage> get onLog => YoutubeDLFlutter.instance.onLog;

  /// Initializes the underlying extractor engine.
  /// Returns false permanently if the native engine cannot initialize on this device.
  Future<bool> initialize({bool enableFFmpeg = true, bool enableAria2c = false}) async {
    if (_isInitialized) return true;
    if (_initFailed) return false;

    try {
      final result = await YoutubeDLFlutter.instance.initialize(
        enableFFmpeg: enableFFmpeg,
        enableAria2c: enableAria2c,
      );
      _isInitialized = result.success;
      if (!_isInitialized) {
        _initFailed = true;
        debugPrint('[ExtractorService] Native engine init returned success=false. Disabling on this device.');
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('[ExtractorService] Initialization failed/unsupported: $e');
      _isInitialized = false;
      _initFailed = true;
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
    if (_initFailed) return null;

    try {
      final initialized = await initialize();
      if (!initialized) return null;
      final videoInfo = await YoutubeDLFlutter.instance.getVideoInfo(url);
      return _convertVideoInfoToTrack(videoInfo, url, quality);
    } catch (e) {
      debugPrint('[ExtractorService] extractTrackInfo error: $e');
      return null;
    }
  }

  /// Extracts direct audio stream URL with the highest possible bitrate using FormatHelper
  Future<String?> getBestAudioStreamUrl(String url) async {
    if (_initFailed) return null;
    try {
      final initialized = await initialize();
      if (!initialized) return null;
      final videoInfo = await YoutubeDLFlutter.instance.getVideoInfo(url);
      final formats = videoInfo.formats;
      if (formats == null || formats.isEmpty) {
        return videoInfo.url;
      }

      // 1. Use FormatHelper to find the best audio format
      final bestAudio = FormatHelper.getBestAudio(formats);
      if (bestAudio?.url != null && bestAudio!.url!.isNotEmpty) {
        return bestAudio.url;
      }

      // 2. Fallback to audio-only formats
      final audioFormats = FormatHelper.getAudioFormats(formats);
      if (audioFormats.isNotEmpty) {
        return audioFormats.first.url ?? videoInfo.url;
      }

      return videoInfo.url;
    } catch (e) {
      debugPrint('[ExtractorService] getBestAudioStreamUrl error: $e');
      return null;
    }
  }

  /// Downloads media directly via Extractor / yt-dlp native pipeline
  Future<DownloadResult> downloadMedia({
    required String url,
    required String outputPath,
    DownloadTemplate template = DownloadTemplate.audioOnly,
    Map<String, String>? customOptions,
  }) async {
    await initialize();
    final request = DownloadTemplates.fromTemplate(
      url: url,
      outputPath: outputPath,
      template: template,
    );
    if (customOptions != null) {
      request.customOptions = customOptions;
    }
    return await YoutubeDLFlutter.instance.download(request);
  }

  /// Cancels an active download process by ID
  Future<bool> cancelDownload(String processId) async {
    try {
      return await YoutubeDLFlutter.instance.cancelDownload(processId);
    } catch (e) {
      debugPrint('[ExtractorService] cancelDownload error: $e');
      return false;
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
      final bestAudio = FormatHelper.getBestAudio(formats);
      if (bestAudio != null) {
        directStreamUrl = bestAudio.url;
        final tbr = bestAudio.tbr?.toInt();
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
