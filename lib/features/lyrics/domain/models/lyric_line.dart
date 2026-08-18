import 'dart:convert';

/// Single word token with timestamp for word-by-word karaoke highlighting
class LyricWord {
  final Duration timestamp;
  final String text;

  LyricWord({required this.timestamp, required this.text});

  Map<String, dynamic> toMap() => {
        'timeMs': timestamp.inMilliseconds,
        'text': text,
      };

  factory LyricWord.fromMap(Map<dynamic, dynamic> map) => LyricWord(
        timestamp: Duration(milliseconds: (map['timeMs'] as num?)?.toInt() ?? 0),
        text: map['text']?.toString() ?? '',
      );
}

/// Single line in synchronized LRC lyrics
class LyricLine {
  final Duration timestamp;
  final String text;
  final List<LyricWord> words;

  LyricLine({
    required this.timestamp,
    required this.text,
    this.words = const [],
  });

  LyricLine copyWith({
    Duration? timestamp,
    String? text,
    List<LyricWord>? words,
  }) {
    return LyricLine(
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      words: words ?? this.words,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timeMs': timestamp.inMilliseconds,
      'text': text,
      'words': words.map((w) => w.toMap()).toList(),
    };
  }

  factory LyricLine.fromMap(Map<dynamic, dynamic> map) {
    return LyricLine(
      timestamp: Duration(milliseconds: (map['timeMs'] as num?)?.toInt() ?? 0),
      text: map['text']?.toString() ?? '',
      words: map['words'] != null
          ? (map['words'] as List)
              .map((w) => LyricWord.fromMap(w as Map<dynamic, dynamic>))
              .toList()
          : const [],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LyricLine.fromJson(String source) =>
      LyricLine.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => Object.hash(timestamp, text);

  @override
  String toString() =>
      '[${timestamp.inMinutes.remainder(60).toString().padLeft(2, '0')}:${timestamp.inSeconds.remainder(60).toString().padLeft(2, '0')}.${(timestamp.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0')}] $text';
}
