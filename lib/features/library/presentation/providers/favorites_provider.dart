import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';

/// StateNotifier managing user favorites in memory and synced with Hive
class FavoritesNotifier extends StateNotifier<List<FavoriteSong>> {
  final LibraryRepository _repository;

  FavoritesNotifier(this._repository) : super([]) {
    _loadFavorites();
  }

  void _loadFavorites() {
    state = _repository.getFavorites();
  }

  bool isFavorite(String trackId) {
    return state.any((item) => item.track.id == trackId);
  }

  Future<void> toggleFavorite(Track track) async {
    final exists = isFavorite(track.id);
    if (exists) {
      await _repository.removeFavorite(track.id);
      state = state.where((item) => item.track.id != track.id).toList();
    } else {
      final updatedTrack = track.copyWith(isFavorite: true);
      await _repository.addFavorite(updatedTrack);
      state = [
        FavoriteSong(track: updatedTrack, likedAt: DateTime.now()),
        ...state,
      ];
    }
  }

  Future<void> removeFavorite(String trackId) async {
    await _repository.removeFavorite(trackId);
    state = state.where((item) => item.track.id != trackId).toList();
  }

  void refresh() {
    _loadFavorites();
  }
}

/// Global provider for favorites list
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<FavoriteSong>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return FavoritesNotifier(repo);
});

/// Family provider to check if a specific track is favorited
final isFavoriteProvider = Provider.family<bool, String>((ref, trackId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.any((item) => item.track.id == trackId);
});
