import 'package:flutter/material.dart';
import 'package:extractor/extractor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/features/downloader/data/extractor_service.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                      LucideIcons.zap,
                      AppColors.accentPurple,
                      'High Performance Caching',
                      'LRU memory search cache, Hive NoSQL persistence, and background isolates.',
                    ),
                    _buildFeatureBullet(
                      LucideIcons.slidersHorizontal,
                      AppColors.accentPink,
                      'Native DSP Sound Suite',
                      '10-band equalizer, dynamic bass boost, 3D spatializer, loudness & volume normalization.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // System Diagnostics Card
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
                  width: 1.0,
                ),
              ),
              child: InkWell(
                onTap: () => _showDiagnosticsSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.cpu, color: AppColors.accentCyan, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System & Device Diagnostics',
                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Engine metrics, storage boxes & runtime info',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Open Source Licenses Button
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
                  width: 1.0,
                ),
              ),
              child: InkWell(
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
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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

  void _showDiagnosticsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<VersionInfo?>(
            future: ExtractorService.instance.getVersion(),
            builder: (context, snapshot) {
              final versionInfo = snapshot.data;
              final ytdlVer = versionInfo?.youtubeDlVersion ?? 'yt-dlp (Bundled)';
              final ffmpegVer = versionInfo?.ffmpegVersion ?? 'FFmpeg 6.0';
              final isAndroid = ExtractorService.instance.isPlatformSupported;

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.cpu, color: AppColors.accentCyan, size: 22),
                        const SizedBox(width: 10),
                        Text('System Diagnostics', style: AppTypography.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDiagRow('App Framework', 'Flutter 3.x • Dart 3.13+'),
                    _buildDiagRow('UI Architecture', 'Material 3 Expressive UI'),
                    _buildDiagRow('Audio Engine', 'just_audio • 320k Opus Streamer'),
                    _buildDiagRow(
                      'Media Extractor',
                      isAndroid ? '$ytdlVer • $ffmpegVer' : 'YouTubeExplode Streamer',
                    ),
                    _buildDiagRow('DSP Processing', '10-Band EQ • Virtualizer • Bass Boost'),
                    _buildDiagRow('Local Database', 'Hive Box Storage (8 Active Boxes)'),
                    _buildDiagRow('Lyrics Engine', 'LRCLIB Synced Real-time API'),
                    if (isAndroid) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentGreen,
                            side: const BorderSide(color: AppColors.accentGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Check for yt-dlp Updates'),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checking for yt-dlp updates...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            final result = await ExtractorService.instance.updateYoutubeDL();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result?.status == OperationStatus.success
                                        ? 'yt-dlp updated: ${result?.version ?? "Latest"}'
                                        : 'yt-dlp status: ${result?.errorMessage ?? "Already up to date"}',
                                  ),
                                  backgroundColor: result?.status == OperationStatus.success
                                      ? AppColors.accentGreen
                                      : AppColors.darkSurfaceVariant,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.labelSmall.copyWith(color: AppColors.accentGreen)),
        ],
      ),
    );
  }
}
