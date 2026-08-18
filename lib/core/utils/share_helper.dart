import 'package:share_plus/share_plus.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Helper utility for native OS share intents and formatted share cards
class ShareHelper {
  ShareHelper._();

  /// Shares a [track] with rich formatted metadata text
  static Future<void> shareTrack(Track track) async {
    final buffer = StringBuffer();
    buffer.writeln('🎵 Listening to "${track.title}" by ${track.artist}');
    if (track.album != null && track.album!.isNotEmpty) {
      buffer.writeln('💿 Album: ${track.album}');
    }
    if (track.streamUrl != null && track.streamUrl!.isNotEmpty) {
      buffer.writeln('🔗 Stream: ${track.streamUrl}');
    }
    buffer.writeln('\n🎧 Shared via Orbitune — Modern Music Player');

    await Share.share(
      buffer.toString(),
      subject: 'Listen to ${track.title} on Orbitune',
    );
  }

  /// Shares an album
  static Future<void> shareAlbum(String albumTitle, String artistName) async {
    final text = '💿 Check out the album "$albumTitle" by $artistName on Orbitune!';
    await Share.share(text, subject: 'Album: $albumTitle');
  }

  /// Shares an artist profile
  static Future<void> shareArtist(String artistName) async {
    final text = '🎤 Check out $artistName on Orbitune Music!';
    await Share.share(text, subject: 'Artist: $artistName');
  }

  /// Shares generic text
  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }
}
