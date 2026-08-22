import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:orbitune/core/constants/api_endpoints.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/core/utils/lrc_parser.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/lyrics/data/lyrics_cache_repository.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';
/// Riverpod provider for LyricsRepository
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  final cacheRepo = ref.watch(lyricsCacheRepositoryProvider);
  return LyricsRepository(
    cacheRepository: cacheRepo,
  );
});

/// Repository for fetching, caching, and parsing synchronized LRC and plain lyrics via LRCLIB
class LyricsRepository {
  final LyricsCacheRepository cacheRepository;
  final http.Client httpClient;

  LyricsRepository({
    required this.cacheRepository,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Fetches synchronized lyrics for a [track], checking cache first, then LRCLIB
  Future<List<LyricLine>> getSyncedLyrics(Track track) async {
    // 1. Check local Hive cache
    final cached = cacheRepository.getCachedLyrics(track.id);
    if (cached != null && cached.isNotEmpty) {
      final parsed = LrcParser.parse(cached);
      if (parsed.isNotEmpty) return parsed;
    }

    // 2. Query LRCLIB Synced Lyrics API
    try {
      final lrcLibLyrics = await _fetchFromLrcLib(track);
      if (lrcLibLyrics != null && lrcLibLyrics.isNotEmpty) {
        await cacheRepository.cacheLyrics(track.id, lrcLibLyrics);
        return LrcParser.parse(lrcLibLyrics);
      }
    } catch (e) {
      debugPrint('[LyricsRepository] LRCLIB fetch failed: $e');
    }

    return const [];
  }

  /// Fetches plain text lyrics
  Future<String?> getPlainLyrics(Track track) async {
    // getSyncedLyrics() runs first and caches whatever the API returns (LRC or plain text).
    // We can just read the cached raw string and extract plain text from it.
    final cached = cacheRepository.getCachedLyrics(track.id);
    if (cached != null && cached.isNotEmpty) {
      return LrcParser.extractPlainLyrics(cached);
    }
    
    // Fallback if not cached
    final lrcLibLyrics = await _fetchFromLrcLib(track);
    if (lrcLibLyrics != null && lrcLibLyrics.isNotEmpty) {
      await cacheRepository.cacheLyrics(track.id, lrcLibLyrics);
      return LrcParser.extractPlainLyrics(lrcLibLyrics);
    }
    
    return null;
  }

  Future<String?> _fetchFromLrcLib(Track track) async {
    final cleanTitle = AudioDecryptor.cleanTrackTitle(track.title);
    final cleanArtist = AudioDecryptor.cleanHtmlEntities(track.artist);
    final durationSeconds = track.duration.inSeconds;

    // 1. Exact match attempt with title, artist, album, duration
    var uri = Uri.parse(
      '${ApiEndpoints.lrcLibBase}?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}'
      '${track.album != null ? '&album_name=${Uri.encodeComponent(track.album!)}' : ''}'
      '${durationSeconds > 0 ? '&duration=$durationSeconds' : ''}',
    );

    var response = await httpClient.get(uri, headers: {
      'User-Agent': 'Orbitune Music Player (https://github.com/orbitune)',
    }).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data is Map) {
        final syncedLyrics = data['syncedLyrics']?.toString();
        if (syncedLyrics != null && syncedLyrics.trim().isNotEmpty) {
          return syncedLyrics;
        }
        final plainLyrics = data['plainLyrics']?.toString();
        if (plainLyrics != null && plainLyrics.trim().isNotEmpty) {
          return plainLyrics;
        }
      }
    }

    // 2. Search fallback with query
    final searchUri = Uri.parse(
      '${ApiEndpoints.lrcLibSearch}?q=${Uri.encodeComponent('$cleanTitle $cleanArtist')}',
    );

    response = await httpClient.get(searchUri, headers: {
      'User-Agent': 'Orbitune Music Player (https://github.com/orbitune)',
    }).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body);
      if (list != null && list is List && list.isNotEmpty) {
        // Pick first item with synced lyrics
        for (final item in list) {
          if (item is Map) {
            final synced = item['syncedLyrics']?.toString();
            if (synced != null && synced.trim().isNotEmpty) {
              return synced;
            }
          }
        }
        // Fallback to first item with plain lyrics
        final first = list.first;
        if (first is Map && first['plainLyrics'] != null) {
          return first['plainLyrics'].toString();
        }
      }
    }

    return null;
  }
}
