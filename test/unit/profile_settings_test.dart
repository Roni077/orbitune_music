import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/settings/data/settings_repository.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

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
  group('AppSettings Profile Model Tests', () {
    test('Default profile settings are properly initialized', () {
      const settings = AppSettings();
      expect(settings.avatarIcon, 'user');
      expect(settings.avatarColorIndex, 0);
      expect(settings.bio, 'Listening on Orbitune');
      expect(settings.profileBadge, 'Hi-Fi');
      expect(settings.favoriteGenre, 'All-Rounder');
      expect(settings.username, isNull);
    });

    test('copyWith updates profile properties correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        username: 'Roni',
        bio: 'Audiophile & Coder',
        avatarIcon: 'headphones',
        avatarColorIndex: 3,
        profileBadge: 'Cosmic Voyager',
        favoriteGenre: 'Electronic / EDM',
      );

      expect(updated.username, 'Roni');
      expect(updated.bio, 'Audiophile & Coder');
      expect(updated.avatarIcon, 'headphones');
      expect(updated.avatarColorIndex, 3);
      expect(updated.profileBadge, 'Cosmic Voyager');
      expect(updated.favoriteGenre, 'Electronic / EDM');
    });

    test('Serialization toMap and fromMap preserves profile fields', () {
      const settings = AppSettings(
        username: 'Astra',
        bio: 'Late night lo-fi explorer',
        avatarIcon: 'sparkles',
        avatarColorIndex: 2,
        profileBadge: 'Night Owl',
        favoriteGenre: 'Lo-Fi & Chill',
      );

      final map = settings.toMap();
      final fromMap = AppSettings.fromMap(map);

      expect(fromMap.username, 'Astra');
      expect(fromMap.bio, 'Late night lo-fi explorer');
      expect(fromMap.avatarIcon, 'sparkles');
      expect(fromMap.avatarColorIndex, 2);
      expect(fromMap.profileBadge, 'Night Owl');
      expect(fromMap.favoriteGenre, 'Lo-Fi & Chill');
    });
  });

  group('SettingsNotifier Profile Methods Tests', () {
    late MockSettingsRepository mockRepo;
    late SettingsNotifier notifier;

    setUp(() {
      mockRepo = MockSettingsRepository();
      notifier = SettingsNotifier(mockRepo);
    });

    test('setUsername updates state and persists', () async {
      await notifier.setUsername('Orbitune Master');
      expect(notifier.state.username, 'Orbitune Master');
      expect(mockRepo.getSettings().username, 'Orbitune Master');
    });

    test('setBio updates state and persists', () async {
      await notifier.setBio('Vibing to 320k Lossless Audio');
      expect(notifier.state.bio, 'Vibing to 320k Lossless Audio');
    });

    test('setAvatarIcon updates state and persists', () async {
      await notifier.setAvatarIcon('disc');
      expect(notifier.state.avatarIcon, 'disc');
    });

    test('setAvatarColorIndex updates state and persists', () async {
      await notifier.setAvatarColorIndex(4);
      expect(notifier.state.avatarColorIndex, 4);
    });

    test('setProfileBadge updates state and persists', () async {
      await notifier.setProfileBadge('Vinyl Purist');
      expect(notifier.state.profileBadge, 'Vinyl Purist');
    });

    test('setFavoriteGenre updates state and persists', () async {
      await notifier.setFavoriteGenre('Bengali & Regional');
      expect(notifier.state.favoriteGenre, 'Bengali & Regional');
    });

    test('updateProfile updates all fields atomically', () async {
      await notifier.updateProfile(
        username: 'Luna',
        bio: 'Cosmic ambient dreams',
        avatarIcon: 'rocket',
        avatarColorIndex: 1,
        profileBadge: 'Cosmic Voyager',
        favoriteGenre: 'Electronic / EDM',
        country: 'JP',
      );

      expect(notifier.state.username, 'Luna');
      expect(notifier.state.bio, 'Cosmic ambient dreams');
      expect(notifier.state.avatarIcon, 'rocket');
      expect(notifier.state.avatarColorIndex, 1);
      expect(notifier.state.profileBadge, 'Cosmic Voyager');
      expect(notifier.state.favoriteGenre, 'Electronic / EDM');
      expect(notifier.state.country, 'JP');
      expect(notifier.state.contentCountry, 'JP');
    });
  });
}
