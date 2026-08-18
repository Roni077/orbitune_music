import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
import 'package:orbitune/features/search/data/jiosaavn_source.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/domain/models/search_result.dart';
import 'package:orbitune/features/search/presentation/providers/album_detail_provider.dart';
import 'package:orbitune/features/search/presentation/providers/artist_detail_provider.dart';
import 'package:orbitune/features/search/presentation/providers/search_provider.dart';
import '../helpers/mock_audio_platform.dart';

// Mock JioSaavn Source for unit testing
class MockJioSaavnSource extends JioSaavnSource {
  @override
  Future<SearchResult> searchAll(String query, {int page = 1, int limit = 25}) async {
    return SearchResult(
      query: query,
      source: 'jiosaavn',
      songs: [
        Track(
          id: 'test_song_1',
          title: 'Kesariya',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 268),
          streamUrl: 'https://example.com/audio.m4a',
          source: 'jiosaavn',
        ),
      ],
      albums: [
        AlbumModel(
          id: 'test_album_1',
          title: 'Brahmastra',
          artist: 'Pritam',
          releaseYear: '2022',
          totalTracks: 8,
          source: 'jiosaavn',
        ),
      ],
      artists: [
        ArtistModel(
          id: 'test_artist_1',
          name: 'Arijit Singh',
          fansCount: 45000000,
          source: 'jiosaavn',
        ),
      ],
      playlists: [
        PlaylistModel(
          id: 'test_playlist_1',
          title: 'Best of Arijit Singh',
          trackCount: 30,
          source: 'jiosaavn',
        ),
      ],
    );
  }

  @override
  Future<ArtistModel?> getArtistDetails(String artistId) async {
    return ArtistModel(
      id: artistId,
      name: 'Arijit Singh',
      fansCount: 45000000,
      bio: 'Legendary Indian playback singer.',
      topTracks: [
        Track(
          id: 'song_1',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 262),
          streamUrl: 'https://example.com/audio.m4a',
          source: 'jiosaavn',
        ),
        Track(
          id: 'song_2',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 289),
          streamUrl: 'https://example.com/audio.m4a',
          source: 'jiosaavn',
        ),
      ],
      albums: [
        AlbumModel(
          id: 'alb_1',
          title: 'Aashiqui 2',
          artist: 'Arijit Singh',
          releaseYear: '2013',
          source: 'jiosaavn',
        ),
      ],
      singles: [
        Track(
          id: 'single_1',
          title: 'O Maahi',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 233),
          streamUrl: 'https://example.com/audio.m4a',
          source: 'jiosaavn',
        ),
      ],
      source: 'jiosaavn',
    );
  }

  @override
  Future<AlbumModel?> getAlbumDetails(String albumId) async {
    return AlbumModel(
      id: albumId,
      title: 'Aashiqui 2',
      artist: 'Mithoon, Ankit Tiwari, Jeet Gannguli',
      artistId: 'test_artist_1',
      releaseYear: '2013',
      totalTracks: 2,
      songs: [
        Track(
          id: 'alb_song_1',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 262),
          streamUrl: 'https://example.com/audio.m4a',
          source: 'jiosaavn',
        ),
        Track(
          id: 'alb_song_2',
          title: 'Sunn Raha Hai',
          artist: 'Ankit Tiwari',
          duration: const Duration(seconds: 390),
          streamUrl: 'https://example.com/audio.m4a',
          source: 'jiosaavn',
        ),
      ],
      source: 'jiosaavn',
    );
  }
}

// Mock YouTube Source
class MockYouTubeSource extends YouTubeSource {
  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    return [
      Track(
        id: 'yt_song_1',
        title: 'Kesariya Lofi Remix',
        artist: 'YT Artist',
        duration: const Duration(seconds: 210),
        source: 'youtube',
      ),
    ];
  }

  @override
  Future<List<PlaylistModel>> searchPlaylists(String query, {int limit = 10}) async {
    return [
      PlaylistModel(
        id: 'yt_pl_1',
        title: 'Kesariya All Versions',
        trackCount: 10,
        source: 'youtube',
      ),
    ];
  }
}

// Mock Extractor Service
class MockExtractorSource extends ExtractorService {
  MockExtractorSource() : super();

