import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Aggregated listening statistics and insights
class ListeningStats {
  final Duration totalListeningTime;
  final int totalPlays;
  final Map<String, int> songPlayCounts; // Track ID -> Play count
  final Map<String, int> artistPlayCounts; // Artist Name -> Play count
  final Map<String, int> genrePlayCounts; // Genre Name -> Play count
  final Map<String, int> dailyListeningMinutes; // Date (YYYY-MM-DD) -> Minutes
  final int streakDays;
  final String? lastActiveDate; // YYYY-MM-DD

  const ListeningStats({
    this.totalListeningTime = Duration.zero,
    this.totalPlays = 0,
    this.songPlayCounts = const {},
    this.artistPlayCounts = const {},
    this.genrePlayCounts = const {},
    this.dailyListeningMinutes = const {},
    this.streakDays = 0,
    this.lastActiveDate,
  });

  /// Records a played track session into listening statistics
  ListeningStats recordSession({
    required Track track,
    required Duration durationPlayed,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Update daily minutes
    final updatedDaily = Map<String, int>.from(dailyListeningMinutes);
    final currentDailyMins = updatedDaily[todayKey] ?? 0;
    final addedMins = (durationPlayed.inSeconds / 60.0).ceil();
    updatedDaily[todayKey] = currentDailyMins + addedMins;

    // Update song counts
    final updatedSongCounts = Map<String, int>.from(songPlayCounts);
    updatedSongCounts[track.id] = (updatedSongCounts[track.id] ?? 0) + 1;

    // Update artist counts
    final updatedArtistCounts = Map<String, int>.from(artistPlayCounts);
    final artist = track.artist.trim();
    if (artist.isNotEmpty) {
      updatedArtistCounts[artist] = (updatedArtistCounts[artist] ?? 0) + 1;
    }

    // Update genre counts
    final updatedGenreCounts = Map<String, int>.from(genrePlayCounts);
    final genre = track.genre?.trim();
    if (genre != null && genre.isNotEmpty) {
      updatedGenreCounts[genre] = (updatedGenreCounts[genre] ?? 0) + 1;
    }

    // Calculate streak
    var newStreak = streakDays;
    if (lastActiveDate == null) {
      newStreak = 1;
    } else if (lastActiveDate != todayKey) {
      final lastDate = DateTime.tryParse(lastActiveDate!);
      if (lastDate != null) {
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diff == 1) {
          newStreak += 1;
        } else if (diff > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
    }

    return ListeningStats(
      totalListeningTime: totalListeningTime + durationPlayed,
      totalPlays: totalPlays + 1,
      songPlayCounts: updatedSongCounts,
      artistPlayCounts: updatedArtistCounts,
      genrePlayCounts: updatedGenreCounts,
      dailyListeningMinutes: updatedDaily,
      streakDays: newStreak,
      lastActiveDate: todayKey,
    );
  }

  ListeningStats copyWith({
    Duration? totalListeningTime,
    int? totalPlays,
    Map<String, int>? songPlayCounts,
    Map<String, int>? artistPlayCounts,
    Map<String, int>? genrePlayCounts,
    Map<String, int>? dailyListeningMinutes,
    int? streakDays,
    String? lastActiveDate,
  }) {
    return ListeningStats(
      totalListeningTime: totalListeningTime ?? this.totalListeningTime,
      totalPlays: totalPlays ?? this.totalPlays,
      songPlayCounts: songPlayCounts ?? this.songPlayCounts,
      artistPlayCounts: artistPlayCounts ?? this.artistPlayCounts,
      genrePlayCounts: genrePlayCounts ?? this.genrePlayCounts,
      dailyListeningMinutes:
          dailyListeningMinutes ?? this.dailyListeningMinutes,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalListeningTimeMs': totalListeningTime.inMilliseconds,
      'totalPlays': totalPlays,
      'songPlayCounts': songPlayCounts,
      'artistPlayCounts': artistPlayCounts,
      'genrePlayCounts': genrePlayCounts,
      'dailyListeningMinutes': dailyListeningMinutes,
      'streakDays': streakDays,
      'lastActiveDate': lastActiveDate,
    };
  }

  factory ListeningStats.fromMap(Map<dynamic, dynamic> map) {
    return ListeningStats(
      totalListeningTime: Duration(
        milliseconds:
            (map['totalListeningTimeMs'] as num?)?.toInt() ?? 0,
      ),
      totalPlays: (map['totalPlays'] as num?)?.toInt() ?? 0,
      songPlayCounts: map['songPlayCounts'] != null
          ? Map<String, int>.from(
              (map['songPlayCounts'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      artistPlayCounts: map['artistPlayCounts'] != null
          ? Map<String, int>.from(
              (map['artistPlayCounts'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      genrePlayCounts: map['genrePlayCounts'] != null
          ? Map<String, int>.from(
              (map['genrePlayCounts'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      dailyListeningMinutes: map['dailyListeningMinutes'] != null
          ? Map<String, int>.from(
              (map['dailyListeningMinutes'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      lastActiveDate: map['lastActiveDate']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ListeningStats.fromJson(String source) =>
      ListeningStats.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
