import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';

/// State for Album Detail Screen
class AlbumDetailState {
  final String albumId;
  final AlbumModel? album;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFavorite;
  final String? errorMessage;

  const AlbumDetailState({
    required this.albumId,
    this.album,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isFavorite = false,
    this.errorMessage,
  });

  /// Total duration of all tracks in the album
  Duration get totalDuration {
    if (album == null || album!.songs.isEmpty) return Duration.zero;
    return album!.songs.fold<Duration>(
      Duration.zero,
      (prev, t) => prev + t.duration,
    );
  }

  AlbumDetailState copyWith({
    String? albumId,
    AlbumModel? album,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFavorite,
    String? errorMessage,
  }) {
    return AlbumDetailState(
      albumId: albumId ?? this.albumId,
      album: album ?? this.album,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFavorite: isFavorite ?? this.isFavorite,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier managing album details, full tracklist, and playback
class AlbumDetailNotifier extends StateNotifier<AlbumDetailState> {
  final String albumId;
  final SearchRepository _searchRepository;
  final Ref _ref;

  AlbumDetailNotifier(
    this._searchRepository,
    this._ref, {
    required this.albumId,
    AlbumModel? initialAlbum,
  }) : super(AlbumDetailState(
          albumId: albumId,
          album: initialAlbum,
          isLoading: initialAlbum == null || initialAlbum.songs.isEmpty,
          isFavorite: initialAlbum?.isFavorite ?? false,
        )) {
    loadAlbumDetails();
  }

  Future<void> loadAlbumDetails({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else if (state.album == null || state.album!.songs.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final fetched = await _searchRepository.getAlbumDetails(albumId);
      if (fetched != null) {
        state = state.copyWith(
          album: fetched,
          isLoading: false,
          isRefreshing: false,
          isFavorite: fetched.isFavorite,
          errorMessage: null,
        );
      } else {
        if (state.album != null) {
          state = state.copyWith(isLoading: false, isRefreshing: false);
        } else {
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: 'Album information unavailable.',
          );
        }
      }
    } catch (e, st) {
      debugPrint('[AlbumDetailNotifier] error loading album $albumId: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: state.album != null ? null : 'Failed to load album tracks.',
      );
    }
  }

  /// Toggles favorite status of the album
  void toggleFavorite() {
    final nextStatus = !state.isFavorite;
    state = state.copyWith(
      isFavorite: nextStatus,
      album: state.album?.copyWith(isFavorite: nextStatus),
    );
  }

  /// Plays all songs in album starting from track 1
  void playAll() {
    final album = state.album;
    if (album != null && album.songs.isNotEmpty) {
      _ref.read(queueProvider.notifier).playPlaylist(
            album.songs,
            queueTitle: album.title,
          );
    }
  }

  /// Shuffles all songs in album and begins playback
  void shuffleAll() {
    final album = state.album;
    if (album != null && album.songs.isNotEmpty) {
      final shuffled = List.of(album.songs)..shuffle();
      _ref.read(queueProvider.notifier).playPlaylist(
            shuffled,
            queueTitle: '${album.title} (Shuffled)',
          );
    }
  }

  /// Plays a specific track within the album and queues the rest
  void playTrackAtIndex(int index) {
    final album = state.album;
    if (album != null && index >= 0 && index < album.songs.length) {
      // Play whole album queue and jump to this index
      _ref.read(queueProvider.notifier).playPlaylist(
            album.songs,
            initialIndex: index,
            queueTitle: album.title,
          );
    }
  }

  /// Adds all album tracks to the current Up Next queue
  void addAllToQueue() {
    final album = state.album;
    if (album != null && album.songs.isNotEmpty) {
      for (final song in album.songs) {
        _ref.read(queueProvider.notifier).addToQueue(song);
      }
    }
  }
}

/// Family provider for AlbumDetail
final albumDetailProvider = StateNotifierProvider.family<AlbumDetailNotifier, AlbumDetailState, String>(
  (ref, albumId) {
    final searchRepo = ref.watch(searchRepositoryProvider);
    return AlbumDetailNotifier(
      searchRepo,
      ref,
      albumId: albumId,
    );
  },
);
