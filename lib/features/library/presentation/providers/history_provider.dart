import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';

/// StateNotifier managing listening history
class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  final LibraryRepository _repository;

  HistoryNotifier(this._repository) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    state = _repository.getHistory();
  }

  Future<void> recordPlay(
    Track track, {
    Duration durationPlayed = Duration.zero,
    bool completed = false,
  }) async {
    await _repository.addHistoryItem(
      track,
      durationPlayed: durationPlayed,
      completed: completed,
    );
    _loadHistory();
  }

  Future<void> removeHistoryItem(String trackId) async {
    await _repository.removeHistoryItem(trackId);
    state = state.where((item) => item.track.id != trackId).toList();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    state = [];
  }

  void refresh() {
    _loadHistory();
  }
}

/// Global provider for listening history
final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return HistoryNotifier(repo);
});
