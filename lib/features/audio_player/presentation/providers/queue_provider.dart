import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/services/hive_service.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_mode.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/domain/models/queue_item.dart';
import 'package:orbitune/features/audio_player/data/player_repository.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/library/data/library_repository.dart';
import 'package:orbitune/features/library/domain/models/user_playlist.dart';
import 'package:orbitune/features/library/presentation/providers/user_playlists_provider.dart';
import 'package:orbitune/features/search/data/search_repository.dart';

/// Immutable snapshot representing the active playback queue
class QueueState {
  final List<QueueItem> items;
  final int currentIndex;
  final bool isAutoplayEnabled;
  final bool isLoadingAutoplay;
  final String? queueTitle;
  final List<Track> history;

  const QueueState({
    this.items = const [],
    this.currentIndex = -1,
    this.isAutoplayEnabled = true,
    this.isLoadingAutoplay = false,
    this.queueTitle,
    this.history = const [],
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  /// Currently playing QueueItem or null if queue is empty
  QueueItem? get currentItem =>
      (currentIndex >= 0 && currentIndex < items.length)
          ? items[currentIndex]
          : null;

  /// Currently playing Track or null
  Track? get currentTrack => currentItem?.track;

  /// History of played items in this queue before current track
  List<QueueItem> get previousItems =>
      (currentIndex > 0 && currentIndex <= items.length)
          ? items.sublist(0, currentIndex)
          : const [];

  /// Upcoming items to be played next
  List<QueueItem> get upcomingItems =>
      (currentIndex >= 0 && currentIndex < items.length - 1)
          ? items.sublist(currentIndex + 1)
          : const [];

  /// Count of upcoming tracks
  int get upcomingCount => upcomingItems.length;

  /// Total duration of upcoming tracks
  Duration get totalRemainingDuration => upcomingItems.fold(
        Duration.zero,
        (prev, item) => prev + item.track.duration,
      );

  /// Has next track available in queue
  bool get hasNext => currentIndex >= 0 && currentIndex < items.length - 1;

  /// Has previous track available in queue
  bool get hasPrevious => currentIndex > 0;

  QueueState copyWith({
    List<QueueItem>? items,
    int? currentIndex,
    bool? isAutoplayEnabled,
    bool? isLoadingAutoplay,
    String? queueTitle,
    List<Track>? history,
  }) {
    return QueueState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isAutoplayEnabled: isAutoplayEnabled ?? this.isAutoplayEnabled,
      isLoadingAutoplay: isLoadingAutoplay ?? this.isLoadingAutoplay,
      queueTitle: queueTitle ?? this.queueTitle,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((i) => i.toMap()).toList(),
      'currentIndex': currentIndex,
      'isAutoplayEnabled': isAutoplayEnabled,
      'queueTitle': queueTitle,
    };
  }

  factory QueueState.fromMap(Map<dynamic, dynamic> map) {
    final rawItems = map['items'] as List?;
    final items = rawItems != null
        ? rawItems
            .map((item) => QueueItem.fromMap(item as Map<dynamic, dynamic>))
            .toList()
        : <QueueItem>[];

    return QueueState(
      items: items,
      currentIndex: (map['currentIndex'] as num?)?.toInt() ?? -1,
      isAutoplayEnabled: map['isAutoplayEnabled'] != false,
      queueTitle: map['queueTitle']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QueueState.fromJson(String source) =>
      QueueState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Riverpod provider for QueueNotifier
final queueProvider =
    StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  final playerRepo = ref.watch(playerRepositoryProvider);
  final searchRepo = ref.watch(searchRepositoryProvider);
  final libraryRepo = ref.watch(libraryRepositoryProvider);

  return QueueNotifier(
    ref,
    playerRepo,
    searchRepo,
    libraryRepo,
  );
});

/// Selector providers for UI performance & clean reactive rebuilding
final queueItemsProvider = Provider<List<QueueItem>>((ref) {
  return ref.watch(queueProvider.select((s) => s.items));
});

final upcomingQueueProvider = Provider<List<QueueItem>>((ref) {
  return ref.watch(queueProvider.select((s) => s.upcomingItems));
});

final queueCountProvider = Provider<int>((ref) {
  return ref.watch(queueProvider.select((s) => s.length));
});

final upcomingCountProvider = Provider<int>((ref) {
  return ref.watch(queueProvider.select((s) => s.upcomingCount));
});

final queueTitleProvider = Provider<String?>((ref) {
  return ref.watch(queueProvider.select((s) => s.queueTitle));
});

final isAutoplayProvider = Provider<bool>((ref) {
  return ref.watch(queueProvider.select((s) => s.isAutoplayEnabled));
});

final queueRemainingDurationProvider = Provider<Duration>((ref) {
  return ref.watch(queueProvider.select((s) => s.totalRemainingDuration));
});

/// StateNotifier managing dynamic audio queue actions, autoplay, reordering, and playlists
class QueueNotifier extends StateNotifier<QueueState> {
  final Ref _ref;
  final PlayerRepository _playerRepository;
  final SearchRepository _searchRepository;
  final LibraryRepository _libraryRepository;

  static const String _queuePersistenceKey = 'active_audio_queue';
  StreamSubscription<PlayerStateSnapshot>? _playerStateSub;
  bool _isAutoAdvancing = false;

  QueueNotifier(
    this._ref,
    this._playerRepository,
    this._searchRepository,
    this._libraryRepository,
  ) : super(const QueueState()) {
    _restoreQueue();
    _listenToPlayback();
    _bindMediaControlHooks();
  }

  void _bindMediaControlHooks() {
    _playerRepository.setControlHooks(
      onSkipToNext: () => next(),
      onSkipToPrevious: () => previous(),
    );
  }

  void _listenToPlayback() {
    _playerStateSub = _ref
        .read(playerProvider.notifier)
        .stream
        .listen((playerState) {
      if (playerState.status == PlaybackStatus.completed) {
        _handleTrackCompleted();
      }
    });
  }

  /// Automatically handles advancing to the next track when current one finishes
  Future<void> _handleTrackCompleted() async {
    if (!mounted || _isAutoAdvancing) return;
    _isAutoAdvancing = true;

    try {
      final mode = _ref.read(playbackModeProvider);
      if (mode == PlaybackMode.repeatOne) {
        // Replay current track from beginning
        await _ref.read(playerProvider.notifier).seek(Duration.zero);
        await _ref.read(playerProvider.notifier).resume();
        return;
      }

      if (!mounted) return;
      if (state.hasNext) {
        await next();
      } else if (mode == PlaybackMode.repeatAll && state.items.isNotEmpty) {
        // Loop back to start of queue
        await skipToQueueIndex(0);
      } else if (state.isAutoplayEnabled) {
        // Fetch recommendations and play next
        await _fetchAndPlayAutoplayNext();
      }
    } finally {
      _isAutoAdvancing = false;
    }
  }

  /// Plays a single [track] and initializes or updates queue
  Future<void> playTrack(
    Track track, {
    List<Track>? queueContext,
    int initialIndex = 0,
    String? queueTitle,
  }) async {
    final contextTracks = queueContext ?? [track];
    final safeInitialIndex = queueContext != null
        ? initialIndex.clamp(0, contextTracks.length - 1)
        : 0;

    final queueItems = <QueueItem>[];
    for (int i = 0; i < contextTracks.length; i++) {
      final t = contextTracks[i];
      final isFav = _libraryRepository.isFavorite(t.id);
      queueItems.add(QueueItem.fromTrack(
        t.copyWith(isFavorite: isFav),
        sourceContext: queueTitle,
      ));
    }

    state = state.copyWith(
      items: queueItems,
      currentIndex: safeInitialIndex,
      queueTitle: queueTitle ?? (queueContext != null ? 'Playlist' : 'Now Playing'),
    );

    _persistQueue();

    final activeTrack = queueItems[safeInitialIndex].track;
    await _ref.read(playerProvider.notifier).playTrack(activeTrack);

    // Predictive preloading for upcoming tracks (Lookahead = 3)
    _ref.read(playerRepositoryProvider).preloadUpcomingTracks(
      queueItems.map((i) => i.track).toList(),
      safeInitialIndex,
    );

    // Pre-fetch autoplay if near queue end
    if (state.upcomingItems.length <= 1 && state.isAutoplayEnabled) {
      unawaited(_fetchAutoplayRecommendations());
    }
  }

  /// Plays an entire playlist sequence and replaces the current queue
  Future<void> playPlaylist(
    List<Track> tracks, {
    int initialIndex = 0,
    String? queueTitle,
  }) async {
    if (tracks.isEmpty) return;
    await playTrack(
      tracks[initialIndex.clamp(0, tracks.length - 1)],
      queueContext: tracks,
      initialIndex: initialIndex,
      queueTitle: queueTitle ?? 'Playlist',
    );
  }

  /// Adds a single track to the end of the queue
  void addToQueue(Track track, {String? sourceContext}) {
    final isFav = _libraryRepository.isFavorite(track.id);
    final newItem = QueueItem.fromTrack(
      track.copyWith(isFavorite: isFav),
      sourceContext: sourceContext,
    );

    if (state.isEmpty) {
      state = state.copyWith(
        items: [newItem],
        currentIndex: 0,
        queueTitle: sourceContext ?? 'Queue',
      );
      _ref.read(playerProvider.notifier).playTrack(newItem.track);
    } else {
      state = state.copyWith(
        items: [...state.items, newItem],
      );
    }

    _persistQueue();
  }

  /// Adds multiple tracks to the end of the queue
  void addTracksToQueue(List<Track> tracks, {String? sourceContext}) {
    if (tracks.isEmpty) return;

    final newItems = tracks.map((t) {
      final isFav = _libraryRepository.isFavorite(t.id);
      return QueueItem.fromTrack(
        t.copyWith(isFavorite: isFav),
        sourceContext: sourceContext,
      );
    }).toList();

    if (state.isEmpty) {
      state = state.copyWith(
        items: newItems,
        currentIndex: 0,
        queueTitle: sourceContext ?? 'Queue',
      );
      _ref.read(playerProvider.notifier).playTrack(newItems[0].track);
    } else {
      state = state.copyWith(
        items: [...state.items, ...newItems],
      );
    }

    _persistQueue();
  }

  /// Inserts a track to be played immediately next
  void playNext(Track track, {String? sourceContext}) {
    final isFav = _libraryRepository.isFavorite(track.id);
    final newItem = QueueItem.fromTrack(
      track.copyWith(isFavorite: isFav),
      sourceContext: sourceContext,
    );

    if (state.isEmpty) {
      state = state.copyWith(
        items: [newItem],
        currentIndex: 0,
        queueTitle: sourceContext ?? 'Queue',
      );
      _ref.read(playerProvider.notifier).playTrack(newItem.track);
    } else {
      final list = List<QueueItem>.from(state.items);
      final insertIndex = (state.currentIndex + 1).clamp(0, list.length);
      list.insert(insertIndex, newItem);
      state = state.copyWith(items: list);
    }

    _persistQueue();
  }

  /// Inserts multiple tracks immediately after the current playing track
  void playNextMultiple(List<Track> tracks, {String? sourceContext}) {
    if (tracks.isEmpty) return;

    final newItems = tracks.map((t) {
      final isFav = _libraryRepository.isFavorite(t.id);
      return QueueItem.fromTrack(
        t.copyWith(isFavorite: isFav),
        sourceContext: sourceContext,
      );
    }).toList();

    if (state.isEmpty) {
      state = state.copyWith(
        items: newItems,
        currentIndex: 0,
        queueTitle: sourceContext ?? 'Queue',
      );
      _ref.read(playerProvider.notifier).playTrack(newItems[0].track);
    } else {
      final list = List<QueueItem>.from(state.items);
      final insertIndex = (state.currentIndex + 1).clamp(0, list.length);
      list.insertAll(insertIndex, newItems);
      state = state.copyWith(items: list);
    }

    _persistQueue();
  }

  /// Removes an item at [index] from the full queue
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.items.length) return;

    final list = List<QueueItem>.from(state.items);
    final isCurrent = index == state.currentIndex;

    if (isCurrent) {
      if (state.hasNext) {
        // Skip to next, then remove old item
        final nextIndex = index + 1;
        final nextTrack = list[nextIndex].track;
        list.removeAt(index);
        state = state.copyWith(
          items: list,
          currentIndex: index, // Since next slid into current position
        );
        await _ref.read(playerProvider.notifier).playTrack(nextTrack);
      } else if (state.hasPrevious) {
        // Skip to previous
        final prevIndex = index - 1;
        final prevTrack = list[prevIndex].track;
        list.removeAt(index);
        state = state.copyWith(
          items: list,
          currentIndex: prevIndex,
        );
        await _ref.read(playerProvider.notifier).playTrack(prevTrack);
      } else {
        // Queue is now empty
        list.clear();
        state = state.copyWith(
          items: const [],
          currentIndex: -1,
        );
        await _ref.read(playerProvider.notifier).stop();
      }
    } else {
      list.removeAt(index);
      final newCurrentIndex =
          index < state.currentIndex ? state.currentIndex - 1 : state.currentIndex;
      state = state.copyWith(
        items: list,
        currentIndex: newCurrentIndex,
      );
    }

    _persistQueue();
  }

