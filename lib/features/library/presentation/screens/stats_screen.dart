import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:orbitune/core/constants/app_colors.dart';
import 'package:orbitune/core/constants/app_typography.dart';
import 'package:orbitune/core/widgets/empty_state_view.dart';
import 'package:orbitune/core/widgets/expressive_card.dart';
import 'package:orbitune/features/audio_player/presentation/providers/player_provider.dart';
import 'package:orbitune/features/library/domain/models/listening_stats.dart';
import 'package:orbitune/features/library/presentation/providers/history_provider.dart';
import 'package:orbitune/features/library/presentation/providers/stats_provider.dart';

/// Screen displaying comprehensive listening stats, daily/weekly charts, top artists and songs
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final history = ref.watch(historyProvider);

    final hasStats = stats.totalPlays > 0 || stats.totalListeningTime > Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Listening Insights', style: AppTypography.titleLarge),
      ),
      body: !hasStats
          ? const EmptyStateView(
              icon: LucideIcons.barChart2,
              title: 'No Stats Available Yet',
              message:
                  'Keep listening to music to unlock detailed insights about your favorite artists, genres, streaks, and listening habits.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Key Metrics 2x2 Grid
                  _buildMetricsGrid(stats),

                  const SizedBox(height: 20),

                  // 2. Weekly Activity Bar Chart
                  _buildWeeklyActivityCard(stats),

                  const SizedBox(height: 20),

                  // 3. Top Artists Distribution
                  if (stats.artistPlayCounts.isNotEmpty) ...[
                    _buildTopArtistsCard(stats),
                    const SizedBox(height: 20),
                  ],

                  // 4. Top Genres Distribution
                  if (stats.genrePlayCounts.isNotEmpty) ...[
                    _buildTopGenresCard(stats),
                    const SizedBox(height: 20),
                  ],

                  // 5. Most Played Tracks
                  if (stats.songPlayCounts.isNotEmpty) ...[
                    _buildTopPlayedSongsCard(context, ref, stats, history),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsGrid(ListeningStats stats) {
    final totalHours = stats.totalListeningTime.inHours;
    final totalMinutes = stats.totalListeningTime.inMinutes.remainder(60);
    final timeStr = totalHours > 0
        ? '${totalHours}h ${totalMinutes}m'
        : '${totalMinutes}m';

    String topGenre = 'Various';
    if (stats.genrePlayCounts.isNotEmpty) {
      final sortedGenres = stats.genrePlayCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topGenre = sortedGenres.first.key;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildMetricItem(
          icon: LucideIcons.clock,
          accentColor: AppColors.accentGreen,
          label: 'Listening Time',
          value: timeStr,
        ),
        _buildMetricItem(
          icon: LucideIcons.music,
          accentColor: AppColors.accentCyan,
          label: 'Total Plays',
          value: '${stats.totalPlays}',
        ),
        _buildMetricItem(
          icon: LucideIcons.flame,
          accentColor: AppColors.accentOrange,
          label: 'Daily Streak',
          value: '${stats.streakDays} ${stats.streakDays == 1 ? 'Day' : 'Days'}',
        ),
        _buildMetricItem(
          icon: LucideIcons.radio,
          accentColor: AppColors.accentPurple,
          label: 'Top Genre',
          value: topGenre,
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color accentColor,
    required String label,
    required String value,
  }) {
    return ExpressiveCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      color: AppColors.darkSurfaceVariant.withOpacity(0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityCard(ListeningStats stats) {
    // Generate data for the last 7 days
    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    final barGroups = <BarChartGroupData>[];
    double maxY = 10.0;

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final minutes = (stats.dailyListeningMinutes[key] ?? 0).toDouble();
      if (minutes > maxY) maxY = minutes + 10;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: minutes,
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.accentGreen, AppColors.accentCyan],
              ),
              width: 14,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: AppColors.white.withOpacity(0.04),
              ),
            ),
          ],
        ),
      );
    }

    return ExpressiveCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.barChart, size: 18, color: AppColors.accentGreen),
              const SizedBox(width: 8),
              Text(
                'Weekly Activity (Minutes)',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: math.max(maxY, 20.0),
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          '${val.toInt()}m',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          final label = DateFormat('E').format(days[idx]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: idx == days.length - 1
                                    ? AppColors.accentGreen
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: idx == days.length - 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtistsCard(ListeningStats stats) {
    final sortedArtists = stats.artistPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists.take(5).toList();
    final maxPlays = topArtists.first.value;

    return ExpressiveCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, size: 18, color: AppColors.accentCyan),
              const SizedBox(width: 8),
              Text(
                'Top Artists',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topArtists.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final ratio = maxPlays > 0 ? item.value / maxPlays : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${index + 1}  ${item.key}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.value} ${item.value == 1 ? 'play' : 'plays'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        index == 0
                            ? AppColors.accentGreen
                            : index == 1
                                ? AppColors.accentCyan
                                : AppColors.accentPurple,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopGenresCard(ListeningStats stats) {
    final sortedGenres = stats.genrePlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(6).toList();

    return ExpressiveCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.disc, size: 18, color: AppColors.accentPurple),
              const SizedBox(width: 8),
              Text(
                'Top Genres',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topGenres.map((g) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${g.key} • ${g.value}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayedSongsCard(
    BuildContext context,
    WidgetRef ref,
    ListeningStats stats,
    List<dynamic> history,
  ) {
    final sortedSongCounts = stats.songPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSongEntries = sortedSongCounts.take(10).toList();

    return ExpressiveCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      color: AppColors.darkSurfaceVariant.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trophy, size: 18, color: AppColors.accentYellow),
              const SizedBox(width: 8),
              Text(
                'Most Played Songs',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topSongEntries.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final songId = entry.value.key;
            final playCount = entry.value.value;

            // Find song metadata from history
            final historyMatch = history.cast<dynamic>().firstWhere(
                  (h) => h.track.id == songId,
                  orElse: () => null,
                );
            final title = historyMatch?.track.title ?? 'Track #$songId';
            final artist = historyMatch?.track.artist ?? 'Artist';

            Color rankBadgeColor = AppColors.textTertiary;
            if (rank == 1) rankBadgeColor = const Color(0xFFFFD700); // Gold
            if (rank == 2) rankBadgeColor = const Color(0xFFC0C0C0); // Silver
            if (rank == 3) rankBadgeColor = const Color(0xFFCD7F32); // Bronze

            return Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rankBadgeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankBadgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  title,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  artist,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '$playCount plays',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  if (historyMatch != null) {
                    ref.read(playerProvider.notifier).playTrack(historyMatch.track);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
