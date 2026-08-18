import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_band_mode.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_preset.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_profile.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';

void main() {
  group('Settings, Equalizer, Downloader & Lyrics Models Tests', () {
    test('AppSettings serialization and default values', () {
      const settings = AppSettings();
      expect(settings.themeMode, 'dark');
      expect(settings.streamingQuality, AudioQuality.high320k);
      expect(settings.gaplessPlayback, true);
      expect(settings.equalizerEnabled, false);

      final modified = settings.copyWith(
        themeMode: 'oled',
        streamingQuality: AudioQuality.lossless,
        crossfadeDurationSeconds: 4,
        equalizerEnabled: true,
      );

      expect(modified.themeMode, 'oled');
      expect(modified.streamingQuality, AudioQuality.lossless);
      expect(modified.crossfadeDurationSeconds, 4);
      expect(modified.equalizerEnabled, true);

      final map = modified.toMap();
      final restored = AppSettings.fromMap(map);
      expect(restored.themeMode, 'oled');
      expect(restored.streamingQuality, AudioQuality.lossless);
      expect(restored.crossfadeDurationSeconds, 4);
      expect(restored.equalizerEnabled, true);
    });

    test('EQPreset and EQProfile functionality', () {
      final rockPreset = EQPreset.getByName('Rock');
      expect(rockPreset.name, 'Rock');
      expect(rockPreset.bandGains[60], 4.5);

      final profile = EQProfile(
        isEnabled: true,
        bandMode: EQBandMode.band5,
        presetName: 'Rock',
        bassBoost: 0.75,
        virtualizer: 0.5,
      );

      expect(profile.isEnabled, true);
      expect(profile.effectiveBandGains[60], 4.5);
      expect(profile.bassBoost, 0.75);

      final map = profile.toMap();
      final restored = EQProfile.fromMap(map);
      expect(restored.presetName, 'Rock');
      expect(restored.bassBoost, 0.75);
      expect(restored.virtualizer, 0.5);
    });

    test('DownloadTask status and progress', () {
      final track = Track(id: 'dl_track_1', title: 'Offline Song', artist: 'Artist');
      final task = DownloadTask(
        id: 'dl_task_1',
        track: track,
        status: DownloadStatus.downloading,
        progress: 0.65,
        downloadedBytes: 6500000,
        totalBytes: 10000000,
        quality: AudioQuality.high320k,
      );

      expect(task.isDownloading, true);
      expect(task.progress, 0.65);

      final map = task.toMap();
      final restored = DownloadTask.fromMap(map);
      expect(restored.id, 'dl_task_1');
      expect(restored.status, DownloadStatus.downloading);
      expect(restored.track.title, 'Offline Song');
    });

    test('LyricLine and LyricWord parsing & string format', () {
      final line = LyricLine(
        timestamp: const Duration(minutes: 1, seconds: 15, milliseconds: 450),
        text: 'I was drowning in the deep',
        words: [
          LyricWord(timestamp: const Duration(seconds: 75), text: 'I'),
          LyricWord(timestamp: const Duration(seconds: 75, milliseconds: 300), text: 'was'),
        ],
      );

      expect(line.timestamp.inSeconds, 75);
      expect(line.toString(), '[01:15.45] I was drowning in the deep');

      final map = line.toMap();
      final restored = LyricLine.fromMap(map);
      expect(restored.text, 'I was drowning in the deep');
      expect(restored.words.length, 2);
      expect(restored.words.first.text, 'I');
    });
  });
}
