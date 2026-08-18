import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/empty_state_view.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/library/domain/models/history_item.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';

/// Screen displaying user's listening history chronologically
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Listening History', style: AppTypography.titleLarge),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.accentPink, size: 20),
              tooltip: 'Clear history',
              onPressed: () => _showClearHistoryDialog(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? const EmptyStateView(
              icon: LucideIcons.history,
              title: 'No Listening History',
              message:
                  'Songs you listen to for more than 15 seconds will appear here in chronological order.',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final isCurrent = currentTrack?.id == item.track.id;

                return Dismissible(
                  key: ValueKey('${item.id}_${item.playedAt.millisecondsSinceEpoch}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.accentPink.withOpacity(0.8),
                    child: const Icon(LucideIcons.trash2, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(historyProvider.notifier).removeHistoryItem(item.id);
                  },
                  child: ListTile(
                    onTap: () {
                      ref.read(playerProvider.notifier).playTrack(item.track);
                    },
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: item.track.bestArtworkUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: item.track.bestArtworkUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const ImageShimmer(),
                                    errorWidget: (_, __, ___) => _buildFallbackCover(),
                                  )
                                : _buildFallbackCover(),
                          ),
                        ),
                        if (isCurrent && isPlaying)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.volume2,
                                color: AppColors.accentGreen,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      item.track.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isCurrent ? AppColors.accentGreen : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.track.artist} • ${_formatTimeAgo(item.playedAt)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreVertical,
                          color: AppColors.textSecondary, size: 18),
                      color: AppColors.darkSurfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'play_next') {
                          ref.read(queueProvider.notifier).playNext(item.track);
                        } else if (val == 'remove') {
                          ref.read(historyProvider.notifier).removeHistoryItem(item.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'play_next',
                          child: Row(
                            children: [
                              Icon(LucideIcons.fastForward, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Play Next'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 16, color: AppColors.accentPink),
                              SizedBox(width: 8),
                              Text('Remove from history',
                                  style: TextStyle(color: AppColors.accentPink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      color: AppColors.darkSurfaceVariant,
      child: const Center(
        child: Icon(LucideIcons.music, color: AppColors.accentGreen, size: 20),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear History?', style: AppTypography.titleMedium),
        content: Text(
          'Are you sure you want to clear your listening history?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(historyProvider.notifier).clearHistory();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
