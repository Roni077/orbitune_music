import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';

/// Riverpod provider for LyricsCacheRepository
final lyricsCacheRepositoryProvider = Provider<LyricsCacheRepository>((ref) {
  return LyricsCacheRepository(HiveService.instance);
});

/// Data repository for caching synchronized LRC & plain lyrics in Hive
class LyricsCacheRepository {
  final HiveService _hiveService;

  LyricsCacheRepository(this._hiveService);

  Box get _box => _hiveService.lyricsCacheBox;

  String? getCachedLyrics(String trackId) {
    final raw = _box.get(trackId);
    return raw?.toString();
  }

  Future<void> cacheLyrics(String trackId, String lyrics) async {
    if (lyrics.trim().isEmpty) return;
    await _box.put(trackId, lyrics);
  }

  Future<void> removeCachedLyrics(String trackId) async {
    await _box.delete(trackId);
  }

  Future<void> clearLyricsCache() async {
    await _box.clear();
  }
}
