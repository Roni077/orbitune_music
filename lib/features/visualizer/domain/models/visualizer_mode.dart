/// Available audio visualizer rendering modes
enum VisualizerMode {
  bars,
  wave,
  circular,
  off;

  String get label {
    switch (this) {
      case VisualizerMode.bars:
        return 'Spectrum Bars';
      case VisualizerMode.wave:
        return 'Sine Wave';
      case VisualizerMode.circular:
        return 'Circular Radial';
      case VisualizerMode.off:
        return 'Off';
    }
  }

  VisualizerMode get next {
    final values = VisualizerMode.values;
    final nextIndex = (index + 1) % values.length;
    return values[nextIndex];
  }
}

/// Color theme presets for visualizer renders
enum VisualizerColorTheme {
  dynamicArtwork,
  neonGreen,
  cyberPink,
  oceanBlue,
  rainbow;

  String get label {
    switch (this) {
      case VisualizerColorTheme.dynamicArtwork:
        return 'Dynamic Artwork';
      case VisualizerColorTheme.neonGreen:
        return 'Neon Green';
      case VisualizerColorTheme.cyberPink:
        return 'Cyber Pink';
      case VisualizerColorTheme.oceanBlue:
        return 'Ocean Blue';
      case VisualizerColorTheme.rainbow:
        return 'Rainbow Gradient';
    }
  }
}
