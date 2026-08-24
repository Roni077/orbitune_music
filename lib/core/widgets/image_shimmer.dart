import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Pure native Flutter cached image loader with built-in ShaderMask shimmer skeleton placeholder
class ImageShimmer extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? errorWidget;

  const ImageShimmer({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppConstants.roundedMedium;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: NativeShimmerPlaceholder(
          width: width,
          height: height,
        ),
      );
    }

    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final memW = width != null ? (width! * dpr).clamp(32.0, 800.0).toInt() : null;
    final memH = height != null ? (height! * dpr).clamp(32.0, 800.0).toInt() : null;

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memW,
        memCacheHeight: memH,
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        placeholder: (context, url) => NativeShimmerPlaceholder(
          width: width,
          height: height,
        ),
        errorWidget: (context, url, error) => errorWidget ?? _buildFallback(effectiveRadius),
      ),
    );
  }

  Widget _buildFallback(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: radius,
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.textMuted,
          size: (width != null && height != null) ? (width! * 0.4).clamp(16.0, 48.0) : 24.0,
        ),
      ),
    );
  }
}

/// Lightweight, GPU-accelerated pure Flutter native shimmer placeholder using AnimationController + ShaderMask
class NativeShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final Color baseColor;
  final Color highlightColor;

  const NativeShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.baseColor = AppColors.darkSurface,
    this.highlightColor = AppColors.darkSurfaceElevated,
  });

  @override
  State<NativeShimmerPlaceholder> createState() => _NativeShimmerPlaceholderState();
}

class _NativeShimmerPlaceholderState extends State<NativeShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.baseColor,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}
