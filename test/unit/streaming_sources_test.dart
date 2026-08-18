import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';
import 'package:orbitune/features/search/data/jiosaavn_source.dart';
import 'package:orbitune/features/search/data/search_cache_repository.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/data/youtube_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('orbitune_test_sources_');
    await HiveService.instance.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ExtractorService Tests', () {
    test('Correctly identifies supported media stream URLs', () {
      final service = ExtractorService.instance;

      expect(service.isSupportedMediaUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
      expect(service.isSupportedMediaUrl('https://youtu.be/dQw4w9WgXcQ'), isTrue);
      expect(service.isSupportedMediaUrl('https://soundcloud.com/artist/track-name'), isTrue);
      expect(service.isSupportedMediaUrl('https://instagram.com/reel/12345'), isTrue);
      expect(service.isSupportedMediaUrl('https://cdn.example.com/audio.mp3'), isTrue);
      expect(service.isSupportedMediaUrl('https://example.com/stream.m4a'), isTrue);

      expect(service.isSupportedMediaUrl('just a random query'), isFalse);
      expect(service.isSupportedMediaUrl(''), isFalse);
    });
  });

  group('SearchRepository Stream Resolver Tests', () {
    late SearchRepository repository;

    setUp(() {
      repository = SearchRepository(
        jioSaavnSource: JioSaavnSource(),
        youTubeSource: YouTubeSource(),
        extractorService: ExtractorService.instance,
        cacheRepository: SearchCacheRepository(HiveService.instance),
      );
    });

    test('Resolves local file path immediately if track is offline available', () async {
      final track = Track(
        id: 'local_1',
        title: 'Offline Song',
        artist: 'Local Artist',
        localFilePath: '/storage/emulated/0/Music/song.mp3',
        source: 'local',
      );

      final streamUrl = await repository.resolveStreamUrl(track);
      expect(streamUrl, equals('/storage/emulated/0/Music/song.mp3'));
    });

    test('Resolves JioSaavn stream URL with requested audio quality bitrate', () async {
      const rawCdnUrl = 'https://aac.saavncdn.com/100/song_96.mp4';
      final encryptedUrl = AudioDecryptor.encryptMediaUrl(rawCdnUrl)!;

      final track = Track(
        id: 'saavn_100',
        title: 'Saavn Song',
        artist: 'Saavn Artist',
        streamUrl: rawCdnUrl,
        source: 'jiosaavn',
        extra: {'encrypted_media_url': encryptedUrl},
      );

      // High 320k
      final url320 = await repository.resolveStreamUrl(track, quality: AudioQuality.high320k);
      expect(url320, equals('https://aac.saavncdn.com/100/song_320.mp4'));

      // Medium 160k
      final url160 = await repository.resolveStreamUrl(track, quality: AudioQuality.medium160k);
      expect(url160, equals('https://aac.saavncdn.com/100/song_160.mp4'));
    });

    test('SearchRepository initializes and handles query execution correctly', () async {
      final searchResult = await repository.search('Arijit Singh', source: 'extractor');
      expect(searchResult, isNotNull);
      expect(searchResult.source, equals('extractor'));
    });
  });
}
