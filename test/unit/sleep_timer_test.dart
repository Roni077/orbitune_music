import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/presentation/providers/sleep_timer_provider.dart';
import '../helpers/mock_audio_platform.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_sleep_timer_test_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  group('SleepTimerState & SleepTimerNotifier Unit Tests', () {
    test('SleepTimerState formatting displays correct remaining time', () {
      const state1 = SleepTimerState(
        isActive: true,
        remainingTime: Duration(minutes: 15, seconds: 30),
      );
      expect(state1.formattedCountdown, equals('15:30'));

      const state2 = SleepTimerState(
        isActive: true,
        stopAfterCurrentTrack: true,
      );
      expect(state2.formattedCountdown, equals('End of song'));

      const state3 = SleepTimerState();
      expect(state3.formattedCountdown, equals(''));
    });

    test('SleepTimerNotifier sets and cancels timer correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(sleepTimerProvider.notifier);

      expect(container.read(sleepTimerProvider).isActive, isFalse);

      notifier.setTimer(const Duration(minutes: 30), label: '30 mins');
      final activeState = container.read(sleepTimerProvider);
      expect(activeState.isActive, isTrue);
      expect(activeState.remainingTime?.inMinutes, equals(30));
      expect(activeState.activeLabel, equals('30 mins'));
      expect(activeState.stopAfterCurrentTrack, isFalse);

      notifier.cancelTimer();
      final cancelledState = container.read(sleepTimerProvider);
      expect(cancelledState.isActive, isFalse);
      expect(cancelledState.remainingTime, isNull);
    });

    test('SleepTimerNotifier sets stopAfterCurrentTrack', () {
      final container = ProviderContainer();
      final notifier = container.read(sleepTimerProvider.notifier);

      notifier.setStopAfterCurrentTrack();
      final state = container.read(sleepTimerProvider);
      expect(state.isActive, isFalse); // No current track playing in container

      notifier.cancelTimer();
      expect(container.read(sleepTimerProvider).isActive, isFalse);
    });
  });
}
