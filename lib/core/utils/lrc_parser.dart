import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';

/// Comprehensive parser and serializer for Synchronized LRC lyrics format
class LrcParser {
  LrcParser._();

  static final RegExp _timestampRegex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{2,3}))?\]');
  static final RegExp _metadataRegex = RegExp(r'^\[(ti|ar|al|au|by|offset|length):([^\]]*)\]', caseSensitive: false);

  /// Parses raw LRC string into a sorted list of [LyricLine]
  static List<LyricLine> parse(String? lrcContent) {
    if (lrcContent == null || lrcContent.trim().isEmpty) {
      return const [];
    }

    final lines = lrcContent.split(RegExp(r'\r?\n'));
    final List<LyricLine> result = [];
    int offsetMs = 0;

    // First pass: extract offset and metadata
    for (final rawLine in lines) {
      final match = _metadataRegex.firstMatch(rawLine.trim());
      if (match != null) {
        final tag = match.group(1)?.toLowerCase();
        final value = match.group(2)?.trim() ?? '';
        if (tag == 'offset') {
          offsetMs = int.tryParse(value) ?? 0;
        }
      }
    }

    // Second pass: extract lyric lines and timestamps
    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || _metadataRegex.hasMatch(trimmed)) {
        continue;
      }

      final matches = _timestampRegex.allMatches(trimmed).toList();
      if (matches.isEmpty) {
        continue;
      }

      // The text is whatever comes after the last timestamp tag
      final text = trimmed.substring(matches.last.end).trim();

      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final fractionStr = match.group(3) ?? '0';
        
        int milliseconds = 0;
        if (fractionStr.length == 2) {
          milliseconds = (int.tryParse(fractionStr) ?? 0) * 10;
        } else if (fractionStr.length == 3) {
          milliseconds = int.tryParse(fractionStr) ?? 0;
        } else if (fractionStr.length == 1) {
          milliseconds = (int.tryParse(fractionStr) ?? 0) * 100;
        }

        var totalMs = (minutes * 60 * 1000) + (seconds * 1000) + milliseconds + offsetMs;
        if (totalMs < 0) totalMs = 0;

        result.add(LyricLine(
          timestamp: Duration(milliseconds: totalMs),
          text: text,
        ));
      }
    }

    // Sort by timestamp
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return result;
  }

  /// Binary search to find the active line index for a given audio playback position
  /// Returns -1 if playback is before the first lyric line
  static int getActiveLineIndex(List<LyricLine> lines, Duration currentPosition) {
    if (lines.isEmpty) return -1;
    if (currentPosition < lines.first.timestamp) return -1;
    if (currentPosition >= lines.last.timestamp) return lines.length - 1;

    int low = 0;
    int high = lines.length - 1;
    int activeIndex = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (lines[mid].timestamp <= currentPosition) {
        activeIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return activeIndex;
  }

  /// Serializes a list of [LyricLine] back into standard .lrc string
  static String format(List<LyricLine> lines) {
    if (lines.isEmpty) return '';

    final buffer = StringBuffer();
    for (final line in lines) {
      final ms = line.timestamp.inMilliseconds;
      final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
      final centiseconds = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');

      buffer.writeln('[$minutes:$seconds.$centiseconds] ${line.text}');
    }

    return buffer.toString().trim();
  }

  /// Strips LRC tags from content and returns clean plain text
  static String extractPlainLyrics(String lrcContent) {
    if (lrcContent.isEmpty) return '';
    final lines = lrcContent.split(RegExp(r'\r?\n'));
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || _metadataRegex.hasMatch(trimmed)) continue;
      final cleaned = trimmed.replaceAll(_timestampRegex, '').trim();
      if (cleaned.isNotEmpty) {
        buffer.writeln(cleaned);
      }
    }

    return buffer.toString().trim();
  }
}
