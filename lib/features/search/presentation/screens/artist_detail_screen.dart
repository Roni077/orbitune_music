import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/error_view.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/core/widgets/section_header.dart';
import 'package:orbitune/features/discovery/presentation/widgets/song_card_horizontal.dart';
import 'package:orbitune/features/search/presentation/providers/artist_detail_provider.dart';
import 'package:orbitune/features/search/presentation/screens/album_detail_screen.dart';
import 'package:orbitune/features/search/presentation/widgets/track_tile.dart';
import 'package:share_plus/share_plus.dart';

/// Artist Profile & Discography Screen with high-res banner, top tracks, albums, singles, and Artist Radio
class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;
  final String? artistName;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    this.artistName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistState = ref.watch(artistDetailProvider(artistId));
    final artistNotifier = ref.read(artistDetailProvider(artistId).notifier);
    final artist = artistState.artist;

    final displayName = artist?.name ?? artistName ?? 'Artist Profile';
    final bannerImage = artist?.bannerUrl ?? artist?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Hero SliverAppBar with Backdrop Banner
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: AppColors.darkSurface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, size: 20, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.share2, size: 18, color: Colors.white),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Share.share('Check out $displayName on Orbitune!');
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Text(
                displayName,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image
                  if (bannerImage != null)
                    ImageShimmer(
                      imageUrl: bannerImage,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
                    Container(
                      color: AppColors.darkSurfaceVariant,
                      child: const Center(
                        child: Icon(LucideIcons.user, size: 64, color: AppColors.textMuted),
                      ),
                    ),

                  // Dark Gradients for typography contrast
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x880B0B14),
                          AppColors.darkBackground,
                        ],
                        stops: [0.3, 0.7, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Artist Details & Action Bar (Play All, Shuffle, Follow, Radio)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listeners Count & Verified Badge
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.badgeCheck,
                        size: 16,
                        color: AppColors.accentCyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Artist',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (artist != null && artist.fansCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•  ${Formatters.formatPlayCount(artist.fansCount)} monthly listeners',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Play All Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            artistNotifier.playAll();
                          },
                          icon: const Icon(LucideIcons.play, size: 18, color: Colors.black),
                          label: const Text('Play All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppConstants.roundedPill,
                            ),
                            textStyle: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Shuffle Button
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          artistNotifier.shuffleAll();
                        },
                        icon: const Icon(LucideIcons.shuffle, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkSurfaceVariant,
                          foregroundColor: Colors.white,
                        ),
                        tooltip: 'Shuffle Artist',
                      ),
                      const SizedBox(width: 8),

                      // Follow Artist Button
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          artistNotifier.toggleFollow();
                        },
                        icon: Icon(
                          artistState.isFollowed ? LucideIcons.heartCrack : LucideIcons.heart,
                          size: 18,
                          color: artistState.isFollowed ? const Color(0xFFFF4D6D) : Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkSurfaceVariant,
                        ),
                        tooltip: artistState.isFollowed ? 'Unfollow' : 'Follow',
                      ),
                      const SizedBox(width: 8),

                      // Artist Radio
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          artistNotifier.startArtistRadio();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Starting $displayName Radio...'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.darkSurfaceVariant,
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.radio, size: 18, color: AppColors.accentCyan),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkSurfaceVariant,
                        ),
                        tooltip: 'Artist Radio',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Body: Loading Shimmer, Error or Content
          if (artistState.isLoading) ...[
            const SliverToBoxAdapter(
              child: _ArtistShimmerLoader(),
            ),
          ] else if (artistState.errorMessage != null && (artist == null || artist.topTracks.isEmpty)) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: ErrorView(
                  message: artistState.errorMessage!,
                  onRetry: () => artistNotifier.loadArtistDetails(isRefresh: true),
                ),
              ),
            ),
          ] else if (artist != null) ...[
            // 3. Top Tracks Section
            if (artist.topTracks.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: SectionHeader(
                    title: 'Popular Tracks',
                    subtitle: 'Most streamed songs',
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = artist.topTracks[index];
                    return TrackTile(
                      track: track,
                      index: index + 1,
                      showIndex: true,
                    );
                  },
                  childCount: artist.topTracks.length,
                ),
              ),
            ],

            // 4. Albums & Discography Section
            if (artist.albums.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                  child: SectionHeader(
                    title: 'Albums & EPs',
                    subtitle: 'Full discography',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 205,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: artist.albums.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final album = artist.albums[index];
                      return SongCardHorizontal(
                        title: album.title,
                        subtitle: album.releaseYear ?? 'Album',
                        artworkUrl: album.bestArtworkUrl,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: album.id,
                                albumTitle: album.title,
                              ),
                            ),
                          );
                        },
                        onPlayTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: album.id,
                                albumTitle: album.title,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],

            // 5. Singles & Features Section (if available)
            if (artist.singles.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                  child: SectionHeader(
                    title: 'Singles & Features',
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final single = artist.singles[index];
                    return TrackTile(
                      track: single,
                      index: index + 1,
                      showIndex: true,
                    );
                  },
                  childCount: artist.singles.length,
                ),
              ),
            ],

            // 6. About / Biography Card
            if (artist.bio != null && artist.bio!.trim().isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: SectionHeader(
                    title: 'About',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
                    borderRadius: AppConstants.roundedLarge,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(
                    artist.bio!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            // Bottom Spacing for floating player & navigation
            const SliverToBoxAdapter(
              child: SizedBox(height: 130),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loader for artist profile
class _ArtistShimmerLoader extends StatelessWidget {
  const _ArtistShimmerLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const ImageShimmer(height: 16, width: 140),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppConstants.roundedSmall,
                    child: const ImageShimmer(height: 48, width: 48),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const ImageShimmer(height: 14, width: 160),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const ImageShimmer(height: 10, width: 90),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
