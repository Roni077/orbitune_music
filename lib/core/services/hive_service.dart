import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/constants/hive_boxes.dart';
import 'package:orbitune/core/errors/exceptions.dart';

/// Centralized service for Hive database initialization and box access
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late Box _settingsBox;
  late Box _favoritesBox;
  late Box _playlistsBox;
  late Box _historyBox;
  late Box _statsBox;
  late Box _downloadsBox;
  late Box _lyricsCacheBox;
  late Box _searchCacheBox;
  Box? _sessionBox;

  Box get settingsBox => _settingsBox;
  Box get favoritesBox => _favoritesBox;
  Box get playlistsBox => _playlistsBox;
  Box get historyBox => _historyBox;
  Box get statsBox => _statsBox;
  Box get downloadsBox => _downloadsBox;
  Box get lyricsCacheBox => _lyricsCacheBox;
  Box get searchCacheBox => _searchCacheBox;
  Box get sessionBox => _sessionBox ?? _settingsBox;

  /// Initializes Hive database and opens all application storage boxes.
  /// [customDirectoryPath] can be provided in tests or headless environments.
  Future<void> init([String? customDirectoryPath]) async {
    if (_isInitialized) return;

    try {
      if (customDirectoryPath != null) {
        Hive.init(customDirectoryPath);
      } else {
        await Hive.initFlutter();
      }

      final boxes = await Future.wait([
        Hive.openBox(HiveBoxes.settings),
        Hive.openBox(HiveBoxes.favorites),
        Hive.openBox(HiveBoxes.playlists),
        Hive.openBox(HiveBoxes.history),
        Hive.openBox(HiveBoxes.stats),
        Hive.openBox(HiveBoxes.downloads),
        Hive.openBox(HiveBoxes.lyricsCache),
        Hive.openBox(HiveBoxes.searchHistory),
        Hive.openBox(HiveBoxes.session),
      ]);

      _settingsBox = boxes[0];
      _favoritesBox = boxes[1];
      _playlistsBox = boxes[2];
      _historyBox = boxes[3];
      _statsBox = boxes[4];
      _downloadsBox = boxes[5];
      _lyricsCacheBox = boxes[6];
      _searchCacheBox = boxes[7];
      _sessionBox = boxes[8];

      _isInitialized = true;
    } catch (e, stack) {
      throw StorageException('Failed to initialize Hive database: $e', stack);
    }
  }

  /// Sets box instances directly (useful for testing)
  void setBoxesForTesting({
    required Box settingsBox,
    required Box favoritesBox,
    required Box playlistsBox,
    required Box historyBox,
    required Box statsBox,
    required Box downloadsBox,
    required Box lyricsCacheBox,
    required Box searchCacheBox,
    Box? sessionBox,
  }) {
    _settingsBox = settingsBox;
    _favoritesBox = favoritesBox;
    _playlistsBox = playlistsBox;
    _historyBox = historyBox;
    _statsBox = statsBox;
    _downloadsBox = downloadsBox;
    _lyricsCacheBox = lyricsCacheBox;
    _searchCacheBox = searchCacheBox;
    _sessionBox = sessionBox ?? settingsBox;
    _isInitialized = true;
  }

  /// Resets initialization state for testing
  void resetForTesting() {
    _isInitialized = false;
    _sessionBox = null;
  }

  /// Clears a specific box by name
  Future<void> clearBox(String boxName) async {
    try {
      switch (boxName) {
        case HiveBoxes.settings:
          await _settingsBox.clear();
          break;
        case HiveBoxes.favorites:
          await _favoritesBox.clear();
          break;
        case HiveBoxes.playlists:
          await _playlistsBox.clear();
          break;
        case HiveBoxes.history:
          await _historyBox.clear();
          break;
        case HiveBoxes.stats:
          await _statsBox.clear();
          break;
        case HiveBoxes.downloads:
          await _downloadsBox.clear();
          break;
        case HiveBoxes.lyricsCache:
          await _lyricsCacheBox.clear();
          break;
        case HiveBoxes.searchHistory:
          await _searchCacheBox.clear();
          break;
        case HiveBoxes.session:
          await (_sessionBox ?? _settingsBox).clear();
          break;
      }
    } catch (e) {
      throw StorageException('Failed to clear box $boxName: $e');
    }
  }

  /// Clears all temporary cache boxes (search history & lyrics cache)
  Future<void> clearCache() async {
    await clearBox(HiveBoxes.lyricsCache);
    await clearBox(HiveBoxes.searchHistory);
  }

  /// Clears all user data across all boxes
  Future<void> clearAllUserData() async {
    await _favoritesBox.clear();
    await _playlistsBox.clear();
    await _historyBox.clear();
    await _statsBox.clear();
    await _downloadsBox.clear();
    await _lyricsCacheBox.clear();
    await _searchCacheBox.clear();
    await (_sessionBox ?? _settingsBox).clear();
  }
}
