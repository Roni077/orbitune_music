import 'dart:convert';
import 'package:orbitune/features/audio_player/domain/models/audio_quality.dart';

/// Central application settings and user preferences model
class AppSettings {
  final String themeMode; // 'dark', 'oled', 'dynamic', 'light', 'solarized', 'cyberpunk'
  final int accentColorIndex;
  final String fontFamily;
  final double cornerRadius;
  final bool enableGlassmorphism;
  final bool enableVisualizer;
  final bool showBitrateBadge;
  final AudioQuality streamingQuality;
  final AudioQuality downloadQuality;
  final bool autoPlay;
  final bool gaplessPlayback;
  final int crossfadeDurationSeconds;
  final bool audioNormalization;
  final bool pauseOnUnplug;
  final bool resumeOnBluetooth;
  final bool skipSilence;
  final bool stopOnAppClose;
  final bool wifiOnlyStreaming;
  final bool wifiOnlyDownloads;
  final int cacheSizeLimitMb;
  final bool searchHistoryEnabled;
  final bool listeningHistoryEnabled;
  final bool incognitoMode;
  final bool dynamicColorEnabled;
  final bool amoledModeEnabled;
  final String language;
  final String contentCountry;
  final String lyricsSource;
  final bool explicitFilter;
  final bool equalizerEnabled;
  final String equalizerPreset;
  
  // User Profile & Persona
  final bool hasCompletedOnboarding;
  final String? username;
  final String? country;
  final String avatarIcon;
  final int avatarColorIndex;
  final String? customAvatarPath;
  final String? bio;
  final String profileBadge;
  final String? favoriteGenre;

  const AppSettings({
    this.themeMode = 'dark',
    this.accentColorIndex = 0,
    this.fontFamily = 'righteous_poppins',
    this.cornerRadius = 20.0,
    this.enableGlassmorphism = true,
    this.enableVisualizer = true,
    this.showBitrateBadge = true,
    this.streamingQuality = AudioQuality.high320k,
    this.downloadQuality = AudioQuality.high320k,
    this.autoPlay = true,
    this.gaplessPlayback = true,
    this.crossfadeDurationSeconds = 0,
    this.audioNormalization = false,
    this.pauseOnUnplug = true,
    this.resumeOnBluetooth = false,
    this.skipSilence = false,
    this.stopOnAppClose = false,
    this.wifiOnlyStreaming = false,
    this.wifiOnlyDownloads = false,
    this.cacheSizeLimitMb = 1024,
    this.searchHistoryEnabled = true,
    this.listeningHistoryEnabled = true,
    this.incognitoMode = false,
    this.dynamicColorEnabled = true,
    this.amoledModeEnabled = false,
    this.language = 'en',
    this.contentCountry = 'US',
    this.lyricsSource = 'lrclib',
    this.explicitFilter = false,
    this.equalizerEnabled = false,
    this.equalizerPreset = 'Flat',
    this.hasCompletedOnboarding = false,
    this.username,
    this.country,
    this.avatarIcon = 'user',
    this.avatarColorIndex = 0,
    this.customAvatarPath,
    this.bio = 'Listening on Orbitune',
    this.profileBadge = 'Hi-Fi',
    this.favoriteGenre = 'All-Rounder',
  });

