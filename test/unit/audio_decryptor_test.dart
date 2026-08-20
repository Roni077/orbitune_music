import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';

void main() {
  group('AudioDecryptor / Text & Media Sanitizer Tests', () {
    test('Upscales artwork URLs to high resolution', () {
      const thumb50 = 'http://example.com/123/art-50x50.jpg';
      final hiRes50 = AudioDecryptor.formatHighResArtwork(thumb50);
      expect(hiRes50, equals('https://example.com/123/art-500x500.jpg'));

      const thumb150 = 'https://example.com/123/art-150x150.jpg';
      final hiRes150 = AudioDecryptor.formatHighResArtwork(thumb150);
      expect(hiRes150, equals('https://example.com/123/art-500x500.jpg'));

      expect(AudioDecryptor.formatHighResArtwork(null), isNull);
    });

    test('Cleans HTML entities properly', () {
      const rawText = 'Rock &amp; Roll &quot;Live&quot; &#039;2026&#039; &lt;Audio&gt;';
      final cleaned = AudioDecryptor.cleanHtmlEntities(rawText);
      expect(cleaned, equals("Rock & Roll \"Live\" '2026' <Audio>"));
    });

    test('Strips video promotional prefixes/suffixes from track titles', () {
      const rawTitle = 'Tum Hi Ho [Official Music Video]';
      final cleaned = AudioDecryptor.cleanTrackTitle(rawTitle);
      expect(cleaned, equals('Tum Hi Ho'));

      const rawTitle2 = 'Kesariya (Official Video) [4K]';
      final cleaned2 = AudioDecryptor.cleanTrackTitle(rawTitle2);
      expect(cleaned2, equals('Kesariya'));
    });

    test('Cleans artist biographies with tags, escape characters, and entities', () {
      const rawBio = r'Arijit Singh is an Indian singer.<br>He was born in Jiaganj &amp; is known for \"Tum Hi Ho\".<p>Bio &copy; 2026</p>\n\n&#039;Legend&#039;';
      final cleaned = AudioDecryptor.cleanBioText(rawBio);
      expect(cleaned, contains('Arijit Singh is an Indian singer.'));
      expect(cleaned, contains('Jiaganj & is known for "Tum Hi Ho".'));
      expect(cleaned, contains("Bio © 2026"));
      expect(cleaned, contains("'Legend'"));
      expect(cleaned, isNot(contains('<br>')));
      expect(cleaned, isNot(contains(r'\"')));
      expect(cleaned, isNot(contains(r'\n')));
    });

    test('Gracefully handles invalid or corrupted inputs', () {
      expect(AudioDecryptor.cleanBioText(null), equals(''));
      expect(AudioDecryptor.cleanBioText(''), equals(''));
      expect(AudioDecryptor.cleanTrackTitle(''), equals(''));
      expect(AudioDecryptor.cleanHtmlEntities(''), equals(''));
    });
  });
}
