import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';

/// Riverpod provider for SearchCacheRepository
final searchCacheRepositoryProvider = Provider<SearchCacheRepository>((ref) {
  return SearchCacheRepository(HiveService.instance);
});

/// Data repository for caching search history in Hive
class SearchCacheRepository {
  final HiveService _hiveService;

  SearchCacheRepository(this._hiveService);

  Box get _box => _hiveService.searchCacheBox;
  static const String _historyKey = 'recent_search_queries';
  static const int _maxHistoryItems = 20;

  List<String> getRecentSearches() {
    final raw = _box.get(_historyKey);
    if (raw != null && raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = getRecentSearches().where((q) => q.toLowerCase() != trimmed.toLowerCase()).toList();
    current.insert(0, trimmed);

    if (current.length > _maxHistoryItems) {
      current.removeRange(_maxHistoryItems, current.length);
    }

    await _box.put(_historyKey, current);
  }

  Future<void> removeSearchQuery(String query) async {
    final current = getRecentSearches().where((q) => q != query).toList();
    await _box.put(_historyKey, current);
  }

  Future<void> clearSearchHistory() async {
    await _box.delete(_historyKey);
  }

  Future<void> clearCache() async {
    await _box.clear();
  }

  Stream<List<String>> watchRecentSearches() {
    return _box.watch(key: _historyKey).map((_) => getRecentSearches());
  }
}
