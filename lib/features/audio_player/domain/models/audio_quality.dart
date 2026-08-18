/// Audio quality tiers for streaming and downloading
enum AudioQuality {
  low96k('96 kbps', 96, 'Standard', 'Low Data (96 kbps)'),
  medium160k('160 kbps', 160, 'HD', 'High Quality (160 kbps)'),
  high320k('320 kbps', 320, 'Ultra HD', 'Very High (320 kbps)'),
  lossless('Lossless', 1411, 'FLAC', 'Lossless Studio Audio');

  final String label;
  final int bitrateKbps;
  final String badgeText;
  final String description;

  int get bitrate => bitrateKbps;

  const AudioQuality(
    this.label,
    this.bitrateKbps,
    this.badgeText,
    this.description,
  );

  static AudioQuality fromString(String? value) {
    if (value == null) return AudioQuality.high320k;
    switch (value.toLowerCase().trim()) {
      case 'low':
      case 'low96k':
      case '96':
      case '96 kbps':
      case '96kbps':
        return AudioQuality.low96k;
      case 'medium':
      case 'medium160k':
      case '160':
      case '160 kbps':
      case '160kbps':
        return AudioQuality.medium160k;
      case 'lossless':
      case 'flac':
      case '1411':
        return AudioQuality.lossless;
      case 'high':
      case 'high320k':
      case '320':
      case '320 kbps':
      case '320kbps':
      default:
        return AudioQuality.high320k;
    }
  }

  String toJson() => name;
}
