/// Base application exception
abstract class AppException implements Exception {
  final String message;
  final dynamic details;

  const AppException(this.message, [this.details]);

  @override
  String toString() => '$runtimeType: $message${details != null ? ' ($details)' : ''}';
}

/// Thrown when local Hive storage or database operation fails
class StorageException extends AppException {
  const StorageException(super.message, [super.details]);
}

/// Thrown when network connection or HTTP request fails
class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException(super.message, [this.statusCode, super.details]);
}

/// Thrown when audio stream resolution or playback fails
class AudioStreamException extends AppException {
  const AudioStreamException(super.message, [super.details]);
}

/// Thrown when encrypted audio/media stream fails decryption
class DecryptionException extends AppException {
  const DecryptionException(super.message, [super.details]);
}

/// Thrown when lyrics fetching or parsing fails
class LyricsException extends AppException {
  const LyricsException(super.message, [super.details]);
}

/// Thrown when media download fails
class DownloadException extends AppException {
  const DownloadException(super.message, [super.details]);
}
