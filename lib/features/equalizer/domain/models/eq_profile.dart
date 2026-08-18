import 'dart:convert';
import 'eq_band_mode.dart';
import 'eq_preset.dart';

/// Active Equalizer profile containing DSP parameters, multi-band gains and audio enhancements
class EQProfile {
  final bool isEnabled;
  final EQBandMode bandMode;
  final String presetName;
  final Map<int, double> customBandGains; // Frequency -> Gain in dB (-10dB to +10dB)
  final double bassBoost; // 0.0 to 1.0 (0% to 100%)
  final double virtualizer; // 0.0 to 1.0 (3D surround sound)
  final double loudnessGain; // 0.0 to 1.0
  final double balance; // -1.0 (Left) to +1.0 (Right), 0.0 is Center
  final bool monoAudio;
  final double stereoEnhancement; // 0.0 to 1.0
  final bool volumeNormalization;
  final double replayGain; // -6.0 to +6.0 dB
  final List<EQPreset> customPresets;

  const EQProfile({
    this.isEnabled = false,
    this.bandMode = EQBandMode.band10,
    this.presetName = 'Flat',
    this.customBandGains = const {
      31: 0.0,
      63: 0.0,
      125: 0.0,
      250: 0.0,
      500: 0.0,
      1000: 0.0,
      2000: 0.0,
      4000: 0.0,
      8000: 0.0,
      16000: 0.0,
      60: 0.0,
      230: 0.0,
      910: 0.0,
      3600: 0.0,
      14000: 0.0,
    },
    this.bassBoost = 0.0,
    this.virtualizer = 0.0,
    this.loudnessGain = 0.0,
    this.balance = 0.0,
    this.monoAudio = false,
    this.stereoEnhancement = 0.0,
    this.volumeNormalization = true,
    this.replayGain = 0.0,
    this.customPresets = const [],
  });

  /// Resolves the effective band gains based on active preset, band mode, and custom gains
  Map<int, double> get effectiveBandGains {
    if (presetName.toLowerCase() == 'custom') {
      final result = <int, double>{};
      for (final freq in bandMode.frequencies) {
        result[freq] = customBandGains[freq] ?? 0.0;
      }
      return result;
    }

    final preset = EQPreset.getByName(presetName, customPresets: customPresets);
    return preset.gainsForMode(bandMode);
  }

  /// Gets gain in dB for a specific frequency
  double getGain(int frequency) {
    return effectiveBandGains[frequency] ?? 0.0;
  }

  /// Checks if the active preset is a built-in or custom preset
  bool get isCustomPreset =>
      presetName.toLowerCase() == 'custom' ||
      customPresets.any((p) => p.name.toLowerCase() == presetName.toLowerCase());

  EQProfile copyWith({
    bool? isEnabled,
    EQBandMode? bandMode,
    String? presetName,
    Map<int, double>? customBandGains,
    double? bassBoost,
    double? virtualizer,
    double? loudnessGain,
    double? balance,
    bool? monoAudio,
    double? stereoEnhancement,
    bool? volumeNormalization,
    double? replayGain,
    List<EQPreset>? customPresets,
  }) {
    return EQProfile(
      isEnabled: isEnabled ?? this.isEnabled,
      bandMode: bandMode ?? this.bandMode,
      presetName: presetName ?? this.presetName,
      customBandGains: customBandGains ?? this.customBandGains,
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      loudnessGain: loudnessGain ?? this.loudnessGain,
      balance: balance ?? this.balance,
      monoAudio: monoAudio ?? this.monoAudio,
      stereoEnhancement: stereoEnhancement ?? this.stereoEnhancement,
      volumeNormalization: volumeNormalization ?? this.volumeNormalization,
      replayGain: replayGain ?? this.replayGain,
      customPresets: customPresets ?? this.customPresets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'bandMode': bandMode.name,
      'presetName': presetName,
      'customBandGains':
          customBandGains.map((k, v) => MapEntry(k.toString(), v)),
      'bassBoost': bassBoost,
      'virtualizer': virtualizer,
      'loudnessGain': loudnessGain,
      'balance': balance,
      'monoAudio': monoAudio,
      'stereoEnhancement': stereoEnhancement,
      'volumeNormalization': volumeNormalization,
      'replayGain': replayGain,
      'customPresets': customPresets.map((p) => p.toMap()).toList(),
    };
  }

  factory EQProfile.fromMap(Map<dynamic, dynamic> map) {
    final rawGains =
        map['customBandGains'] as Map<dynamic, dynamic>? ?? {};
    final parsedGains = <int, double>{};
    rawGains.forEach((k, v) {
      final freq = int.tryParse(k.toString());
      if (freq != null) {
        parsedGains[freq] = (v as num).toDouble();
      }
    });

    final rawPresets = map['customPresets'] as List<dynamic>? ?? [];
    final parsedPresets = rawPresets
        .map((p) => p is Map<dynamic, dynamic> ? EQPreset.fromMap(p) : null)
        .whereType<EQPreset>()
        .toList();

    return EQProfile(
      isEnabled: map['isEnabled'] == true,
      bandMode: EQBandMode.fromString(map['bandMode']?.toString()),
      presetName: map['presetName']?.toString() ?? 'Flat',
      customBandGains: parsedGains.isEmpty
          ? const {
              31: 0.0,
              63: 0.0,
              125: 0.0,
              250: 0.0,
              500: 0.0,
              1000: 0.0,
              2000: 0.0,
              4000: 0.0,
              8000: 0.0,
              16000: 0.0,
              60: 0.0,
              230: 0.0,
              910: 0.0,
              3600: 0.0,
              14000: 0.0,
            }
          : parsedGains,
      bassBoost: (map['bassBoost'] as num?)?.toDouble() ?? 0.0,
      virtualizer: (map['virtualizer'] as num?)?.toDouble() ?? 0.0,
      loudnessGain: (map['loudnessGain'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      monoAudio: map['monoAudio'] == true,
      stereoEnhancement:
          (map['stereoEnhancement'] as num?)?.toDouble() ?? 0.0,
      volumeNormalization: map['volumeNormalization'] != false,
      replayGain: (map['replayGain'] as num?)?.toDouble() ?? 0.0,
      customPresets: parsedPresets,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory EQProfile.fromJson(String source) =>
      EQProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
