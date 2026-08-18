import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/download_repository.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/search/data/search_repository.dart';

/// Riverpod provider for DownloadService
final downloadServiceProvider = Provider<DownloadService>((ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  final searchRepo = ref.watch(searchRepositoryProvider);
  final extractor = ExtractorService.instance;
  return DownloadService(
    ref: ref,
    repository: repository,
    searchRepository: searchRepo,
    extractorService: extractor,
  );
});

/// Service managing offline music file downloads using Dio and Extractor
class DownloadService {
  final Ref? _ref;
  final DownloadRepository _repository;
  final SearchRepository _searchRepository;
  final ExtractorService _extractorService;
  final Dio _dio;

  // Active cancel tokens for in-flight downloads
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadService({
    Ref? ref,
    required DownloadRepository repository,
    required SearchRepository searchRepository,
    required ExtractorService extractorService,
    Dio? dio,
  })  : _ref = ref,
        _repository = repository,
        _searchRepository = searchRepository,
        _extractorService = extractorService,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 5),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                },
              ),
            );

  /// Gets the local downloads directory
  Future<Directory> getDownloadsDirectory() async {
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }
    final dir = Directory('${baseDir.path}/orbitune_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Calculates total offline storage used by downloads in bytes
  Future<int> calculateTotalStorageUsed() async {
    try {
      final dir = await getDownloadsDirectory();
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
      return total;
    } catch (e) {
      debugPrint('[DownloadService] calculateTotalStorageUsed error: $e');
      return 0;
    }
  }

  /// Starts downloading a [track]
  Future<void> startDownload(
    Track track, {
    AudioQuality quality = AudioQuality.high320k,
  }) async {
    // Check if already completed or downloading
    final existing = _repository.getDownload(track.id);
    if (existing != null && existing.isCompleted && existing.localFilePath != null) {
      final file = File(existing.localFilePath!);
      if (await file.exists()) {
        debugPrint('[DownloadService] Track "${track.title}" is already downloaded.');
        return;
      }
    }

    final cancelToken = CancelToken();
    _cancelTokens[track.id] = cancelToken;

    var task = DownloadTask(
      id: track.id,
      track: track,
      status: DownloadStatus.downloading,
      progress: 0.0,
      quality: quality,
      startedAt: DateTime.now(),
    );

    await _saveAndNotify(task);

    try {
      // 1. Resolve direct download/stream URL
      String? downloadUrl = track.downloadUrl ?? track.streamUrl;
      if (downloadUrl == null || downloadUrl.isEmpty) {
        downloadUrl = await _searchRepository.resolveStreamUrl(track, quality: quality);
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        if (track.source == 'extractor' || _extractorService.isSupportedMediaUrl(track.id)) {
          downloadUrl = await _extractorService.getBestAudioStreamUrl(track.id);
        }
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception('Unable to resolve audio stream URL for download');
      }

      // 2. Prepare file destination
      final downloadsDir = await getDownloadsDirectory();
      final sanitizedTitle = track.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final sanitizedArtist = track.artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final extension = downloadUrl.contains('.m4a')
          ? 'm4a'
          : downloadUrl.contains('.flac')
              ? 'flac'
              : downloadUrl.contains('.mp4')
                  ? 'mp4'
                  : 'mp3';

      final filePath =
          '${downloadsDir.path}/${track.id}_${sanitizedArtist}_$sanitizedTitle.$extension';
      final file = File(filePath);

      // 3. Download with Dio progress callback
      await _dio.download(
        downloadUrl,
        file.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            task = task.copyWith(
              status: DownloadStatus.downloading,
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
              localFilePath: file.path,
            );
            _saveAndNotify(task);
          }
        },
      );

      // 4. Mark as completed
      final fileLength = await file.length();
      final completedTrack = track.copyWith(
        streamUrl: file.path,
        downloadUrl: file.path,
        audioQuality: quality,
      );

      task = task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: fileLength,
        totalBytes: fileLength,
        localFilePath: file.path,
        track: completedTrack,
        completedAt: DateTime.now(),
      );

      await _saveAndNotify(task);
      _cancelTokens.remove(track.id);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        task = task.copyWith(
          status: DownloadStatus.cancelled,
          errorMessage: 'Download cancelled',
        );
      } else {
        task = task.copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.message ?? 'Network error during download',
        );
      }
      await _saveAndNotify(task);
      _cancelTokens.remove(track.id);
    } catch (e) {
      task = task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      await _saveAndNotify(task);
      _cancelTokens.remove(track.id);
    }
  }

  /// Cancels an in-flight download
  Future<void> cancelDownload(String trackId) async {
    final token = _cancelTokens[trackId];
    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled download');
    }
    _cancelTokens.remove(trackId);

    final task = _repository.getDownload(trackId);
    if (task != null) {
      final updated = task.copyWith(
        status: DownloadStatus.cancelled,
        errorMessage: 'Cancelled',
      );
      await _saveAndNotify(updated);
    }
  }

  /// Pauses a download
  Future<void> pauseDownload(String trackId) async {
    await cancelDownload(trackId);
    final task = _repository.getDownload(trackId);
    if (task != null) {
      final updated = task.copyWith(status: DownloadStatus.paused);
      await _saveAndNotify(updated);
    }
  }

  /// Resumes or retries a failed/paused download
  Future<void> retryDownload(String trackId) async {
    final task = _repository.getDownload(trackId);
    if (task != null) {
      await startDownload(task.track, quality: task.quality);
    }
  }

  /// Deletes a downloaded song file and removes from Hive
  Future<void> deleteDownload(String trackId) async {
    await cancelDownload(trackId);

    final task = _repository.getDownload(trackId);
    if (task != null && task.localFilePath != null) {
      try {
        final file = File(task.localFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[DownloadService] Error deleting file: $e');
      }
    }

    await _repository.removeDownload(trackId);
    if (_ref != null) {
      _ref!.read(downloadListProvider.notifier).removeTask(trackId);
    }
  }

  /// Deletes all downloaded files and clears download records
  Future<void> deleteAllDownloads() async {
    final all = _repository.getAllDownloads();
    for (final task in all) {
      await deleteDownload(task.id);
    }
  }

  Future<void> _saveAndNotify(DownloadTask task) async {
    await _repository.saveDownload(task);
    if (_ref != null) {
      _ref!.read(downloadListProvider.notifier).addOrUpdateTask(task);
    }
  }
}
