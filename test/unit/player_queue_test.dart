import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late ProviderContainer container;

  final sampleTracks = List.generate(
    5,
    (i) => Track(
      id: 'test_track_$i',
      title: 'Song $i',
      artist: 'Artist $i',
      duration: Duration(seconds: 180 + i * 10),
      localFilePath: 'C:/mock/music/song_$i.mp3',
    ),
  );

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_queue_test_');

    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
  });

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    HiveService.instance.resetForTesting();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Queue Domain State & Notifier Tests', () {
    test('Initial QueueState is empty with default autoplay enabled', () {
      final state = container.read(queueProvider);
      expect(state.isEmpty, true);
      expect(state.length, 0);
      expect(state.currentIndex, -1);
      expect(state.currentItem, isNull);
      expect(state.upcomingCount, 0);
      expect(state.isAutoplayEnabled, true);
      expect(state.totalRemainingDuration, Duration.zero);
    });

    test('playTrack initializes single-track queue', () async {
      final notifier = container.read(queueProvider.notifier);
      final track = sampleTracks[0];

      await notifier.playTrack(track, queueTitle: 'Single Play');

      final state = container.read(queueProvider);
      expect(state.length, 1);
      expect(state.currentIndex, 0);
      expect(state.currentTrack?.id, track.id);
      expect(state.upcomingCount, 0);
      expect(state.queueTitle, 'Single Play');
    });

    test('playPlaylist loads full track sequence with correct initial index', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playPlaylist(
        sampleTracks,
        initialIndex: 2,
        queueTitle: 'Chill Vibes',
      );

      final state = container.read(queueProvider);
      expect(state.length, 5);
      expect(state.currentIndex, 2);
      expect(state.currentTrack?.id, sampleTracks[2].id);
      expect(state.previousItems.length, 2);
      expect(state.upcomingCount, 2);
      expect(state.upcomingItems.first.track.id, sampleTracks[3].id);
      expect(state.queueTitle, 'Chill Vibes');
    });

    test('addToQueue and addTracksToQueue appends to end', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playTrack(sampleTracks[0]);
      expect(container.read(queueProvider).length, 1);

      notifier.addToQueue(sampleTracks[1]);
      var state = container.read(queueProvider);
      expect(state.length, 2);
      expect(state.upcomingCount, 1);
      expect(state.upcomingItems.first.track.id, sampleTracks[1].id);

      notifier.addTracksToQueue([sampleTracks[2], sampleTracks[3]]);
      state = container.read(queueProvider);
      expect(state.length, 4);
      expect(state.upcomingCount, 3);
      expect(state.items.last.track.id, sampleTracks[3].id);
    });

    test('playNext inserts item immediately after current track', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playPlaylist(sampleTracks, initialIndex: 1); // Current is Song 1
      final newTrack = Track(
        id: 'inserted_next',
        title: 'Instant Next Song',
        artist: 'Orbitune',
        duration: const Duration(seconds: 200),
        localFilePath: 'C:/mock/music/next.mp3',
      );

      notifier.playNext(newTrack);

      final state = container.read(queueProvider);
      expect(state.length, 6);
      expect(state.currentIndex, 1); // Current is still Song 1
      expect(state.upcomingItems.first.track.id, 'inserted_next');
      expect(state.items[2].track.id, 'inserted_next');
    });

    test('removeFromQueue and removeUpcomingItem safely adjusts indices', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playPlaylist(sampleTracks, initialIndex: 2); // items: 0, 1, [2], 3, 4

      // Remove from upcoming (Song 3 at index 3, relative upcoming index 0)
      await notifier.removeUpcomingItem(0);
      var state = container.read(queueProvider);
      expect(state.length, 4);
      expect(state.currentIndex, 2);
      expect(state.upcomingCount, 1);
      expect(state.upcomingItems.first.track.id, sampleTracks[4].id);

      // Remove previous item (Song 0 at index 0)
      await notifier.removeFromQueue(0);
      state = container.read(queueProvider);
      expect(state.length, 3);
      expect(state.currentIndex, 1); // Index shifted from 2 to 1
      expect(state.currentTrack?.id, sampleTracks[2].id);
    });

    test('reorderUpcoming correctly rearranges upcoming list', () async {
      final notifier = container.read(queueProvider.notifier);

      // items: [0], 1, 2, 3, 4 -> currentIndex = 0
      await notifier.playPlaylist(sampleTracks, initialIndex: 0);

      // Reorder upcoming: move upcoming item 0 (Song 1) to upcoming position 2 (after Song 3)
      notifier.reorderUpcoming(0, 2);

      final state = container.read(queueProvider);
      expect(state.currentIndex, 0);
      expect(state.currentTrack?.id, sampleTracks[0].id);
      expect(state.upcomingItems[0].track.id, sampleTracks[2].id);
      expect(state.upcomingItems[1].track.id, sampleTracks[1].id);
    });

    test('shuffleQueue shuffles upcoming items while keeping current and previous intact', () async {
      final notifier = container.read(queueProvider.notifier);

      final largePlaylist = List.generate(
        15,
        (i) => Track(
          id: 'large_$i',
          title: 'Track $i',
          artist: 'Artist $i',
          localFilePath: 'C:/mock/music/$i.mp3',
        ),
      );

      await notifier.playPlaylist(largePlaylist, initialIndex: 3);
      final currentTrackId = container.read(queueProvider).currentTrack?.id;
      final prevTrackIds = container
          .read(queueProvider)
          .previousItems
          .map((i) => i.track.id)
          .toList();

      notifier.shuffleQueue();

      final newState = container.read(queueProvider);
      expect(newState.currentTrack?.id, currentTrackId);
      expect(
        newState.previousItems.map((i) => i.track.id).toList(),
        prevTrackIds,
      );
      expect(newState.upcomingCount, 11);
    });

    test('clearQueue preserves or deletes current track as configured', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playPlaylist(sampleTracks, initialIndex: 1);

      // Clear upcoming only
      notifier.clearUpcoming();
      var state = container.read(queueProvider);
      expect(state.length, 2);
      expect(state.upcomingCount, 0);
      expect(state.currentTrack?.id, sampleTracks[1].id);

      // Clear queue keeping current track
      await notifier.clearQueue(keepCurrentTrack: true);
      state = container.read(queueProvider);
      expect(state.length, 1);
      expect(state.currentIndex, 0);
      expect(state.currentTrack?.id, sampleTracks[1].id);

      // Clear queue completely
      await notifier.clearQueue(keepCurrentTrack: false);
      state = container.read(queueProvider);
      expect(state.isEmpty, true);
      expect(state.currentIndex, -1);
    });

    test('skipToQueueIndex and skipToItem navigates and logs history', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playPlaylist(sampleTracks, initialIndex: 0);

      await notifier.skipToQueueIndex(3);
      var state = container.read(queueProvider);
      expect(state.currentIndex, 3);
      expect(state.currentTrack?.id, sampleTracks[3].id);
      expect(state.history.length, 1);
      expect(state.history.first.id, sampleTracks[0].id);

      final secondItemId = state.items[1].queueId;
      await notifier.skipToItem(secondItemId);
      state = container.read(queueProvider);
      expect(state.currentIndex, 1);
      expect(state.currentTrack?.id, sampleTracks[1].id);
    });

    test('toggleAutoplay toggles state', () {
      final notifier = container.read(queueProvider.notifier);

      expect(container.read(queueProvider).isAutoplayEnabled, true);
      notifier.toggleAutoplay();
      expect(container.read(queueProvider).isAutoplayEnabled, false);
      notifier.toggleAutoplay();
      expect(container.read(queueProvider).isAutoplayEnabled, true);
    });

    test('saveQueueAsPlaylist creates user playlist in LibraryRepository', () async {
      final notifier = container.read(queueProvider.notifier);

      await notifier.playPlaylist(sampleTracks, initialIndex: 0, queueTitle: 'Saved Mix');

      final savedPlaylist = await notifier.saveQueueAsPlaylist(
        'My Masterpiece Queue',
        description: 'Exported from queue',
      );

      expect(savedPlaylist.name, 'My Masterpiece Queue');
      expect(savedPlaylist.songs.length, 5);
      expect(savedPlaylist.songs.first.id, sampleTracks[0].id);

      // Verify playlists provider reflects saved playlist
      final userPlaylists = container.read(userPlaylistsProvider);
      expect(userPlaylists.any((p) => p.name == 'My Masterpiece Queue'), true);
    });
  });
}
