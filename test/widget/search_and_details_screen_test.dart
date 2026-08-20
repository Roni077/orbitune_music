import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/search_screen.dart';
import 'package:orbitune/features/search/presentation/widgets/filter_source_bar.dart';
import 'package:orbitune/features/search/presentation/widgets/recent_searches_view.dart';
import 'package:orbitune/features/search/presentation/widgets/search_bar_widget.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';
import '../helpers/mock_audio_platform.dart';

class MockYouTubeWidgetSource extends YouTubeSource {
  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    return [
      Track(
        id: 'song_101',
        title: 'Heeriye',
        artist: 'Arijit Singh, Jasleen Royal',
        duration: const Duration(seconds: 195),
        source: 'youtube',
      ),
    ];
  }

  @override
  Future<List<PlaylistModel>> searchPlaylists(String query, {int limit = 10}) async => const [];

  @override
  Future<ArtistModel?> getArtistDetails(String artistId, {String? artistName}) async {
    return ArtistModel(
      id: artistId,
      name: 'Arijit Singh',
      fansCount: 45000000,
      bio: 'Renowned playback artist.',
      topTracks: [
        Track(
          id: 'song_101',
          title: 'Heeriye',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 195),
          source: 'youtube',
        ),
      ],
      albums: [
        AlbumModel(
          id: 'album_101',
          title: 'Ultimate Arijit',
          artist: 'Arijit Singh',
          releaseYear: '2024',
          source: 'youtube',
        ),
      ],
      source: 'youtube',
    );
  }

  @override
  Future<AlbumModel?> getAlbumDetails(String albumId) async {
    return AlbumModel(
      id: albumId,
      title: 'Ultimate Arijit',
      artist: 'Arijit Singh',
      artistId: 'artist_101',
      releaseYear: '2024',
      totalTracks: 1,
      songs: [
        Track(
          id: 'song_101',
          title: 'Heeriye',
          artist: 'Arijit Singh',
          duration: const Duration(seconds: 195),
          source: 'youtube',
        ),
      ],
      source: 'youtube',
    );
  }
}

class MockExtractorWidgetSource extends ExtractorService {
  MockExtractorWidgetSource() : super();

  Future<List<Track>> search(String query, {int limit = 20}) async => const [];
}

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late SearchCacheRepository cacheRepo;
  late SearchRepository searchRepo;

  setUpAll(() async {
    registerMockJustAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('orbitune_widget_search_test_');
    hiveService = HiveService.instance;
    await hiveService.init(tempDir.path);
    cacheRepo = SearchCacheRepository(hiveService);
    searchRepo = SearchRepository(
      youTubeSource: MockYouTubeWidgetSource(),
      extractorService: MockExtractorWidgetSource(),
      cacheRepository: cacheRepo,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    HiveService.instance.resetForTesting();
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('SearchScreen renders search bar, filters, and trending searches',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepo),
          searchCacheRepositoryProvider.overrideWithValue(cacheRepo),
        ],
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify search bar and filter bar
    expect(find.byType(SearchBarWidget), findsOneWidget);
    expect(find.byType(FilterSourceBar), findsOneWidget);
    expect(find.text('All Sources'), findsOneWidget);
    expect(find.text('YouTube Music'), findsOneWidget);

    // Verify Initial Recent / Trending searches view
    expect(find.byType(RecentSearchesView), findsOneWidget);
    expect(find.text('Trending Searches'), findsOneWidget);
  });

  testWidgets('ArtistDetailScreen renders banner, action buttons, and top songs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepo),
        ],
        child: const MaterialApp(
          home: ArtistDetailScreen(
            artistId: 'artist_101',
            artistName: 'Arijit Singh',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Header & Actions
    expect(find.text('Arijit Singh'), findsWidgets);
    expect(find.text('Verified Artist'), findsOneWidget);
    expect(find.text('Play All'), findsOneWidget);
    expect(find.text('Popular Tracks'), findsOneWidget);

    // Verify Top Track
    expect(find.text('Heeriye'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('AlbumDetailScreen renders album artwork, metadata, and tracklist',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepo),
        ],
        child: const MaterialApp(
          home: AlbumDetailScreen(
            albumId: 'album_101',
            albumTitle: 'Ultimate Arijit',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Album Details
    expect(find.text('Ultimate Arijit'), findsWidgets);
    expect(find.text('Arijit Singh'), findsWidgets);
    expect(find.text('Play All'), findsOneWidget);

    // Verify Tracklist item
    expect(find.text('Heeriye'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('TrackTile renders song details, source badge, duration and responds to tap',
      (WidgetTester tester) async {
    bool tapped = false;
    final track = Track(
      id: 'test_tile_song',
      title: 'Chaleya',
      artist: 'Arijit Singh, Shilpa Rao',
      duration: const Duration(seconds: 200),
      source: 'youtube',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TrackTile(
              track: track,
              index: 1,
              showIndex: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Chaleya'), findsOneWidget);
    expect(find.text('Arijit Singh, Shilpa Rao'), findsOneWidget);
    expect(find.text('03:20'), findsOneWidget);
    expect(find.text('YT MUSIC'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Chaleya'));
    expect(tapped, true);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
