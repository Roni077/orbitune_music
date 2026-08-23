import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/core/utils/lrc_parser.dart';
import 'package:orbitune/features/lyrics/data/lyrics_repository.dart';
import 'package:orbitune/features/lyrics/domain/models/lyric_line.dart';

/// State representation for synchronized and plain lyrics viewer
@immutable
class LyricsState {
  final bool isLoading;
  final String? trackId;
  final List<LyricLine> lines;
  final String? plainLyrics;
  final int activeLineIndex;
  final bool isSynced;
  final double fontSize;
  final bool isAutoScrollEnabled;
  final String? errorMessage;

  const LyricsState({
    this.isLoading = false,
    this.trackId,
    this.lines = const [],
    this.plainLyrics,
    this.activeLineIndex = 0,
    this.isSynced = false,
    this.fontSize = 20.0,
    this.isAutoScrollEnabled = true,
    this.errorMessage,
  });

  bool get hasLyrics => lines.isNotEmpty || (plainLyrics != null && plainLyrics!.isNotEmpty);

  LyricsState copyWith({
    bool? isLoading,
    String? trackId,
    List<LyricLine>? lines,
    String? plainLyrics,
    int? activeLineIndex,
    bool? isSynced,
    double? fontSize,
    bool? isAutoScrollEnabled,
    String? errorMessage,
  }) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      trackId: trackId ?? this.trackId,
      lines: lines ?? this.lines,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      activeLineIndex: activeLineIndex ?? this.activeLineIndex,
      isSynced: isSynced ?? this.isSynced,
      fontSize: fontSize ?? this.fontSize,
      isAutoScrollEnabled: isAutoScrollEnabled ?? this.isAutoScrollEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for synchronized lyrics state
final lyricsProvider =
    StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  final repo = ref.watch(lyricsRepositoryProvider);
  return LyricsNotifier(ref, repo);
});

/// StateNotifier synchronizing lyrics with active track and audio position
class LyricsNotifier extends StateNotifier<LyricsState> {
  final Ref _ref;
  final LyricsRepository _lyricsRepository;
  ProviderSubscription<Track?>? _trackSub;
  ProviderSubscription<Duration>? _positionSub;

  LyricsNotifier(this._ref, this._lyricsRepository)
      : super(const LyricsState()) {
    _initListeners();
  }

  void _initListeners() {
    // Listen to current track changes
    _trackSub = _ref.listen<Track?>(currentTrackProvider, (previous, next) {
      if (next != null && next.id != state.trackId) {
        loadLyricsForTrack(next);
      }
    });

    // Listen directly to position ticks to update activeLineIndex
    _positionSub = _ref.listen<Duration>(playerPositionProvider, (previous, next) {
      if (state.lines.isEmpty || !state.isSynced) return;
      _updateActiveLine(next);
    });

    // Load initial track if already playing
    final initialTrack = _ref.read(currentTrackProvider);
    if (initialTrack != null) {
      loadLyricsForTrack(initialTrack);
    }
  }

  /// Loads synchronized or plain lyrics for [track]
  Future<void> loadLyricsForTrack(Track track) async {
    state = state.copyWith(
      isLoading: true,
      trackId: track.id,
      lines: const [],
      plainLyrics: null,
      activeLineIndex: 0,
      isSynced: false,
      errorMessage: null,
    );

    try {
      final syncedLines = await _lyricsRepository.getSyncedLyrics(track);

      if (syncedLines.isNotEmpty) {
        // If lines have distinct timestamps > 0, consider it synced
        final hasTimestamps = syncedLines.length > 1 ||
            (syncedLines.isNotEmpty && syncedLines.first.timestamp > Duration.zero);

        state = state.copyWith(
          isLoading: false,
          lines: syncedLines,
          isSynced: hasTimestamps,
          plainLyrics: syncedLines.map((l) => l.text).join('\n'),
        );
        _updateActiveLine(_ref.read(playerPositionProvider));
        return;
      }

      // Fallback: try plain lyrics
      final plain = await _lyricsRepository.getPlainLyrics(track);
      state = state.copyWith(
        isLoading: false,
        plainLyrics: plain,
        isSynced: false,
        lines: const [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load lyrics: $e',
      );
    }
  }

  /// Calculates which lyric line corresponds to the active [position] (O(1) fast path + O(log N) binary search)
  void _updateActiveLine(Duration position) {
    if (state.lines.isEmpty) return;

    // O(1) Fast Path: check if playback is still inside active line's interval
    final currentIndex = state.activeLineIndex;
    if (currentIndex >= 0 && currentIndex < state.lines.length) {
      final currentStart = state.lines[currentIndex].timestamp;
      final nextStart = (currentIndex + 1 < state.lines.length)
          ? state.lines[currentIndex + 1].timestamp
          : const Duration(hours: 99);

      if (position >= currentStart && position < nextStart) {
        return; // Fast path: unchanged line, 0ms execution
      }
    }

    // O(log N) Binary Search Fallback on song seek or skip
    final newIndex = LrcParser.getActiveLineIndex(state.lines, position);
    final safeIndex = newIndex >= 0 ? newIndex : 0;

    if (safeIndex != state.activeLineIndex) {
      state = state.copyWith(activeLineIndex: safeIndex);
    }
  }

  /// Seeks playback to the timestamp of [lineIndex] and re-enables auto-scroll
  Future<void> seekToLine(int lineIndex) async {
    if (lineIndex < 0 || lineIndex >= state.lines.length) return;
    final line = state.lines[lineIndex];
    state = state.copyWith(
      activeLineIndex: lineIndex,
      isAutoScrollEnabled: true,
    );
    await _ref.read(playerProvider.notifier).seek(line.timestamp);
  }

  /// Adjusts lyric text font size (14.0 to 32.0)
  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(14.0, 32.0));
  }

  /// Pauses auto-scrolling when user manually scrolls through lyrics
  void pauseAutoScroll() {
    if (state.isAutoScrollEnabled) {
      state = state.copyWith(isAutoScrollEnabled: false);
    }
  }

  /// Resumes auto-scrolling to keep active line centered
  void resumeAutoScroll() {
    if (!state.isAutoScrollEnabled) {
      state = state.copyWith(isAutoScrollEnabled: true);
    }
  }

  /// Toggles auto-scroll mode
  void toggleAutoScroll() {
    state = state.copyWith(isAutoScrollEnabled: !state.isAutoScrollEnabled);
  }

  /// Re-fetches lyrics directly
  Future<void> refreshLyrics() async {
    final currentTrack = _ref.read(currentTrackProvider);
    if (currentTrack != null) {
      await loadLyricsForTrack(currentTrack);
    }
  }

  @override
  void dispose() {
    _trackSub?.close();
    _positionSub?.close();
    super.dispose();
  }
}
