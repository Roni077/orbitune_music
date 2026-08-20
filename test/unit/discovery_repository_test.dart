import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/discovery/data/discovery_repository.dart';
import 'package:orbitune/features/discovery/domain/models/chart_playlist.dart';
import 'package:orbitune/features/discovery/domain/models/home_section.dart';
import 'package:orbitune/features/discovery/domain/models/trending_item.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discovery Repository & Models Tests', () {
    late DiscoveryRepository repository;

    setUp(() {
      repository = DiscoveryRepository(
        youTubeSource: YouTubeSource(),
      );
    });

    test('ChartPlaylist domain model serialization and copyWith', () {
      final chart = ChartPlaylist(
        id: 'chart_1',
        title: 'Top 50 Global',
        subtitle: 'Worldwide hits',
        description: 'Updated daily',
        artworkUrl: 'https://example.com/art.jpg',
        trackCount: 50,
        category: 'Chart',
        colorHex: '#6366F1',
        songs: [
          Track(
            id: 'song_1',
            title: 'Track 1',
            artist: 'Artist 1',
            duration: const Duration(seconds: 200),
          ),
        ],
      );

      final map = chart.toMap();
      expect(map['id'], 'chart_1');
      expect(map['title'], 'Top 50 Global');
      expect(map['trackCount'], 50);

      final fromMap = ChartPlaylist.fromMap(map);
      expect(fromMap.id, 'chart_1');
      expect(fromMap.title, 'Top 50 Global');
      expect(fromMap.songs.length, 1);

      final updated = chart.copyWith(title: 'Top 100 Global', trackCount: 100);
      expect(updated.title, 'Top 100 Global');
      expect(updated.trackCount, 100);
      expect(updated.id, 'chart_1');
    });

    test('HomeSection and TrendingItem model validations', () {
      final section = HomeSection(
        id: 'sec_1',
        title: 'Trending',
        sectionType: 'tracks',
        tracks: [
          Track(id: 't1', title: 'Song', artist: 'Artist'),
        ],
      );
      expect(section.isNotEmpty, isTrue);
      expect(section.isEmpty, isFalse);

      final emptySection = HomeSection(
        id: 'sec_2',
        title: 'Empty',
        sectionType: 'tracks',
      );
      expect(emptySection.isEmpty, isTrue);

      final trendingItem = TrendingItem(
        id: 'item_1',
        title: 'Hero Song',
        subtitle: 'Top Artist',
        bannerUrl: 'https://example.com/hero.jpg',
        type: 'song',
      );
      final itemMap = trendingItem.toMap();
      expect(itemMap['id'], 'item_1');
      expect(TrendingItem.fromMap(itemMap).title, 'Hero Song');
    });

    test('DiscoveryRepository getCuratedCharts returns complete chart list', () {
      final charts = repository.getCuratedCharts();
      expect(charts.length, greaterThanOrEqualTo(4));
      expect(charts.any((c) => c.title.contains('Top 50')), isTrue);
      expect(charts.any((c) => c.title.contains('Bollywood')), isTrue);
    });

    test('DiscoveryRepository getPopularArtists returns top artists', () async {
      final artists = await repository.getPopularArtists();
      expect(artists.isNotEmpty, isTrue);
      expect(artists.any((a) => a.name.contains('Arijit') || a.name.contains('Diljit')), isTrue);
    });

    test('DiscoveryRepository getDailyMixes returns curated mixes', () {
      final mixes = repository.getDailyMixes();
      expect(mixes.length, greaterThanOrEqualTo(3));
      expect(mixes.any((m) => m.title.contains('Daily Mix')), isTrue);
    });

    test('DiscoveryRepository getHomeFeed returns structured banners and sections', () async {
      final feed = await repository.getHomeFeed();
      expect(feed.banners.isNotEmpty, isTrue);
      expect(feed.sections.isNotEmpty, isTrue);
      expect(feed.charts.isNotEmpty, isTrue);
      expect(feed.popularArtists.isNotEmpty, isTrue);
      expect(feed.dailyMixes.isNotEmpty, isTrue);
    });
  });
}
