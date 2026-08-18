import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';

/// Central application settings and user preferences model
class AppSettings {
  final String themeMode; // 'dark', 'oled', 'dynamic', 'light'
  final AudioQuality streamingQuality;
  final AudioQuality downloadQuality;
  final bool autoPlay;
  final bool gaplessPlayback;
  final int crossfadeDurationSeconds;
  final bool stopOnAppClose;
  final bool wifiOnlyStreaming;
  final bool wifiOnlyDownloads;
  final int cacheSizeLimitMb;
  final bool searchHistoryEnabled;
  final bool listeningHistoryEnabled;
  final bool dynamicColorEnabled;
  final bool amoledModeEnabled;
  final String language;
  final bool equalizerEnabled;
  final String equalizerPreset;

  const AppSettings({
    this.themeMode = 'dark',
    this.streamingQuality = AudioQuality.high320k,
    this.downloadQuality = AudioQuality.high320k,
    this.autoPlay = true,
    this.gaplessPlayback = true,
    this.crossfadeDurationSeconds = 0,
    this.stopOnAppClose = false,
    this.wifiOnlyStreaming = false,
    this.wifiOnlyDownloads = false,
    this.cacheSizeLimitMb = 1024,
    this.searchHistoryEnabled = true,
    this.listeningHistoryEnabled = true,
    this.dynamicColorEnabled = true,
    this.amoledModeEnabled = false,
    this.language = 'en',
    this.equalizerEnabled = false,
    this.equalizerPreset = 'Flat',
  });

  AppSettings copyWith({
    String? themeMode,
    AudioQuality? streamingQuality,
    AudioQuality? downloadQuality,
    bool? autoPlay,
    bool? gaplessPlayback,
    int? crossfadeDurationSeconds,
    bool? stopOnAppClose,
    bool? wifiOnlyStreaming,
    bool? wifiOnlyDownloads,
    int? cacheSizeLimitMb,
    bool? searchHistoryEnabled,
    bool? listeningHistoryEnabled,
    bool? dynamicColorEnabled,
    bool? amoledModeEnabled,
    String? language,
    bool? equalizerEnabled,
    String? equalizerPreset,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      autoPlay: autoPlay ?? this.autoPlay,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      crossfadeDurationSeconds:
          crossfadeDurationSeconds ?? this.crossfadeDurationSeconds,
      stopOnAppClose: stopOnAppClose ?? this.stopOnAppClose,
      wifiOnlyStreaming: wifiOnlyStreaming ?? this.wifiOnlyStreaming,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
      searchHistoryEnabled:
          searchHistoryEnabled ?? this.searchHistoryEnabled,
      listeningHistoryEnabled:
          listeningHistoryEnabled ?? this.listeningHistoryEnabled,
      dynamicColorEnabled: dynamicColorEnabled ?? this.dynamicColorEnabled,
      amoledModeEnabled: amoledModeEnabled ?? this.amoledModeEnabled,
      language: language ?? this.language,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'streamingQuality': streamingQuality.name,
      'downloadQuality': downloadQuality.name,
      'autoPlay': autoPlay,
      'gaplessPlayback': gaplessPlayback,
      'crossfadeDurationSeconds': crossfadeDurationSeconds,
      'stopOnAppClose': stopOnAppClose,
      'wifiOnlyStreaming': wifiOnlyStreaming,
      'wifiOnlyDownloads': wifiOnlyDownloads,
      'cacheSizeLimitMb': cacheSizeLimitMb,
      'searchHistoryEnabled': searchHistoryEnabled,
      'listeningHistoryEnabled': listeningHistoryEnabled,
      'dynamicColorEnabled': dynamicColorEnabled,
      'amoledModeEnabled': amoledModeEnabled,
      'language': language,
      'equalizerEnabled': equalizerEnabled,
      'equalizerPreset': equalizerPreset,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      themeMode: map['themeMode']?.toString() ?? 'dark',
      streamingQuality:
          AudioQuality.fromString(map['streamingQuality']?.toString()),
      downloadQuality:
          AudioQuality.fromString(map['downloadQuality']?.toString()),
      autoPlay: map['autoPlay'] != false,
      gaplessPlayback: map['gaplessPlayback'] != false,
      crossfadeDurationSeconds:
          (map['crossfadeDurationSeconds'] as num?)?.toInt() ?? 0,
      stopOnAppClose: map['stopOnAppClose'] == true,
      wifiOnlyStreaming: map['wifiOnlyStreaming'] == true,
      wifiOnlyDownloads: map['wifiOnlyDownloads'] == true,
      cacheSizeLimitMb:
          (map['cacheSizeLimitMb'] as num?)?.toInt() ?? 1024,
      searchHistoryEnabled: map['searchHistoryEnabled'] != false,
      listeningHistoryEnabled: map['listeningHistoryEnabled'] != false,
      dynamicColorEnabled: map['dynamicColorEnabled'] != false,
      amoledModeEnabled: map['amoledModeEnabled'] == true,
      language: map['language']?.toString() ?? 'en',
      equalizerEnabled: map['equalizerEnabled'] == true,
      equalizerPreset: map['equalizerPreset']?.toString() ?? 'Flat',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
