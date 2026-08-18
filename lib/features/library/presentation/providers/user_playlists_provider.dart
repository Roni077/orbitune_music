import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';

/// StateNotifier managing user custom playlists
class UserPlaylistsNotifier extends StateNotifier<List<UserPlaylist>> {
  final LibraryRepository _repository;

  UserPlaylistsNotifier(this._repository) : super([]) {
    _loadPlaylists();
  }

  void _loadPlaylists() {
    state = _repository.getUserPlaylists();
  }

  Future<UserPlaylist> createPlaylist(
    String name, {
    String? description,
    String? artworkUrl,
    List<Track> initialTracks = const [],
  }) async {
    final newPlaylist = UserPlaylist(
      id: 'playlist_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'My Playlist' : name.trim(),
      description: description,
      artworkUrl: artworkUrl,
      songs: initialTracks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveUserPlaylist(newPlaylist);
    state = [newPlaylist, ...state];
    return newPlaylist;
  }

  Future<void> deletePlaylist(String id) async {
    await _repository.deleteUserPlaylist(id);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final updated = state[index].copyWith(
      name: newName.trim(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveUserPlaylist(updated);
    _loadPlaylists();
  }

  Future<void> addTrackToPlaylist(String playlistId, Track track) async {
    await _repository.addTrackToPlaylist(playlistId, track);
    _loadPlaylists();
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    await _repository.removeTrackFromPlaylist(playlistId, trackId);
    _loadPlaylists();
  }

  Future<void> reorderTracks(
      String playlistId, int oldIndex, int newIndex) async {
    final playlist = _repository.getPlaylistById(playlistId);
    if (playlist == null) return;

    final songs = List<Track>.from(playlist.songs);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = songs.removeAt(oldIndex);
    songs.insert(newIndex, item);

    final updated = playlist.copyWith(songs: songs, updatedAt: DateTime.now());
    await _repository.saveUserPlaylist(updated);
    _loadPlaylists();
  }

  Future<void> togglePin(String playlistId) async {
    final playlist = _repository.getPlaylistById(playlistId);
    if (playlist == null) return;

    final updated = playlist.copyWith(
      isPinned: !playlist.isPinned,
      updatedAt: DateTime.now(),
    );
    await _repository.saveUserPlaylist(updated);
    _loadPlaylists();
  }

  void refresh() {
    _loadPlaylists();
  }
}

/// Global provider for user playlists list
final userPlaylistsProvider =
    StateNotifierProvider<UserPlaylistsNotifier, List<UserPlaylist>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return UserPlaylistsNotifier(repo);
});

/// Family provider for single playlist details by ID
final userPlaylistByIdProvider =
    Provider.family<UserPlaylist?, String>((ref, id) {
  final playlists = ref.watch(userPlaylistsProvider);
  try {
    return playlists.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});
