import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/discovery/data/discovery_repository.dart';
import 'package:orbitune/features/discovery/domain/models/chart_playlist.dart';
import 'package:orbitune/features/discovery/domain/models/home_section.dart';
import 'package:orbitune/features/discovery/domain/models/trending_item.dart';
import 'package:orbitune/features/library/presentation/providers/favorites_provider.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';

/// State representation for Home Discovery dashboard
class HomeState {
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final List<TrendingItem> banners;
  final List<HomeSection> sections;
  final List<ChartPlaylist> charts;
  final List<ArtistModel> popularArtists;
  final List<PlaylistModel> dailyMixes;
  final String selectedFilter;
  final List<Track> quickPicks;
  final List<Track> continueListening;

  const HomeState({
    this.isLoading = true,
    this.isRefreshing = false,
    this.errorMessage,
    this.banners = const [],
    this.sections = const [],
    this.charts = const [],
    this.popularArtists = const [],
    this.dailyMixes = const [],
    this.selectedFilter = 'All',
    this.quickPicks = const [],
    this.continueListening = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    List<TrendingItem>? banners,
    List<HomeSection>? sections,
    List<ChartPlaylist>? charts,
    List<ArtistModel>? popularArtists,
    List<PlaylistModel>? dailyMixes,
    String? selectedFilter,
    List<Track>? quickPicks,
    List<Track>? continueListening,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      banners: banners ?? this.banners,
      sections: sections ?? this.sections,
      charts: charts ?? this.charts,
      popularArtists: popularArtists ?? this.popularArtists,
      dailyMixes: dailyMixes ?? this.dailyMixes,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      quickPicks: quickPicks ?? this.quickPicks,
      continueListening: continueListening ?? this.continueListening,
    );
  }
}

/// StateNotifier managing home discovery feed data and interactions
class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;
  final DiscoveryRepository _repository;
  final String _country;

  HomeNotifier(this._ref, this._repository, this._country) : super(const HomeState()) {
    loadHomeFeed();
  }

  /// Initial load and data fetch
  Future<void> loadHomeFeed() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final feed = await _repository.getHomeFeed(
        filter: state.selectedFilter,
        country: _country,
      );

      final quickPicks = _computeQuickPicks(feed.banners);
      final continueListening = _computeContinueListening();

      state = state.copyWith(
        isLoading: false,
        banners: feed.banners,
        sections: feed.sections,
        charts: feed.charts,
        popularArtists: feed.popularArtists,
        dailyMixes: feed.dailyMixes,
        quickPicks: quickPicks,
        continueListening: continueListening,
      );
    } catch (e) {
      debugPrint('[HomeNotifier] loadHomeFeed error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load discovery feed. Tap to retry.',
      );
    }
  }

  /// Pull-to-refresh feed with fresh live queries
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: null);

    try {
      final feed = await _repository.getHomeFeed(
        filter: state.selectedFilter,
        country: _country,
        forceRefresh: true,
      );

      final quickPicks = _computeQuickPicks(feed.banners);
      final continueListening = _computeContinueListening();

      state = state.copyWith(
        isRefreshing: false,
        banners: feed.banners,
        sections: feed.sections,
        charts: feed.charts,
        popularArtists: feed.popularArtists,
        dailyMixes: feed.dailyMixes,
        quickPicks: quickPicks,
        continueListening: continueListening,
      );
    } catch (e) {
      debugPrint('[HomeNotifier] refresh error: $e');
      state = state.copyWith(isRefreshing: false);
    }
  }

  /// Sets selected genre / language filter chip and refreshes relevant sections
  Future<void> setFilter(String filter) async {
    if (state.selectedFilter == filter) return;

    state = state.copyWith(selectedFilter: filter, isLoading: true);

    try {
      final feed = await _repository.getHomeFeed(
        language: filter == 'All' ? 'hindi,english' : filter.toLowerCase(),
        filter: filter,
        country: _country,
      );

      state = state.copyWith(
        isLoading: false,
        banners: feed.banners,
        sections: feed.sections,
        charts: feed.charts,
        popularArtists: feed.popularArtists,
        dailyMixes: feed.dailyMixes,
      );
    } catch (e) {
      debugPrint('[HomeNotifier] setFilter error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  List<Track> _computeQuickPicks(List<TrendingItem> banners) {
    // 1. First check recent history
    final history = _ref.read(historyProvider);
    if (history.isNotEmpty) {
      return history.take(6).map((h) => h.track).toList();
    }

    // 2. Second check user favorites
    final favorites = _ref.read(favoritesProvider);
    if (favorites.isNotEmpty) {
      return favorites.take(6).map((f) => f.track).toList();
    }

    // 3. Fallback to banner/trending tracks
    final List<Track> tracks = [];
    for (final b in banners) {
      if (b.track != null) tracks.add(b.track!);
      if (tracks.length >= 6) break;
    }
    return tracks;
  }

  List<Track> _computeContinueListening() {
    final history = _ref.read(historyProvider);
    return history.take(10).map((h) => h.track).toList();
  }
}

/// Global provider for Home discovery state
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(discoveryRepositoryProvider);
  final country = ref.watch(settingsProvider.select((s) => s.country ?? 'Global'));
  return HomeNotifier(ref, repository, country);
});

/// Convenience selectors
final homeBannersProvider = Provider<List<TrendingItem>>((ref) {
  return ref.watch(homeProvider.select((s) => s.banners));
});

final homeSectionsProvider = Provider<List<HomeSection>>((ref) {
  return ref.watch(homeProvider.select((s) => s.sections));
});

final homeChartsProvider = Provider<List<ChartPlaylist>>((ref) {
  return ref.watch(homeProvider.select((s) => s.charts));
});

final homeFilterProvider = Provider<String>((ref) {
  return ref.watch(homeProvider.select((s) => s.selectedFilter));
});
