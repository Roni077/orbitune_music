import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/utils/formatters.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';

/// Waveform styled audio progress bar with draggable scrubber and seek preview
class WaveformSeekBar extends ConsumerStatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;
  final Color? activeColor;
  final Color? inactiveColor;

  const WaveformSeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.onSeek,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  ConsumerState<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends ConsumerState<WaveformSeekBar> {
  double? _dragValue;
  bool _isDragging = false;

  static const List<double> _waveformHeights = [
    0.3, 0.45, 0.7, 0.9, 0.5, 0.35, 0.6, 0.85, 0.95, 0.65,
    0.4, 0.55, 0.8, 1.0, 0.75, 0.5, 0.3, 0.6, 0.85, 0.7,
    0.45, 0.3, 0.65, 0.9, 0.8, 0.55, 0.4, 0.7, 0.95, 0.6,
    0.35, 0.5, 0.8, 0.95, 0.75, 0.45, 0.3, 0.6, 0.85, 0.5,
  ];

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.accentGreen;
    final inactiveColor =
        widget.inactiveColor ?? AppColors.darkSurfaceVariant;

    final totalMs = widget.duration.inMilliseconds > 0
        ? widget.duration.inMilliseconds.toDouble()
        : 1.0;

    final currentMs = _isDragging && _dragValue != null
        ? _dragValue!
        : widget.position.inMilliseconds.toDouble().clamp(0.0, totalMs);

    final progressRatio = (currentMs / totalMs).clamp(0.0, 1.0);
    final displayedPosition = Duration(milliseconds: currentMs.toInt());
    final remainingDuration = widget.duration - displayedPosition;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform Visual & Scrubber Slider
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() {
              _isDragging = true;
            });
          },
          onHorizontalDragUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              final localX = details.localPosition.dx;
              final width = box.size.width;
              final ratio = (localX / width).clamp(0.0, 1.0);
              setState(() {
                _dragValue = ratio * totalMs;
              });
              HapticFeedback.selectionClick();
            }
          },
          onHorizontalDragEnd: (details) {
            if (_dragValue != null) {
              final seekTo = Duration(milliseconds: _dragValue!.toInt());
              if (widget.onSeek != null) {
                widget.onSeek!(seekTo);
              } else {
                ref.read(playerProvider.notifier).seek(seekTo);
              }
            }
            setState(() {
              _isDragging = false;
              _dragValue = null;
            });
            HapticFeedback.mediumImpact();
          },
          child: SizedBox(
            height: 38,
            child: CustomPaint(
              size: const Size(double.infinity, 38),
              painter: _WaveformPainter(
                progress: progressRatio,
                waveformHeights: _waveformHeights,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDragging: _isDragging,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Time Stamps (Elapsed vs Remaining)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.formatDuration(displayedPosition),
                style: AppTypography.labelSmall.copyWith(
                  color: _isDragging
                      ? activeColor
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '-${Formatters.formatDuration(remainingDuration.isNegative ? Duration.zero : remainingDuration)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final List<double> waveformHeights;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDragging;

  _WaveformPainter({
    required this.progress,
    required this.waveformHeights,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = waveformHeights.length;
    final spacing = 2.5;
    final totalSpacing = (barCount - 1) * spacing;
    final barWidth = ((size.width - totalSpacing) / barCount).clamp(2.0, 8.0);
    final midY = size.height / 2;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final barProgress = i / barCount;
      final isBarActive = barProgress <= progress;

      final normalizedHeight = waveformHeights[i];
      final barHeight = (normalizedHeight * (size.height - 12)).clamp(4.0, size.height - 12);
      final y = midY - (barHeight / 2);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2.0),
      );

      canvas.drawRRect(rrect, isBarActive ? activePaint : inactivePaint);
    }

    // Draw active scrubber head thumb
    final thumbX = (progress * size.width).clamp(0.0, size.width);
    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: isDragging ? 0.6 : 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(thumbX, midY), isDragging ? 8.0 : 5.0, glowPaint);
    canvas.drawCircle(Offset(thumbX, midY), isDragging ? 6.0 : 4.0, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.activeColor != activeColor;
}
