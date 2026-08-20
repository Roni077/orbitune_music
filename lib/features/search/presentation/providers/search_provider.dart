import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/domain/models/search_result.dart';

/// Available search streaming sources
enum SearchSourceFilter {
  all('all', 'All Sources'),
  youTube('youtube', 'YouTube Music'),
  extractor('extractor', 'Media Extractor');

  final String key;
  final String label;
  const SearchSourceFilter(this.key, this.label);
}

/// Available media type category filters
enum SearchCategoryFilter {
  all('all', 'Top Results'),
  songs('songs', 'Songs'),
  artists('artists', 'Artists'),
  albums('albums', 'Albums'),
  playlists('playlists', 'Playlists');

  final String key;
  final String label;
  const SearchCategoryFilter(this.key, this.label);
}

/// State model for Universal Search
class SearchState {
  final String query;
  final SearchSourceFilter sourceFilter;
  final SearchCategoryFilter categoryFilter;
  final bool isLoading;
  final bool isDebouncing;
  final SearchResult? result;
  final List<String> recentSearches;
  final List<String> suggestions;
  final String? errorMessage;
  final bool hasSearched;

  const SearchState({
    this.query = '',
    this.sourceFilter = SearchSourceFilter.all,
    this.categoryFilter = SearchCategoryFilter.all,
    this.isLoading = false,
    this.isDebouncing = false,
    this.result,
    this.recentSearches = const [],
    this.suggestions = const [],
    this.errorMessage,
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? query,
    SearchSourceFilter? sourceFilter,
    SearchCategoryFilter? categoryFilter,
    bool? isLoading,
    bool? isDebouncing,
    SearchResult? result,
    bool clearResult = false,
    List<String>? recentSearches,
    List<String>? suggestions,
    String? errorMessage,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      isLoading: isLoading ?? this.isLoading,
      isDebouncing: isDebouncing ?? this.isDebouncing,
      result: clearResult ? null : (result ?? this.result),
      recentSearches: recentSearches ?? this.recentSearches,
      suggestions: suggestions ?? this.suggestions,
      errorMessage: errorMessage,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

/// Riverpod StateNotifier for Search
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _searchRepository;
  final SearchCacheRepository _cacheRepository;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 400);

  SearchNotifier(this._searchRepository, this._cacheRepository)
      : super(const SearchState()) {
    loadRecentSearches();
  }

  /// Loads search history from Hive cache
  void loadRecentSearches() {
    final recents = _cacheRepository.getRecentSearches();
    state = state.copyWith(recentSearches: recents);
  }

  /// Handles real-time text input with 400ms debounce
  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      loadRecentSearches();
      state = state.copyWith(
        query: '',
        isLoading: false,
        isDebouncing: false,
        clearResult: true,
        suggestions: const [],
        errorMessage: null,
        hasSearched: false,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isDebouncing: true,
      errorMessage: null,
    );

    _debounceTimer = Timer(_debounceDuration, () {
      _executeSearch(query, state.sourceFilter);
    });
  }

  /// Executes immediate search without debounce (e.g. on keyboard submit or history click)
  Future<void> searchImmediate(String query) async {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(
      query: trimmed,
      isDebouncing: false,
    );

    await _executeSearch(trimmed, state.sourceFilter);
  }

  /// Switches source filter (All / YouTube Music / Extractor)
  void setSourceFilter(SearchSourceFilter filter) {
    if (state.sourceFilter == filter) return;

    state = state.copyWith(sourceFilter: filter);
    if (state.query.trim().isNotEmpty) {
      _debounceTimer?.cancel();
      _executeSearch(state.query, filter);
    }
  }

  /// Switches media type category filter (All, Songs, Artists, Albums, Playlists)
  void setCategoryFilter(SearchCategoryFilter filter) {
    if (state.categoryFilter == filter) return;
    state = state.copyWith(categoryFilter: filter);
  }

  /// Clears query input and restores history view
  void clearQuery() {
    _debounceTimer?.cancel();
    loadRecentSearches();
    state = state.copyWith(
      query: '',
      isLoading: false,
      isDebouncing: false,
      clearResult: true,
      suggestions: const [],
      errorMessage: null,
      hasSearched: false,
    );
  }

  /// Removes single item from search history
  Future<void> removeRecentSearch(String query) async {
    await _cacheRepository.removeSearchQuery(query);
    loadRecentSearches();
  }

  /// Clears entire search history
  Future<void> clearSearchHistory() async {
    await _cacheRepository.clearSearchHistory();
    state = state.copyWith(recentSearches: const []);
  }

  /// Retries current search
  void retry() {
    if (state.query.trim().isNotEmpty) {
      _executeSearch(state.query, state.sourceFilter);
    }
  }

  Future<void> _executeSearch(String query, SearchSourceFilter source) async {
    state = state.copyWith(
      isLoading: true,
      isDebouncing: false,
      errorMessage: null,
    );

    try {
      final searchRes = await _searchRepository.search(
        query,
        source: source.key,
      );

      if (state.query != query) return;

      // Refresh recent searches since new search was saved
      final recents = _cacheRepository.getRecentSearches();

      state = state.copyWith(
        isLoading: false,
        result: searchRes,
        recentSearches: recents,
        hasSearched: true,
        errorMessage: null,
      );
    } catch (e, st) {
      if (state.query != query) return;
      debugPrint('[SearchNotifier] search error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        hasSearched: true,
        errorMessage: 'Failed to find music for "$query". Please check your connection.',
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Main Riverpod provider for Search
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchRepo = ref.watch(searchRepositoryProvider);
  final cacheRepo = ref.watch(searchCacheRepositoryProvider);
  return SearchNotifier(searchRepo, cacheRepo);
});
