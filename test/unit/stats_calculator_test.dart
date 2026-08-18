import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';

void main() {
  group('ListeningStats Domain & Calculation Unit Tests', () {
    const defaultStats = ListeningStats();

    final testTrack1 = Track(
      id: 'song_1',
      title: 'Kesariya',
      artist: 'Arijit Singh',
      album: 'Brahmastra',
      genre: 'Bollywood',
      duration: const Duration(minutes: 4, seconds: 28),
    );

    final testTrack2 = Track(
      id: 'song_2',
      title: 'Starboy',
      artist: 'The Weeknd',
      album: 'Starboy',
      genre: 'Pop / R&B',
      duration: const Duration(minutes: 3, seconds: 50),
    );

    test('Initial stats state has zero duration and empty maps', () {
      expect(defaultStats.totalListeningTime, Duration.zero);
      expect(defaultStats.totalPlays, 0);
      expect(defaultStats.songPlayCounts, isEmpty);
      expect(defaultStats.artistPlayCounts, isEmpty);
      expect(defaultStats.genrePlayCounts, isEmpty);
      expect(defaultStats.streakDays, 0);
    });

    test('recordSession increments play counts, durations, artists and genres correctly', () {
      final now = DateTime(2026, 8, 18, 14, 30);
      final updated1 = defaultStats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 4),
        timestamp: now,
      );

      expect(updated1.totalPlays, 1);
      expect(updated1.totalListeningTime, const Duration(minutes: 4));
      expect(updated1.songPlayCounts['song_1'], 1);
      expect(updated1.artistPlayCounts['Arijit Singh'], 1);
      expect(updated1.genrePlayCounts['Bollywood'], 1);
      expect(updated1.dailyListeningMinutes['2026-08-18'], 4);
      expect(updated1.streakDays, 1);

      // Record second session with same artist
      final updated2 = updated1.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 3),
        timestamp: now,
      );

      expect(updated2.totalPlays, 2);
      expect(updated2.totalListeningTime, const Duration(minutes: 7));
      expect(updated2.songPlayCounts['song_1'], 2);
      expect(updated2.artistPlayCounts['Arijit Singh'], 2);
      expect(updated2.genrePlayCounts['Bollywood'], 2);
      expect(updated2.dailyListeningMinutes['2026-08-18'], 7);

      // Record third session with different artist
      final updated3 = updated2.recordSession(
        track: testTrack2,
        durationPlayed: const Duration(minutes: 3),
        timestamp: now,
      );

      expect(updated3.totalPlays, 3);
      expect(updated3.songPlayCounts['song_2'], 1);
      expect(updated3.artistPlayCounts['The Weeknd'], 1);
      expect(updated3.genrePlayCounts['Pop / R&B'], 1);
    });

    test('Listening streak increments correctly across consecutive days', () {
      final day1 = DateTime(2026, 8, 16, 12, 0);
      final day2 = DateTime(2026, 8, 17, 12, 0);
      final day3 = DateTime(2026, 8, 18, 12, 0);

      var stats = defaultStats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 3),
        timestamp: day1,
      );
      expect(stats.streakDays, 1);

      stats = stats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 3),
        timestamp: day2,
      );
      expect(stats.streakDays, 2);

      stats = stats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 3),
        timestamp: day3,
      );
      expect(stats.streakDays, 3);
    });

    test('Listening streak resets to 1 if consecutive day is missed', () {
      final day1 = DateTime(2026, 8, 10, 12, 0);
      final day4 = DateTime(2026, 8, 14, 12, 0);

      var stats = defaultStats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 3),
        timestamp: day1,
      );
      expect(stats.streakDays, 1);

      // 4 days later
      stats = stats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 3),
        timestamp: day4,
      );
      expect(stats.streakDays, 1);
    });

    test('ListeningStats JSON serialization and deserialization works reliably', () {
      final stats = defaultStats.recordSession(
        track: testTrack1,
        durationPlayed: const Duration(minutes: 5),
        timestamp: DateTime(2026, 8, 18),
      );

      final jsonString = stats.toJson();
      final decoded = ListeningStats.fromJson(jsonString);

      expect(decoded.totalPlays, stats.totalPlays);
      expect(decoded.totalListeningTime, stats.totalListeningTime);
      expect(decoded.songPlayCounts, stats.songPlayCounts);
      expect(decoded.artistPlayCounts, stats.artistPlayCounts);
      expect(decoded.genrePlayCounts, stats.genrePlayCounts);
      expect(decoded.streakDays, stats.streakDays);
      expect(decoded.lastActiveDate, stats.lastActiveDate);
    });
  });
}
