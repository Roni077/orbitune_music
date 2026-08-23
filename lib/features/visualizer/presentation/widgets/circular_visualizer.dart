import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/visualizer/presentation/providers/visualizer_provider.dart';

/// 360-degree radial audio spectrum visualizer surrounding artwork
class CircularVisualizer extends ConsumerStatefulWidget {
  final Widget? child;
  final double radius;
  final int rayCount;
  final Color? primaryColor;
  final Color? secondaryColor;

  const CircularVisualizer({
    super.key,
    this.child,
    this.radius = 120.0,
    this.rayCount = 48,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  ConsumerState<CircularVisualizer> createState() => _CircularVisualizerState();
}

class _CircularVisualizerState extends ConsumerState<CircularVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final math.Random _random = math.Random();
  late List<double> _rayHeights;
  late List<double> _targetHeights;

  @override
  void initState() {
    super.initState();
    _rayHeights = List.generate(widget.rayCount, (_) => 0.05);
    _targetHeights = List.generate(widget.rayCount, (_) => 0.05);

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
      for (int i = 0; i < widget.rayCount; i++) {
        _rayHeights[i] *= 0.88;
        if (_rayHeights[i] > 0.01) hasActive = true;
      }
      if (!hasActive && _animController.isAnimating) {
        _animController.stop();
      }
      setState(() {});
      return;
    }

    final sensitivity = visualizerState.sensitivity;

    for (int i = 0; i < widget.rayCount; i++) {
      if (_random.nextDouble() < 0.25) {
        _targetHeights[i] =
            (_random.nextDouble() * 0.85 + 0.15) * sensitivity;
      }
      _rayHeights[i] += (_targetHeights[i] - _rayHeights[i]) * 0.3;
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
        painter: _CircularVisualizerPainter(
          rayHeights: _rayHeights,
          innerRadius: widget.radius,
          primaryColor: primary,
          secondaryColor: secondary,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _CircularVisualizerPainter extends CustomPainter {
  final List<double> rayHeights;
  final double innerRadius;
  final Color primaryColor;
  final Color secondaryColor;

  static final Paint _rayPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 3.0;

  _CircularVisualizerPainter({
    required this.rayHeights,
    required this.innerRadius,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final count = rayHeights.length;
    if (count == 0) return;

    final angleStep = (2 * math.pi) / count;
    const maxRayLength = 28.0;

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep;
      final rayLength = (rayHeights[i] * maxRayLength).clamp(3.0, maxRayLength);

      final startX = center.dx + math.cos(angle) * (innerRadius + 4);
      final startY = center.dy + math.sin(angle) * (innerRadius + 4);

      final endX = center.dx + math.cos(angle) * (innerRadius + 4 + rayLength);
      final endY = center.dy + math.sin(angle) * (innerRadius + 4 + rayLength);

      final t = i / count;
      _rayPaint.color = Color.lerp(primaryColor, secondaryColor, t) ?? primaryColor;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularVisualizerPainter oldDelegate) => true;
}
