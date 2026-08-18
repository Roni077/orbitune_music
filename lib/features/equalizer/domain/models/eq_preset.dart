import 'dart:convert';
import 'eq_band_mode.dart';

/// Equalizer preset representing preset frequency band gain configurations (-10.0dB to +10.0dB)
class EQPreset {
  final String name;
  final Map<int, double> bandGains; // Frequency in Hz -> Gain in dB
  final bool isCustom;

  const EQPreset({
    required this.name,
    required this.bandGains,
    this.isCustom = false,
  });

  // Standard 5-band center frequencies: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
  static const List<int> standard5Bands = [60, 230, 910, 3600, 14000];

  // Standard 10-band center frequencies: 31Hz, 63Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz
  static const List<int> standard10Bands = [
    31,
    63,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];

  static const EQPreset flat = EQPreset(
    name: 'Flat',
    bandGains: {
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
      // 5-band backward compatibility
      60: 0.0,
      230: 0.0,
      910: 0.0,
      3600: 0.0,
      14000: 0.0,
    },
  );

  static const EQPreset bassBoost = EQPreset(
    name: 'Bass Boost',
    bandGains: {
      31: 7.0,
      63: 6.5,
      125: 5.0,
      250: 3.0,
      500: 1.0,
      1000: 0.0,
      2000: 0.0,
      4000: 0.0,
      8000: 0.0,
      16000: 0.0,
      // 5-band
      60: 6.5,
      230: 4.0,
      910: 1.0,
      3600: 0.0,
      14000: 0.0,
    },
  );

  static const EQPreset bassReducer = EQPreset(
    name: 'Bass Reducer',
    bandGains: {
      31: -6.0,
      63: -5.5,
      125: -4.0,
      250: -2.5,
      500: -1.0,
      1000: 0.0,
      2000: 0.0,
      4000: 0.0,
      8000: 0.0,
      16000: 0.0,
      // 5-band
      60: -5.5,
      230: -3.0,
      910: 0.0,
      3600: 0.0,
      14000: 0.0,
    },
  );

  static const EQPreset vocalBooster = EQPreset(
    name: 'Vocal Booster',
    bandGains: {
      31: -3.0,
      63: -2.0,
      125: 0.0,
      250: 2.0,
      500: 4.0,
      1000: 5.0,
      2000: 4.0,
      4000: 2.5,
      8000: 1.0,
      16000: 0.0,
      // 5-band
      60: -2.0,
      230: 1.0,
      910: 4.5,
      3600: 3.5,
      14000: 1.0,
    },
  );

  static const EQPreset rock = EQPreset(
    name: 'Rock',
    bandGains: {
      31: 5.0,
      63: 4.5,
      125: 3.0,
      250: 1.5,
      500: -0.5,
      1000: -1.0,
      2000: 1.0,
      4000: 3.0,
      8000: 4.5,
      16000: 5.0,
      // 5-band
      60: 4.5,
      230: 2.5,
      910: -1.0,
      3600: 2.0,
      14000: 4.0,
    },
  );

  static const EQPreset pop = EQPreset(
    name: 'Pop',
    bandGains: {
      31: -1.0,
      63: 0.5,
      125: 2.0,
      250: 3.5,
      500: 4.0,
      1000: 3.5,
      2000: 2.0,
      4000: 0.5,
      8000: -1.0,
      16000: -1.5,
      // 5-band
      60: -1.5,
      230: 1.5,
      910: 4.0,
      3600: 2.5,
      14000: -1.0,
    },
  );

  static const EQPreset jazz = EQPreset(
    name: 'Jazz',
    bandGains: {
      31: 3.5,
      63: 3.0,
      125: 2.0,
      250: 1.0,
      500: -1.0,
      1000: -1.5,
      2000: 0.5,
      4000: 2.0,
      8000: 3.0,
      16000: 3.5,
      // 5-band
      60: 3.0,
      230: 1.5,
      910: -1.5,
      3600: 1.5,
      14000: 3.0,
    },
  );

  static const EQPreset classical = EQPreset(
    name: 'Classical',
    bandGains: {
      31: 4.5,
      63: 4.0,
      125: 3.0,
      250: 1.5,
      500: -1.0,
      1000: -1.5,
      2000: 0.0,
      4000: 2.5,
      8000: 3.5,
      16000: 4.0,
      // 5-band
      60: 4.0,
      230: 2.5,
      910: -1.5,
      3600: 2.5,
      14000: 3.5,
    },
  );

  static const EQPreset hipHop = EQPreset(
    name: 'Hip Hop',
    bandGains: {
      31: 6.0,
      63: 5.5,
      125: 4.0,
      250: 2.0,
      500: 0.5,
      1000: 0.0,
      2000: 1.0,
      4000: 2.0,
      8000: 3.5,
      16000: 4.0,
      // 5-band
      60: 5.5,
      230: 3.0,
      910: 0.0,
      3600: 1.5,
      14000: 3.0,
    },
  );

  static const EQPreset dance = EQPreset(
    name: 'Dance',
    bandGains: {
      31: 6.0,
      63: 5.0,
      125: 3.5,
      250: 1.0,
      500: 0.5,
      1000: 1.5,
      2000: 3.0,
      4000: 4.0,
      8000: 4.5,
      16000: 4.5,
      // 5-band
      60: 5.0,
      230: 2.0,
      910: 1.0,
      3600: 3.5,
      14000: 4.0,
    },
  );

