import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/search/domain/models/album_model.dart';
import 'package:orbitune/features/search/domain/models/artist_model.dart';
import 'package:orbitune/features/search/domain/models/playlist_model.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';
import 'package:orbitune/features/search/presentation/screens/playlist_detail_screen.dart';

/// Top match Hero Card displayed when "All / Top Results" is selected
class TopResultHeroCard extends ConsumerWidget {
  final dynamic item; // Track | ArtistModel | AlbumModel

  const TopResultHeroCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item is Track) {
      final track = item as Track;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E1E38),
              Color(0xFF14142B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppConstants.roundedLarge,
          border: Border.all(
            color: AppColors.accentGreen.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppConstants.roundedMedium,
              child: ImageShimmer(
                imageUrl: track.bestArtworkUrl,
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TOP MATCH',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    track.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Song • ${track.artist}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.play,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(queueProvider.notifier).playTrack(track);
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// M3 Expressive Card for Artist Search Results
class ArtistSearchCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback? onTap;

  const ArtistSearchCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = artist.avatarUrl ?? artist.bannerUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedMedium,
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArtistDetailScreen(
                  artistId: artist.id,
                  artistName: artist.name,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              ClipOval(
                child: ImageShimmer(
                  imageUrl: avatar,
                  width: 56,
                  height: 56,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      artist.fansCount > 0
                          ? 'Artist • ${Formatters.formatPlayCount(artist.fansCount)} listeners'
                          : 'Artist',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// M3 Expressive Card for Album Search Results
class AlbumSearchCard extends ConsumerWidget {
  final AlbumModel album;
  final VoidCallback? onTap;

  const AlbumSearchCard({
    super.key,
    required this.album,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedMedium,
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(
                  albumId: album.id,
                  albumTitle: album.title,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppConstants.roundedSmall,
                child: ImageShimmer(
                  imageUrl: album.bestArtworkUrl,
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Album • ${album.artist}${album.releaseYear != null ? " • ${album.releaseYear}" : ""}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.play,
                  size: 18,
                  color: AppColors.accentGreen,
                ),
                splashRadius: 20,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  if (album.songs.isNotEmpty) {
                    ref.read(queueProvider.notifier).playPlaylist(
                          album.songs,
                          queueTitle: album.title,
                        );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(
                          albumId: album.id,
                          albumTitle: album.title,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// M3 Expressive Card for Playlist Search Results
class PlaylistSearchCard extends ConsumerWidget {
  final PlaylistModel playlist;
  final VoidCallback? onTap;

  const PlaylistSearchCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.roundedMedium,
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(
                  playlistId: playlist.id,
                  playlistTitle: playlist.title,
                  source: playlist.source,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppConstants.roundedSmall,
                child: ImageShimmer(
                  imageUrl: playlist.bestArtworkUrl,
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Playlist • ${playlist.author ?? "${playlist.trackCount} songs"}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
