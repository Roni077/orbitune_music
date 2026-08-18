/// Playback repeat and shuffle modes
enum PlaybackMode {
  off('Off', 'Repeat Off'),
  repeatAll('Repeat All', 'Repeating Queue'),
  repeatOne('Repeat One', 'Repeating Current Track'),
  shuffle('Shuffle', 'Shuffle Queue');

  final String label;
  final String description;

  const PlaybackMode(this.label, this.description);

  bool get isRepeatAll => this == PlaybackMode.repeatAll;
  bool get isRepeatOne => this == PlaybackMode.repeatOne;
  bool get isShuffle => this == PlaybackMode.shuffle;
  bool get isOff => this == PlaybackMode.off;

  /// Cycle through standard repeat loop: off -> repeatAll -> repeatOne -> off
  PlaybackMode nextRepeatMode() {
    switch (this) {
      case PlaybackMode.off:
        return PlaybackMode.repeatAll;
      case PlaybackMode.repeatAll:
        return PlaybackMode.repeatOne;
      case PlaybackMode.repeatOne:
      case PlaybackMode.shuffle:
        return PlaybackMode.off;
    }
  }

  static PlaybackMode fromString(String? value) {
    if (value == null) return PlaybackMode.off;
    return PlaybackMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => PlaybackMode.off,
    );
  }

  String toJson() => name;
}
