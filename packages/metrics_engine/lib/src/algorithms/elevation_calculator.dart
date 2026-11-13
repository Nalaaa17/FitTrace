import 'dart:math' as math;

class ElevationSummary {
  const ElevationSummary({
    required this.totalGainM,
    required this.totalLossM,
    required this.smoothedAltitudesM,
  });

  final double totalGainM;
  final double totalLossM;
  final List<double> smoothedAltitudesM;
}

/// Computes smoothed elevation gain & loss (5-point window, 0.5 m threshold)
/// to suppress barometric/GPS altimeter jitter (PRD M2-05).
class ElevationCalculator {
  const ElevationCalculator();

  static const int smoothingRadius = 2; // 5-point centered window (-2..+2)
  static const double minStepThresholdM = 0.5;

  ElevationSummary calculate(List<double> rawAltitudesM) {
    if (rawAltitudesM.isEmpty) {
      return const ElevationSummary(
        totalGainM: 0.0,
        totalLossM: 0.0,
        smoothedAltitudesM: <double>[],
      );
    }

    final n = rawAltitudesM.length;
    final smoothed = List<double>.generate(n, (i) {
      final start = math.max(0, i - smoothingRadius);
      final end = math.min(n - 1, i + smoothingRadius);
      var sum = 0.0;
      for (var j = start; j <= end; j++) {
        sum += rawAltitudesM[j];
      }
      return sum / (end - start + 1);
    }, growable: false);

    var gain = 0.0;
    var loss = 0.0;
    var anchor = smoothed.first;

    for (var i = 1; i < n; i++) {
      final delta = smoothed[i] - anchor;
      if (delta >= minStepThresholdM) {
        gain += delta;
        anchor = smoothed[i];
      } else if (-delta >= minStepThresholdM) {
        loss += -delta;
        anchor = smoothed[i];
      }
    }

    return ElevationSummary(
      totalGainM: gain,
      totalLossM: loss,
      smoothedAltitudesM: smoothed,
    );
  }
}

