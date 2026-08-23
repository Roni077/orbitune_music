import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/visualizer/presentation/providers/visualizer_provider.dart';

/// Real-time multi-bar frequency spectrum analyzer with physics simulation and peak gravity
class BarVisualizer extends ConsumerStatefulWidget {
  final int barCount;
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;

  const BarVisualizer({
    super.key,
    this.barCount = 32,
    this.height = 64.0,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  ConsumerState<BarVisualizer> createState() => _BarVisualizerState();
}

class _BarVisualizerState extends ConsumerState<BarVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final math.Random _random = math.Random();
  late List<double> _targetHeights;
  late List<double> _currentHeights;
  late List<double> _peakHeights;
  late List<double> _peakVelocities;

  @override
  void initState() {
    super.initState();
    _targetHeights = List.generate(widget.barCount, (_) => 0.1);
    _currentHeights = List.generate(widget.barCount, (_) => 0.1);
    _peakHeights = List.generate(widget.barCount, (_) => 0.1);
    _peakVelocities = List.generate(widget.barCount, (_) => 0.0);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_tick);

    _animController.repeat();
  }

  void _tick() {
    final isPlaying = ref.read(isPlayingProvider);
    final visualizerState = ref.read(visualizerProvider);

    if (!isPlaying || !visualizerState.isEnabled) {
      bool hasActive = false;
      for (int i = 0; i < widget.barCount; i++) {
        _currentHeights[i] *= 0.85;
        _peakHeights[i] *= 0.85;
        if (_currentHeights[i] > 0.01) hasActive = true;
      }
      if (!hasActive && _animController.isAnimating) {
        _animController.stop();
      }
      setState(() {});
      return;
    }

    final sensitivity = visualizerState.sensitivity;

    // Simulate audio frequencies with natural curve (higher bass on left, mids center, treble right)
    for (int i = 0; i < widget.barCount; i++) {
      if (_random.nextDouble() < 0.25) {
        // Natural audio spectrum curve weighting
        final normalizedIndex = i / widget.barCount;
        final curveFactor = (1.0 - (normalizedIndex - 0.3).abs()).clamp(0.4, 1.0);
        final rawHeight = (_random.nextDouble() * 0.85 + 0.15) * curveFactor * sensitivity;
        _targetHeights[i] = rawHeight.clamp(0.08, 1.0);
      }

      // Smooth lerp towards target height
      _currentHeights[i] += (_targetHeights[i] - _currentHeights[i]) * 0.35;

      // Peak gravity simulation
      if (_currentHeights[i] > _peakHeights[i]) {
        _peakHeights[i] = _currentHeights[i];
        _peakVelocities[i] = 0.0;
      } else {
        _peakVelocities[i] += 0.004; // gravity acceleration
        _peakHeights[i] = (_peakHeights[i] - _peakVelocities[i]).clamp(0.0, 1.0);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final visualizerState = ref.watch(visualizerProvider);

    if (isPlaying && visualizerState.isEnabled && !_animController.isAnimating) {
      _animController.repeat();
    }

    final primary = widget.primaryColor ?? AppColors.accentGreen;
    final secondary = widget.secondaryColor ?? AppColors.accentNeonBlue;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _BarVisualizerPainter(
          heights: _currentHeights,
          peaks: _peakHeights,
          primaryColor: primary,
          secondaryColor: secondary,
        ),
      ),
    );
  }
}

class _BarVisualizerPainter extends CustomPainter {
  final List<double> heights;
  final List<double> peaks;
  final Color primaryColor;
  final Color secondaryColor;

  static final Paint _barPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _peakPaint = Paint()..style = PaintingStyle.fill;

  _BarVisualizerPainter({
    required this.heights,
    required this.peaks,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = heights.length;
    if (count == 0) return;

    final totalSpacing = (count - 1) * 3.0;
    final barWidth = ((size.width - totalSpacing) / count).clamp(2.0, 12.0);

    final gradientShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [primaryColor, secondaryColor],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    _barPaint.shader = gradientShader;
    _peakPaint.color = primaryColor;

    for (int i = 0; i < count; i++) {
      final x = i * (barWidth + 3.0);
      final barHeight = (heights[i] * size.height).clamp(3.0, size.height);
      final y = size.height - barHeight;

      // Draw rounded bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3.0),
      );
      canvas.drawRRect(barRect, _barPaint);

      // Draw peak dot / cap
      final peakY = (size.height - (peaks[i] * size.height) - 4.0).clamp(0.0, size.height - 4.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, peakY, barWidth, 2.5),
          const Radius.circular(1.5),
        ),
        _peakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarVisualizerPainter oldDelegate) => true;
}
