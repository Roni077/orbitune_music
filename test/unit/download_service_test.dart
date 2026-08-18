import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';

void main() {
  group('DownloadTask Domain Model & Status Unit Tests', () {
    final testTrack = Track(
      id: 'download_song_1',
      title: 'Pasoori',
      artist: 'Ali Sethi x Shae Gill',
      album: 'Coke Studio',
      duration: const Duration(minutes: 3, seconds: 44),
      streamUrl: 'https://example.com/audio/pasoori.mp3',
    );

    test('DownloadTask creation has pending status by default', () {
      final task = DownloadTask(
        id: testTrack.id,
        track: testTrack,
      );

      expect(task.id, testTrack.id);
      expect(task.track.title, 'Pasoori');
      expect(task.status, DownloadStatus.pending);
      expect(task.progress, 0.0);
      expect(task.downloadedBytes, 0);
      expect(task.totalBytes, 0);
      expect(task.isCompleted, isFalse);
      expect(task.isDownloading, isFalse);
    });

    test('DownloadTask copyWith updates progress, bytes, and status correctly', () {
      final task = DownloadTask(
        id: testTrack.id,
        track: testTrack,
      );

      final downloadingTask = task.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.45,
        downloadedBytes: 4500000,
        totalBytes: 10000000,
      );

      expect(downloadingTask.status, DownloadStatus.downloading);
      expect(downloadingTask.isDownloading, isTrue);
      expect(downloadingTask.progress, 0.45);
      expect(downloadingTask.downloadedBytes, 4500000);
      expect(downloadingTask.totalBytes, 10000000);

      final completedTask = downloadingTask.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        localFilePath: '/data/user/0/com.orbitune/app_flutter/orbitune_downloads/song.mp3',
        completedAt: DateTime.now(),
      );

      expect(completedTask.isCompleted, isTrue);
      expect(completedTask.progress, 1.0);
      expect(completedTask.localFilePath, contains('orbitune_downloads'));
    });

    test('DownloadTask JSON serialization and deserialization', () {
      final task = DownloadTask(
        id: testTrack.id,
        track: testTrack,
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: 8500000,
        totalBytes: 8500000,
        quality: AudioQuality.high320k,
        localFilePath: '/storage/emulated/0/Music/pasoori.mp3',
      );

      final json = task.toJson();
      final decoded = DownloadTask.fromJson(json);

      expect(decoded.id, task.id);
      expect(decoded.track.title, task.track.title);
      expect(decoded.status, DownloadStatus.completed);
      expect(decoded.progress, 1.0);
      expect(decoded.downloadedBytes, 8500000);
      expect(decoded.quality, AudioQuality.high320k);
      expect(decoded.localFilePath, task.localFilePath);
    });

    test('DownloadStatus helper getters report correct flags', () {
      final taskPending = DownloadTask(id: '1', track: testTrack, status: DownloadStatus.pending);
      final taskDownloading = DownloadTask(id: '2', track: testTrack, status: DownloadStatus.downloading);
      final taskPaused = DownloadTask(id: '3', track: testTrack, status: DownloadStatus.paused);
      final taskFailed = DownloadTask(id: '4', track: testTrack, status: DownloadStatus.failed);
      final taskCompleted = DownloadTask(id: '5', track: testTrack, status: DownloadStatus.completed);

      expect(taskPending.isDownloading, isFalse);
      expect(taskDownloading.isDownloading, isTrue);
      expect(taskPaused.isPaused, isTrue);
      expect(taskFailed.isFailed, isTrue);
      expect(taskCompleted.isCompleted, isTrue);
    });
  });
}
