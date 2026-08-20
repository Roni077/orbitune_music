import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/audio_badge.dart';
import 'package:orbitune/core/widgets/empty_state_view.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/glass_container.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/queue_item.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';

/// Modal bottom sheet for viewing, reordering, shuffling, and managing the Up Next playback queue
class QueueSheet extends ConsumerStatefulWidget {
  const QueueSheet({super.key});

  /// Shows the QueueSheet as an expressive modal bottom sheet
  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QueueSheet(),
    );
  }

  @override
  ConsumerState<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends ConsumerState<QueueSheet> {
  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: AppConstants.roundedPill,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header with stats & actions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            child: _buildHeader(context, queueState),
          ),
          const SizedBox(height: 8),

          // Action Toolbar (Shuffle, Autoplay, Save, Clear)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            child: _buildActionToolbar(context, queueState),
          ),
          const SizedBox(height: 12),

          // Queue Content (Now Playing + Up Next Reorderable List)
          Expanded(
            child: queueState.isEmpty
                ? _buildEmptyState(context)
                : CustomScrollView(
                    slivers: [
                      // Now Playing Section
                      if (queueState.currentItem != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.horizontalPadding,
                              vertical: 6.0,
                            ),
                            child: _buildNowPlayingCard(
                              context,
                              queueState.currentItem!,
                              isPlaying,
                            ),
                          ),
                        ),

                      // Up Next Section Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppConstants.horizontalPadding,
                            16,
                            AppConstants.horizontalPadding,
                            8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'UP NEXT',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (queueState.upcomingCount > 0)
                                Text(
                                  '${queueState.upcomingCount} tracks',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Up Next Items List
                      if (queueState.upcomingItems.isEmpty)
                        SliverToBoxAdapter(
                          child: _buildUpcomingEmptyPlaceholder(context, queueState),
                        )
                      else
                        SliverToBoxAdapter(
                          child: _buildReorderableUpcomingList(context, queueState),
                        ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 48),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QueueState queueState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playing Queue',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              queueState.upcomingCount > 0
                  ? '${queueState.upcomingCount} upcoming • ${Formatters.formatDuration(queueState.totalRemainingDuration)} left'
                  : (queueState.currentItem != null ? '1 track in queue' : 'Queue is empty'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            LucideIcons.x,
            color: AppColors.textSecondary,
            size: 22,
          ),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildActionToolbar(BuildContext context, QueueState queueState) {
    return Row(
      children: [
        // Shuffle Button
        Expanded(
          child: ExpressiveCard(
            borderRadius: AppConstants.roundedMedium,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(queueProvider.notifier).shuffleQueue();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Up next queue shuffled'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.shuffle,
                  color: AppColors.accentIndigo,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Shuffle',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // AutoPlay Pill Toggle
        Expanded(
          child: ExpressiveCard(
            borderRadius: AppConstants.roundedMedium,
            color: queueState.isAutoplayEnabled
                ? AppColors.accentGreen.withValues(alpha: 0.15)
                : AppColors.darkSurface,
            borderColor: queueState.isAutoplayEnabled
                ? AppColors.accentGreen.withValues(alpha: 0.4)
                : AppColors.glassBorder,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(queueProvider.notifier).toggleAutoplay();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: queueState.isAutoplayEnabled
                      ? AppColors.accentGreen
                      : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  queueState.isAutoplayEnabled ? 'AutoPlay ON' : 'AutoPlay OFF',
                  style: TextStyle(
                    color: queueState.isAutoplayEnabled
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Save as Playlist Button
        IconButton(
          onPressed: queueState.isEmpty
              ? null
              : () => _showSavePlaylistDialog(context, queueState),
          icon: const Icon(
            LucideIcons.listPlus,
            color: AppColors.textSecondary,
            size: 20,
          ),
          tooltip: 'Save as Playlist',
        ),

        // Clear Queue Button
        IconButton(
          onPressed: queueState.upcomingItems.isEmpty
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  ref.read(queueProvider.notifier).clearUpcoming();
                },
          icon: const Icon(
            LucideIcons.trash2,
            color: AppColors.textSecondary,
            size: 20,
          ),
          tooltip: 'Clear Up Next',
        ),
      ],
    );
  }

  Widget _buildNowPlayingCard(
    BuildContext context,
    QueueItem currentItem,
    bool isPlaying,
  ) {
    final track = currentItem.track;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: AppConstants.roundedLarge,
      color: AppColors.darkSurfaceElevated,
      borderColor: AppColors.accentIndigo.withValues(alpha: 0.4),
      child: Row(
        children: [
          // Track Artwork with Playing Indicator
          ClipRRect(
            borderRadius: AppConstants.roundedMedium,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageShimmer(
                    imageUrl: track.bestArtworkUrl,
                    width: 56,
                    height: 56,
                  ),
                  if (isPlaying)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: _AnimatedEqualizerBars(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Track Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        borderRadius: AppConstants.roundedSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PLAYING',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSourceBadge(track),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  track.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Favorite Button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(playerProvider.notifier).toggleFavorite();
            },
            icon: Icon(
              track.isFavorite ? LucideIcons.heart : LucideIcons.heart,
              color: track.isFavorite ? AppColors.accentPink : AppColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableUpcomingList(
    BuildContext context,
    QueueState queueState,
  ) {
    final upcoming = queueState.upcomingItems;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: upcoming.length,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.selectionClick();
        ref.read(queueProvider.notifier).reorderUpcoming(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = upcoming[index];
        final track = item.track;

        return Dismissible(
          key: ValueKey('queue_item_${item.queueId}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red.withValues(alpha: 0.3),
            child: const Icon(
              LucideIcons.trash2,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            ref.read(queueProvider.notifier).removeUpcomingItem(index);
          },
          child: Container(
            key: ValueKey('tile_${item.queueId}'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
              vertical: 4,
            ),
            child: ExpressiveCard(
              borderRadius: AppConstants.roundedMedium,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(queueProvider.notifier).skipToQueueIndex(
                      queueState.currentIndex + 1 + index,
                    );
              },
              child: Row(
                children: [
                  // Drag Handle
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        LucideIcons.gripVertical,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),

                  // Artwork
                  ClipRRect(
                    borderRadius: AppConstants.roundedSmall,
                    child: ImageShimmer(
                      imageUrl: track.bestArtworkUrl,
                      width: 44,
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Track Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                track.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isAutoplay) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentIndigo.withValues(alpha: 0.2),
                                  borderRadius: AppConstants.roundedSmall,
                                ),
                                child: Text(
                                  'AUTO',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentIndigo,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${track.artist} • ${Formatters.formatDuration(track.duration)}',
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

                  // More Menu Popup
                  PopupMenuButton<String>(
                    icon: const Icon(
                      LucideIcons.ellipsisVertical,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    color: AppColors.darkSurfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppConstants.roundedMedium,
                      side: const BorderSide(color: AppColors.glassBorder),
                    ),
                    onSelected: (value) {
                      HapticFeedback.lightImpact();
                      switch (value) {
                        case 'play_now':
                          ref.read(queueProvider.notifier).skipToQueueIndex(
                                queueState.currentIndex + 1 + index,
                              );
                          break;
                        case 'play_next':
                          // Move this item to upcoming index 0
                          if (index > 0) {
                            ref.read(queueProvider.notifier).reorderUpcoming(index, 0);
                          }
                          break;
                        case 'remove':
                          ref.read(queueProvider.notifier).removeUpcomingItem(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'play_now',
                        child: Row(
                          children: [
                            Icon(LucideIcons.play, size: 16, color: AppColors.textPrimary),
                            SizedBox(width: 10),
                            Text('Play Now', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'play_next',
                        child: Row(
                          children: [
                            Icon(LucideIcons.listStart, size: 16, color: AppColors.textPrimary),
                            SizedBox(width: 10),
                            Text('Play Next', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Remove from Queue', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingEmptyPlaceholder(
    BuildContext context,
    QueueState queueState,
  ) {
    if (queueState.isAutoplayEnabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding,
          vertical: 20,
        ),
        child: GlassContainer(
          borderRadius: AppConstants.roundedLarge,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                LucideIcons.sparkles,
                color: AppColors.accentGreen,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                'AutoPlay is Active',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Similar songs will automatically queue and play when the current track finishes.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
        vertical: 24,
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.listMusic,
            color: AppColors.textMuted,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming tracks',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Turn on AutoPlay or add tracks to keep the music flowing.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: EmptyStateView(
        icon: LucideIcons.disc,
        title: 'Your Queue is Empty',
        message: 'Play a song, album, or playlist to start listening.',
      ),
    );
  }

  Widget _buildSourceBadge(Track track) {
    if (track.isOfflineAvailable) {
      return const AudioBadge(type: AudioBadgeType.offline);
    }
    if (track.source == 'youtube') {
      return const AudioBadge(type: AudioBadgeType.youtube);
    }
    if (track.bitrate >= 320) {
      return const AudioBadge(type: AudioBadgeType.highQuality320);
    }
    return const AudioBadge(type: AudioBadgeType.opusHq);
  }

  void _showSavePlaylistDialog(BuildContext context, QueueState queueState) {
    final titleController = TextEditingController(
      text: queueState.queueTitle ?? 'Queue - ${DateTime.now().day}/${DateTime.now().month}',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.roundedLarge,
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            'Save Queue as Playlist',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Playlist Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppConstants.roundedMedium,
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppConstants.roundedMedium,
                    borderSide: const BorderSide(color: AppColors.accentIndigo),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Will save all ${queueState.length} tracks from your current queue.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.roundedMedium,
                ),
              ),
              onPressed: () async {
                final name = titleController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(queueProvider.notifier).saveQueueAsPlaylist(name);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved "$name" to your playlists!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Playlist'),
            ),
          ],
        );
      },
    );
  }
}

/// Animated equalizer wave bars for indicating actively playing track
class _AnimatedEqualizerBars extends StatefulWidget {
  const _AnimatedEqualizerBars();

  @override
  State<_AnimatedEqualizerBars> createState() => _AnimatedEqualizerBarsState();
}

class _AnimatedEqualizerBarsState extends State<_AnimatedEqualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final val = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(14 * (0.4 + 0.6 * val)),
            const SizedBox(width: 2.5),
            _buildBar(18 * (1.0 - 0.5 * val)),
            const SizedBox(width: 2.5),
            _buildBar(16 * (0.3 + 0.7 * (1.0 - val))),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3.5,
      height: height.clamp(4.0, 20.0),
      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        borderRadius: AppConstants.roundedPill,
      ),
    );
  }
}
