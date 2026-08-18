import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:orbitune/features/audio_player/data/audio_handler.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_player_service.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  setUpAll(() {
    registerMockJustAudioPlatform();
  });

  group('OrbituneAudioHandler Tests', () {
    test('createAudioSource correctly wraps network track with MediaItem tag', () {
      final track = Track(
        id: 'track_1',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        duration: const Duration(minutes: 3, seconds: 20),
        artworkUrl: 'https://example.com/artwork.jpg',
        streamUrl: 'https://example.com/audio.mp4',
        source: 'jiosaavn',
        bitrate: 320,
        audioQuality: AudioQuality.high320k,
      );

      final source = OrbituneAudioHandler.createAudioSource(
        track,
        'https://example.com/audio.mp4',
        headers: {'User-Agent': 'Orbitune/1.0'},
      );

      expect(source, isA<UriAudioSource>());
      final uriSource = source as UriAudioSource;
      expect(uriSource.uri.toString(), 'https://example.com/audio.mp4');
      expect(uriSource.tag, isNotNull);
    });

    test('createAudioSource correctly creates FileAudioSource for local paths', () {
      final track = Track(
        id: 'track_local',
        title: 'Offline Jam',
        artist: 'Artist',
        localFilePath: '/storage/emulated/0/Music/song.mp3',
      );

      final source = OrbituneAudioHandler.createAudioSource(
        track,
        '/storage/emulated/0/Music/song.mp3',
      );

      expect(source, isA<UriAudioSource>());
    });

    test('createConcatenatingSource creates sequential audio playlist', () {
      final track1 = Track(id: 't1', title: 'Song 1', artist: 'Artist 1');
      final track2 = Track(id: 't2', title: 'Song 2', artist: 'Artist 2');

      final concatSource = OrbituneAudioHandler.createConcatenatingSource([
        MapEntry(track1, 'https://example.com/s1.mp3'),
        MapEntry(track2, 'https://example.com/s2.mp3'),
      ]);

      expect(concatSource.length, 2);
    });
  });

  group('AudioPlayerService Unit Tests', () {
    late AudioPlayerService playerService;

    setUp(() {
      playerService = AudioPlayerService();
    });

    tearDown(() async {
      await playerService.dispose();
    });

    test('Initial snapshot has idle status, zero position, and default volume/speed', () {
      final snap = playerService.currentSnapshot;
      expect(snap.status, PlaybackStatus.idle);
      expect(snap.position, Duration.zero);
      expect(snap.volume, 1.0);
      expect(snap.speed, 1.0);
    });

    test('setVolume and setSpeed update current snapshot', () async {
      await playerService.setVolume(0.65);
      expect(playerService.currentSnapshot.volume, 0.65);

      await playerService.setSpeed(1.75);
      expect(playerService.currentSnapshot.speed, 1.75);
    });

    test('duckVolume adjusts volume', () async {
      await playerService.duckVolume(0.2);
      expect(playerService.currentSnapshot.volume, 0.2);
    });

    test('playTrack updates currentTrack and playlist state', () async {
      final track = Track(
        id: 'play_track_1',
        title: 'Test Title',
        artist: 'Test Artist',
        duration: const Duration(seconds: 180),
      );

      await playerService.playTrack(track, 'https://example.com/song.mp3');

      expect(playerService.currentTrack?.id, 'play_track_1');
      expect(playerService.currentPlaylist.length, 1);
      expect(playerService.currentSnapshot.currentTrack?.title, 'Test Title');
    });

    test('playPlaylist initializes playlist queue correctly', () async {
      final t1 = Track(id: 'pt1', title: 'Song A', artist: 'Artist A');
      final t2 = Track(id: 'pt2', title: 'Song B', artist: 'Artist B');

      await playerService.playPlaylist(
        [t1, t2],
        ['https://example.com/a.mp3', 'https://example.com/b.mp3'],
        initialIndex: 1,
      );

      expect(playerService.currentPlaylist.length, 2);
      expect(playerService.currentTrack?.id, 'pt2');
    });
  });

  group('PlayerStateSnapshot and PlaybackMode Tests', () {
    test('PlayerStateSnapshot state flags and progress calculation', () {
      const snapshot = PlayerStateSnapshot(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 45),
        duration: Duration(seconds: 180),
        bufferedPosition: Duration(seconds: 90),
        volume: 0.8,
        speed: 1.25,
      );

      expect(snapshot.isPlaying, true);
      expect(snapshot.isPaused, false);
      expect(snapshot.isBuffering, false);
      expect(snapshot.hasError, false);
      expect(snapshot.progressRatio, 0.25);
      expect(snapshot.bufferedRatio, 0.5);
    });

    test('PlayerStateSnapshot handles zero duration without NaN', () {
      const snapshot = PlayerStateSnapshot(
        status: PlaybackStatus.idle,
        position: Duration.zero,
        duration: Duration.zero,
      );

      expect(snapshot.progressRatio, 0.0);
      expect(snapshot.bufferedRatio, 0.0);
    });

    test('PlaybackMode converts from and to JSON strings', () {
      expect(PlaybackMode.fromString('repeatAll'), PlaybackMode.repeatAll);
      expect(PlaybackMode.fromString('repeatOne'), PlaybackMode.repeatOne);
      expect(PlaybackMode.fromString('shuffle'), PlaybackMode.shuffle);
      expect(PlaybackMode.fromString('unknown'), PlaybackMode.off);

      expect(PlaybackMode.repeatAll.toJson(), 'repeatAll');
      expect(PlaybackMode.shuffle.isShuffle, true);
    });
  });
}
