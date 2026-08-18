import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/screens/full_player_screen.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/player_controls.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/waveform_seek_bar.dart';

void main() {
  final sampleTrack = Track(
    id: 'test_123',
    title: 'Midnight City',
    artist: 'M83',
    album: 'Hurry Up, We\'re Dreaming',
    duration: const Duration(minutes: 4, seconds: 3),
    artworkUrl: 'https://example.com/artwork.jpg',
    bitrate: 320,
    source: 'jiosaavn',
  );

  Widget createWidgetUnderTest({Track? track, bool isPlaying = true}) {
    return ProviderScope(
      overrides: [
        playerProvider.overrideWith(
          (ref) => _MockPlayerNotifier(
            PlayerStateSnapshot(
              status: isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
              currentTrack: track ?? sampleTrack,
              position: const Duration(minutes: 1, seconds: 20),
              duration: const Duration(minutes: 4, seconds: 3),
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        home: FullPlayerScreen(),
      ),
    );
  }

  group('FullPlayerScreen Widget Tests', () {
    testWidgets('FullPlayerScreen renders track info, controls, waveform and action bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('M83'), findsWidgets);
      expect(find.byType(WaveformSeekBar), findsOneWidget);
      expect(find.byType(PlayerControls), findsOneWidget);
      expect(find.byIcon(LucideIcons.heart), findsWidgets);
      expect(find.byIcon(LucideIcons.mic2), findsOneWidget);
      expect(find.byIcon(LucideIcons.activity), findsOneWidget);
    });

    testWidgets('FullPlayerScreen switches to visualizer view and lyrics view on action bar tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Tap visualizer action button
      await tester.tap(find.byIcon(LucideIcons.activity));
      await tester.pump();

      expect(find.textContaining('Mode:'), findsOneWidget);

      // Tap lyrics action button
      await tester.tap(find.byIcon(LucideIcons.mic2));
      await tester.pump();

      expect(find.byIcon(LucideIcons.mic2), findsOneWidget);
    });
  });
}

class _MockPlayerNotifier extends StateNotifier<PlayerStateSnapshot>
    implements PlayerNotifier {
  _MockPlayerNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
