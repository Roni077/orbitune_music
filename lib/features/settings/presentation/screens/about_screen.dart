import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';

/// Screen detailing Orbitune version, technology stack, features, and open source licenses
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('About Orbitune', style: AppTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // App Brand Logo & Name
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentCyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.orbit,
                  size: 44,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Orbitune',
              style: AppTypography.brandTitle.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0 (Build 1)',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            // Feature Highlights
            ExpressiveCard(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.darkSurfaceVariant.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Built with Next-Gen Architecture',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureBullet(
                    LucideIcons.sparkles,
                    AppColors.accentGreen,
                    'Material 3 Expressive UI',
                    'Dynamic theming, spring physics, and fluid haptic feedback.',
                  ),
                  _buildFeatureBullet(
                    LucideIcons.radio,
                    AppColors.accentCyan,
                    'YouTube Explode Audio Engine',
                    'High-fidelity pure Opus/AAC audio streaming with resilient multi-client rotation.',
                  ),
                  _buildFeatureBullet(
                    LucideIcons.slidersHorizontal,
                    AppColors.accentPink,
                    '10-Band DSP Equalizer',
                    'Bass boost, 3D virtualizer, loudness enhancer, and custom presets.',
                  ),
                  _buildFeatureBullet(
                    LucideIcons.mic,
                    AppColors.accentYellow,
                    'Synchronized Lyrics',
                    'Real-time line-by-line karaoke lyrics powered by LRCLIB.',
                  ),
                  _buildFeatureBullet(
                    LucideIcons.downloadCloud,
                    AppColors.accentPurple,
                    'Offline First Downloader',
                    'High-speed chunked downloads with local Hive persistence.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Open Source Licenses Button
            ExpressiveCard(
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Orbitune',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(LucideIcons.orbit, size: 36, color: AppColors.accentGreen),
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.darkSurfaceVariant.withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(LucideIcons.fileCode2, color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Open Source Licenses',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Crafted with ❤️ for pure musical bliss.',
              style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
