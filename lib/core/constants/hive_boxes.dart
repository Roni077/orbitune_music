/// Centralized Hive box names and storage keys
class HiveBoxes {
  HiveBoxes._();

  static const String settings = 'settings_box';
  static const String favorites = 'favorites_box';
  static const String playlists = 'playlists_box';
  static const String history = 'history_box';
  static const String stats = 'stats_box';
  static const String downloads = 'downloads_box';
  static const String lyricsCache = 'lyrics_cache_box';
  static const String searchHistory = 'search_cache_box';
  static const String session = 'session_box';

  // Common Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyStreamingQuality = 'streaming_quality';
  static const String keyDownloadQuality = 'download_quality';
  static const String keyCrossfadeDuration = 'crossfade_duration';
  static const String keyEqualizerEnabled = 'equalizer_enabled';
  static const String keyEqualizerPreset = 'equalizer_preset';
}
