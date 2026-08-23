import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/screens/about_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/appearance_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/audio_playback_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/content_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/storage_settings_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/theme_settings_screen.dart';
import '../helpers/mock_audio_platform.dart';

class _MockSettingsNotifier extends StateNotifier<AppSettings>
    implements SettingsNotifier {
  _MockSettingsNotifier(super.state);

  @override
  Future<void> setThemeMode(String themeMode) async {
    state = state.copyWith(themeMode: themeMode);
  }

  @override
  Future<void> setStreamingQuality(AudioQuality quality) async {
    state = state.copyWith(streamingQuality: quality);
  }

  @override
  Future<void> setDownloadQuality(AudioQuality quality) async {
    state = state.copyWith(downloadQuality: quality);
  }

  @override
  Future<void> setAutoPlay(bool autoPlay) async {
    state = state.copyWith(autoPlay: autoPlay);
  }

  @override
  Future<void> setGaplessPlayback(bool gapless) async {
    state = state.copyWith(gaplessPlayback: gapless);
  }

  @override
  Future<void> setCrossfadeDuration(int seconds) async {
    state = state.copyWith(crossfadeDurationSeconds: seconds);
  }

  @override
  Future<void> setStopOnAppClose(bool stop) async {
    state = state.copyWith(stopOnAppClose: stop);
  }

  @override
  Future<void> setWifiOnlyStreaming(bool wifiOnly) async {
    state = state.copyWith(wifiOnlyStreaming: wifiOnly);
  }

  @override
  Future<void> setWifiOnlyDownloads(bool wifiOnly) async {
    state = state.copyWith(wifiOnlyDownloads: wifiOnly);
  }

  @override
  Future<void> setCacheSizeLimit(int limitMb) async {
    state = state.copyWith(cacheSizeLimitMb: limitMb);
  }

  @override
  Future<void> setSearchHistoryEnabled(bool enabled) async {
    state = state.copyWith(searchHistoryEnabled: enabled);
  }

  @override
  Future<void> setListeningHistoryEnabled(bool enabled) async {
    state = state.copyWith(listeningHistoryEnabled: enabled);
  }

  @override
  Future<void> setDynamicColorEnabled(bool enabled) async {
    state = state.copyWith(dynamicColorEnabled: enabled);
  }

  @override
  Future<void> setAmoledModeEnabled(bool enabled) async {
    state = state.copyWith(amoledModeEnabled: enabled);
  }

  @override
  Future<void> setEqualizerEnabled(bool enabled) async {
    state = state.copyWith(equalizerEnabled: enabled);
  }

  @override
  Future<void> setEqualizerPreset(String preset) async {
    state = state.copyWith(equalizerPreset: preset);
  }

  @override
  Future<void> setAccentColorIndex(int index) async {
    state = state.copyWith(accentColorIndex: index);
  }

  @override
  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
  }

  @override
  Future<void> setCornerRadius(double radius) async {
    state = state.copyWith(cornerRadius: radius);
  }

  @override
  Future<void> setGlassmorphism(bool enabled) async {
    state = state.copyWith(enableGlassmorphism: enabled);
  }

  @override
  Future<void> setVisualizerEnabled(bool enabled) async {
    state = state.copyWith(enableVisualizer: enabled);
  }

  @override
  Future<void> setShowBitrateBadge(bool show) async {
    state = state.copyWith(showBitrateBadge: show);
  }

  @override
  Future<void> setAudioNormalization(bool enabled) async {
    state = state.copyWith(audioNormalization: enabled);
  }

  @override
  Future<void> setPauseOnUnplug(bool enabled) async {
    state = state.copyWith(pauseOnUnplug: enabled);
  }

  @override
  Future<void> setResumeOnBluetooth(bool enabled) async {
    state = state.copyWith(resumeOnBluetooth: enabled);
  }

  @override
  Future<void> setSkipSilence(bool enabled) async {
    state = state.copyWith(skipSilence: enabled);
  }

  @override
  Future<void> setContentCountry(String country) async {
    state = state.copyWith(contentCountry: country);
  }

  @override
  Future<void> setLyricsSource(String source) async {
    state = state.copyWith(lyricsSource: source);
  }

  @override
  Future<void> setExplicitFilter(bool enabled) async {
    state = state.copyWith(explicitFilter: enabled);
  }

  @override
  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
  }

  @override
  Future<void> setIncognitoMode(bool enabled) async {
    state = state.copyWith(incognitoMode: enabled);
  }

  @override
  Future<void> resetAllSettings() async {
    state = const AppSettings();
  }

  @override
  void refresh() {}

  @override
  Future<void> setOnboardingData({
    required bool hasCompletedOnboarding,
    required String username,
    required String country,
  }) async {
    state = state.copyWith(
      hasCompletedOnboarding: hasCompletedOnboarding,
      username: username,
      country: country,
    );
  }

  @override
  Future<void> setUsername(String username) async {
    state = state.copyWith(username: username);
  }

  @override
  Future<void> setBio(String bio) async {
    state = state.copyWith(bio: bio);
  }

  @override
  Future<void> setAvatarIcon(String icon) async {
    state = state.copyWith(avatarIcon: icon);
  }

  @override
  Future<void> setAvatarColorIndex(int index) async {
    state = state.copyWith(avatarColorIndex: index);
  }

  @override
  Future<void> setCustomAvatarPath(String? path) async {
    state = state.copyWith(
      customAvatarPath: path,
      clearCustomAvatar: path == null,
    );
  }

  @override
  Future<void> setProfileBadge(String badge) async {
    state = state.copyWith(profileBadge: badge);
  }

  @override
  Future<void> setFavoriteGenre(String genre) async {
    state = state.copyWith(favoriteGenre: genre);
  }

  @override
  Future<void> updateProfile({
    String? username,
    String? bio,
    String? avatarIcon,
    int? avatarColorIndex,
    String? customAvatarPath,
    bool clearCustomAvatar = false,
    String? profileBadge,
    String? favoriteGenre,
    String? country,
  }) async {
    state = state.copyWith(
      username: username ?? state.username,
      bio: bio ?? state.bio,
      avatarIcon: avatarIcon ?? state.avatarIcon,
      avatarColorIndex: avatarColorIndex ?? state.avatarColorIndex,
      customAvatarPath: customAvatarPath,
      clearCustomAvatar: clearCustomAvatar,
      profileBadge: profileBadge ?? state.profileBadge,
      favoriteGenre: favoriteGenre ?? state.favoriteGenre,
      country: country ?? state.country,
      contentCountry: country ?? state.contentCountry,
    );
  }
}

