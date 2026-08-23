import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';

/// Riverpod provider for LibraryRepository
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(HiveService.instance);
});

/// Data repository for Library, Favorites, Custom Playlists, History & Stats
class LibraryRepository {
  final HiveService _hiveService;

  LibraryRepository(this._hiveService);

  Box get _favoritesBox => _hiveService.favoritesBox;
  Box get _playlistsBox => _hiveService.playlistsBox;
  Box get _historyBox => _hiveService.historyBox;
  Box get _statsBox => _hiveService.statsBox;

  // ==========================================
  // FAVORITES
  // ==========================================

  List<FavoriteSong> getFavorites() {
    final list = <FavoriteSong>[];
    for (final raw in _favoritesBox.values) {
      if (raw != null && raw is Map) {
        try {
          list.add(FavoriteSong.fromMap(raw));
        } catch (_) {}
      }
    }
    // Sort recently favorited first
    list.sort((a, b) => b.likedAt.compareTo(a.likedAt));
    return list;
  }

  bool isFavorite(String trackId) {
    return _favoritesBox.containsKey(trackId);
  }

  Future<void> toggleFavorite(Track track) async {
    if (isFavorite(track.id)) {
      await removeFavorite(track.id);
    } else {
      await addFavorite(track);
    }
  }

  Future<void> addFavorite(Track track) async {
    final fav = FavoriteSong(track: track.copyWith(isFavorite: true));
    await _favoritesBox.put(track.id, fav.toMap());
  }

  Future<void> removeFavorite(String trackId) async {
    await _favoritesBox.delete(trackId);
  }

  Stream<List<FavoriteSong>> watchFavorites() {
    return _favoritesBox.watch().map((_) => getFavorites());
  }

  // ==========================================
  // USER PLAYLISTS
  // ==========================================

  List<UserPlaylist> getUserPlaylists() {
    final list = <UserPlaylist>[];
    for (final raw in _playlistsBox.values) {
      if (raw != null && raw is Map) {
        try {
          list.add(UserPlaylist.fromMap(raw));
        } catch (_) {}
      }
    }
    // Pinned playlists first, then updated recently
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  UserPlaylist? getPlaylistById(String id) {
    final raw = _playlistsBox.get(id);
    if (raw != null && raw is Map) {
      try {
        return UserPlaylist.fromMap(raw);
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveUserPlaylist(UserPlaylist playlist) async {
    final updated = playlist.copyWith(updatedAt: DateTime.now());
    await _playlistsBox.put(playlist.id, updated.toMap());
  }

  Future<void> deleteUserPlaylist(String playlistId) async {
    await _playlistsBox.delete(playlistId);
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return;

    // Avoid duplicate track in same playlist if present, or append
    final updatedSongs = List<Track>.from(playlist.songs);
    if (!updatedSongs.any((t) => t.id == track.id)) {
      updatedSongs.add(track);
      await saveUserPlaylist(playlist.copyWith(songs: updatedSongs));
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return;

    final updatedSongs =
        playlist.songs.where((t) => t.id != trackId).toList();
    await saveUserPlaylist(playlist.copyWith(songs: updatedSongs));
  }

  Stream<List<UserPlaylist>> watchUserPlaylists() {
    return _playlistsBox.watch().map((_) => getUserPlaylists());
  }

  // ==========================================
  // LISTENING HISTORY
  // ==========================================

  List<HistoryItem> getHistory() {
    final list = <HistoryItem>[];
    for (final raw in _historyBox.values) {
      if (raw != null && raw is Map) {
        try {
          list.add(HistoryItem.fromMap(raw));
        } catch (_) {}
      }
    }
    // Most recent history first
    list.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return list;
  }

  Future<void> addHistoryItem(
    Track track, {
    Duration durationPlayed = Duration.zero,
    bool completed = false,
  }) async {
    final item = HistoryItem(
      id: track.id,
      track: track,
      durationPlayed: durationPlayed,
      completed: completed,
      playedAt: DateTime.now(),
    );
    await _historyBox.put(track.id, item.toMap());

    // Also record into listening statistics
    await recordTrackPlay(track, durationPlayed);
  }

  Future<void> removeHistoryItem(String trackId) async {
    await _historyBox.delete(trackId);
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
  }

  Stream<List<HistoryItem>> watchHistory() {
    return _historyBox.watch().map((_) => getHistory());
  }

  // ==========================================
  // LISTENING STATS
  // ==========================================

  static const String _statsKey = 'user_listening_stats';

  ListeningStats getListeningStats() {
    final raw = _statsBox.get(_statsKey);
    if (raw != null && raw is Map) {
      try {
        return ListeningStats.fromMap(raw);
      } catch (_) {}
    }
    return const ListeningStats();
  }

  Future<void> saveListeningStats(ListeningStats stats) async {
    await _statsBox.put(_statsKey, stats.toMap());
  }

  Future<void> recordTrackPlay(Track track, Duration durationPlayed) async {
    final currentStats = getListeningStats();
    final updatedStats = currentStats.recordSession(
      track: track,
      durationPlayed: durationPlayed,
    );
    await saveListeningStats(updatedStats);
  }

  Stream<ListeningStats> watchListeningStats() {
    return _statsBox.watch(key: _statsKey).map((_) => getListeningStats());
  }
}
