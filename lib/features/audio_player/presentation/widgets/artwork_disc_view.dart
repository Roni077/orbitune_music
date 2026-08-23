import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/widgets/image_shimmer.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/visualizer/domain/models/visualizer_mode.dart';
import 'package:orbitune/features/visualizer/presentation/providers/visualizer_provider.dart';
import 'package:orbitune/features/visualizer/presentation/widgets/circular_visualizer.dart';

/// Artwork container supporting switchable rounded glass card and rotating vinyl disc mode
class ArtworkDiscView extends ConsumerStatefulWidget {
  final String imageUrl;
  final double size;
  final Color? glowColor;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const ArtworkDiscView({
    super.key,
    required this.imageUrl,
    this.size = 280.0,
    this.glowColor,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  ConsumerState<ArtworkDiscView> createState() => _ArtworkDiscViewState();
}

class _ArtworkDiscViewState extends ConsumerState<ArtworkDiscView>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isVinylMode = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    final isPlaying = ref.read(isPlayingProvider);
    if (isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleVinylMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isVinylMode = !_isVinylMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final visualizerState = ref.watch(visualizerProvider);
    final glowColor = widget.glowColor ?? AppColors.accentGreen;

    // Control rotation based on playback state and vinyl mode
    if (isPlaying && _isVinylMode) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    Widget content = _isVinylMode
        ? _buildVinylDisc(glowColor)
        : _buildGlassCardArtwork(glowColor);

    if (visualizerState.mode == VisualizerMode.circular &&
        visualizerState.isEnabled) {
      content = CircularVisualizer(
        radius: widget.size / 2,
        primaryColor: glowColor,
        secondaryColor: AppColors.accentNeonBlue,
        child: content,
      );
    }

    return GestureDetector(
      onTap: _toggleVinylMode,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -250) {
            // Swipe Left -> Skip Next
            HapticFeedback.mediumImpact();
            if (widget.onSwipeLeft != null) {
              widget.onSwipeLeft!();
            } else {
              ref.read(playerProvider.notifier).next();
            }
          } else if (details.primaryVelocity! > 250) {
            // Swipe Right -> Skip Previous
            HapticFeedback.mediumImpact();
            if (widget.onSwipeRight != null) {
              widget.onSwipeRight!();
            } else {
              ref.read(playerProvider.notifier).previous();
            }
          }
        }
      },
      child: Center(
        child: SizedBox(
          width: widget.size + 40,
          height: widget.size + 40,
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildGlassCardArtwork(Color glowColor) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ImageShimmer(
          imageUrl: widget.imageUrl,
          width: widget.size,
          height: widget.size,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildVinylDisc(Color glowColor) {
    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(0.05),
        child: RotationTransition(
          turns: _rotationController,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF1E1E28),
                  Color(0xFF0F0F16),
                  Color(0xFF232332),
                  Color(0xFF0A0A10),
                ],
                stops: [0.35, 0.6, 0.85, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.35),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
                const BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF33334A),
                width: 3.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric vinyl grooves with specular reflection
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _VinylGroovesPainter(),
                ),

                // Center Artwork Label
                ClipOval(
                  child: SizedBox(
                    width: widget.size * 0.42,
                    height: widget.size * 0.42,
                    child: ImageShimmer(
                      imageUrl: widget.imageUrl,
                      width: widget.size * 0.42,
                      height: widget.size * 0.42,
                    ),
                  ),
                ),

                // Center spindle hole
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B0B14),
                    border: Border.all(
                      color: const Color(0xFF8888AA),
                      width: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  static final Paint _groovePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x22FFFFFF)
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw concentric grooves
    for (double r = maxRadius * 0.46; r < maxRadius - 6; r += 7.0) {
      canvas.drawCircle(center, r, _groovePaint);
    }

    // Anisotropic light reflection sweep
    final shimmerPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius - 3, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
