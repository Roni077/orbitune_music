import 'dart:convert';
import 'package:dart_des/dart_des.dart';
import 'package:orbitune/core/constants/api_endpoints.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';

/// Decryptor and URL transformer for JioSaavn encrypted media streams
class AudioDecryptor {
  AudioDecryptor._();

  static const String _defaultKey = ApiEndpoints.saavnDesKey; // '38346591'

  /// Decrypts a Base64-encoded JioSaavn encrypted_media_url into a direct streaming URL.
  /// Automatically updates the bitrate according to the specified [quality].
  static String? decryptMediaUrl(
    String? encryptedMediaUrl, {
    AudioQuality quality = AudioQuality.high320k,
    String key = _defaultKey,
  }) {
    if (encryptedMediaUrl == null || encryptedMediaUrl.trim().isEmpty) {
      return null;
    }

    try {
      final trimmed = encryptedMediaUrl.trim();
      
      // If it's already an unencrypted URL, just format the bitrate
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return formatQualityUrl(trimmed, quality);
      }

      final keyBytes = utf8.encode(key);
      final encryptedBytes = base64.decode(trimmed);
      
      final des = DES(
        key: keyBytes,
        mode: DESMode.ECB,
        paddingType: DESPaddingType.PKCS7,
      );

      final decryptedBytes = des.decrypt(encryptedBytes);
      final rawUrl = utf8.decode(decryptedBytes).trim();

      if (rawUrl.isEmpty || (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://'))) {
        return null;
      }

      return formatQualityUrl(rawUrl, quality);
    } catch (_) {
      return null;
    }
  }

  /// Encrypts a direct streaming URL to JioSaavn Base64 encrypted format (useful for testing & caching)
  static String? encryptMediaUrl(
    String url, {
    String key = _defaultKey,
  }) {
    try {
      final keyBytes = utf8.encode(key);
      final plainBytes = utf8.encode(url);

      final des = DES(
        key: keyBytes,
        mode: DESMode.ECB,
        paddingType: DESPaddingType.PKCS7,
      );

      final encryptedBytes = des.encrypt(plainBytes);
      return base64.encode(encryptedBytes);
    } catch (_) {
      return null;
    }
  }

  /// Changes the bitrate quality of a JioSaavn CDN audio URL
  /// Supported qualities: 320kbps (_320.mp4), 160kbps (_160.mp4), 96kbps (_96.mp4), 48kbps (_48.mp4)
  static String formatQualityUrl(String url, AudioQuality quality) {
    var formatted = url.trim();
    
    // Ensure HTTPS
    if (formatted.startsWith('http://')) {
      formatted = formatted.replaceFirst('http://', 'https://');
    }

    final targetBitrate = '_${quality.bitrate}.mp4';

    // Regex to match existing bitrate markers e.g. _96.mp4, _160.mp4, _320.mp4, _48.mp4, _128.mp4, _96.m4a, etc.
    final bitrateRegex = RegExp(r'_(48|96|128|160|320)\.(mp4|m4a|mp3)');
    if (bitrateRegex.hasMatch(formatted)) {
      formatted = formatted.replaceAll(bitrateRegex, targetBitrate);
    } else if (formatted.endsWith('.mp4') || formatted.endsWith('.m4a') || formatted.endsWith('.mp3')) {
      final extIndex = formatted.lastIndexOf('.');
      formatted = '${formatted.substring(0, extIndex)}$targetBitrate';
    }

    return formatted;
  }

  /// Upgrades JioSaavn / external artwork URLs to 500x500 high resolution
  static String? formatHighResArtwork(String? artworkUrl) {
    if (artworkUrl == null || artworkUrl.trim().isEmpty) return null;

    var formatted = artworkUrl.trim();
    if (formatted.startsWith('http://')) {
      formatted = formatted.replaceFirst('http://', 'https://');
    }

    // Replace 50x50, 150x150, 250x250, 350x350 with 500x500
    formatted = formatted.replaceAll(RegExp(r'(50x50|150x150|250x250|350x350)'), '500x500');
    return formatted;
  }

  /// Standardizes and cleans HTML entities in titles and artist names (e.g. &amp;, &quot;, &#039;)
  static String cleanHtmlEntities(String text) {
    if (text.isEmpty) return text;

    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Strips promotional prefixes or suffixes (e.g. "(From 'Movie')", "[Official Video]", "(Audio)")
  static String cleanTrackTitle(String title) {
    var cleaned = cleanHtmlEntities(title);
    
    // Remove brackets with video/audio promotional noise
    cleaned = cleaned
        .replaceAll(RegExp(r'\[(Official\s*(Music\s*)?Video|Audio|HD|4K|Lyric\s*Video|Full\s*Song)\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\((Official\s*(Music\s*)?Video|Audio|HD|4K|Lyric\s*Video|Full\s*Song)\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }
}
