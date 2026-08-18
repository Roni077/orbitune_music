import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/downloader/presentation/screens/downloads_screen.dart';
import 'package:orbitune/features/downloader/presentation/widgets/download_tile.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/stats_provider.dart';
import 'package:orbitune/features/library/presentation/screens/history_screen.dart';
import 'package:orbitune/features/library/presentation/screens/stats_screen.dart';
import '../helpers/mock_audio_platform.dart';

class _MockDownloadNotifier extends StateNotifier<List<DownloadTask>>
    implements DownloadListNotifier {
  _MockDownloadNotifier(super.state);

  @override
  Future<void> addOrUpdateTask(DownloadTask task) async {}

  @override
  Future<void> removeTask(String trackId) async {}

  @override
  bool isDownloaded(String trackId) => true;

  @override
  void refresh() {}
}

class _MockStatsNotifier extends StateNotifier<ListeningStats>
    implements StatsNotifier {
  _MockStatsNotifier(super.state);

  @override
  Future<void> recordSession(Track track, Duration durationPlayed) async {}

  @override
  void refresh() {}
}

class _MockHistoryNotifier extends StateNotifier<List<HistoryItem>>
    implements HistoryNotifier {
  _MockHistoryNotifier(super.state);

  @override
  Future<void> recordPlay(Track track,
      {Duration durationPlayed = Duration.zero, bool completed = false}) async {}

  @override
  Future<void> removeHistoryItem(String trackId) async {}

  @override
  Future<void> clearHistory() async {}

  @override
  void refresh() {}
}

void main() {
  setUpAll(() {
    registerMockJustAudioPlatform();
  });

  final testTrack = Track(
    id: 't_down_1',
    title: 'Unholy',
    artist: 'Sam Smith',
    duration: const Duration(minutes: 2, seconds: 36),
  );

  final testTask = DownloadTask(
    id: testTrack.id,
    track: testTrack,
    status: DownloadStatus.completed,
    progress: 1.0,
    downloadedBytes: 5000000,
    totalBytes: 5000000,
  );

  final testStats = ListeningStats(
    totalPlays: 25,
    totalListeningTime: const Duration(hours: 3, minutes: 15),
    songPlayCounts: {'t_down_1': 15},
    artistPlayCounts: {'Sam Smith': 15, 'Dua Lipa': 10},
    genrePlayCounts: {'Pop': 20, 'Dance': 5},
    streakDays: 4,
    dailyListeningMinutes: {'2026-08-18': 45},
  );

  group('DownloadsScreen, HistoryScreen & StatsScreen Widget Tests', () {
    testWidgets('DownloadsScreen renders storage card, download items, and play all',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            downloadListProvider.overrideWith((ref) => _MockDownloadNotifier([testTask])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DownloadsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Offline Downloads'), findsOneWidget);
      expect(find.text('Offline Storage'), findsOneWidget);
      expect(find.byType(DownloadTile), findsOneWidget);
      expect(find.text('Unholy'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('HistoryScreen renders listening history list',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyProvider.overrideWith((ref) => _MockHistoryNotifier([
                  HistoryItem(
                    id: 'h_1',
                    track: testTrack,
                    playedAt: DateTime.now().subtract(const Duration(minutes: 5)),
                  ),
                ])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Listening History'), findsOneWidget);
      expect(find.text('Unholy'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('StatsScreen renders key metrics, charts, and top artists',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statsProvider.overrideWith((ref) => _MockStatsNotifier(testStats)),
            historyProvider.overrideWith((ref) => _MockHistoryNotifier([
                  HistoryItem(id: 'h_1', track: testTrack),
                ])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Listening Insights'), findsOneWidget);
      expect(find.text('Listening Time'), findsOneWidget);
      expect(find.text('3h 15m'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('4 Days'), findsOneWidget);
      expect(find.text('Top Artists'), findsOneWidget);
      expect(find.text('Top Genres'), findsOneWidget);
      expect(find.text('Most Played Songs'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
