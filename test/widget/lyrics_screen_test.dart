import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';
import 'package:orbitune/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:orbitune/features/lyrics/presentation/screens/lyrics_screen.dart';
import 'package:orbitune/features/lyrics/presentation/widgets/lrc_view.dart';
import 'package:orbitune/features/lyrics/presentation/widgets/plain_lyrics_view.dart';

void main() {
  final sampleTrack = Track(
    id: 'test_123',
    title: 'Starboy',
    artist: 'The Weeknd',
    duration: const Duration(seconds: 230),
    artworkUrl: 'https://example.com/artwork.jpg',
  );

  final sampleLyrics = [
    LyricLine(timestamp: const Duration(seconds: 0), text: "I'm tryna put you in the worst mood"),
    LyricLine(timestamp: const Duration(seconds: 5), text: 'P1 cleaner than your church shoes'),
    LyricLine(timestamp: const Duration(seconds: 10), text: 'Milli point two just to hurt you'),
  ];

  Widget createWidgetUnderTest({
    LyricsState? lyricsState,
  }) {
    return ProviderScope(
      overrides: [
        playerProvider.overrideWith(
          (ref) => _MockPlayerNotifier(
            PlayerStateSnapshot(
              status: PlaybackStatus.playing,
              currentTrack: sampleTrack,
              position: const Duration(seconds: 5),
              duration: const Duration(seconds: 230),
            ),
          ),
        ),
        lyricsProvider.overrideWith(
          (ref) => _MockLyricsNotifier(
            lyricsState ??
                LyricsState(
                  lines: sampleLyrics,
                  isSynced: true,
                  activeLineIndex: 1,
                  fontSize: 20.0,
                ),
          ),
        ),
      ],
      child: const MaterialApp(
        home: LyricsScreen(),
      ),
    );
  }

  group('LyricsScreen Widget Tests', () {
    testWidgets('LyricsScreen renders header and LrcView with active line', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Starboy'), findsWidgets);
      expect(find.text('The Weeknd'), findsWidgets);
      expect(find.byType(LrcView), findsOneWidget);
      expect(find.text("I'm tryna put you in the worst mood"), findsOneWidget);
      expect(find.text('P1 cleaner than your church shoes'), findsOneWidget);
    });

    testWidgets('LyricsScreen renders PlainLyricsView when only plain lyrics available', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          lyricsState: const LyricsState(
            plainLyrics: 'Line 1 of plain lyrics\nLine 2 of plain lyrics',
            isSynced: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PlainLyricsView), findsOneWidget);
      expect(find.textContaining('Line 1 of plain lyrics'), findsOneWidget);
    });
  });
}

class _MockPlayerNotifier extends StateNotifier<PlayerStateSnapshot>
    implements PlayerNotifier {
  _MockPlayerNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLyricsNotifier extends StateNotifier<LyricsState>
    implements LyricsNotifier {
  _MockLyricsNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
