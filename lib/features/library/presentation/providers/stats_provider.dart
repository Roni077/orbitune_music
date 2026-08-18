import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';

/// StateNotifier managing aggregate listening statistics
class StatsNotifier extends StateNotifier<ListeningStats> {
  final LibraryRepository _repository;

  StatsNotifier(this._repository) : super(const ListeningStats()) {
    _loadStats();
  }

  void _loadStats() {
    state = _repository.getListeningStats();
  }

  Future<void> recordSession(Track track, Duration durationPlayed) async {
    await _repository.recordTrackPlay(track, durationPlayed);
    _loadStats();
  }

  void refresh() {
    _loadStats();
  }
}

/// Global provider for listening stats
final statsProvider =
    StateNotifierProvider<StatsNotifier, ListeningStats>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return StatsNotifier(repo);
});
