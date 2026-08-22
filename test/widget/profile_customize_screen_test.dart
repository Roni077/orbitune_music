import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';
import 'package:orbitune/features/settings/presentation/screens/profile_customize_screen.dart';

class MockSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings(
    username: 'Test User',
    bio: 'Music is life',
    avatarIcon: 'headphones',
    profileBadge: 'Hi-Fi',
    favoriteGenre: 'Electronic / EDM',
  );

  @override
  AppSettings getSettings() => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> updateThemeMode(String themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
  }

  @override
  Future<void> updateStreamingQuality(AudioQuality quality) async {
    _settings = _settings.copyWith(streamingQuality: quality);
  }

  @override
  Future<void> updateDownloadQuality(AudioQuality quality) async {
    _settings = _settings.copyWith(downloadQuality: quality);
  }

  @override
  Future<void> updateCrossfadeDuration(int seconds) async {
    _settings = _settings.copyWith(crossfadeDurationSeconds: seconds);
  }

  @override
  Future<void> updateEqualizerPreset(String preset) async {
    _settings = _settings.copyWith(equalizerPreset: preset);
  }

  @override
  Future<void> updateEqualizerEnabled(bool enabled) async {
    _settings = _settings.copyWith(equalizerEnabled: enabled);
  }

  @override
  Future<void> updateOnboardingData({
    required bool hasCompletedOnboarding,
    required String username,
    required String country,
  }) async {
    _settings = _settings.copyWith(
      hasCompletedOnboarding: hasCompletedOnboarding,
      username: username,
      country: country,
    );
  }

  @override
  Stream<AppSettings> watchSettings() {
    return Stream.value(_settings);
  }
}

void main() {
  testWidgets('ProfileCustomizeScreen renders header, inputs, and chips properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = MockSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ProfileCustomizeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and main sections
    expect(find.text('Profile & Persona'), findsOneWidget);
    expect(find.text('AVATAR ICON PRESET'), findsOneWidget);
    expect(find.text('AVATAR GLOW & COLOR THEME'), findsOneWidget);
    expect(find.text('PROFILE IDENTITY'), findsOneWidget);
    expect(find.text('MUSIC PERSONA BADGE'), findsOneWidget);
    expect(find.text('PRIMARY VIBE / FAVORITE GENRE'), findsOneWidget);
    expect(find.text('REGION & DISCOVERY PREFERENCES'), findsOneWidget);

    // Verify initial values in fields
    expect(find.text('Test User'), findsNWidgets(2)); // Preview header + TextField
    expect(find.text('Save Profile'), findsOneWidget);
  });
}
