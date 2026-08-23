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
      if (_currentAmplitude < 0.01 && _animController.isAnimating) {
        _animController.stop();
      }
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
    final isPlaying = ref.watch(isPlayingProvider);
    final visualizerState = ref.watch(visualizerProvider);

    if (isPlaying && visualizerState.isEnabled && !_animController.isAnimating) {
      _animController.repeat();
    }

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

  static final Path _singlePath = Path();
  static final Path _strokePath = Path();
  static final Path _fillPath = Path();

  static final Paint _singlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _primaryStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;

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
    _singlePath.reset();
    const step = 4.0;

    for (double x = 0; x <= size.width; x += step) {
      final normalizedX = x / size.width;
      // Damping at screen edges for elegant curve
      final edgeDamping = math.sin(normalizedX * math.pi);
      final y = midY +
          math.sin((normalizedX * frequency * 2 * math.pi) + wavePhase) *
              waveAmp *
              edgeDamping;

      if (x == 0) {
        _singlePath.moveTo(x, y);
      } else {
        _singlePath.lineTo(x, y);
      }
    }

    _singlePaint.color = color;
    _singlePaint.strokeWidth = strokeWidth;

    canvas.drawPath(_singlePath, _singlePaint);
  }

  void _drawPrimaryFilledWave(
    Canvas canvas,
    Size size,
    double midY,
    double waveAmp,
    double wavePhase,
    double frequency,
  ) {
    _strokePath.reset();
    _fillPath.reset();
    const step = 4.0;

    _fillPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += step) {
      final normalizedX = x / size.width;
      final edgeDamping = math.sin(normalizedX * math.pi);
      final y = midY +
          math.sin((normalizedX * frequency * 2 * math.pi) + wavePhase) *
              waveAmp *
              edgeDamping;

      if (x == 0) {
        _strokePath.moveTo(x, y);
        _fillPath.lineTo(x, y);
      } else {
        _strokePath.lineTo(x, y);
        _fillPath.lineTo(x, y);
      }
    }

    _fillPath.lineTo(size.width, size.height);
    _fillPath.close();

    // Fill with fading gradient
    _fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.25),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(_fillPath, _fillPaint);

    // Primary stroke
    _primaryStrokePaint.shader = LinearGradient(
      colors: [primaryColor, secondaryColor],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(_strokePath, _primaryStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveVisualizerPainter oldDelegate) => true;
}
