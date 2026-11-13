import 'best_effort.dart';
import 'enums.dart';
import 'parsed_lap_split.dart';
import 'parsed_track_point.dart';

/// Complete parsed running activity ready for local database persistence.
class ParsedActivity {
  const ParsedActivity({
    required this.title,
    required this.sportType,
    required this.startTimeUtc,
    required this.utcOffsetSeconds,
    required this.durationTotalSec,
    required this.durationMovingSec,
    required this.distanceMeters,
    required this.avgPaceSecPerKm,
    required this.totalElevationGainM,
    required this.totalElevationLossM,
    required this.caloriesKcal,
    required this.isIndoor,
    required this.hasGpsTrack,
    required this.gpsQuality,
    required this.splitPacesSecPerKm,
    required this.zoneDurationsSec,
    required this.trackPoints,
    required this.lapSplits,
    this.garminActivityId,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    this.rawHrvIntervalsSec = const <double>[],
    this.fitLapCount = 0,
    this.bestEfforts = const <BestEffortSegment>[],
  });

  final int? garminActivityId;
  final String title;
  final SportType sportType;
  final DateTime startTimeUtc;
  final int utcOffsetSeconds;
  final int durationTotalSec;
  final int durationMovingSec;
  final double distanceMeters;
  final double avgPaceSecPerKm;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgCadence;
  final double totalElevationGainM;
  final double totalElevationLossM;
  final int caloriesKcal;
  final bool isIndoor;
  final bool hasGpsTrack;
  final GpsQuality gpsQuality;
  final List<int> splitPacesSecPerKm;
  final List<int> zoneDurationsSec;
  final List<ParsedTrackPoint> trackPoints;
  final List<ParsedLapSplit> lapSplits;
  final List<double> rawHrvIntervalsSec;
  final int fitLapCount;
  final List<BestEffortSegment> bestEfforts;

  /// Returns wall-clock local start time preserved from activity timezone offset.
  DateTime get startTimeLocal =>
      startTimeUtc.toUtc().add(Duration(seconds: utcOffsetSeconds));
}

