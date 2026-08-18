/// User-facing failure representations for clean UI error states and retries
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

/// Failure representing storage / database issues
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Unable to read or write local data', super.code]);
}

/// Failure representing network connectivity or server issues
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection or server unreachable', super.code]);
}

/// Failure representing audio streaming or decode issues
class AudioPlaybackFailure extends Failure {
  const AudioPlaybackFailure([super.message = 'Unable to play this audio stream', super.code]);
}

/// Failure representing audio decryption issues
class DecryptionFailure extends Failure {
  const DecryptionFailure([super.message = 'Unable to decrypt audio stream', super.code]);
}

/// Failure representing lyrics fetch or parsing issues
class LyricsFailure extends Failure {
  const LyricsFailure([super.message = 'Lyrics not available for this track', super.code]);
}

/// Failure representing download issues
class DownloadFailure extends Failure {
  const DownloadFailure([super.message = 'Download failed. Please check your storage or network', super.code]);
}
