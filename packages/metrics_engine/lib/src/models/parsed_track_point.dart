/// Normalized trackpoint emitted by the FIT metrics engine (PRD §4.2).
class ParsedTrackPoint {
  const ParsedTrackPoint({
    required this.timestampUtc,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.altitudeM,
    required this.speedMps,
    required this.distanceMeters,
    this.heartRateBpm,
    this.cadenceRpm,
    this.hrZone,
  });

  final DateTime timestampUtc;
  final double latitudeDeg;
  final double longitudeDeg;
  final double altitudeM;
  final double speedMps;
  final int distanceMeters;
  final int? heartRateBpm;
  final int? cadenceRpm;
  final int? hrZone;
}

