import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';
import 'package:orbitune/features/audio_player/domain/models/track.dart';

/// Status of offline media download task
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Offline media download record
class DownloadTask {
  final String id;
  final Track track;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? localFilePath;
  final AudioQuality quality;
  final int bytesPerSecond;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;

  DownloadTask({
    required this.id,
    required this.track,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.bytesPerSecond = 0,
    this.localFilePath,
    this.quality = AudioQuality.high320k,
    this.errorMessage,
    DateTime? startedAt,
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isPaused => status == DownloadStatus.paused;

  Duration? get estimatedTimeRemaining {
    if (bytesPerSecond <= 0 || totalBytes <= downloadedBytes) return null;
    final remainingBytes = totalBytes - downloadedBytes;
    return Duration(seconds: (remainingBytes / bytesPerSecond).ceil());
  }

  DownloadTask copyWith({
    String? id,
    Track? track,
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? localFilePath,
    AudioQuality? quality,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      track: track ?? this.track,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      localFilePath: localFilePath ?? this.localFilePath,
      quality: quality ?? this.quality,
      errorMessage: errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'track': track.toMap(),
      'status': status.name,
      'progress': progress,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'localFilePath': localFilePath,
      'quality': quality.name,
      'errorMessage': errorMessage,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DownloadTask.fromMap(Map<dynamic, dynamic> map) {
    return DownloadTask(
      id: map['id']?.toString() ?? '',
      track: Track.fromMap(map['track'] as Map<dynamic, dynamic>),
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.pending,
      ),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      localFilePath: map['localFilePath']?.toString(),
      quality: AudioQuality.fromString(map['quality']?.toString()),
      errorMessage: map['errorMessage']?.toString(),
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DownloadTask.fromJson(String source) =>
      DownloadTask.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
