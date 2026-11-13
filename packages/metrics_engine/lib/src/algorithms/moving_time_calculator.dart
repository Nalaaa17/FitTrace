import 'dart:math' as math;

class MovingTimeResult {
  const MovingTimeResult({
    required this.movingTimeSec,
    required this.totalElapsedSec,
    required this.movingIntervals,
    required this.effectiveSpeedsMps,
  });

  final int movingTimeSec;
  final int totalElapsedSec;

  /// Length `n - 1`: true when interval `[i, i + 1]` counts as moving.
  final List<bool> movingIntervals;

  /// Length `n`: resolved instantaneous speeds (m/s) per sample.
  final List<double> effectiveSpeedsMps;
}

/// Moving time detector following PRD M2-03:
/// smoothed speed (window +/-3 points) < 0.5 m/s consecutively >= 10s = stopped.
class MovingTimeCalculator {
  const MovingTimeCalculator();

  static const double stoppedSpeedThresholdMps = 0.5;
  static const int minStoppedDurationSec = 10;
  static const int smoothingRadius = 3;

  MovingTimeResult calculate({
    required List<DateTime> timestampsUtc,
    required List<double?> sensorSpeedsMps,
    required List<double> cumulativeDistancesM,
  }) {
    final n = timestampsUtc.length;
    if (n < 2) {
      return MovingTimeResult(
        movingTimeSec: 0,
        totalElapsedSec: 0,
        movingIntervals: const <bool>[],
        effectiveSpeedsMps: n == 1
            ? <double>[sensorSpeedsMps.first ?? 0.0]
            : const <double>[],
      );
    }

    final rawSpeeds = List<double>.generate(n, (i) {
      final sensor = sensorSpeedsMps[i];
      if (sensor != null && sensor.isFinite && sensor >= 0) {
        return sensor;
      }
      if (i == 0) {
        final dt =
            timestampsUtc[1].difference(timestampsUtc[0]).inMilliseconds /
            1000.0;
        if (dt <= 0) return 0.0;
        return math.max(
          0.0,
          (cumulativeDistancesM[1] - cumulativeDistancesM[0]) / dt,
        );
      }
      final dt =
          timestampsUtc[i].difference(timestampsUtc[i - 1]).inMilliseconds /
          1000.0;
      if (dt <= 0) return 0.0;
      return math.max(
        0.0,
        (cumulativeDistancesM[i] - cumulativeDistancesM[i - 1]) / dt,
      );
    }, growable: false);

    final smoothedSpeeds = List<double>.generate(n, (i) {
      final start = math.max(0, i - smoothingRadius);
      final end = math.min(n - 1, i + smoothingRadius);
      final window = <double>[
        for (var j = start; j <= end; j++) rawSpeeds[j],
      ]..sort();
      return window[window.length ~/ 2];
    }, growable: false);

    final isLowSpeedPoint = List<bool>.generate(
      n,
      (i) => smoothedSpeeds[i] < stoppedSpeedThresholdMps,
      growable: false,
    );

    final movingIntervals = List<bool>.filled(n - 1, true, growable: false);

    var i = 0;
    while (i < n) {
      if (!isLowSpeedPoint[i]) {
        i++;
        continue;
      }
      var end = i;
      while (end + 1 < n && isLowSpeedPoint[end + 1]) {
        end++;
      }

      // Include leading transition into the stationary run if both endpoints
      // are slow or span meets the >=10s stationary threshold.
      final spanSec =
          timestampsUtc[end].difference(timestampsUtc[i]).inMilliseconds /
          1000.0;
      if (spanSec >= minStoppedDurationSec) {
        for (var k = i; k < end; k++) {
          movingIntervals[k] = false;
        }
      }
      i = end + 1;
    }

    var movingMs = 0;
    var elapsedMs = 0;
    for (var k = 0; k < n - 1; k++) {
      final dtMs = math.max(
        0,
        timestampsUtc[k + 1].difference(timestampsUtc[k]).inMilliseconds,
      );
      elapsedMs += dtMs;
      if (movingIntervals[k]) {
        movingMs += dtMs;
      }
    }

    return MovingTimeResult(
      movingTimeSec: (movingMs / 1000.0).round(),
      totalElapsedSec: (elapsedMs / 1000.0).round(),
      movingIntervals: movingIntervals,
      effectiveSpeedsMps: rawSpeeds,
    );
  }
}