  Future<List<Track>> search(String query, {int limit = 20}) async => const [];
}

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late SearchCacheRepository cacheRepo;
  late SearchRepository searchRepo;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_search_test_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
    cacheRepo = SearchCacheRepository(hiveService);
    searchRepo = SearchRepository(
      jioSaavnSource: MockJioSaavnSource(),
      youTubeSource: MockYouTubeSource(),
      extractorService: MockExtractorSource(),
      cacheRepository: cacheRepo,
    );
  });

  tearDownAll(() async {
    searchRepo.close();
    await Hive.close();
    HiveService.instance.resetForTesting();
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('SearchNotifier & SearchState Unit Tests', () {
    test('SearchNotifier initializes with empty query and empty history', () {
      final notifier = SearchNotifier(searchRepo, cacheRepo);
      expect(notifier.state.query, '');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.sourceFilter, SearchSourceFilter.all);
      expect(notifier.state.categoryFilter, SearchCategoryFilter.all);
      expect(notifier.state.hasSearched, false);
      notifier.dispose();
    });

    test('SearchNotifier searchImmediate executes aggregated multi-source search', () async {
      final notifier = SearchNotifier(searchRepo, cacheRepo);
      await notifier.searchImmediate('Kesariya');

      expect(notifier.state.query, 'Kesariya');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.hasSearched, true);
      expect(notifier.state.result, isNotNull);
      expect(notifier.state.result!.songs.isNotEmpty, true);
      expect(notifier.state.result!.albums.isNotEmpty, true);
      expect(notifier.state.result!.artists.isNotEmpty, true);

      // Verify search query was persisted in history
      expect(notifier.state.recentSearches.contains('Kesariya'), true);
      notifier.dispose();
    });

    test('SearchNotifier filter switching updates state and re-executes search', () async {
      final notifier = SearchNotifier(searchRepo, cacheRepo);
      await notifier.searchImmediate('Kesariya');

      // Change source filter to YouTube
      notifier.setSourceFilter(SearchSourceFilter.youTube);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state.sourceFilter, SearchSourceFilter.youTube);

      // Change category filter to songs
      notifier.setCategoryFilter(SearchCategoryFilter.songs);
      expect(notifier.state.categoryFilter, SearchCategoryFilter.songs);

      // Clear query restores history state
      notifier.clearQuery();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.query, '');
      expect(notifier.state.result, isNull);
      expect(notifier.state.hasSearched, false);
      notifier.dispose();
    });

    test('SearchNotifier removes individual query and clears history', () async {
      final notifier = SearchNotifier(searchRepo, cacheRepo);
      await notifier.searchImmediate('Arijit Singh');
      await notifier.searchImmediate('Taylor Swift');

      expect(notifier.state.recentSearches.contains('Arijit Singh'), true);
      expect(notifier.state.recentSearches.contains('Taylor Swift'), true);

      await notifier.removeRecentSearch('Taylor Swift');
      expect(notifier.state.recentSearches.contains('Taylor Swift'), false);
      expect(notifier.state.recentSearches.contains('Arijit Singh'), true);

      await notifier.clearSearchHistory();
      expect(notifier.state.recentSearches.isEmpty, true);
      notifier.dispose();
    });

    test('SearchNotifier debouncing handles text typing seamlessly', () async {
      final notifier = SearchNotifier(searchRepo, cacheRepo);
      notifier.onQueryChanged('A');
      expect(notifier.state.isDebouncing, true);

      notifier.onQueryChanged('Ar');
      notifier.onQueryChanged('Arijit');
      expect(notifier.state.isDebouncing, true);

      // Wait for debounce timer (400ms + 150ms margin)
      await Future.delayed(const Duration(milliseconds: 600));
      expect(notifier.state.isDebouncing, false);
      expect(notifier.state.hasSearched, true);
      expect(notifier.state.result != null, true);
      notifier.dispose();
    });
  });

  group('ArtistDetailNotifier & ArtistDetailState Unit Tests', () {
    test('ArtistDetailNotifier loads artist details, top tracks, albums & singles', () async {
      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepo),
        ],
      );

      final notifier = container.read(artistDetailProvider('test_artist_1').notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(artistDetailProvider('test_artist_1'));
      expect(state.isLoading, false);
      expect(state.artist, isNotNull);
      expect(state.artist!.name, 'Arijit Singh');
      expect(state.artist!.topTracks.length, 2);
      expect(state.artist!.albums.length, 1);
      expect(state.artist!.singles.length, 1);

      // Test follow toggle
      expect(state.isFollowed, false);
      notifier.toggleFollow();
      expect(container.read(artistDetailProvider('test_artist_1')).isFollowed, true);

      // Test Play All and Shuffle All into queue
      notifier.playAll();
      await Future.delayed(const Duration(milliseconds: 100));
      final queueState = container.read(queueProvider);
      expect(queueState.items.length, 2);
      expect(queueState.currentTrack?.title, 'Tum Hi Ho');

      container.dispose();
    });
  });

  group('AlbumDetailNotifier & AlbumDetailState Unit Tests', () {
    test('AlbumDetailNotifier loads album tracklist and calculates total runtime', () async {
      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepo),
        ],
      );

      final notifier = container.read(albumDetailProvider('test_album_1').notifier);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(albumDetailProvider('test_album_1'));
      expect(state.isLoading, false);
      expect(state.album, isNotNull);
      expect(state.album!.title, 'Aashiqui 2');
      expect(state.album!.songs.length, 2);

      // Total duration = 262s + 390s = 652 seconds = 10 minutes 52 seconds
      expect(state.totalDuration.inSeconds, 652);

      // Test favorite album toggle
      expect(state.isFavorite, false);
      notifier.toggleFavorite();
      expect(container.read(albumDetailProvider('test_album_1')).isFavorite, true);

      // Test Play Track at index
      notifier.playTrackAtIndex(1);
      await Future.delayed(const Duration(milliseconds: 100));
      final queueState = container.read(queueProvider);
      expect(queueState.currentIndex, 1);
      expect(queueState.currentTrack?.title, 'Sunn Raha Hai');

      container.dispose();
    });
  });
}
