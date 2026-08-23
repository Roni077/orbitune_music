import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/core/widgets/empty_state_view.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/core/widgets/expressive_confirmation_sheet.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/downloader/data/download_service.dart';
import 'package:orbitune/features/downloader/domain/models/download_task.dart';
import 'package:orbitune/features/downloader/presentation/providers/download_provider.dart';
import 'package:orbitune/features/downloader/presentation/widgets/download_tile.dart';

/// Screen displaying offline downloaded music, active downloading tasks and storage stats
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
    );
  }

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Downloaded, 2: In Progress
  int _storageUsedBytes = 0;
  String _downloadsPath = '';

  @override
  void initState() {
    super.initState();
    _refreshStorage();
  }

  Future<void> _refreshStorage() async {
    final service = ref.read(downloadServiceProvider);
    final storage = await service.calculateTotalStorageUsed();
    final dir = await service.getDownloadsDirectory();
    if (mounted) {
      setState(() {
        _storageUsedBytes = storage;
        _downloadsPath = dir.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadListProvider);
    final completedDownloads = downloads.where((d) => d.isCompleted).toList();
    final inProgressDownloads = downloads.where((d) => !d.isCompleted).toList();

    List<DownloadTask> filteredList;
    if (_selectedFilterIndex == 1) {
      filteredList = completedDownloads;
    } else if (_selectedFilterIndex == 2) {
      filteredList = inProgressDownloads;
    } else {
      filteredList = downloads;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Offline Downloads', style: AppTypography.titleLarge),
        actions: [
          if (downloads.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary),
              color: AppColors.darkSurfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: AppColors.accentPink),
                      SizedBox(width: 8),
                      Text('Delete all downloads', style: TextStyle(color: AppColors.accentPink)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(downloadListProvider.notifier).refresh();
          await _refreshStorage();
        },
        color: AppColors.accentGreen,
        backgroundColor: AppColors.darkSurface,
        child: downloads.isEmpty
            ? const EmptyStateView(
                icon: LucideIcons.downloadCloud,
                title: 'No Offline Music Yet',
                message:
                    'Download high-bitrate songs from search, albums, or playlists to listen offline without internet.',
              )
            : CustomScrollView(
                slivers: [
                  // Storage & Action Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Storage info card
                          ExpressiveCard(
                            padding: const EdgeInsets.all(16),
                            color: AppColors.darkSurfaceVariant.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentCyan.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.hardDrive,
                                        color: AppColors.accentCyan,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Offline Storage',
                                            style: AppTypography.titleSmall.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${completedDownloads.length} songs • ${Formatters.formatFileSize(_storageUsedBytes)}',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (inProgressDownloads.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentYellow.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.accentYellow.withOpacity(0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 8,
                                              height: 8,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                    AppColors.accentYellow),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${inProgressDownloads.length} active',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.accentYellow,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (_downloadsPath.isNotEmpty) ...[
                                  const Divider(color: AppColors.glassBorder, height: 16),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.folderDown, size: 14, color: AppColors.accentCyan),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _downloadsPath,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.copy, size: 14, color: AppColors.accentCyan),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Copy Path',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: _downloadsPath));
                                          HapticFeedback.lightImpact();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Download directory path copied!'),
                                              backgroundColor: AppColors.accentGreen,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Play All & Shuffle Buttons
                          if (completedDownloads.isNotEmpty)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGreen,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      final tracks =
                                          completedDownloads.map((d) => d.track).toList();
                                      ref.read(playerProvider.notifier).playPlaylist(tracks);
                                    },
                                    icon: const Icon(LucideIcons.play, size: 18),
                                    label: Text(
                                      'Play All (${completedDownloads.length})',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: BorderSide(
                                      color: AppColors.white.withOpacity(0.15),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    final tracks =
                                        completedDownloads.map((d) => d.track).toList()..shuffle();
                                    ref.read(playerProvider.notifier).playPlaylist(tracks);
                                  },
                                  icon: const Icon(LucideIcons.shuffle, size: 18),
                                  label: const Text('Shuffle'),
                                ),
                              ],
                            ),

                          const SizedBox(height: 14),

                          // Filter Segmented Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(0, 'All (${downloads.length})'),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                    1, 'Downloaded (${completedDownloads.length})'),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                    2, 'Downloading (${inProgressDownloads.length})'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),

                  // Download List Items
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _selectedFilterIndex == 1
                              ? 'No completed downloads'
                              : 'No active downloads in progress',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = filteredList[index];
                          return DownloadTile(
                            task: task,
                            onTap: () {
                              final tracks =
                                  completedDownloads.map((d) => d.track).toList();
                              final initialIndex =
                                  tracks.indexWhere((t) => t.id == task.track.id);
                              if (initialIndex != -1) {
                                ref.read(playerProvider.notifier).playPlaylist(
                                      tracks,
                                      initialIndex: initialIndex,
                                    );
                              } else {
                                ref.read(playerProvider.notifier).playTrack(task.track);
                              }
                            },
                          );
                        },
                        childCount: filteredList.length,
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen : AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog() async {
    final confirmed = await ExpressiveConfirmationSheet.show(
      context,
      title: 'Delete All Downloads?',
      message: 'This will delete all offline music files from your device and clear download tasks.',
      confirmLabel: 'Delete All',
      icon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(downloadServiceProvider).deleteAllDownloads();
      await _refreshStorage();
    }
  }
}
