import 'dart:math' as math;

import '../models/best_effort.dart';
import '../models/parsed_track_point.dart';

/// Detects fastest contiguous 5K, 10K, HM, and FM efforts within an activity
/// in `O(N)` per target distance using a two-pointer sliding window (`PRD M2-10`).
class BestEffortCalculator {
  const BestEffortCalculator({
    this.minPlausiblePaceSecPerKm = 100.0,
  });

  /// Lower pace guard (~1:40/km) to ignore synthetic/zero-dt timestamp glitches.
  final double minPlausiblePaceSecPerKm;

  List<BestEffortSegment> detect({
    required List<ParsedTrackPoint> trackPoints,
    double? summaryDistanceMeters,
    int? summaryMovingDurationSec,
  }) {
    final results = <BestEffortSegment>[];

    final hasTrackDistances =
        trackPoints.length >= 2 && trackPoints.last.distanceMeters > 0;

    for (final target in BestEffortDistance.values) {
      BestEffortSegment? segment;
      if (hasTrackDistances) {
        segment = _detectFromTrackPoints(trackPoints, target);
      }
      if (segment == null &&
          !hasTrackDistances &&
          summaryDistanceMeters != null &&
          summaryMovingDurationSec != null &&
          summaryDistanceMeters >= target.distanceMeters &&
          summaryMovingDurationSec > 0) {
        final scaled = (summaryMovingDurationSec *
                (target.distanceMeters / summaryDistanceMeters))
            .round();
        final pace = scaled / (target.distanceMeters / 1000.0);
        if (scaled > 0 && pace >= minPlausiblePaceSecPerKm) {
          segment = BestEffortSegment(
            distance: target,
            durationSec: scaled,
            paceSecPerKm: pace,
            startDistanceMeters: 0,
            endDistanceMeters: target.distanceMeters,
          );
        }
      }
      if (segment != null) {
        results.add(segment);
      }
    }

    return results;
  }

  BestEffortSegment? _detectFromTrackPoints(
    List<ParsedTrackPoint> points,
    BestEffortDistance target,
  ) {
    final totalDist = points.last.distanceMeters.toDouble();
    if (totalDist < target.distanceMeters) return null;

    var left = 0;
    double? bestDurationSec;
    var bestStartM = 0.0;
    var bestEndM = 0.0;

    for (var right = 1; right < points.length; right++) {
      final rightDist = points[right].distanceMeters.toDouble();
      if (rightDist - points[left].distanceMeters < target.distanceMeters) {
        continue;
      }

      // Shrink from left while still covering at least target distance.
      while (left + 1 < right &&
          (rightDist - points[left + 1].distanceMeters) >=
              target.distanceMeters) {
        left++;
      }

      final leftDist = points[left].distanceMeters.toDouble();
      final windowDist = rightDist - leftDist;
      if (windowDist < target.distanceMeters || windowDist <= 0) continue;

      final windowSec = points[right]
              .timestampUtc
              .difference(points[left].timestampUtc)
              .inMilliseconds /
          1000.0;
      if (windowSec <= 0) continue;

      // Normalize linearly to exact target distance so slight point overshoots
      // do not penalize longer trackpoint intervals.
      final exactSec = windowSec * (target.distanceMeters / windowDist);
      final paceSecPerKm = exactSec / (target.distanceMeters / 1000.0);
      if (paceSecPerKm < minPlausiblePaceSecPerKm) continue;

      if (bestDurationSec == null || exactSec < bestDurationSec) {
        bestDurationSec = exactSec;
        bestStartM = leftDist;
        bestEndM = math.min(rightDist, leftDist + target.distanceMeters);
      }
    }

    if (bestDurationSec == null) return null;
    final roundedSec = math.max(1, bestDurationSec.round());
    return BestEffortSegment(
      distance: target,
      durationSec: roundedSec,
      paceSecPerKm: roundedSec / (target.distanceMeters / 1000.0),
      startDistanceMeters: bestStartM,
      endDistanceMeters: bestEndM,
    );
  }
}

