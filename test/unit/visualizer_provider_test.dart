import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/visualizer/domain/models/visualizer_mode.dart';
import 'package:orbitune/features/visualizer/presentation/providers/visualizer_provider.dart';

void main() {
  group('VisualizerMode & VisualizerNotifier Unit Tests', () {
    test('VisualizerMode enum labels and cycle progression', () {
      expect(VisualizerMode.bars.label, equals('Spectrum Bars'));
      expect(VisualizerMode.wave.label, equals('Sine Wave'));
      expect(VisualizerMode.circular.label, equals('Circular Radial'));
      expect(VisualizerMode.off.label, equals('Off'));

      expect(VisualizerMode.bars.next, equals(VisualizerMode.wave));
      expect(VisualizerMode.wave.next, equals(VisualizerMode.circular));
      expect(VisualizerMode.circular.next, equals(VisualizerMode.off));
      expect(VisualizerMode.off.next, equals(VisualizerMode.bars));
    });

    test('VisualizerNotifier updates state, modes, fps, and sensitivity', () {
      final container = ProviderContainer();
      final notifier = container.read(visualizerProvider.notifier);

      expect(container.read(visualizerProvider).mode, equals(VisualizerMode.bars));
      expect(container.read(visualizerProvider).isEnabled, isTrue);

      notifier.cycleMode();
      expect(container.read(visualizerProvider).mode, equals(VisualizerMode.wave));

      notifier.setMode(VisualizerMode.circular);
      expect(container.read(visualizerProvider).mode, equals(VisualizerMode.circular));

      notifier.setColorTheme(VisualizerColorTheme.cyberPink);
      expect(container.read(visualizerProvider).colorTheme, equals(VisualizerColorTheme.cyberPink));

      notifier.setTargetFps(30);
      expect(container.read(visualizerProvider).targetFps, equals(30));

      notifier.setSensitivity(1.5);
      expect(container.read(visualizerProvider).sensitivity, equals(1.5));

      notifier.toggleArtworkReactivity();
      expect(container.read(visualizerProvider).isArtworkReactive, isFalse);

      notifier.setMode(VisualizerMode.off);
      expect(container.read(visualizerProvider).isEnabled, isFalse);

      notifier.toggleEnabled();
      expect(container.read(visualizerProvider).isEnabled, isTrue);
      expect(container.read(visualizerProvider).mode, equals(VisualizerMode.bars));
    });
  });
}