  /// Removes an item from the upcoming list by its relative [upcomingIndex]
  Future<void> removeUpcomingItem(int upcomingIndex) async {
    final actualIndex = state.currentIndex + 1 + upcomingIndex;
    await removeFromQueue(actualIndex);
  }

  /// Removes an item matching [queueId]
  Future<void> removeItemByQueueId(String queueId) async {
    final index = state.items.indexWhere((i) => i.queueId == queueId);
    if (index != -1) {
      await removeFromQueue(index);
    }
  }

  /// Reorders items in the full queue list
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length) return;

    final list = List<QueueItem>.from(state.items);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    int newCurrentIndex = state.currentIndex;
    if (oldIndex == state.currentIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex && newIndex >= state.currentIndex) {
      newCurrentIndex = state.currentIndex - 1;
    } else if (oldIndex > state.currentIndex && newIndex <= state.currentIndex) {
      newCurrentIndex = state.currentIndex + 1;
    }

    state = state.copyWith(
      items: list,
      currentIndex: newCurrentIndex,
    );

    _persistQueue();
  }

  /// Reorders items strictly within the "Up Next" section
  void reorderUpcoming(int oldUpcomingIndex, int newUpcomingIndex) {
    final baseOffset = state.currentIndex + 1;
    final actualOld = baseOffset + oldUpcomingIndex;
    final actualNew = baseOffset + newUpcomingIndex;
    reorderQueue(actualOld, actualNew);
  }

  /// Clears the queue. If [keepCurrentTrack] is true, preserves the active song.
  Future<void> clearQueue({bool keepCurrentTrack = true}) async {
    if (keepCurrentTrack && state.currentItem != null) {
      state = state.copyWith(
        items: [state.currentItem!],
        currentIndex: 0,
      );
    } else {
      state = state.copyWith(
        items: const [],
        currentIndex: -1,
      );
      await _ref.read(playerProvider.notifier).stop();
    }
    _persistQueue();
  }

  /// Clears only upcoming tracks while preserving current track and history
  void clearUpcoming() {
    if (state.currentIndex < 0) return;
    final preserved = state.items.sublist(0, state.currentIndex + 1);
    state = state.copyWith(items: preserved);
    _persistQueue();
  }

  /// Shuffles upcoming tracks randomly while preserving current track & history
  void shuffleQueue() {
    if (state.upcomingItems.isEmpty) return;

    final list = List<QueueItem>.from(state.items);
    final preserved = list.sublist(0, state.currentIndex + 1);
    final upcoming = list.sublist(state.currentIndex + 1)..shuffle(Random());

    state = state.copyWith(
      items: [...preserved, ...upcoming],
    );

    _persistQueue();
  }

  /// Shuffles all tracks in the queue, keeping the currently playing track at index 0
  void shuffleAll() {
    if (state.items.length <= 1) return;

    final current = state.currentItem;
    final others = state.items.where((i) => i.queueId != current?.queueId).toList()
      ..shuffle(Random());

    final newItems = current != null ? [current, ...others] : others;

    state = state.copyWith(
      items: newItems,
      currentIndex: current != null ? 0 : -1,
    );

    _persistQueue();
  }

  /// Skips directly to a specific [index] in the queue
  Future<void> skipToQueueIndex(int index) async {
    if (index < 0 || index >= state.items.length) return;

    // Record previous track to session history
    final historyList = List<Track>.from(state.history);
    if (state.currentTrack != null) {
      historyList.add(state.currentTrack!);
    }

    state = state.copyWith(
      currentIndex: index,
      history: historyList,
    );

    _persistQueue();

    final targetTrack = state.items[index].track;
    await _ref.read(playerProvider.notifier).playTrack(targetTrack);

    // Predictive preloading for upcoming tracks (Lookahead = 3)
    _ref.read(playerRepositoryProvider).preloadUpcomingTracks(
      state.items.map((i) => i.track).toList(),
      index,
    );

    // Pre-fetch autoplay if near queue end
    if (state.upcomingItems.length <= 1 && state.isAutoplayEnabled) {
      unawaited(_fetchAutoplayRecommendations());
    }
  }

  /// Skips to an item by its unique [queueId]
  Future<void> skipToItem(String queueId) async {
    final index = state.items.indexWhere((i) => i.queueId == queueId);
    if (index != -1) {
      await skipToQueueIndex(index);
    }
  }

  /// Advances to next track in queue or fetches AutoPlay recommendations
  Future<void> next() async {
    if (state.hasNext) {
      await skipToQueueIndex(state.currentIndex + 1);
    } else if (state.isAutoplayEnabled) {
      await _fetchAndPlayAutoplayNext();
    }
  }

  /// Skips to previous track in queue or seeks to start of current track
  Future<void> previous() async {
    final playerSnapshot = _ref.read(playerProvider);
    if (playerSnapshot.position.inSeconds > 3) {
      await _ref.read(playerProvider.notifier).seek(Duration.zero);
      return;
    }

    if (state.hasPrevious) {
      await skipToQueueIndex(state.currentIndex - 1);
    } else {
      await _ref.read(playerProvider.notifier).seek(Duration.zero);
    }
  }

  /// Toggles AutoPlay smart queue recommendations
  void toggleAutoplay() {
    setAutoplay(!state.isAutoplayEnabled);
  }

  /// Sets AutoPlay enabled status
  void setAutoplay(bool enabled) {
    state = state.copyWith(isAutoplayEnabled: enabled);
    _persistQueue();

    if (enabled && state.upcomingItems.length <= 1) {
      unawaited(_fetchAutoplayRecommendations());
    }
  }

  /// Fetches smart AutoPlay recommendations and appends them to upcoming queue
  Future<void> _fetchAutoplayRecommendations() async {
    if (!mounted || state.isLoadingAutoplay || !state.isAutoplayEnabled) return;
    final current = state.currentTrack;
    if (current == null) return;

    state = state.copyWith(isLoadingAutoplay: true);

    try {
      final recos = await _searchRepository.getRecommendations(current);
      if (!mounted) return;
      if (recos.isNotEmpty) {
        final existingIds = state.items.map((i) => i.track.id).toSet();
        final uniqueRecos = recos.where((t) => !existingIds.contains(t.id)).toList();

        if (uniqueRecos.isNotEmpty) {
          final autoplayItems = uniqueRecos.take(10).map((t) {
            final isFav = _libraryRepository.isFavorite(t.id);
            return QueueItem.fromTrack(
              t.copyWith(isFavorite: isFav),
              isAutoplay: true,
              sourceContext: 'AutoPlay • Similar to ${current.title}',
            );
          }).toList();

          if (!mounted) return;
          state = state.copyWith(
            items: [...state.items, ...autoplayItems],
            isLoadingAutoplay: false,
          );
          _persistQueue();
          return;
        }
      }
    } catch (e) {
      debugPrint('[QueueNotifier] Autoplay fetch failed: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(isLoadingAutoplay: false);
      }
    }
  }

  /// Fetches AutoPlay recommendations and immediately starts playback of the first one
  Future<void> _fetchAndPlayAutoplayNext() async {
    await _fetchAutoplayRecommendations();
    if (state.hasNext) {
      await skipToQueueIndex(state.currentIndex + 1);
    }
  }

  /// Saves all tracks in the current queue as a new [UserPlaylist]
  Future<UserPlaylist> saveQueueAsPlaylist(
    String playlistTitle, {
    String? description,
  }) async {
    final playlist = UserPlaylist(
      id: 'queue_pl_${DateTime.now().millisecondsSinceEpoch}',
      name: playlistTitle.trim().isNotEmpty ? playlistTitle.trim() : 'Queue Playlist',
      description: description ?? 'Saved from active queue on ${DateTime.now().toLocal().toString().split(' ')[0]}',
      songs: state.items.map((i) => i.track).toList(),
      artworkUrl: state.currentTrack?.bestArtworkUrl,
    );

    await _libraryRepository.saveUserPlaylist(playlist);
    _ref.invalidate(userPlaylistsProvider);
    return playlist;
  }

  /// Saves only upcoming tracks as a new [UserPlaylist]
  Future<UserPlaylist> saveUpcomingAsPlaylist(
    String playlistTitle, {
    String? description,
  }) async {
    final playlist = UserPlaylist(
      id: 'upcoming_pl_${DateTime.now().millisecondsSinceEpoch}',
      name: playlistTitle.trim().isNotEmpty ? playlistTitle.trim() : 'Upcoming Tracks',
      description: description ?? 'Saved from upcoming queue on ${DateTime.now().toLocal().toString().split(' ')[0]}',
      songs: state.upcomingItems.map((i) => i.track).toList(),
      artworkUrl: state.upcomingItems.isNotEmpty
          ? state.upcomingItems.first.track.bestArtworkUrl
          : null,
    );

    await _libraryRepository.saveUserPlaylist(playlist);
    _ref.invalidate(userPlaylistsProvider);
    return playlist;
  }

  /// Persists the active queue to local Hive storage for session restore
  void _persistQueue() {
    try {
      if (!HiveService.instance.isInitialized) return;
      final box = HiveService.instance.sessionBox;
      box.put(_queuePersistenceKey, state.toMap());
    } catch (e) {
      debugPrint('[QueueNotifier] Failed to persist queue: $e');
    }
  }

  /// Restores queue state from local storage upon app startup
  void _restoreQueue() {
    try {
      if (!HiveService.instance.isInitialized) return;
      final sessionBox = HiveService.instance.sessionBox;
      dynamic raw = sessionBox.get(_queuePersistenceKey);
      
      // Fallback check in settingsBox for backward migration
      if (raw == null) {
        final settingsBox = HiveService.instance.settingsBox;
        raw = settingsBox.get(_queuePersistenceKey);
      }

      if (raw != null && raw is Map) {
        final restored = QueueState.fromMap(raw);
        if (restored.items.isNotEmpty) {
          state = restored;
        }
      }
    } catch (e) {
      debugPrint('[QueueNotifier] Failed to restore queue: $e');
    }
  }

  @override
  void dispose() {
    _playerRepository.setControlHooks(
      onSkipToNext: null,
      onSkipToPrevious: null,
    );
    _playerStateSub?.cancel();
    super.dispose();
  }
}
