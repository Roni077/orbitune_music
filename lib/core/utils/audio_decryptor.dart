/// Utility helper for cleaning track titles, artist bios, HTML entities, and formatting artwork
class AudioDecryptor {
  AudioDecryptor._();

  /// Upgrades external/YouTube artwork URLs to high resolution
  static String? formatHighResArtwork(String? artworkUrl) {
    if (artworkUrl == null || artworkUrl.trim().isEmpty) return null;

    var formatted = artworkUrl.trim();
    if (formatted.startsWith('http://')) {
      formatted = formatted.replaceFirst('http://', 'https://');
    }

    // Replace low-res thumbnail dimensions with high-res
    formatted = formatted
        .replaceAll(RegExp(r'(50x50|150x150|250x250|350x350)'), '500x500')
        .replaceAll(RegExp(r'(hqdefault|mqdefault|sddefault)\.jpg'), 'maxresdefault.jpg');
    return formatted;
  }

  /// Standardizes and cleans HTML entities in titles and artist names (e.g. &amp;, &quot;, &#039;)
  static String cleanHtmlEntities(String text) {
    if (text.isEmpty) return text;

    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Strips promotional prefixes or suffixes (e.g. "(From 'Movie')", "[Official Video]", "(Audio)")
  static String cleanTrackTitle(String title) {
    var cleaned = cleanHtmlEntities(title);
    
    // Remove brackets with video/audio promotional noise
    cleaned = cleaned
        .replaceAll(RegExp(r'\[(Official\s*(Music\s*)?Video|Audio|HD|4K|Lyric\s*Video|Full\s*Song)\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\((Official\s*(Music\s*)?Video|Audio|HD|4K|Lyric\s*Video|Full\s*Song)\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned;
  }

  /// Cleans artist biographies, descriptions, and lyrics by removing HTML tags, decoding entities, and unescaping slash sequences
  static String cleanBioText(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    var text = raw.trim();

    // 1. Unescape escaped slashes and control characters from JSON responses (e.g. \" -> ", \n -> newline)
    text = text
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\/', '/')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', ' ');

    // 2. Replace HTML break/paragraph tags with newlines
    text = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<p\s*>', caseSensitive: false), '');

    // 3. Strip all remaining HTML tags (e.g. <b>, <i>, <a>, <span>)
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 4. Decode all standard and numeric HTML entities
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™');

    // Decode hex numeric entities (e.g. &#x27; -> ')
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final hex = match.group(1);
      if (hex != null) {
        final code = int.tryParse(hex, radix: 16);
        if (code != null) return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });

    // Decode decimal numeric entities (e.g. &#39; -> ')
    text = text.replaceAllMapped(RegExp(r'&#([0-9]+);'), (match) {
      final dec = match.group(1);
      if (dec != null) {
        final code = int.tryParse(dec);
        if (code != null) return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });

    // 5. Normalize consecutive line breaks and whitespace
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    return text.trim();
  }
}
