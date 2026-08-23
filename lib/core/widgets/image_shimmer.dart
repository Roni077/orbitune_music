import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Cached image loader with shimmer skeleton placeholder and error fallback
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
        child: Shimmer.fromColors(
          baseColor: AppColors.darkSurface,
          highlightColor: AppColors.darkSurfaceElevated,
          child: Container(
            width: width,
            height: height,
            color: AppColors.darkSurface,
          ),
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
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: AppColors.darkSurface,
          highlightColor: AppColors.darkSurfaceElevated,
          child: Container(
            width: width,
            height: height,
            color: AppColors.darkSurface,
          ),
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