  AppSettings copyWith({
    String? themeMode,
    int? accentColorIndex,
    String? fontFamily,
    double? cornerRadius,
    bool? enableGlassmorphism,
    bool? enableVisualizer,
    bool? showBitrateBadge,
    AudioQuality? streamingQuality,
    AudioQuality? downloadQuality,
    bool? autoPlay,
    bool? gaplessPlayback,
    int? crossfadeDurationSeconds,
    bool? audioNormalization,
    bool? pauseOnUnplug,
    bool? resumeOnBluetooth,
    bool? skipSilence,
    bool? stopOnAppClose,
    bool? wifiOnlyStreaming,
    bool? wifiOnlyDownloads,
    int? cacheSizeLimitMb,
    bool? searchHistoryEnabled,
    bool? listeningHistoryEnabled,
    bool? incognitoMode,
    bool? dynamicColorEnabled,
    bool? amoledModeEnabled,
    String? language,
    String? contentCountry,
    String? lyricsSource,
    bool? explicitFilter,
    bool? equalizerEnabled,
    String? equalizerPreset,
    bool? hasCompletedOnboarding,
    String? username,
    String? country,
    String? avatarIcon,
    int? avatarColorIndex,
    String? customAvatarPath,
    bool clearCustomAvatar = false,
    String? bio,
    String? profileBadge,
    String? favoriteGenre,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      fontFamily: fontFamily ?? this.fontFamily,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      enableGlassmorphism: enableGlassmorphism ?? this.enableGlassmorphism,
      enableVisualizer: enableVisualizer ?? this.enableVisualizer,
      showBitrateBadge: showBitrateBadge ?? this.showBitrateBadge,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      autoPlay: autoPlay ?? this.autoPlay,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      crossfadeDurationSeconds:
          crossfadeDurationSeconds ?? this.crossfadeDurationSeconds,
      audioNormalization: audioNormalization ?? this.audioNormalization,
      pauseOnUnplug: pauseOnUnplug ?? this.pauseOnUnplug,
      resumeOnBluetooth: resumeOnBluetooth ?? this.resumeOnBluetooth,
      skipSilence: skipSilence ?? this.skipSilence,
      stopOnAppClose: stopOnAppClose ?? this.stopOnAppClose,
      wifiOnlyStreaming: wifiOnlyStreaming ?? this.wifiOnlyStreaming,
      wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
      cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
      searchHistoryEnabled:
          searchHistoryEnabled ?? this.searchHistoryEnabled,
      listeningHistoryEnabled:
          listeningHistoryEnabled ?? this.listeningHistoryEnabled,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      dynamicColorEnabled: dynamicColorEnabled ?? this.dynamicColorEnabled,
      amoledModeEnabled: amoledModeEnabled ?? this.amoledModeEnabled,
      language: language ?? this.language,
      contentCountry: contentCountry ?? this.contentCountry,
      lyricsSource: lyricsSource ?? this.lyricsSource,
      explicitFilter: explicitFilter ?? this.explicitFilter,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      username: username ?? this.username,
      country: country ?? this.country,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      customAvatarPath: clearCustomAvatar ? null : (customAvatarPath ?? this.customAvatarPath),
      bio: bio ?? this.bio,
      profileBadge: profileBadge ?? this.profileBadge,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'accentColorIndex': accentColorIndex,
      'fontFamily': fontFamily,
      'cornerRadius': cornerRadius,
      'enableGlassmorphism': enableGlassmorphism,
      'enableVisualizer': enableVisualizer,
      'showBitrateBadge': showBitrateBadge,
      'streamingQuality': streamingQuality.name,
      'downloadQuality': downloadQuality.name,
      'autoPlay': autoPlay,
      'gaplessPlayback': gaplessPlayback,
      'crossfadeDurationSeconds': crossfadeDurationSeconds,
      'audioNormalization': audioNormalization,
      'pauseOnUnplug': pauseOnUnplug,
      'resumeOnBluetooth': resumeOnBluetooth,
      'skipSilence': skipSilence,
      'stopOnAppClose': stopOnAppClose,
      'wifiOnlyStreaming': wifiOnlyStreaming,
      'wifiOnlyDownloads': wifiOnlyDownloads,
      'cacheSizeLimitMb': cacheSizeLimitMb,
      'searchHistoryEnabled': searchHistoryEnabled,
      'listeningHistoryEnabled': listeningHistoryEnabled,
      'incognitoMode': incognitoMode,
      'dynamicColorEnabled': dynamicColorEnabled,
      'amoledModeEnabled': amoledModeEnabled,
      'language': language,
      'contentCountry': contentCountry,
      'lyricsSource': lyricsSource,
      'explicitFilter': explicitFilter,
      'equalizerEnabled': equalizerEnabled,
      'equalizerPreset': equalizerPreset,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'username': username,
      'country': country,
      'avatarIcon': avatarIcon,
      'avatarColorIndex': avatarColorIndex,
      'customAvatarPath': customAvatarPath,
      'bio': bio,
      'profileBadge': profileBadge,
      'favoriteGenre': favoriteGenre,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      themeMode: map['themeMode']?.toString() ?? 'dark',
      accentColorIndex: (map['accentColorIndex'] as num?)?.toInt() ?? 0,
      fontFamily: map['fontFamily']?.toString() ?? 'righteous_poppins',
      cornerRadius: (map['cornerRadius'] as num?)?.toDouble() ?? 20.0,
      enableGlassmorphism: map['enableGlassmorphism'] != false,
      enableVisualizer: map['enableVisualizer'] != false,
      showBitrateBadge: map['showBitrateBadge'] != false,
      streamingQuality:
          AudioQuality.fromString(map['streamingQuality']?.toString()),
      downloadQuality:
          AudioQuality.fromString(map['downloadQuality']?.toString()),
      autoPlay: map['autoPlay'] != false,
      gaplessPlayback: map['gaplessPlayback'] != false,
      crossfadeDurationSeconds:
          (map['crossfadeDurationSeconds'] as num?)?.toInt() ?? 0,
      audioNormalization: map['audioNormalization'] == true,
      pauseOnUnplug: map['pauseOnUnplug'] != false,
      resumeOnBluetooth: map['resumeOnBluetooth'] == true,
      skipSilence: map['skipSilence'] == true,
      stopOnAppClose: map['stopOnAppClose'] == true,
      wifiOnlyStreaming: map['wifiOnlyStreaming'] == true,
      wifiOnlyDownloads: map['wifiOnlyDownloads'] == true,
      cacheSizeLimitMb:
          (map['cacheSizeLimitMb'] as num?)?.toInt() ?? 1024,
      searchHistoryEnabled: map['searchHistoryEnabled'] != false,
      listeningHistoryEnabled: map['listeningHistoryEnabled'] != false,
      incognitoMode: map['incognitoMode'] == true,
      dynamicColorEnabled: map['dynamicColorEnabled'] != false,
      amoledModeEnabled: map['amoledModeEnabled'] == true,
      language: map['language']?.toString() ?? 'en',
      contentCountry: map['contentCountry']?.toString() ?? 'US',
      lyricsSource: map['lyricsSource']?.toString() ?? 'lrclib',
      explicitFilter: map['explicitFilter'] == true,
      equalizerEnabled: map['equalizerEnabled'] == true,
      equalizerPreset: map['equalizerPreset']?.toString() ?? 'Flat',
      hasCompletedOnboarding: map['hasCompletedOnboarding'] == true,
      username: map['username']?.toString(),
      country: map['country']?.toString(),
      avatarIcon: map['avatarIcon']?.toString() ?? 'user',
      avatarColorIndex: (map['avatarColorIndex'] as num?)?.toInt() ?? 0,
      customAvatarPath: map['customAvatarPath']?.toString(),
      bio: map['bio']?.toString() ?? 'Listening on Orbitune',
      profileBadge: map['profileBadge']?.toString() ?? 'Hi-Fi',
      favoriteGenre: map['favoriteGenre']?.toString() ?? 'All-Rounder',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
