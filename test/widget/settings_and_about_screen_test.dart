import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/theme/app_theme.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/library/domain/models/favorite_song.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/settings/domain/models/app_settings.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/screens/about_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/backup_restore_screen.dart';
import 'package:orbitune/features/settings/presentation/screens/settings_screen.dart';
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
  void refresh() {}
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

void main() {
  setUpAll(() {
    registerMockJustAudioPlatform();
  });

  group('SettingsScreen, AboutScreen & BackupRestoreScreen Widget Tests', () {
    testWidgets('SettingsScreen renders audio, theme, network, and data sections',
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
      expect(find.text('Streaming Quality'), findsOneWidget);
      expect(find.text('Download Quality'), findsOneWidget);
      expect(find.text('10-Band DSP Equalizer'), findsOneWidget);
      expect(find.text('Crossfade Tracks'), findsOneWidget);
      expect(find.text('Gapless Playback'), findsOneWidget);
      expect(find.text('Theme Style'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('About Orbitune'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('AboutScreen renders brand info, version, and feature list',
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
      expect(find.text('Open Source Licenses'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('BackupRestoreScreen renders Export and Restore sections',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith((ref) => _MockFavNotifier([])),
            userPlaylistsProvider.overrideWith((ref) => _MockPlayNotifier([])),
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
      expect(find.text('Export Data Backup'), findsOneWidget);
      expect(find.text('Restore from Backup'), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);
      expect(find.text('Restore Data'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
