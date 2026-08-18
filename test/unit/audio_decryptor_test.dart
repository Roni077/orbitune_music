import 'package:flutter_test/flutter_test.dart';
import 'package:orbitune/core/utils/audio_decryptor.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';

void main() {
  group('AudioDecryptor Tests', () {
    const testPlainUrl = 'https://aac.saavncdn.com/123/sample_song_96.mp4';

    test('Encrypts and decrypts JioSaavn media URL with DES key', () {
      final encrypted = AudioDecryptor.encryptMediaUrl(testPlainUrl);
      expect(encrypted, isNotNull);
      expect(encrypted, isNotEmpty);

      // Decrypt to 320kbps
      final decrypted320 = AudioDecryptor.decryptMediaUrl(encrypted, quality: AudioQuality.high320k);
      expect(decrypted320, isNotNull);
      expect(decrypted320, contains('_320.mp4'));

      // Decrypt to 160kbps
      final decrypted160 = AudioDecryptor.decryptMediaUrl(encrypted, quality: AudioQuality.medium160k);
      expect(decrypted160, isNotNull);
      expect(decrypted160, contains('_160.mp4'));

      // Decrypt to 96kbps
      final decrypted96 = AudioDecryptor.decryptMediaUrl(encrypted, quality: AudioQuality.low96k);
      expect(decrypted96, isNotNull);
      expect(decrypted96, contains('_96.mp4'));
    });

    test('Formats bitrate correctly on raw URLs', () {
      const url96 = 'http://aac.saavncdn.com/test_96.mp4';
      final formatted320 = AudioDecryptor.formatQualityUrl(url96, AudioQuality.high320k);
      expect(formatted320, equals('https://aac.saavncdn.com/test_320.mp4'));

      const url160 = 'https://aac.saavncdn.com/test_160.mp4';
      final formatted96 = AudioDecryptor.formatQualityUrl(url160, AudioQuality.low96k);
      expect(formatted96, equals('https://aac.saavncdn.com/test_96.mp4'));
    });

    test('Upscales artwork URLs to 500x500 high resolution', () {
      const thumb50 = 'http://c.saavncdn.com/123/art-50x50.jpg';
      final hiRes50 = AudioDecryptor.formatHighResArtwork(thumb50);
      expect(hiRes50, equals('https://c.saavncdn.com/123/art-500x500.jpg'));

      const thumb150 = 'https://c.saavncdn.com/123/art-150x150.jpg';
      final hiRes150 = AudioDecryptor.formatHighResArtwork(thumb150);
      expect(hiRes150, equals('https://c.saavncdn.com/123/art-500x500.jpg'));

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

    test('Gracefully handles invalid or corrupted inputs', () {
      expect(AudioDecryptor.decryptMediaUrl(null), isNull);
      expect(AudioDecryptor.decryptMediaUrl(''), isNull);
      expect(AudioDecryptor.decryptMediaUrl('invalid-base64-payload!'), isNull);
    });
  });
}
