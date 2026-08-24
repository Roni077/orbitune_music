import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/features/audio_player/data/player_repository.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/search/data/search_repository.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';

/// State for Artist Detail Screen
class ArtistDetailState {
  final String artistId;
  final ArtistModel? artist;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFollowed;
  final String? errorMessage;

  const ArtistDetailState({
    required this.artistId,
    this.artist,
    this.isLoading = true,
    this.isRefreshing = false,
    this.isFollowed = false,
    this.errorMessage,
  });

  ArtistDetailState copyWith({
    String? artistId,
    ArtistModel? artist,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFollowed,
    String? errorMessage,
  }) {
    return ArtistDetailState(
      artistId: artistId ?? this.artistId,
      artist: artist ?? this.artist,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFollowed: isFollowed ?? this.isFollowed,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier managing artist profile, discography, and radio actions
class ArtistDetailNotifier extends StateNotifier<ArtistDetailState> {
  final String artistId;
  final SearchRepository _searchRepository;
  final Ref _ref;

  ArtistDetailNotifier(
    this._searchRepository,
    this._ref, {
    required this.artistId,
    ArtistModel? initialArtist,
  }) : super(ArtistDetailState(
          artistId: artistId,
          artist: initialArtist,
          isLoading: initialArtist == null || initialArtist.topTracks.isEmpty,
          isFollowed: initialArtist?.isFollowed ?? false,
        )) {
    loadArtistDetails();
  }

  Future<void> loadArtistDetails({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else if (state.artist == null || state.artist!.topTracks.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final fetched = await _searchRepository.getArtistDetails(artistId);
      if (fetched != null) {
        state = state.copyWith(
          artist: fetched,
          isLoading: false,
          isRefreshing: false,
          isFollowed: fetched.isFollowed,
          errorMessage: null,
        );

        // Preload first 3 top tracks of the artist for instant 0ms playback on tap
        if (fetched.topTracks.isNotEmpty) {
          _ref.read(playerRepositoryProvider).preloadUpcomingTracks(fetched.topTracks, -1, lookahead: 3);
        }
      } else {
        // If fetch returned null but we had initial partial artist
        if (state.artist != null) {
          state = state.copyWith(isLoading: false, isRefreshing: false);
        } else {
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: 'Artist information unavailable.',
          );
        }
      }
    } catch (e, st) {
      debugPrint('[ArtistDetailNotifier] error loading artist $artistId: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: state.artist != null ? null : 'Failed to load artist profile.',
      );
    }
  }

  /// Toggles follow status
  void toggleFollow() {
    final nextStatus = !state.isFollowed;
    state = state.copyWith(
      isFollowed: nextStatus,
      artist: state.artist?.copyWith(isFollowed: nextStatus),
    );
  }

  /// Plays all top songs of artist
  void playAll() {
    final artist = state.artist;
    if (artist != null && artist.topTracks.isNotEmpty) {
      _ref.read(queueProvider.notifier).playPlaylist(
            artist.topTracks,
            queueTitle: '${artist.name} - Top Tracks',
          );
    }
  }

  /// Shuffles and plays all top songs
  void shuffleAll() {
    final artist = state.artist;
    if (artist != null && artist.topTracks.isNotEmpty) {
      final shuffled = List.of(artist.topTracks)..shuffle();
      _ref.read(queueProvider.notifier).playPlaylist(
            shuffled,
            queueTitle: '${artist.name} (Shuffled)',
          );
    }
  }

  /// Launches endless Artist Radio based on artist's tracks & recommendations
  Future<void> startArtistRadio() async {
    final artist = state.artist;
    if (artist == null) return;

    if (artist.topTracks.isNotEmpty) {
      final seedTrack = artist.topTracks.first;
      // Start playback with seed track
      await _ref.read(queueProvider.notifier).playTrack(seedTrack);

      // Fetch related recommendations to queue
      try {
        final recos = await _searchRepository.getRecommendations(seedTrack);
        if (recos.isNotEmpty) {
          for (final track in recos) {
            if (track.id != seedTrack.id) {
              _ref.read(queueProvider.notifier).addToQueue(track);
            }
          }
        }
      } catch (e) {
        debugPrint('[ArtistDetailNotifier] startArtistRadio reco error: $e');
      }
    }
  }
}

/// Family provider for ArtistDetail
final artistDetailProvider = StateNotifierProvider.family<ArtistDetailNotifier, ArtistDetailState, String>(
  (ref, artistId) {
    final searchRepo = ref.watch(searchRepositoryProvider);
    return ArtistDetailNotifier(
      searchRepo,
      ref,
      artistId: artistId,
    );
  },
);
