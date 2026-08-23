/// String & number formatters for audio durations, bitrates, and counts
class Formatters {
  Formatters._();

  static String _twoDigits(int n) => n >= 10 ? '$n' : '0$n';

  /// Format seconds/duration into 'mm:ss' or 'hh:mm:ss'
  static String formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minStr = _twoDigits(minutes);
    final secStr = _twoDigits(seconds);

    if (hours > 0) {
      return '${_twoDigits(hours)}:$minStr:$secStr';
    }
    return '$minStr:$secStr';
  }

  /// Format view/play counts into human readable strings (e.g. 1.2M, 450K)
  static String formatCompactNumber(int? count) {
    if (count == null) return '0';
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Alias for play / follower counts
  static String formatPlayCount(int? count) => formatCompactNumber(count);

  /// Format byte size into readable string (e.g. 8.4 MB)
  static String formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }
}
