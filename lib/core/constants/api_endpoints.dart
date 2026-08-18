/// API Endpoints for JioSaavn, LRCLIB Synced Lyrics, and Media Streaming
class ApiEndpoints {
  ApiEndpoints._();

  // JioSaavn Endpoints
  static const String jioSaavnDirectBase = 'https://www.jiosaavn.com/api.php';
  static const String jioSaavnApiMirror = 'https://saavn.dev/api';
  static const String saavnDesKey = '38346591'; // DES-ECB decryption key

  // LRCLIB Synced Lyrics API
  static const String lrcLibBase = 'https://lrclib.net/api/get';
  static const String lrcLibSearch = 'https://lrclib.net/api/search';
}
