import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/palette_helper.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/domain/models/playback_state.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:orbitune/features/lyrics/presentation/widgets/lrc_view.dart';
import 'package:orbitune/features/lyrics/presentation/widgets/plain_lyrics_view.dart';
import 'package:palette_generator_plus/palette_generator_plus.dart';

/// Fullscreen synchronized karaoke lyrics screen with ambient theming and bottom mini-controls
class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  /// Opens the lyrics screen with a slide-up transition
  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const LyricsScreen(),
        transitionsBuilder: (context, anim1, anim2, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curve),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  PaletteGenerator? _palette;
  String? _lastArtworkUrl;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    final lyricsState = ref.watch(lyricsProvider);

    // Extract dynamic palette if track artwork changes
    if (track != null && track.artworkUrl != null && track.artworkUrl != _lastArtworkUrl) {
      _lastArtworkUrl = track.artworkUrl;
      PaletteHelper.extractPalette(track.artworkUrl!).then((palette) {
        if (mounted) {
          setState(() {
            _palette = palette;
          });
        }
      });
    }

    final dominantColor = PaletteHelper.getDominantColor(
      _palette,
      fallback: AppColors.darkSurface,
    );

    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Dynamic ambient gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dominantColor.withValues(alpha: 0.45),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                  scaffoldBg,
                ],
              ),
            ),
          ),

          // Blurred glass overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: const SizedBox.expand(),
          ),

          // Main SafeArea Content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildHeader(context, track, lyricsState),

                // Lyrics Content Area
                Expanded(
                  child: _buildLyricsBody(lyricsState, dominantColor),
                ),

                // Bottom Minimal Player Bar
                if (track != null) _buildBottomBar(playerState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic track, LyricsState lyricsState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronDown, size: 28),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.title ?? 'Lyrics',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track?.artist ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Font Size Adjuster Popover
          IconButton(
            icon: const Icon(LucideIcons.type, size: 20),
            onPressed: () => _showFontSizeDialog(context),
            tooltip: 'Font Size',
          ),

          // Refresh Lyrics
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(lyricsProvider.notifier).refreshLyrics();
            },
            tooltip: 'Refresh Lyrics',
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsBody(LyricsState lyricsState, Color dominantColor) {
    if (lyricsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accentGreen,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Finding synchronized lyrics...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (lyricsState.lines.isNotEmpty && lyricsState.isSynced) {
      return LrcView(
        lines: lyricsState.lines,
        activeIndex: lyricsState.activeLineIndex,
        fontSize: lyricsState.fontSize,
        activeColor: dominantColor == AppColors.darkSurface
            ? AppColors.accentGreen
            : dominantColor,
      );
    }

    if (lyricsState.plainLyrics != null && lyricsState.plainLyrics!.isNotEmpty) {
      return PlainLyricsView(
        lyrics: lyricsState.plainLyrics!,
        fontSize: lyricsState.fontSize,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.micOff,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No lyrics found for this track',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We searched the LRCLIB synchronized lyrics database.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(lyricsProvider.notifier).refreshLyrics();
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(PlayerStateSnapshot playerState) {
    final track = playerState.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isPlaying = playerState.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: AppConstants.roundedSmall,
                child: ImageShimmer(
                  imageUrl: track.artworkUrl,
                  width: 40,
                  height: 40,
                  borderRadius: AppConstants.roundedSmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.skipBack, size: 20),
                onPressed: () => ref.read(playerProvider.notifier).previous(),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? LucideIcons.pause : LucideIcons.play,
                  size: 22,
                  color: AppColors.accentGreen,
                ),
                onPressed: () =>
                    ref.read(playerProvider.notifier).togglePlayPause(),
              ),
              IconButton(
                icon: const Icon(LucideIcons.skipForward, size: 20),
                onPressed: () => ref.read(playerProvider.notifier).next(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const _LyricsProgressBar(),
        ],
      ),
    );
  }
  void _showFontSizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentSize = ref.watch(lyricsProvider).fontSize;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LYRICS FONT SIZE', style: AppTypography.labelSmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: currentSize,
                          min: 14.0,
                          max: 32.0,
                          divisions: 9,
                          activeColor: AppColors.accentGreen,
                          onChanged: (val) {
                            ref.read(lyricsProvider.notifier).setFontSize(val);
                          },
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LyricsProgressBar extends ConsumerWidget {
  const _LyricsProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerPositionProvider);
    final duration = ref.watch(playerDurationProvider);
    final progress = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LinearProgressIndicator(
      value: progress,
      minHeight: 2.0,
      backgroundColor: AppColors.darkSurfaceVariant,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
    );
  }
}
