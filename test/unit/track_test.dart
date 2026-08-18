import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/queue_item.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

void main() {
  group('Track Domain Model Tests', () {
    test('Track creates and serializes toMap/fromMap correctly', () {
      final track = Track(
        id: 'track_123',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: const Duration(minutes: 3, seconds: 50),
        artworkUrl: 'https://example.com/art_150.jpg',
        highResArtworkUrl: 'https://example.com/art_500.jpg',
        streamUrl: 'https://example.com/stream.mp4',
        source: 'jiosaavn',
        bitrate: 320,
        audioQuality: AudioQuality.high320k,
        isExplicit: true,
        hasSyncedLyrics: true,
      );

      final map = track.toMap();
      expect(map['id'], 'track_123');
      expect(map['title'], 'Starboy');
      expect(map['durationMs'], 230000);
      expect(map['audioQuality'], 'high320k');
      expect(map['bitrate'], 320);

      final deserialized = Track.fromMap(map);
      expect(deserialized.id, track.id);
      expect(deserialized.title, track.title);
      expect(deserialized.artist, track.artist);
      expect(deserialized.duration, track.duration);
      expect(deserialized.bestArtworkUrl, 'https://example.com/art_500.jpg');
      expect(deserialized.isExplicit, true);
      expect(deserialized.hasSyncedLyrics, true);
      expect(deserialized, track);
    });

    test('Track json serialization works', () {
      final track = Track(
        id: 'track_456',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
      );
      final jsonStr = track.toJson();
      final fromJson = Track.fromJson(jsonStr);
      expect(fromJson.id, 'track_456');
      expect(fromJson.title, 'Blinding Lights');
    });

    test('Track converts to MediaItem for background playback', () {
      final track = Track(
        id: 'track_789',
        title: 'Levitating',
        artist: 'Dua Lipa',
        album: 'Future Nostalgia',
        duration: const Duration(minutes: 3, seconds: 23),
        artworkUrl: 'https://example.com/art.jpg',
      );

      final mediaItem = track.toMediaItem();
      expect(mediaItem.id, 'track_789');
      expect(mediaItem.title, 'Levitating');
      expect(mediaItem.artist, 'Dua Lipa');
      expect(mediaItem.album, 'Future Nostalgia');
      expect(mediaItem.artUri, Uri.parse('https://example.com/art.jpg'));
    });

    test('AudioQuality handles labels and string conversions', () {
      expect(AudioQuality.fromString('320kbps'), AudioQuality.high320k);
      expect(AudioQuality.fromString('160'), AudioQuality.medium160k);
      expect(AudioQuality.fromString('96'), AudioQuality.low96k);
      expect(AudioQuality.fromString('flac'), AudioQuality.lossless);
      expect(AudioQuality.high320k.bitrateKbps, 320);
    });

    test('PlaybackMode repeat mode cycling', () {
      var mode = PlaybackMode.off;
      expect(mode.nextRepeatMode(), PlaybackMode.repeatAll);
      mode = PlaybackMode.repeatAll;
      expect(mode.nextRepeatMode(), PlaybackMode.repeatOne);
      mode = PlaybackMode.repeatOne;
      expect(mode.nextRepeatMode(), PlaybackMode.off);
    });

    test('PlayerStateSnapshot calculations', () {
      final state = PlayerStateSnapshot(
        status: PlaybackStatus.playing,
        position: const Duration(seconds: 30),
        duration: const Duration(seconds: 120),
        bufferedPosition: const Duration(seconds: 60),
      );

      expect(state.isPlaying, true);
      expect(state.progressRatio, 0.25);
      expect(state.bufferedRatio, 0.5);
    });

    test('QueueItem serializes correctly', () {
      final track = Track(id: 'q_1', title: 'Song', artist: 'Artist');
      final queueItem = QueueItem(queueId: 'item_1', track: track);
      final map = queueItem.toMap();
      final restored = QueueItem.fromMap(map);
      expect(restored.queueId, 'item_1');
      expect(restored.track.id, 'q_1');
    });
  });
}
