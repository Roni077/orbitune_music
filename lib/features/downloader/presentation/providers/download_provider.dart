import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/downloader/data/download_repository.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';

/// StateNotifier managing offline downloads list
class DownloadListNotifier extends StateNotifier<List<DownloadTask>> {
  final DownloadRepository _repository;

  DownloadListNotifier(this._repository) : super([]) {
    _loadDownloads();
  }

  void _loadDownloads() {
    state = _repository.getAllDownloads();
  }

  Future<void> addOrUpdateTask(DownloadTask task) async {
    await _repository.saveDownload(task);
    final index = state.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      state = [task, ...state];
    } else {
      final updated = List<DownloadTask>.from(state);
      updated[index] = task;
      state = updated;
    }
  }

  Future<void> removeTask(String trackId) async {
    await _repository.removeDownload(trackId);
    state = state.where((t) => t.id != trackId).toList();
  }

  bool isDownloaded(String trackId) {
    return state.any((t) => t.id == trackId && t.isCompleted);
  }

  void refresh() {
    _loadDownloads();
  }
}

/// Global provider for offline downloads
final downloadListProvider =
    StateNotifierProvider<DownloadListNotifier, List<DownloadTask>>((ref) {
  final repo = ref.watch(downloadRepositoryProvider);
  return DownloadListNotifier(repo);
});

/// Family provider checking if track is downloaded offline
final isTrackDownloadedProvider =
    Provider.family<bool, String>((ref, trackId) {
  final downloads = ref.watch(downloadListProvider);
  return downloads.any((t) => t.id == trackId && t.isCompleted);
});
