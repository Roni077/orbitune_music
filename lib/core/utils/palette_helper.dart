import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator_plus/palette_generator_plus.dart';
import '../constants/app_colors.dart';

/// Extracts dominant & vibrant colors from artwork images for dynamic ambient backgrounds
class PaletteHelper {
  PaletteHelper._();

  static const int _maxCacheSize = 40;
  static final Map<String, PaletteGenerator> _cache = {};

  static Future<PaletteGenerator> extractPalette(String imageUrl) async {
    if (imageUrl.isEmpty ||
        imageUrl.contains('example.com') ||
        imageUrl.startsWith('test://')) {
      return PaletteGenerator.fromColors([
        PaletteColor(AppColors.darkSurface, 1),
        PaletteColor(AppColors.accentGreen, 1),
      ]);
    }

    if (_cache.containsKey(imageUrl)) {
      return _cache[imageUrl]!;
    }

    try {
      final ImageProvider imageProvider = imageUrl.startsWith('http')
          ? CachedNetworkImageProvider(imageUrl)
          : NetworkImage(imageUrl);

      final generator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(96, 96),
        maximumColorCount: 12,
      ).timeout(const Duration(seconds: 3));

      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[imageUrl] = generator;
      return generator;
    } catch (_) {
      // Return dummy default generator if extraction fails
      return PaletteGenerator.fromColors([
        PaletteColor(AppColors.darkSurface, 1),
        PaletteColor(AppColors.accentGreen, 1),
      ]);
    }
  }

  static Color getDominantColor(PaletteGenerator? palette, {Color fallback = AppColors.darkSurface}) {
    if (palette == null) return fallback;
    return palette.dominantColor?.color ??
        palette.vibrantColor?.color ??
        palette.darkVibrantColor?.color ??
        palette.mutedColor?.color ??
        fallback;
  }
}
