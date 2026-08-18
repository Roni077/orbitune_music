import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';

void main() {
  group('Library Domain Models & Analytics Tests', () {
    test('UserPlaylist tracks and duration calculation', () {
      final t1 = Track(
        id: 't1',
        title: 'Song 1',
        artist: 'Artist 1',
        duration: const Duration(minutes: 3),
      );
      final t2 = Track(
        id: 't2',
        title: 'Song 2',
        artist: 'Artist 2',
        duration: const Duration(minutes: 2, seconds: 30),
      );

      final playlist = UserPlaylist(
        id: 'custom_pl_1',
        name: 'Late Night Chill',
        description: 'Atmospheric electronic beats',
        songs: [t1, t2],
        isPinned: true,
      );

      expect(playlist.songCount, 2);
      expect(playlist.totalDuration, const Duration(minutes: 5, seconds: 30));
      expect(playlist.isPinned, true);

      final map = playlist.toMap();
      final restored = UserPlaylist.fromMap(map);
      expect(restored.name, 'Late Night Chill');
      expect(restored.songCount, 2);
      expect(restored.songs.last.title, 'Song 2');
    });

    test('FavoriteSong and HistoryItem serialization', () {
      final track = Track(id: 'fav_1', title: 'Favorite Hit', artist: 'Pop Star');
      final fav = FavoriteSong(track: track, playCount: 15);
      final favMap = fav.toMap();
      final favRestored = FavoriteSong.fromMap(favMap);
      expect(favRestored.track.title, 'Favorite Hit');
      expect(favRestored.playCount, 15);

      final history = HistoryItem(
        id: track.id,
        track: track,
        durationPlayed: const Duration(minutes: 3),
        completed: true,
      );
      final histMap = history.toMap();
      final histRestored = HistoryItem.fromMap(histMap);
      expect(histRestored.completed, true);
      expect(histRestored.durationPlayed, const Duration(minutes: 3));
    });

    test('ListeningStats records sessions, streak and top statistics', () {
      var stats = const ListeningStats();
      final track = Track(
        id: 'hit_1',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        genre: 'Pop',
      );

      // Record first session
      final day1 = DateTime(2026, 8, 15, 10, 0);
      stats = stats.recordSession(
        track: track,
        durationPlayed: const Duration(minutes: 4),
        timestamp: day1,
      );

      expect(stats.totalPlays, 1);
      expect(stats.totalListeningTime, const Duration(minutes: 4));
      expect(stats.artistPlayCounts['Ed Sheeran'], 1);
      expect(stats.genrePlayCounts['Pop'], 1);
      expect(stats.streakDays, 1);

      // Record second session on next day (consecutive)
      final day2 = DateTime(2026, 8, 16, 10, 0);
      stats = stats.recordSession(
        track: track,
        durationPlayed: const Duration(minutes: 6),
        timestamp: day2,
      );

      expect(stats.totalPlays, 2);
      expect(stats.totalListeningTime, const Duration(minutes: 10));
      expect(stats.artistPlayCounts['Ed Sheeran'], 2);
      expect(stats.streakDays, 2);

      final map = stats.toMap();
      final fromMap = ListeningStats.fromMap(map);
      expect(fromMap.totalPlays, 2);
      expect(fromMap.streakDays, 2);
      expect(fromMap.artistPlayCounts['Ed Sheeran'], 2);
    });
  });
}
