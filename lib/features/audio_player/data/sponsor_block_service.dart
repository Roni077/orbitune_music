import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:orbitune/core/constants/api_endpoints.dart';

/// Provider for SponsorBlockService
final sponsorBlockServiceProvider = Provider<SponsorBlockService>((ref) {
  final service = SponsorBlockService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Immutable model representing a non-music or sponsor segment within a track
class SponsorBlockSegment {
  final String category;
  final Duration start;
  final Duration end;
  final String uuid;

  const SponsorBlockSegment({
    required this.category,
    required this.start,
    required this.end,
    this.uuid = '',
  });

  /// Duration length of this skipped segment
  Duration get duration => end - start;

  /// Whether a specific playback [position] falls inside this segment
  bool contains(Duration position) {
    return position >= start && position < end;
  }

  factory SponsorBlockSegment.fromJson(Map<String, dynamic> json) {
    final segment = json['segment'] as List?;
    final startSec = (segment != null && segment.isNotEmpty)
        ? (segment[0] as num).toDouble()
        : 0.0;
    final endSec = (segment != null && segment.length > 1)
        ? (segment[1] as num).toDouble()
        : 0.0;

    return SponsorBlockSegment(
      category: json['category']?.toString() ?? 'sponsor',
      start: Duration(milliseconds: (startSec * 1000).round()),
      end: Duration(milliseconds: (endSec * 1000).round()),
      uuid: json['UUID']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'SponsorBlockSegment(category: $category, start: $start, end: $end)';
}

/// Service querying the community-driven SponsorBlock API to skip non-music intros, outros, and promotions
class SponsorBlockService {
  final http.Client _httpClient;
  final Map<String, List<SponsorBlockSegment>> _cache = {};

  static const List<String> defaultCategories = [
    'sponsor',
    'intro',
    'outro',
    'music_offtopic',
    'selfpromo',
    'preview',
  ];

  SponsorBlockService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Fetches skip segments for a given YouTube [videoId]
  Future<List<SponsorBlockSegment>> getSkipSegments(
    String videoId, {
    List<String> categories = defaultCategories,
  }) async {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return const [];

    // Check cache
    if (_cache.containsKey(cleanId)) {
      return _cache[cleanId]!;
    }

    try {
      final categoriesParam = jsonEncode(categories);
      final uri = Uri.parse(
        '${ApiEndpoints.sponsorBlockBase}?videoID=$cleanId&categories=$categoriesParam',
      );

      final response = await _httpClient.get(uri, headers: {
        'User-Agent': 'Orbitune Music Player (https://github.com/orbitune)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        if (rawData is List) {
          final segments = rawData
              .whereType<Map<String, dynamic>>()
              .map((item) => SponsorBlockSegment.fromJson(item))
              .where((s) => s.end > s.start)
              .toList();

          // Sort segments chronologically
          segments.sort((a, b) => a.start.compareTo(b.start));
          _cache[cleanId] = List.unmodifiable(segments);
          return _cache[cleanId]!;
        }
      }
    } catch (e) {
      debugPrint('[SponsorBlockService] Failed to fetch segments for $videoId: $e');
    }

    // Cache empty list to avoid redundant rapid failed lookups
    _cache[cleanId] = const [];
    return const [];
  }

  /// Checks if [position] falls into any skip segment and returns the skip target [Duration], or null
  Duration? findSkipTarget(
    Duration position,
    List<SponsorBlockSegment> segments,
  ) {
    for (final segment in segments) {
      if (segment.contains(position)) {
        return segment.end;
      }
    }
    return null;
  }

  /// Clears in-memory segments cache
  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _cache.clear();
  }
}
