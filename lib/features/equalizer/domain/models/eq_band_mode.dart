/// Mode specifying the number of active frequency bands in the equalizer
enum EQBandMode {
  band5(5, '5-Band', [60, 230, 910, 3600, 14000]),
  band10(10, '10-Band', [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]);

  final int bandCount;
  final String label;
  final List<int> frequencies;

  const EQBandMode(this.bandCount, this.label, this.frequencies);

  static EQBandMode fromString(String? value) {
    if (value == null) return EQBandMode.band10;
    if (value.toLowerCase() == 'band5' || value == '5') {
      return EQBandMode.band5;
    }
    return EQBandMode.band10;
  }
}
