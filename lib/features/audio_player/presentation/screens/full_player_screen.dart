import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:marquee/marquee.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/palette_helper.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/audio_player/presentation/providers/queue_provider.dart';
import 'package:orbitune/features/audio_player/presentation/providers/sleep_timer_provider.dart';
import 'package:orbitune/features/audio_player/presentation/screens/queue_sheet.dart';
import 'package:orbitune/features/audio_player/presentation/screens/sleep_timer_sheet.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/artwork_disc_view.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/player_controls.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/player_header.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/volume_speed_slider.dart';
import 'package:orbitune/features/audio_player/presentation/widgets/waveform_seek_bar.dart';
import 'package:orbitune/features/lyrics/presentation/providers/lyrics_provider.dart';
import 'package:orbitune/features/lyrics/presentation/widgets/lrc_view.dart';
import 'package:orbitune/features/lyrics/presentation/widgets/plain_lyrics_view.dart';
import 'package:orbitune/features/search/presentation/screens/artist_detail_screen.dart';
import 'package:orbitune/features/visualizer/domain/models/visualizer_mode.dart';
import 'package:orbitune/features/visualizer/presentation/providers/visualizer_provider.dart';
import 'package:orbitune/features/visualizer/presentation/widgets/bar_visualizer.dart';
import 'package:orbitune/features/visualizer/presentation/widgets/circular_visualizer.dart';
import 'package:orbitune/features/visualizer/presentation/widgets/wave_visualizer.dart';
import 'package:palette_generator/palette_generator.dart';

/// Available center view modes in FullPlayerScreen
enum _PlayerCenterView {
  artwork,
  lyrics,
  visualizer,
}

