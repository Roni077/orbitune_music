import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/services/audio_session_service.dart';

void main() {
  group('AudioSessionService Tests', () {
    test('AudioSessionService initial state and configuration flags', () {
      final service = AudioSessionService();
      expect(service.isConfigured, false);
    });

    test('AudioSessionService registers callbacks correctly', () async {
      final service = AudioSessionService();
      bool pauseTriggered = false;
      bool resumeTriggered = false;
      double? duckedVolume;

      await service.init(
        onPause: () => pauseTriggered = true,
        onResume: () => resumeTriggered = true,
        onDuckVolume: (v) => duckedVolume = v,
      );

      expect(service.isConfigured, true);
      expect(service.onPauseRequested, isNotNull);
      expect(service.onResumeRequested, isNotNull);
      expect(service.onVolumeDuckRequested, isNotNull);

      // Verify callback triggers
      service.onPauseRequested?.call();
      expect(pauseTriggered, true);

      service.onResumeRequested?.call();
      expect(resumeTriggered, true);

      service.onVolumeDuckRequested?.call(0.2);
      expect(duckedVolume, 0.2);

      await service.dispose();
      expect(service.isConfigured, false);
    });
  });
}
