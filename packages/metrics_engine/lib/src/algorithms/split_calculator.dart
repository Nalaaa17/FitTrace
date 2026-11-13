import '../models/parsed_lap_split.dart';
import '../models/parsed_track_point.dart';

/// Aggregates normalized trackpoints into per-1000m running splits (PRD M2-04).
class SplitCalculator {
  const SplitCalculator();

  static const double splitDistanceMeters = 1000.0;
  static const double minTrailingSplitMeters = 10.0;

  List<ParsedLapSplit> calculate({
    required List<ParsedTrackPoint> trackPoints,
    required List<double> cumulativeDistancesM,
    required List<bool> movingIntervals,
    required List<double> smoothedAltitudesM,
  }) {
    if (trackPoints.length < 2 || cumulativeDistancesM.last <= 0) {
      return const <ParsedLapSplit>[];
    }

    final splits = <ParsedLapSplit>[];
    var splitIndex = 0;
    var splitStartDist = 0.0;
    var splitStartAlt = smoothedAltitudesM.first;
    var nextBoundary = splitDistanceMeters;

    var movingMs = 0;
    var elapsedMs = 0;
    var hrSum = 0.0;
    var hrCount = 0;
    var cadSum = 0.0;
    var cadCount = 0;

    void emitSplit(double endDist, double endAlt) {
      final dist = endDist - splitStartDist;
      if (dist <= 0) return;
      final effectiveMovingSec = movingMs > 0
          ? (movingMs / 1000.0).round()
          : (elapsedMs / 1000.0).round();
      final pace = dist > 0 && effectiveMovingSec > 0
          ? effectiveMovingSec / (dist / 1000.0)
          : 0.0;

      splits.add(
        ParsedLapSplit(
          splitIndex: splitIndex,
          distanceMeters: dist,
          durationSec: effectiveMovingSec,
          avgPaceSecPerKm: pace,
          avgHeartRate: hrCount > 0 ? hrSum / hrCount : null,
          avgCadence: cadCount > 0 ? cadSum / cadCount : null,
          elevationDeltaM: endAlt - splitStartAlt,
        ),
      );
      splitIndex++;
      splitStartDist = endDist;
      splitStartAlt = endAlt;
      nextBoundary += splitDistanceMeters;
      movingMs = 0;
      elapsedMs = 0;
      hrSum = 0;
      hrCount = 0;
      cadSum = 0;
      cadCount = 0;
    }

    final firstHr = trackPoints.first.heartRateBpm;
    if (firstHr != null && firstHr > 0) {
      hrSum += firstHr;
      hrCount++;
    }
    final firstCad = trackPoints.first.cadenceRpm;
    if (firstCad != null && firstCad > 0) {
      cadSum += firstCad;
      cadCount++;
    }

    for (var i = 1; i < trackPoints.length; i++) {
      final prevDist = cumulativeDistancesM[i - 1];
      final currDist = cumulativeDistancesM[i];
      final prevAlt = smoothedAltitudesM[i - 1];
      final currAlt = smoothedAltitudesM[i];
      final segDist = currDist - prevDist;
      final segMs = trackPoints[i].timestampUtc
          .difference(trackPoints[i - 1].timestampUtc)
          .inMilliseconds;
      final isMoving = movingIntervals[i - 1];

      if (currDist >= nextBoundary && segDist > 0) {
        var remainingSegDist = segDist;
        var currentAnchorDist = prevDist;
        var remainingSegMs = segMs;
        var currentAnchorAlt = prevAlt;

        while (currDist >= nextBoundary && remainingSegDist > 0) {
          final closedBoundary = nextBoundary;
          final partDist = closedBoundary - currentAnchorDist;
          final fraction = (partDist / remainingSegDist).clamp(0.0, 1.0);
          final partMs = (remainingSegMs * fraction).round();
          final boundaryAlt =
              currentAnchorAlt + (currAlt - currentAnchorAlt) * fraction;

          elapsedMs += partMs;
          if (isMoving) {
            movingMs += partMs;
          }
          emitSplit(closedBoundary, boundaryAlt);

          remainingSegDist -= partDist;
          remainingSegMs -= partMs;
          currentAnchorDist = closedBoundary;
          currentAnchorAlt = boundaryAlt;
        }

        elapsedMs += remainingSegMs;
        if (isMoving) {
          movingMs += remainingSegMs;
        }
      } else {
        elapsedMs += segMs;
        if (isMoving) {
          movingMs += segMs;
        }
      }

      final hr = trackPoints[i].heartRateBpm;
      if (hr != null && hr > 0) {
        hrSum += hr;
        hrCount++;
      }
      final cad = trackPoints[i].cadenceRpm;
      if (cad != null && cad > 0) {
        cadSum += cad;
        cadCount++;
      }
    }

    final totalDist = cumulativeDistancesM.last;
    if (totalDist - splitStartDist >= minTrailingSplitMeters ||
        (splits.isEmpty && totalDist > 0)) {
      emitSplit(totalDist, smoothedAltitudesM.last);
    }

    return splits;
  }
}