/// Immersive fullscreen player with dynamic theming, synchronized lyrics, audio visualizers and gestural controls
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  /// Opens the FullPlayerScreen with a smooth vertical slide-up transition
  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const FullPlayerScreen(),
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
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  _PlayerCenterView _currentView = _PlayerCenterView.artwork;
  PaletteGenerator? _palette;
  String? _lastArtworkUrl;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    final lyricsState = ref.watch(lyricsProvider);
    final visualizerState = ref.watch(visualizerProvider);
    final timerState = ref.watch(sleepTimerProvider);

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.disc, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No track selected', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract dynamic palette from current track artwork
    if (track.artworkUrl != null && track.artworkUrl != _lastArtworkUrl) {
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
      fallback: AppColors.accentGreen,
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss / collapse back to MiniPlayer
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          children: [
            // Layer 1: Ambient dynamic blurred gradient background
            AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    dominantColor.withValues(alpha: 0.45),
                    const Color(0xFF10101C).withValues(alpha: 0.85),
                    AppColors.darkBackground,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Layer 2: Frosted Glass Filter
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: const SizedBox.expand(),
            ),

            // Layer 3: Main Player Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Top Player Header
                    PlayerHeader(
                      track: track,
                      onCollapse: () => Navigator.of(context).maybePop(),
                    ),

                    // Central View (Artwork / Synced Lyrics / Visualizer)
                    Expanded(
                      child: _buildCenterView(
                        track,
                        lyricsState,
                        visualizerState,
                        dominantColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Track Title, Artist, and Favorite Heart Action
                    _buildTrackInfoRow(track),

                    const SizedBox(height: 16),

                    // Waveform Progress Bar & Scrubber
                    WaveformSeekBar(
                      position: playerState.position,
                      duration: playerState.duration,
                      activeColor: dominantColor == AppColors.darkSurface
                          ? AppColors.accentGreen
                          : dominantColor,
                      onSeek: (position) {
                        ref.read(playerProvider.notifier).seek(position);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Playback Controls (Play/Pause, Skip, 10s Seeks, Shuffle, Repeat)
                    PlayerControls(
                      primaryColor: dominantColor == AppColors.darkSurface
                          ? AppColors.accentGreen
                          : dominantColor,
                    ),

                    const SizedBox(height: 14),

                    // Bottom Quick Action Bar (Lyrics, Visualizer, EQ, Timer, Queue)
                    _buildBottomQuickBar(
                      lyricsState,
                      visualizerState,
                      timerState,
                      dominantColor,
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterView(
    dynamic track,
    LyricsState lyricsState,
    VisualizerState visualizerState,
    Color dominantColor,
  ) {
    switch (_currentView) {
      case _PlayerCenterView.artwork:
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = (constraints.maxHeight * 0.85).clamp(200.0, 320.0);
            return Center(
              child: ArtworkDiscView(
                imageUrl: track.artworkUrl ?? '',
                size: size,
                glowColor: dominantColor,
                onSwipeLeft: () => ref.read(playerProvider.notifier).next(),
                onSwipeRight: () => ref.read(playerProvider.notifier).previous(),
              ),
            );
          },
        );

      case _PlayerCenterView.lyrics:
        if (lyricsState.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGreen),
          );
        }
        if (lyricsState.lines.isNotEmpty && lyricsState.isSynced) {
          return LrcView(
            lines: lyricsState.lines,
            activeIndex: lyricsState.activeLineIndex,
            fontSize: lyricsState.fontSize,
            activeColor: dominantColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          );
        }
        if (lyricsState.plainLyrics != null && lyricsState.plainLyrics!.isNotEmpty) {
          return PlainLyricsView(
            lyrics: lyricsState.plainLyrics!,
            fontSize: lyricsState.fontSize,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.micOff, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('No lyrics available', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkSurfaceVariant,
                  foregroundColor: AppColors.accentGreen,
                ),
                onPressed: () => ref.read(lyricsProvider.notifier).refreshLyrics(),
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );

      case _PlayerCenterView.visualizer:
        return LayoutBuilder(
          builder: (context, constraints) {
            final vizHeight = (constraints.maxHeight * 0.55).clamp(60.0, 150.0);
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visualizerState.mode == VisualizerMode.bars)
                      BarVisualizer(
                        height: vizHeight,
                        primaryColor: dominantColor,
                        secondaryColor: AppColors.accentNeonBlue,
                      )
                    else if (visualizerState.mode == VisualizerMode.wave)
                      WaveVisualizer(
                        height: vizHeight,
                        primaryColor: dominantColor,
                        secondaryColor: AppColors.accentPink,
                      )
                    else
                      CircularVisualizer(
                        radius: (vizHeight * 0.55).clamp(36.0, 75.0),
                        primaryColor: dominantColor,
                        secondaryColor: AppColors.accentNeonBlue,
                        child: Container(
                          width: (vizHeight * 0.8).clamp(50.0, 110.0),
                          height: (vizHeight * 0.8).clamp(50.0, 110.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.darkSurfaceElevated,
                          ),
                          child: const Icon(
                            LucideIcons.music,
                            size: 28,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Visualizer Mode Switcher Chip
                    ActionChip(
                      avatar: const Icon(LucideIcons.activity, size: 16),
                      label: Text('Mode: ${visualizerState.mode.label}'),
                      backgroundColor: AppColors.darkSurfaceVariant,
                      side: BorderSide(color: dominantColor.withValues(alpha: 0.4)),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(visualizerProvider.notifier).cycleMode();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildTrackInfoRow(dynamic track) {
    final isFavorite = track.isFavorite;

    return Row(
      children: [
        // Track Title & Artist
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with Marquee if long text
              SizedBox(
                height: 28,
                child: track.title.length > 28
                    ? Marquee(
                        text: track.title,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 30.0,
                        velocity: 30.0,
                        pauseAfterRound: const Duration(seconds: 2),
                      )
                    : Text(
                        track.title,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(
                        artistId: track.artist,
                        artistName: track.artist,
                      ),
                    ),
                  );
                },
                child: Text(
                  track.artist,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Animated Favorite Heart Button
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFavorite ? LucideIcons.heart : LucideIcons.heart,
              key: ValueKey<bool>(isFavorite),
              size: 26,
              color: isFavorite ? AppColors.accentPink : AppColors.textMuted,
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(playerProvider.notifier).toggleFavorite();
          },
          tooltip: 'Favorite',
        ),
      ],
    );
  }

  Widget _buildBottomQuickBar(
    LyricsState lyricsState,
    VisualizerState visualizerState,
    SleepTimerState timerState,
    Color activeColor,
  ) {
    final queueItems = ref.watch(upcomingQueueProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Lyrics View Toggle
        IconButton(
          icon: Icon(
            LucideIcons.mic2,
            size: 22,
            color: _currentView == _PlayerCenterView.lyrics
                ? activeColor
                : (lyricsState.hasLyrics ? AppColors.textPrimary : AppColors.textMuted),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() {
              _currentView = _currentView == _PlayerCenterView.lyrics
                  ? _PlayerCenterView.artwork
                  : _PlayerCenterView.lyrics;
            });
          },
          tooltip: 'Lyrics',
        ),

        // Visualizer View Toggle
        IconButton(
          icon: Icon(
            LucideIcons.activity,
            size: 22,
            color: _currentView == _PlayerCenterView.visualizer
                ? activeColor
                : AppColors.textSecondary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() {
              _currentView = _currentView == _PlayerCenterView.visualizer
                  ? _PlayerCenterView.artwork
                  : _PlayerCenterView.visualizer;
            });
          },
          tooltip: 'Visualizer',
        ),

        // Playback Speed & Volume Quick Sheet
        IconButton(
          icon: const Icon(
            LucideIcons.sliders,
            size: 22,
            color: AppColors.textSecondary,
          ),
          onPressed: () => VolumeSpeedSlider.show(context),
          tooltip: 'Volume & Speed',
        ),

        // Sleep Timer
        IconButton(
          icon: Icon(
            LucideIcons.timer,
            size: 22,
            color: timerState.isActive ? AppColors.accentNeonBlue : AppColors.textSecondary,
          ),
          onPressed: () => SleepTimerSheet.show(context),
          tooltip: timerState.isActive ? 'Timer: ${timerState.formattedCountdown}' : 'Sleep Timer',
        ),

        // Up Next Queue Button with item badge
        IconButton(
          icon: Badge(
            isLabelVisible: queueItems.isNotEmpty,
            label: Text('${queueItems.length}'),
            backgroundColor: activeColor,
            textColor: Colors.black,
            child: const Icon(
              LucideIcons.listMusic,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          onPressed: () => QueueSheet.show(context),
          tooltip: 'Queue',
        ),
      ],
    );
  }
}
