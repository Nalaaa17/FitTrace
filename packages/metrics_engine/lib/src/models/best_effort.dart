/// Standard personal-record race distances supported by FitTrace (`PRD M2-10`).
enum BestEffortDistance {
  fiveK('5k', '5K', 5000.0),
  tenK('10k', '10K', 10000.0),
  halfMarathon('hm', 'Half Marathon', 21097.5),
  marathon('fm', 'Marathon', 42195.0);

  const BestEffortDistance(
    this.storageKey,
    this.label,
    this.distanceMeters,
  );

  final String storageKey;
  final String label;
  final double distanceMeters;

  static BestEffortDistance? fromStorageKey(String key) {
    for (final value in BestEffortDistance.values) {
      if (value.storageKey == key) return value;
    }
    return null;
  }
}

/// Fastest contiguous segment covering a standard distance inside one run.
class BestEffortSegment {
  const BestEffortSegment({
    required this.distance,
    required this.durationSec,
    required this.paceSecPerKm,
    this.startDistanceMeters = 0,
    this.endDistanceMeters = 0,
  });

  final BestEffortDistance distance;
  final int durationSec;
  final double paceSecPerKm;
  final double startDistanceMeters;
  final double endDistanceMeters;
}

/// Estimated target finish time & pace for a standard distance (`PRD M2-11`).
class RacePrediction {
  const RacePrediction({
    required this.distance,
    required this.predictedDurationSec,
    required this.predictedPaceSecPerKm,
  });

  final BestEffortDistance distance;
  final int predictedDurationSec;
  final double predictedPaceSecPerKm;
}

/// VDOT-lite VO2max estimate & derived race predictions (`PRD M2-11`).
class VdotEstimate {
  const VdotEstimate({
    required this.vo2Max,
    required this.sourceTitle,
    required this.sourceDistanceMeters,
    required this.sourceDurationSec,
    required this.predictions,
    this.isEstimate = true,
  });

  final double vo2Max;
  final String sourceTitle;
  final double sourceDistanceMeters;
  final int sourceDurationSec;
  final List<RacePrediction> predictions;
  final bool isEstimate;
}

