class IntervalRep {
  const IntervalRep({
    required this.repIndex,
    required this.workDistanceMeters,
    required this.workDurationSec,
    required this.workPaceSecPerKm,
    this.workAvgHeartRate,
    this.workMaxHeartRate,
    required this.restDistanceMeters,
    required this.restDurationSec,
    required this.restPaceSecPerKm,
    this.restAvgHeartRate,
  });

  final int repIndex;
  final double workDistanceMeters;
  final int workDurationSec;
  final double workPaceSecPerKm;
  final double? workAvgHeartRate;
  final double? workMaxHeartRate;

  final double restDistanceMeters;
  final int restDurationSec;
  final double restPaceSecPerKm;
  final double? restAvgHeartRate;
}

class IntervalAnalysisResult {
  const IntervalAnalysisResult({
    required this.isIntervalSession,
    this.reps = const <IntervalRep>[],
    this.totalWorkDistanceMeters = 0.0,
    this.totalWorkDurationSec = 0,
    this.avgWorkPaceSecPerKm = 0.0,
    this.totalRestDistanceMeters = 0.0,
    this.totalRestDurationSec = 0,
    this.avgRestPaceSecPerKm = 0.0,
    this.detectionSource = 'none',
  });

  final bool isIntervalSession;
  final List<IntervalRep> reps;
  final double totalWorkDistanceMeters;
  final int totalWorkDurationSec;
  final double avgWorkPaceSecPerKm;
  final double totalRestDistanceMeters;
  final int totalRestDurationSec;
  final double avgRestPaceSecPerKm;
  final String detectionSource; // 'laps' or 'trackpoints'
}

