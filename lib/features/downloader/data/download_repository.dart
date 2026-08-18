import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';

/// Riverpod provider for DownloadRepository
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(HiveService.instance);
});

/// Data repository for offline download tasks persistence in Hive
class DownloadRepository {
  final HiveService _hiveService;

  DownloadRepository(this._hiveService);

  Box get _box => _hiveService.downloadsBox;

  List<DownloadTask> getAllDownloads() {
    final list = <DownloadTask>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null && raw is Map) {
        try {
          list.add(DownloadTask.fromMap(raw));
        } catch (_) {}
      }
    }
    // Completed downloads first, then latest
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  DownloadTask? getDownload(String trackId) {
    final raw = _box.get(trackId);
    if (raw != null && raw is Map) {
      try {
        return DownloadTask.fromMap(raw);
      } catch (_) {}
    }
    return null;
  }

  bool isDownloaded(String trackId) {
    final task = getDownload(trackId);
    return task != null && task.isCompleted;
  }

  Future<void> saveDownload(DownloadTask task) async {
    await _box.put(task.id, task.toMap());
  }

  Future<void> removeDownload(String trackId) async {
    await _box.delete(trackId);
  }

  Stream<List<DownloadTask>> watchDownloads() {
    return _box.watch().map((_) => getAllDownloads());
  }
}
