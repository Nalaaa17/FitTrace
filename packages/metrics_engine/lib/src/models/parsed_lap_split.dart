/// Per-kilometer split summary emitted by the FIT metrics engine (PRD §4.3).
class ParsedLapSplit {
  const ParsedLapSplit({
    required this.splitIndex,
    required this.distanceMeters,
    required this.durationSec,
    required this.avgPaceSecPerKm,
    required this.elevationDeltaM,
    this.avgHeartRate,
    this.avgCadence,
  });

  final int splitIndex;
  final double distanceMeters;
  final int durationSec;
  final double avgPaceSecPerKm;
  final double elevationDeltaM;
  final double? avgHeartRate;
  final double? avgCadence;
}

