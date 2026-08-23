import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/onboarding/presentation/onboarding_screen.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';

class MockSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

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
  testWidgets('OnboardingScreen renders and navigates to clean country selection',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Welcome Page
    expect(find.text('Welcome to Orbitune'), findsOneWidget);

    // Tap Next through pages
    // 1 -> Permissions
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Optimize Your Experience'), findsOneWidget);

    // 2 -> Username
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('What should we call you?'), findsOneWidget);

    // 3 -> Country Selection
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Music Region'), findsOneWidget);
    expect(find.text('Change Country / Region'), findsOneWidget);

    // Open Bottom Sheet
    await tester.tap(find.text('Change Country / Region'));
    await tester.pumpAndSettle();

    // Verify countries are listed in bottom sheet
    expect(find.text('Music Country & Region'), findsOneWidget);
    expect(find.text('Search country or region...'), findsOneWidget);
    expect(find.text('Global Worldwide'), findsWidgets);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);

    // Test Search Filter inside Bottom Sheet
    await tester.enterText(find.byType(TextField).last, 'Japan');
    await tester.pumpAndSettle();

    final japanCard = find.widgetWithText(ExpressiveCard, 'Japan');
    expect(japanCard, findsOneWidget);
    expect(find.text('United States'), findsNothing);

    // Select Japan from bottom sheet
    await tester.tap(japanCard);
    await tester.pumpAndSettle();

    // 4 -> Ready Page
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text("You're all set!"), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Finish onboarding
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(mockRepo.getSettings().hasCompletedOnboarding, isTrue);
    expect(mockRepo.getSettings().country, 'JP');
  });
}
