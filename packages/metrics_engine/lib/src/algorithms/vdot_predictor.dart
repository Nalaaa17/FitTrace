import 'dart:math' as math;

import '../models/best_effort.dart';

/// Input performance sample used to derive an estimated VDOT score.
class PerformanceSample {
  const PerformanceSample({
    required this.title,
    required this.distanceMeters,
    required this.durationSec,
  });

  final String title;
  final double distanceMeters;
  final int durationSec;
}

/// Daniels / Gilbert VDOT-lite VO2max estimator & race time predictor (`PRD M2-11`).
///
/// Results are explicitly marked as estimates (`isEstimate = true`).
class VdotPredictor {
  const VdotPredictor();

  static const double minDistanceMeters = 1500.0;

  /// Computes VDOT from a single run distance (m) & duration (s).
  /// Returns `null` for distances under 1.5 km or unrealistic speeds.
  static double? computeVdot({
    required double distanceMeters,
    required int durationSec,
  }) {
    if (distanceMeters < minDistanceMeters || durationSec <= 0) return null;
    final minutes = durationSec / 60.0;
    final velocityMPerMin = distanceMeters / minutes;
    if (velocityMPerMin <= 40.0 || velocityMPerMin > 500.0) return null;

    final vdot = _rawVdot(distanceMeters: distanceMeters, minutes: minutes);
    if (vdot == null || vdot < 15.0 || vdot > 95.0) {
      return null;
    }
    return vdot;
  }

  static double? _rawVdot({
    required double distanceMeters,
    required double minutes,
  }) {
    if (minutes <= 0) return null;
    final velocityMPerMin = distanceMeters / minutes;
    final vo2 = -4.60 +
        0.182258 * velocityMPerMin +
        0.000104 * velocityMPerMin * velocityMPerMin;
    final pctMax = 0.8 +
        0.1894393 * math.exp(-0.012778 * minutes) +
        0.2989558 * math.exp(-0.1932605 * minutes);
    if (pctMax <= 0) return null;
    final vdot = vo2 / pctMax;
    if (vdot.isNaN || vdot.isInfinite) return null;
    return vdot;
  }

  /// Estimates VO2max & 5K/10K/HM/FM race predictions from candidate performances.
  VdotEstimate? estimateFromSamples(List<PerformanceSample> samples) {
    PerformanceSample? bestSample;
    double? bestVdot;

    for (final sample in samples) {
      final vdot = computeVdot(
        distanceMeters: sample.distanceMeters,
        durationSec: sample.durationSec,
      );
      if (vdot == null) continue;
      if (bestVdot == null || vdot > bestVdot) {
        bestVdot = vdot;
        bestSample = sample;
      }
    }

    if (bestVdot == null || bestSample == null) return null;
    final predictions = predictRaces(bestVdot);
    return VdotEstimate(
      vo2Max: bestVdot,
      sourceTitle: bestSample.title,
      sourceDistanceMeters: bestSample.distanceMeters,
      sourceDurationSec: bestSample.durationSec,
      predictions: predictions,
      isEstimate: true,
    );
  }

  /// Solves Daniels VDOT equation monotonically via binary search for each target race.
  List<RacePrediction> predictRaces(double vdot) {
    final predictions = <RacePrediction>[];
    for (final dist in BestEffortDistance.values) {
      final sec = _solveDurationForVdot(
        targetDistanceM: dist.distanceMeters,
        targetVdot: vdot,
      );
      predictions.add(
        RacePrediction(
          distance: dist,
          predictedDurationSec: sec,
          predictedPaceSecPerKm: sec / (dist.distanceMeters / 1000.0),
        ),
      );
    }
    return predictions;
  }

  int _solveDurationForVdot({
    required double targetDistanceM,
    required double targetVdot,
  }) {
    // Shorter duration yields strictly higher VDOT on [lowSec, highSec].
    var lowSec = (targetDistanceM / 8.0).round(); // ~2:05/km floor
    var highSec = (targetDistanceM * 1.2).round(); // ~20:00/km ceiling

    for (var i = 0; i < 48; i++) {
      final midSec = (lowSec + highSec) ~/ 2;
      final vdotAtMid = _rawVdot(
        distanceMeters: targetDistanceM,
        minutes: midSec / 60.0,
      );
      if (vdotAtMid != null && vdotAtMid > targetVdot) {
        lowSec = midSec;
      } else {
        highSec = midSec;
      }
    }
    return math.max(1, ((lowSec + highSec) / 2.0).round());
  }
}
