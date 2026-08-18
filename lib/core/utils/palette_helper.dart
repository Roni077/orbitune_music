import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../constants/app_colors.dart';

/// Extracts dominant & vibrant colors from artwork images for dynamic ambient backgrounds
class PaletteHelper {
  PaletteHelper._();

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
      final generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(128, 128),
        maximumColorCount: 16,
      ).timeout(const Duration(seconds: 3));
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
