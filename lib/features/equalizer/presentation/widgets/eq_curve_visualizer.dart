import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_constants.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/equalizer/domain/models/eq_band_mode.dart';

/// Interactive real-time frequency response curve visualizer with glowing Bézier spline & dB grid
class EQCurveVisualizer extends StatefulWidget {
  final Map<int, double> bandGains;
  final EQBandMode bandMode;
  final bool isEnabled;
  final Function(int frequency, double gain)? onGainChanged;
  final double height;

  const EQCurveVisualizer({
    super.key,
    required this.bandGains,
    required this.bandMode,
    this.isEnabled = true,
    this.onGainChanged,
    this.height = 180,
  });

  @override
  State<EQCurveVisualizer> createState() => _EQCurveVisualizerState();
}

class _EQCurveVisualizerState extends State<EQCurveVisualizer> {
  int? _activeDraggingFreq;

  @override
  Widget build(BuildContext context) {
    final frequencies = widget.bandMode.frequencies;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withValues(alpha: 0.6),
        borderRadius: AppConstants.roundedLarge,
        border: Border.all(
          color: widget.isEnabled
              ? AppColors.accentGreen.withValues(alpha: 0.25)
              : AppColors.glassBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppConstants.roundedLarge,
        child: GestureDetector(
          onPanDown: (details) => _handleTouch(details.localPosition, frequencies),
          onPanUpdate: (details) => _handleTouch(details.localPosition, frequencies),
          onPanEnd: (_) => setState(() => _activeDraggingFreq = null),
          child: CustomPaint(
            size: Size.infinite,
            painter: _EQCurvePainter(
              bandGains: widget.bandGains,
              frequencies: frequencies,
              isEnabled: widget.isEnabled,
              activeFreq: _activeDraggingFreq,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTouch(Offset localPos, List<int> frequencies) {
    if (!widget.isEnabled || widget.onGainChanged == null) return;

    final width = context.size?.width ?? 300.0;
    final height = widget.height;
    if (width <= 0 || height <= 0) return;

    const padX = 24.0;
    const padY = 20.0;
    final graphWidth = width - (padX * 2);
    final graphHeight = height - (padY * 2);

    // Find closest frequency point on X axis
    int? closestFreq;
    double minDistance = double.infinity;

    for (int i = 0; i < frequencies.length; i++) {
      final nodeX = padX + (i / (frequencies.length - 1)) * graphWidth;
      final dist = (localPos.dx - nodeX).abs();
      if (dist < minDistance) {
        minDistance = dist;
        closestFreq = frequencies[i];
      }
    }

    if (closestFreq != null) {
      final clampedY = localPos.dy.clamp(padY, height - padY);
      final normalizedY = (clampedY - padY) / graphHeight; // 0.0 top (+10dB), 1.0 bottom (-10dB)
      final gainDb = (1.0 - (normalizedY * 2.0)) * 10.0; // +10dB to -10dB

      if (_activeDraggingFreq != closestFreq) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _activeDraggingFreq = closestFreq;
      });
      widget.onGainChanged!(closestFreq, double.parse(gainDb.toStringAsFixed(1)));
    }
  }
}

class _EQCurvePainter extends CustomPainter {
  final Map<int, double> bandGains;
  final List<int> frequencies;
  final bool isEnabled;
  final int? activeFreq;

  _EQCurvePainter({
    required this.bandGains,
    required this.frequencies,
    required this.isEnabled,
    this.activeFreq,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 24.0;
    const padY = 22.0;
    final graphWidth = size.width - (padX * 2);
    final graphHeight = size.height - (padY * 2);
    final centerY = padY + (graphHeight / 2); // 0 dB line

    // 1. Draw dB Grid & Guidelines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    final centerGridPaint = Paint()
      ..color = isEnabled
          ? AppColors.accentGreen.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dbLevels = [10.0, 5.0, 0.0, -5.0, -10.0];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final db in dbLevels) {
      final y = padY + ((10.0 - db) / 20.0) * graphHeight;

      if (db == 0.0) {
        canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), centerGridPaint);
      } else {
        canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), gridPaint);
      }

      // Draw dB label
      final label = db > 0 ? '+${db.toInt()}dB' : '${db.toInt()}dB';
      textPainter.text = TextSpan(
        text: label,
        style: AppTypography.bodySmall.copyWith(
          color: db == 0.0
              ? (isEnabled ? AppColors.accentGreen.withValues(alpha: 0.6) : AppColors.textMuted)
              : AppColors.textMuted.withValues(alpha: 0.45),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - (textPainter.height / 2)));
    }

    if (frequencies.isEmpty) return;

    // 2. Calculate node points on the canvas
    final points = <Offset>[];
    for (int i = 0; i < frequencies.length; i++) {
      final freq = frequencies[i];
      final gain = (bandGains[freq] ?? 0.0).clamp(-10.0, 10.0);
      final x = padX + (i / (frequencies.length - 1)) * graphWidth;
      final y = padY + ((10.0 - gain) / 20.0) * graphHeight;
      points.add(Offset(x, y));
    }

    // 3. Build Smooth Catmull-Rom / Spline Curve Path
    final splinePath = Path();
    splinePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      for (double t = 0; t <= 1.0; t += 0.05) {
        final pt = _catmullRom(p0, p1, p2, p3, t);
        splinePath.lineTo(pt.dx, pt.dy);
      }
    }

    // 4. Draw Gradient Area Fill under Curve (relative to 0 dB line)
    final fillPath = Path.from(splinePath);
    fillPath.lineTo(points.last.dx, centerY);
    fillPath.lineTo(points.first.dx, centerY);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isEnabled
          ? [
              AppColors.accentGreen.withValues(alpha: 0.35),
              AppColors.accentIndigo.withValues(alpha: 0.15),
              AppColors.accentNeonBlue.withValues(alpha: 0.02),
            ]
          : [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
            ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTRB(padX, padY, size.width - padX, size.height - padY),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Glowing Spline Stroke Line
    final strokePaint = Paint()
      ..color = isEnabled ? AppColors.accentGreen : AppColors.textMuted
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isEnabled) {
      // Draw outer glow
      final glowPaint = Paint()
        ..color = AppColors.accentGreen.withValues(alpha: 0.3)
        ..strokeWidth = 7.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawPath(splinePath, glowPaint);
    }

    canvas.drawPath(splinePath, strokePaint);

    // 6. Draw Interactive Frequency Nodes
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final freq = frequencies[i];
      final isActive = activeFreq == freq;

      // Outer halo for node
      if (isEnabled) {
        final nodeGlowPaint = Paint()
          ..color = isActive
              ? AppColors.accentPink.withValues(alpha: 0.5)
              : AppColors.accentGreen.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, isActive ? 9.0 : 6.5, nodeGlowPaint);
      }

      // Center solid node dot
      final nodeDotPaint = Paint()
        ..color = !isEnabled
            ? AppColors.textMuted
            : (isActive ? AppColors.accentPink : AppColors.accentGreen)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isActive ? 4.5 : 3.5, nodeDotPaint);

      // Inner white core
      final whiteCorePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 1.5, whiteCorePaint);
    }
  }

  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final x = 0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y = 0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _EQCurvePainter oldDelegate) {
    return oldDelegate.bandGains != bandGains ||
        oldDelegate.frequencies != frequencies ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.activeFreq != activeFreq;
  }
}
