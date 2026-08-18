import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/downloader/data/download_service.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';

/// Single item tile in the Downloads screen displaying progress, status, and actions
class DownloadTile extends ConsumerWidget {
  final DownloadTask task;
  final VoidCallback? onTap;

  const DownloadTile({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isCurrent = currentTrack?.id == task.track.id;
    final downloadService = ref.read(downloadServiceProvider);

    return ExpressiveCard(
      onTap: () {
        if (task.isCompleted) {
          if (onTap != null) {
            onTap!();
          } else {
            ref.read(playerProvider.notifier).playTrack(task.track);
          }
        }
      },
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(16),
      color: isCurrent
          ? AppColors.accentGreen.withOpacity(0.12)
          : AppColors.darkSurface.withOpacity(0.7),
      borderColor: isCurrent
          ? AppColors.accentGreen.withOpacity(0.4)
          : AppColors.white.withOpacity(0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Artwork with playback indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: task.track.bestArtworkUrl != null
                          ? CachedNetworkImage(
                              imageUrl: task.track.bestArtworkUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ImageShimmer(),
                              errorWidget: (_, __, ___) => _buildFallbackArtwork(),
                            )
                          : _buildFallbackArtwork(),
                    ),
                  ),
                  if (isCurrent && isPlaying)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.volume2,
                          color: AppColors.accentGreen,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Title, Artist and Status Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.track.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: isCurrent ? AppColors.accentGreen : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.track.artist,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusLabel(),
                  ],
                ),
              ),

              // Action buttons / Popup Menu
              _buildTrailingAction(context, downloadService),
            ],
          ),

          // Downloading Progress Bar
          if (task.isDownloading || task.isPaused) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress > 0 ? task.progress : null,
                backgroundColor: AppColors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.isPaused ? AppColors.accentYellow : AppColors.accentGreen,
                ),
                minHeight: 3.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusLabel() {
    switch (task.status) {
      case DownloadStatus.completed:
        final sizeStr = task.downloadedBytes > 0
            ? Formatters.formatFileSize(task.downloadedBytes)
            : '';
        return Row(
          children: [
            const Icon(LucideIcons.checkCircle2, size: 12, color: AppColors.accentGreen),
            const SizedBox(width: 4),
            Text(
              'Offline • $sizeStr ${task.quality.label}',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case DownloadStatus.downloading:
        final pct = (task.progress * 100).toInt();
        final bytesStr = task.totalBytes > 0
            ? '${Formatters.formatFileSize(task.downloadedBytes)} / ${Formatters.formatFileSize(task.totalBytes)}'
            : Formatters.formatFileSize(task.downloadedBytes);
        return Row(
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Downloading $pct% ($bytesStr)',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentCyan,
              ),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          children: [
            const Icon(LucideIcons.pause, size: 12, color: AppColors.accentYellow),
            const SizedBox(width: 4),
            Text(
              'Paused',
              style: AppTypography.caption.copyWith(color: AppColors.accentYellow),
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          children: [
            const Icon(LucideIcons.alertCircle, size: 12, color: AppColors.accentPink),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                task.errorMessage ?? 'Download failed',
                style: AppTypography.caption.copyWith(color: AppColors.accentPink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case DownloadStatus.cancelled:
        return Text(
          'Cancelled',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        );
      case DownloadStatus.pending:
        return Text(
          'Queued...',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        );
    }
  }

  Widget _buildTrailingAction(BuildContext context, DownloadService downloadService) {
    if (task.isDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.pause, size: 18, color: AppColors.accentYellow),
            onPressed: () => downloadService.pauseDownload(task.id),
            tooltip: 'Pause',
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18, color: AppColors.accentPink),
            onPressed: () => downloadService.cancelDownload(task.id),
            tooltip: 'Cancel',
          ),
        ],
      );
    }

    if (task.isPaused || task.isFailed || task.status == DownloadStatus.cancelled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCw, size: 18, color: AppColors.accentGreen),
            onPressed: () => downloadService.retryDownload(task.id),
            tooltip: 'Retry',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.textTertiary),
            onPressed: () => downloadService.deleteDownload(task.id),
            tooltip: 'Remove',
          ),
        ],
      );
    }

    // Completed download - popup menu
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
      color: AppColors.darkSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'delete') {
          downloadService.deleteDownload(task.id);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: AppColors.accentPink),
              SizedBox(width: 8),
              Text('Delete from device', style: TextStyle(color: AppColors.accentPink)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackArtwork() {
    return Container(
      color: AppColors.darkSurfaceVariant,
      child: const Center(
        child: Icon(LucideIcons.music, color: AppColors.accentGreen, size: 22),
      ),
    );
  }
}