class _MockFavNotifier extends StateNotifier<List<FavoriteSong>>
    implements FavoritesNotifier {
  _MockFavNotifier(super.state);

  @override
  bool isFavorite(String trackId) => false;
  @override
  Future<void> toggleFavorite(dynamic track) async {}
  @override
  Future<void> removeFavorite(String trackId) async {}
  @override
  void refresh() {}
}

class _MockPlayNotifier extends StateNotifier<List<UserPlaylist>>
    implements UserPlaylistsNotifier {
  _MockPlayNotifier(super.state);

  @override
  Future<UserPlaylist> createPlaylist(String name,
      {String? description, String? artworkUrl, List<dynamic> initialTracks = const []}) async {
    return UserPlaylist(id: '1', name: name);
  }
  @override
  Future<void> deletePlaylist(String id) async {}
  @override
  Future<void> renamePlaylist(String id, String newName) async {}
  @override
  Future<void> addTrackToPlaylist(String playlistId, dynamic track) async {}
  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {}
  @override
  Future<void> reorderTracks(String playlistId, int oldIndex, int newIndex) async {}
  @override
  Future<void> togglePin(String playlistId) async {}
  @override
  void refresh() {}
}

class _MockHistoryNotifier extends StateNotifier<List<HistoryItem>>
    implements HistoryNotifier {
  _MockHistoryNotifier(super.state);

  @override
  Future<void> recordPlay(dynamic track, {Duration durationPlayed = Duration.zero, bool completed = false}) async {}
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

  group('Settings Hub & Nested Sub-Screens Widget Tests', () {
    testWidgets('SettingsScreen renders hub sections, profile, and navigation tiles',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance & UI'), findsOneWidget);
      expect(find.text('Theme & Palette'), findsOneWidget);
      expect(find.text('Audio & Playback'), findsOneWidget);
      expect(find.text('Content & Region'), findsOneWidget);
      expect(find.text('Storage & Cache'), findsOneWidget);
      expect(find.text('Data & Privacy'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('About Orbitune'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('AppearanceSettingsScreen renders Live Preview and customization options',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AppearanceSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Appearance & UI'), findsOneWidget);
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Dynamic Artwork Colors'), findsOneWidget);
      expect(find.text('Animated Visualizer'), findsOneWidget);
      expect(find.text('Audio Quality Badges'), findsOneWidget);
      expect(find.text('Corner Roundness'), findsOneWidget);
      expect(find.text('Glassmorphic Blur Container'), findsOneWidget);
      expect(find.text('System Default Font'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('ThemeSettingsScreen renders theme cards and accent color swatches',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ThemeSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Theme & Palette'), findsOneWidget);
      expect(find.text('Deep Midnight'), findsOneWidget);
      expect(find.text('Pure OLED'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Solarized Amber'), findsOneWidget);
      expect(find.text('Cyberpunk Neon'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('AudioPlaybackSettingsScreen renders bitrates, crossfade, and equalizer',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AudioPlaybackSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Audio & Playback'), findsOneWidget);
      expect(find.text('Streaming Quality'), findsOneWidget);
      expect(find.text('Download Quality'), findsOneWidget);
      expect(find.text('10-Band DSP Equalizer'), findsOneWidget);
      expect(find.text('Crossfade Duration'), findsOneWidget);
      expect(find.text('Gapless Playback'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('StorageSettingsScreen renders storage visualizer and cache actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const StorageSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Storage & Cache'), findsOneWidget);
      expect(find.text('Orbitune Footprint'), findsOneWidget);
      expect(find.text('Stream on Wi-Fi Only'), findsOneWidget);
      expect(find.text('Manage Offline Downloads'), findsOneWidget);
      expect(find.text('Clear All Application Cache'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('PrivacySettingsScreen renders incognito mode and clear actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PrivacySettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Data & Privacy'), findsOneWidget);
      expect(find.text('Incognito Private Session'), findsOneWidget);
      expect(find.text('Keep Listening History'), findsOneWidget);
      expect(find.text('Clear Listening History'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('ContentSettingsScreen renders regional charts, language and lyrics source',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ContentSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Content & Region'), findsOneWidget);
      expect(find.text('Music Country / Region'), findsOneWidget);
      expect(find.text('App Interface Language'), findsOneWidget);
      expect(find.text('Synchronized Lyrics Source'), findsOneWidget);
      expect(find.text('Explicit Content Filter'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('AboutScreen renders brand info, version, and system diagnostics',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AboutScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('About Orbitune'), findsOneWidget);
      expect(find.text('Orbitune'), findsOneWidget);
      expect(find.text('Version 1.0.0 (Build 1)'), findsOneWidget);
      expect(find.text('Material 3 Expressive UI'), findsOneWidget);
      expect(find.text('System & Device Diagnostics'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('BackupRestoreScreen renders Export, Restore, and Reset sections',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => _MockFavNotifier([])),
            userPlaylistsProvider.overrideWith((ref) => _MockPlayNotifier([])),
            historyProvider.overrideWith((ref) => _MockHistoryNotifier([])),
            settingsProvider.overrideWith((ref) => _MockSettingsNotifier(const AppSettings())),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const BackupRestoreScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Create Backup (orbitune.orb)'), findsOneWidget);
      expect(find.text('Restore Backup File'), findsOneWidget);
      expect(find.text('Create Backup'), findsOneWidget);
      expect(find.text('Select .orb Backup File'), findsOneWidget);
      expect(find.text('Factory Reset Settings'), findsOneWidget);
      expect(find.text('Reset All Settings'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
