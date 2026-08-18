import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/visualizer/presentation/providers/visualizer_provider.dart';

/// Smooth multi-layered flowing sinusoidal audio wave visualizer
class WaveVisualizer extends ConsumerStatefulWidget {
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;

  const WaveVisualizer({
    super.key,
    this.height = 70.0,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  ConsumerState<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends ConsumerState<WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _phase = 0.0;
  double _currentAmplitude = 0.2;

  @override
  void initState() {
    super.initState();
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
      _currentAmplitude *= 0.9;
    } else {
      final target = 0.55 * visualizerState.sensitivity;
      _currentAmplitude += (target - _currentAmplitude) * 0.1;
      _phase += 0.06;
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
    final primary = widget.primaryColor ?? AppColors.accentNeonBlue;
    final secondary = widget.secondaryColor ?? AppColors.accentPink;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _WaveVisualizerPainter(
          phase: _phase,
          amplitude: _currentAmplitude,
          primaryColor: primary,
          secondaryColor: secondary,
        ),
      ),
    );
  }
}

class _WaveVisualizerPainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final Color primaryColor;
  final Color secondaryColor;

  _WaveVisualizerPainter({
    required this.phase,
    required this.amplitude,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final maxAmp = size.height * 0.42 * amplitude;

    // Draw background subtle wave
    _drawSingleWave(
      canvas,
      size,
      midY,
      maxAmp * 0.6,
      phase * 0.8,
      2.0,
      secondaryColor.withValues(alpha: 0.35),
      strokeWidth: 2.0,
    );

    // Draw secondary harmonic wave
    _drawSingleWave(
      canvas,
      size,
      midY,
      maxAmp * 0.8,
      phase * 1.2 + 1.5,
      2.8,
      primaryColor.withValues(alpha: 0.6),
      strokeWidth: 2.5,
    );

    // Draw primary bright wave with gradient fill
    _drawPrimaryFilledWave(
      canvas,
      size,
      midY,
      maxAmp,
      phase,
      2.2,
    );
  }

  void _drawSingleWave(
    Canvas canvas,
    Size size,
    double midY,
    double waveAmp,
    double wavePhase,
    double frequency,
    Color color, {
    double strokeWidth = 2.0,
  }) {
    final path = Path();
    final step = 4.0;

    for (double x = 0; x <= size.width; x += step) {
      final normalizedX = x / size.width;
      // Damping at screen edges for elegant curve
      final edgeDamping = math.sin(normalizedX * math.pi);
      final y = midY +
          math.sin((normalizedX * frequency * 2 * math.pi) + wavePhase) *
              waveAmp *
              edgeDamping;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawPrimaryFilledWave(
    Canvas canvas,
    Size size,
    double midY,
    double waveAmp,
    double wavePhase,
    double frequency,
  ) {
    final strokePath = Path();
    final fillPath = Path();
    final step = 4.0;

    fillPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += step) {
      final normalizedX = x / size.width;
      final edgeDamping = math.sin(normalizedX * math.pi);
      final y = midY +
          math.sin((normalizedX * frequency * 2 * math.pi) + wavePhase) *
              waveAmp *
              edgeDamping;

      if (x == 0) {
        strokePath.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        strokePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill with fading gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Primary stroke
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveVisualizerPainter oldDelegate) => true;
}