  static const EQPreset electronic = EQPreset(
    name: 'Electronic',
    bandGains: {
      31: 5.0,
      63: 4.5,
      125: 3.0,
      250: 1.0,
      500: -0.5,
      1000: 0.5,
      2000: 2.0,
      4000: 3.5,
      8000: 4.5,
      16000: 5.0,
      // 5-band
      60: 4.5,
      230: 1.5,
      910: 0.0,
      3600: 2.0,
      14000: 4.5,
    },
  );

  static const EQPreset acoustic = EQPreset(
    name: 'Acoustic',
    bandGains: {
      31: 3.5,
      63: 3.0,
      125: 2.5,
      250: 1.5,
      500: 0.5,
      1000: 1.0,
      2000: 2.0,
      4000: 3.0,
      8000: 3.0,
      16000: 2.5,
      // 5-band
      60: 3.0,
      230: 2.0,
      910: 1.0,
      3600: 2.5,
      14000: 2.5,
    },
  );

  static const EQPreset trebleBooster = EQPreset(
    name: 'Treble Booster',
    bandGains: {
      31: -3.0,
      63: -2.0,
      125: -1.0,
      250: 0.0,
      500: 1.0,
      1000: 2.5,
      2000: 4.0,
      4000: 5.5,
      8000: 7.0,
      16000: 8.0,
      // 5-band
      60: -2.0,
      230: 0.0,
      910: 1.5,
      3600: 4.5,
      14000: 7.5,
    },
  );

  static const EQPreset trebleReducer = EQPreset(
    name: 'Treble Reducer',
    bandGains: {
      31: 0.0,
      63: 0.0,
      125: 0.0,
      250: 0.0,
      500: -1.0,
      1000: -2.0,
      2000: -3.5,
      4000: -5.0,
      8000: -6.5,
      16000: -8.0,
      // 5-band
      60: 0.0,
      230: 0.0,
      910: -1.5,
      3600: -4.0,
      14000: -7.0,
    },
  );

  static const EQPreset deep = EQPreset(
    name: 'Deep',
    bandGains: {
      31: 6.5,
      63: 5.5,
      125: 4.0,
      250: 1.5,
      500: -1.0,
      1000: -2.0,
      2000: -1.5,
      4000: 0.5,
      8000: 2.0,
      16000: 3.0,
      // 5-band
      60: 5.5,
      230: 2.5,
      910: -1.5,
      3600: 1.0,
      14000: 2.5,
    },
  );

  static const EQPreset metal = EQPreset(
    name: 'Metal',
    bandGains: {
      31: 5.5,
      63: 5.0,
      125: 2.5,
      250: 0.0,
      500: -2.5,
      1000: -1.0,
      2000: 1.5,
      4000: 4.0,
      8000: 5.5,
      16000: 6.0,
      // 5-band
      60: 5.0,
      230: 1.0,
      910: -2.0,
      3600: 2.5,
      14000: 5.5,
    },
  );

  static const EQPreset lounge = EQPreset(
    name: 'Lounge',
    bandGains: {
      31: -2.5,
      63: -1.5,
      125: 0.5,
      250: 2.0,
      500: 3.5,
      1000: 2.0,
      2000: 0.0,
      4000: -1.5,
      8000: 1.0,
      16000: 2.0,
      // 5-band
      60: -2.0,
      230: 1.5,
      910: 2.5,
      3600: -1.0,
      14000: 1.5,
    },
  );

  static const List<EQPreset> defaultPresets = [
    flat,
    bassBoost,
    bassReducer,
    vocalBooster,
    rock,
    pop,
    jazz,
    classical,
    hipHop,
    dance,
    electronic,
    acoustic,
    trebleBooster,
    trebleReducer,
    deep,
    metal,
    lounge,
  ];

  static EQPreset getByName(String name, {List<EQPreset>? customPresets}) {
    if (customPresets != null) {
      final customMatch = customPresets.where(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
      if (customMatch.isNotEmpty) return customMatch.first;
    }

    return defaultPresets.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () => flat,
    );
  }

  /// Extracts gain map for a specific EQBandMode
  Map<int, double> gainsForMode(EQBandMode mode) {
    final result = <int, double>{};
    for (final freq in mode.frequencies) {
      if (bandGains.containsKey(freq)) {
        result[freq] = bandGains[freq]!;
      } else {
        // Interpolate or fallback to closest frequency
        result[freq] = _findClosestGain(freq);
      }
    }
    return result;
  }

  double _findClosestGain(int targetFreq) {
    if (bandGains.isEmpty) return 0.0;
    int closestKey = bandGains.keys.first;
    int minDiff = (closestKey - targetFreq).abs();

    for (final k in bandGains.keys) {
      final diff = (k - targetFreq).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestKey = k;
      }
    }
    return bandGains[closestKey] ?? 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bandGains': bandGains.map((k, v) => MapEntry(k.toString(), v)),
      'isCustom': isCustom,
    };
  }

  factory EQPreset.fromMap(Map<dynamic, dynamic> map) {
    final rawGains = map['bandGains'] as Map<dynamic, dynamic>? ?? {};
    final parsedGains = <int, double>{};
    rawGains.forEach((k, v) {
      final freq = int.tryParse(k.toString());
      if (freq != null) {
        parsedGains[freq] = (v as num).toDouble();
      }
    });

    return EQPreset(
      name: map['name']?.toString() ?? 'Flat',
      bandGains: parsedGains.isEmpty ? flat.bandGains : parsedGains,
      isCustom: map['isCustom'] == true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory EQPreset.fromJson(String source) =>
      EQPreset.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
