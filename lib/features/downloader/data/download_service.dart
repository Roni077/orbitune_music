import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
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
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
              ),
            ) {
    int lastExtractorUpdate = 0;
    _extractorService.onProgress.listen((progressEvent) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastExtractorUpdate < 500 && progressEvent.progressFraction < 1.0) return;
      lastExtractorUpdate = now;

      final trackId = progressEvent.processId;
      var task = _repository.getDownload(trackId);
      if (task != null && task.status == DownloadStatus.downloading) {
        task = task.copyWith(
          progress: progressEvent.progressFraction,
        );
        _saveAndNotify(task);
      }
    });
  }

  /// Resolves the storage directory for offline music downloads
  static Future<Directory> resolveDownloadsDirectory() async {
    if (kIsWeb) {
      return Directory.systemTemp;
    }

    if (Platform.isAndroid) {
      final publicDownloadDir = Directory('/storage/emulated/0/Download/Orbitune_Downloads');
      try {
        if (!await publicDownloadDir.exists()) {
          await publicDownloadDir.create(recursive: true);
        }
        return publicDownloadDir;
      } catch (e) {
        debugPrint('[DownloadService] Fallback from Android public Download folder: $e');
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final sysDownloads = await path_provider.getDownloadsDirectory();
        if (sysDownloads != null) {
          final dir = Directory('${sysDownloads.path}/Orbitune_Downloads');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (e) {
        debugPrint('[DownloadService] Desktop getDownloadsDirectory fallback: $e');
      }
    }

    // Default fallback (e.g. iOS or sandboxed environments)
    Directory baseDir;
    try {
      baseDir = await path_provider.getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }
    final dir = Directory('${baseDir.path}/Orbitune_Downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ensures the downloads folder exists (used on startup/first launch)
  static Future<Directory> ensureDownloadsDirectoryExists() async {
    return resolveDownloadsDirectory();
  }

  /// Gets the local downloads directory
  Future<Directory> getDownloadsDirectory() async {
    return resolveDownloadsDirectory();
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
      // 1. Resolve URL for extraction
      final sourceUrl = (track.source == 'youtube' || track.source == 'extractor')
          ? 'https://youtube.com/watch?v=${track.id}'
          : track.id;

      // 2. Prepare file destination
      final downloadsDir = await getDownloadsDirectory();
      final sanitizedTitle = track.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final sanitizedArtist = track.artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final extension = 'mp3'; // Native extractor converts to mp3 with tags

      final filePath =
          '${downloadsDir.path}/${track.id}_${sanitizedArtist}_$sanitizedTitle.$extension';
      final file = File(filePath);

      // 3. Download media
      if (_extractorService.isAvailable) {
        final result = await _extractorService.downloadMedia(
          url: sourceUrl,
          outputPath: downloadsDir.path,
          outputTemplate: '${track.id}_${sanitizedArtist}_$sanitizedTitle.%(ext)s',
          processId: track.id,
        );

        if (result.status.name != 'success') {
          throw Exception(result.errorMessage ?? 'Extractor failed to download media');
        }
      } else {
        // Fallback to Dio + SearchRepository stream resolution
        final streamUrl = await _searchRepository.resolveStreamUrl(track, quality: quality);
        if (streamUrl == null || streamUrl.isEmpty) {
          throw Exception('Failed to resolve stream URL for downloading');
        }
        
        int lastUpdate = 0;
        await _dio.download(
          streamUrl,
          file.path,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final now = DateTime.now().millisecondsSinceEpoch;
              // Throttle UI and Hive updates to every 500ms
              if (now - lastUpdate > 500 || received == total) {
                lastUpdate = now;
                var progressTask = _repository.getDownload(track.id);
                if (progressTask != null && progressTask.status == DownloadStatus.downloading) {
                  progressTask = progressTask.copyWith(
                    progress: received / total,
                    downloadedBytes: received,
                    totalBytes: total,
                  );
                  _saveAndNotify(progressTask);
                }
              }
            }
          },
        );
      }

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
    if (_extractorService.isAvailable) {
      await _extractorService.cancelDownload(trackId);
    }
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
    final ref = _ref;
    if (ref != null) {
      ref.read(downloadListProvider.notifier).removeTask(trackId);
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
    final ref = _ref;
    if (ref != null) {
      ref.read(downloadListProvider.notifier).addOrUpdateTask(task);
    }
  }
}
