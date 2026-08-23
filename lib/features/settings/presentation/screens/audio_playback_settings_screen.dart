import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:orbitune/features/settings/presentation/dialogs/audio_quality_selection_dialog.dart';
import 'package:orbitune/features/settings/presentation/providers/settings_provider.dart';
import 'package:orbitune/features/settings/presentation/widgets/settings_tile.dart';

/// Sub-Screen dedicated to Audio Engine, Bitrates, Equalizer, and Playback Transitions
class AudioPlaybackSettingsScreen extends ConsumerWidget {
  const AudioPlaybackSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AudioPlaybackSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Audio & Playback', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // 1. AUDIO STREAMING & BITRATE
          _buildSectionHeader('Streaming & Codecs'),
          _buildCard(
            child: Column(
              children: [
                // Streaming Quality
                SettingsTile(
                  icon: LucideIcons.radio,
                  iconColor: AppColors.accentCyan,
                  title: 'Streaming Quality',
                  subtitle:
                      '${settings.streamingQuality.label} • ${settings.streamingQuality.description}',
                  badgeText: settings.streamingQuality == AudioQuality.lossless
                      ? 'FLAC'
                      : '${settings.streamingQuality.bitrateKbps}K',
                  badgeColor: AppColors.accentCyan,
                  showChevron: true,
                  onTap: () => AudioQualitySelectionSheet.show(
                    context,
                    currentQuality: settings.streamingQuality,
                    onQualitySelected: (q) => notifier.setStreamingQuality(q),
                    isDownload: false,
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // Download Quality
                SettingsTile(
                  icon: LucideIcons.downloadCloud,
                  iconColor: AppColors.accentGreen,
                  title: 'Download Quality',
                  subtitle:
                      '${settings.downloadQuality.label} • Offline storage footprint',
                  badgeText: settings.downloadQuality == AudioQuality.lossless
                      ? 'FLAC'
                      : '${settings.downloadQuality.bitrateKbps}K',
                  badgeColor: AppColors.accentGreen,
                  showChevron: true,
                  onTap: () => AudioQualitySelectionSheet.show(
                    context,
                    currentQuality: settings.downloadQuality,
                    onQualitySelected: (q) => notifier.setDownloadQuality(q),
                    isDownload: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. EQUALIZER & DSP
          _buildSectionHeader('Digital Signal Processing'),
          _buildCard(
            child: SettingsTile(
              icon: LucideIcons.slidersHorizontal,
              iconColor: AppColors.accentPink,
              title: '10-Band DSP Equalizer',
              subtitle: settings.equalizerEnabled
                  ? 'Active Preset: ${settings.equalizerPreset}'
                  : 'Bass Boost, 3D Virtualizer & Custom Gains',
              badgeText: settings.equalizerEnabled ? 'ACTIVE' : null,
              badgeColor: AppColors.accentGreen,
              showChevron: true,
              onTap: () => EqualizerScreen.open(context),
            ),
          ),
          const SizedBox(height: 20),

          // 3. TRANSITIONS & CROSSFADE
          _buildSectionHeader('Transitions & Playback Flow'),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crossfade
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.gitFork, size: 20, color: AppColors.accentOrange),
                        ),
                        const SizedBox(width: 12),
                        Text('Crossfade Duration', style: AppTypography.titleSmall),
                      ],
                    ),
                    Text(
                      settings.crossfadeDurationSeconds == 0
                          ? 'Disabled'
                          : '${settings.crossfadeDurationSeconds}s',
                      style: AppTypography.labelMedium.copyWith(
                        color: settings.crossfadeDurationSeconds > 0
                            ? AppColors.accentGreen
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: settings.crossfadeDurationSeconds.toDouble(),
                  min: 0,
                  max: 12,
                  divisions: 12,
                  activeColor: AppColors.accentGreen,
                  inactiveColor: AppColors.white.withValues(alpha: 0.1),
                  onChanged: (val) => notifier.setCrossfadeDuration(val.toInt()),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // Gapless Playback
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.music, size: 20, color: AppColors.accentPurple),
                  ),
                  title: Text('Gapless Playback', style: AppTypography.titleSmall),
                  subtitle: Text('Preload next track for continuous transitions',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.gaplessPlayback,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setGaplessPlayback(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // AutoPlay Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.sparkles, size: 20, color: AppColors.accentYellow),
                  ),
                  title: Text('AutoPlay Similar Tracks', style: AppTypography.titleSmall),
                  subtitle: Text('Seamlessly append recommended songs when queue ends',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.autoPlay,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setAutoPlay(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),

                // Skip Silence
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.volumeX, size: 20, color: AppColors.accentCyan),
                  ),
                  title: Text('Skip Silent Sections', style: AppTypography.titleSmall),
                  subtitle: Text('Fast forward through silent intros and track outros',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.skipSilence,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setSkipSilence(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. AUDIO FOCUS & VOLUME NORMALIZATION
          _buildSectionHeader('Focus & Normalization'),
          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.headphones, size: 20, color: AppColors.accentEmerald),
                  ),
                  title: Text('Pause on Disconnect', style: AppTypography.titleSmall),
                  subtitle: Text('Instantly pause playback when headphones or Bluetooth unplug',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.pauseOnUnplug,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setPauseOnUnplug(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.bluetooth, size: 20, color: AppColors.accentIndigo),
                  ),
                  title: Text('Resume on Bluetooth Reconnect', style: AppTypography.titleSmall),
                  subtitle: Text('Automatically resume playback when audio accessory reconnects',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.resumeOnBluetooth,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setResumeOnBluetooth(val),
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.volume2, size: 20, color: AppColors.accentAmber),
                  ),
                  title: Text('ReplayGain Normalization', style: AppTypography.titleSmall),
                  subtitle: Text('Equalize volume across different songs to prevent jarring volume jumps',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: settings.audioNormalization,
                  activeTrackColor: AppColors.accentGreen,
                  onChanged: (val) => notifier.setAudioNormalization(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. SYSTEM & LOCK SCREEN CONTROLS
          _buildSectionHeader('System & Lock Screen Controls'),
          _buildCard(
            child: Column(
              children: [
                SettingsTile(
                  icon: LucideIcons.bellRing,
                  iconColor: AppColors.accentCyan,
                  title: 'Notification & Lock Screen Player',
                  subtitle:
                      'Rich mini player with album artwork, seekbar, previous/next and play/pause controls',
                  badgeText: 'ACTIVE',
                  badgeColor: AppColors.accentGreen,
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                SettingsTile(
                  icon: LucideIcons.smartphone,
                  iconColor: AppColors.accentPurple,
                  title: 'Lock Screen Media Session',
                  subtitle:
                      'Compact 3-button playback controls and instant resume while device is locked',
                  badgeText: 'INTEGRATED',
                  badgeColor: AppColors.accentCyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.accentGreen,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return ExpressiveCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withValues(alpha: 0.55),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
