import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Morphing Animated Play/Pause button with spring feedback & glow
class AnimatedPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final Color? iconColor;

  const AnimatedPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 56.0,
    this.color,
    this.iconColor,
  });

  @override
  State<AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<AnimatedPlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.fastAnimation,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.accentGreen;
    final effectiveIconColor = widget.iconColor ?? AppColors.getAccessibleTextColor(effectiveColor);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          width: widget.size.clamp(AppConstants.minTouchTarget, 120.0),
          height: widget.size.clamp(AppConstants.minTouchTarget, 120.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveColor,
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: widget.isPlaying ? 0.45 : 0.25),
                blurRadius: widget.isPlaying ? 20.0 : 12.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.isPlaying ? LucideIcons.pause : LucideIcons.play,
                key: ValueKey<bool>(widget.isPlaying),
                color: effectiveIconColor,
                size: widget.size * 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
