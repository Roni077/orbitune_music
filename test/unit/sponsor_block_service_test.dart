import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:orbitune/features/audio_player/data/sponsor_block_service.dart';

void main() {
  group('SponsorBlockSegment Domain Model Tests', () {
    test('Correctly deserializes from JSON with second-level timestamps', () {
      final json = {
        'category': 'sponsor',
        'segment': [12.5, 45.0],
        'UUID': 'uuid-12345',
      };

      final segment = SponsorBlockSegment.fromJson(json);

      expect(segment.category, 'sponsor');
      expect(segment.start, const Duration(milliseconds: 12500));
      expect(segment.end, const Duration(milliseconds: 45000));
      expect(segment.duration, const Duration(milliseconds: 32500));
      expect(segment.uuid, 'uuid-12345');
    });

    test('Correctly checks if a playback position falls inside segment', () {
      const segment = SponsorBlockSegment(
        category: 'intro',
        start: Duration(seconds: 0),
        end: Duration(seconds: 15),
      );

      expect(segment.contains(const Duration(seconds: 0)), isTrue);
      expect(segment.contains(const Duration(seconds: 7)), isTrue);
      expect(segment.contains(const Duration(seconds: 14, milliseconds: 999)), isTrue);
      expect(segment.contains(const Duration(seconds: 15)), isFalse);
      expect(segment.contains(const Duration(seconds: 20)), isFalse);
    });
  });

  group('SponsorBlockService Unit Tests', () {
    test('Fetches and parses skip segments from API successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['videoID'] == 'sample_video_1') {
          return http.Response(
            jsonEncode([
              {
                'category': 'music_offtopic',
                'segment': [0.0, 18.2],
                'UUID': 'seg_1',
              },
              {
                'category': 'sponsor',
                'segment': [120.0, 150.0],
                'UUID': 'seg_2',
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = SponsorBlockService(httpClient: mockClient);

      final segments = await service.getSkipSegments('sample_video_1');

      expect(segments.length, 2);
      expect(segments[0].category, 'music_offtopic');
      expect(segments[0].start, Duration.zero);
      expect(segments[0].end, const Duration(milliseconds: 18200));

      expect(segments[1].category, 'sponsor');
      expect(segments[1].start, const Duration(seconds: 120));
      expect(segments[1].end, const Duration(seconds: 150));
    });

    test('Caches fetched segments for subsequent calls', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode([
            {
              'category': 'intro',
              'segment': [0.0, 10.0],
              'UUID': 'seg_intro',
            }
          ]),
          200,
        );
      });

      final service = SponsorBlockService(httpClient: mockClient);

      final first = await service.getSkipSegments('vid_cached');
      final second = await service.getSkipSegments('vid_cached');

      expect(first.length, 1);
      expect(second.length, 1);
      expect(callCount, 1); // Only one network call
    });

    test('Finds correct skip target when playback position enters a segment', () {
      final service = SponsorBlockService();
      final segments = [
        const SponsorBlockSegment(
          category: 'intro',
          start: Duration(seconds: 0),
          end: Duration(seconds: 22),
        ),
        const SponsorBlockSegment(
          category: 'sponsor',
          start: Duration(seconds: 180),
          end: Duration(seconds: 215),
        ),
      ];

      // Inside intro
      final target1 = service.findSkipTarget(const Duration(seconds: 5), segments);
      expect(target1, const Duration(seconds: 22));

      // Inside sponsor segment
      final target2 = service.findSkipTarget(const Duration(seconds: 190), segments);
      expect(target2, const Duration(seconds: 215));

      // Outside any segment (music playing normally)
      final target3 = service.findSkipTarget(const Duration(seconds: 50), segments);
      expect(target3, isNull);
    });

    test('Gracefully returns empty list on API errors or 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('No segments found', 404);
      });

      final service = SponsorBlockService(httpClient: mockClient);
      final segments = await service.getSkipSegments('empty_vid');

      expect(segments, isEmpty);
    });
  });
}
