import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/utils/lrc_parser.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';

void main() {
  group('LrcParser Tests', () {
    const sampleLrc = '''
[ti:Midnight City]
[ar:M83]
[al:Hurry Up, We're Dreaming]
[offset:500]
[00:15.20]Waiting in a car
[00:18.50]Waiting for a ride in the dark
[00:22.00][00:25.00]The night city grows
[00:30.123]Look and see her eyes, they glow
''';

    test('Parses standard and multi-timestamp LRC lines with offset', () {
      final lines = LrcParser.parse(sampleLrc);

      expect(lines.length, equals(5));
      // First line: 15.20s + 500ms offset = 15700ms
      expect(lines[0].timestamp.inMilliseconds, equals(15700));
      expect(lines[0].text, equals('Waiting in a car'));

      // Second line: 18.50s + 500ms offset = 19000ms
      expect(lines[1].timestamp.inMilliseconds, equals(19000));
      expect(lines[1].text, equals('Waiting for a ride in the dark'));

      // Multi-timestamp line expanded to 2 lines sorted
      expect(lines[2].text, equals('The night city grows'));
      expect(lines[2].timestamp.inMilliseconds, equals(22500));
      expect(lines[3].text, equals('The night city grows'));
      expect(lines[3].timestamp.inMilliseconds, equals(25500));

      // 3-digit millisecond timestamp
      expect(lines[4].text, equals('Look and see her eyes, they glow'));
      expect(lines[4].timestamp.inMilliseconds, equals(30623));
    });

    test('Finds correct active line index using binary search', () {
      final lines = [
        LyricLine(timestamp: const Duration(seconds: 10), text: 'Line 1'),
        LyricLine(timestamp: const Duration(seconds: 20), text: 'Line 2'),
        LyricLine(timestamp: const Duration(seconds: 30), text: 'Line 3'),
      ];

      // Before first line
      expect(LrcParser.getActiveLineIndex(lines, const Duration(seconds: 5)), equals(-1));

      // Exactly at first line
      expect(LrcParser.getActiveLineIndex(lines, const Duration(seconds: 10)), equals(0));

      // Between first and second
      expect(LrcParser.getActiveLineIndex(lines, const Duration(seconds: 15)), equals(0));

      // At second line
      expect(LrcParser.getActiveLineIndex(lines, const Duration(seconds: 20)), equals(1));

      // At or after last line
      expect(LrcParser.getActiveLineIndex(lines, const Duration(seconds: 35)), equals(2));
    });

    test('Formats LyricLine list back to LRC string', () {
      final lines = [
        LyricLine(timestamp: const Duration(minutes: 1, seconds: 5, milliseconds: 200), text: 'First phrase'),
        LyricLine(timestamp: const Duration(minutes: 1, seconds: 12, milliseconds: 500), text: 'Second phrase'),
      ];

      final formatted = LrcParser.format(lines);
      expect(formatted, contains('[01:05.20] First phrase'));
      expect(formatted, contains('[01:12.50] Second phrase'));
    });

    test('Extracts plain lyrics cleanly without timestamps or metadata', () {
      final plain = LrcParser.extractPlainLyrics(sampleLrc);
      expect(plain, contains('Waiting in a car'));
      expect(plain, contains('Waiting for a ride in the dark'));
      expect(plain, isNot(contains('[00:15.20]')));
      expect(plain, isNot(contains('[ti:Midnight City]')));
    });

    test('Handles empty and invalid LRC strings gracefully', () {
      expect(LrcParser.parse(null), isEmpty);
      expect(LrcParser.parse(''), isEmpty);
      expect(LrcParser.parse('No timestamps here\nJust plain text'), isEmpty);
    });
  });
}
