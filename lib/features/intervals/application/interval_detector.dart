import '../../../core/database/app_database.dart';
import '../domain/interval_session.dart';

class IntervalDetector {
  const IntervalDetector();

  /// Analyzes an activity bundle (laps & trackpoints) to detect if it was an
  /// interval workout (sprint/work vs recovery/rest pattern).
  IntervalAnalysisResult detectIntervals({
    required ActivityRecord activity,
    required List<LapSplitRecord> lapSplits,
    List<TrackPointRecord> trackPoints = const <TrackPointRecord>[],
  }) {
    // 1. Try detecting from structured lap splits first
    final lapResult = _detectFromLapSplits(lapSplits);
    if (lapResult.isIntervalSession && lapResult.reps.isNotEmpty) {
      return lapResult;
    }

    // 2. Fall back to high-resolution trackpoints analysis (e.g. fartlek or unmarked intervals)
    if (trackPoints.length >= 60) {
      final tpResult = _detectFromTrackPoints(activity, trackPoints);
      if (tpResult.isIntervalSession && tpResult.reps.isNotEmpty) {
        return tpResult;
      }
    }

    return const IntervalAnalysisResult(isIntervalSession: false);
  }

  /// Detects alternating work/rest patterns in Garmin/manual laps.
  IntervalAnalysisResult _detectFromLapSplits(List<LapSplitRecord> splits) {
    if (splits.length < 3) {
      return const IntervalAnalysisResult(isIntervalSession: false);
    }

    // Check if splits are not all uniform 1.0km (+/- 50m) auto-splits
    final areAllStandardKm = splits.every(
      (s) => (s.distanceMeters >= 950 && s.distanceMeters <= 1050),
    );

    // If all splits are exact 1km splits, laps were likely auto-lap, not manual interval laps
    if (areAllStandardKm && splits.length < 5) {
      return const IntervalAnalysisResult(isIntervalSession: false);
    }

    final reps = <IntervalRep>[];
    int repCounter = 1;

    // Search for pairs: [Work Lap, Rest Lap]
    // Work lap typically has significantly faster pace (lower sec/km) than rest lap.
    int i = 0;
    // Skip initial warmup lap if it's long and slow
    if (splits.length >= 4 && splits[0].avgPaceSecPerKm > splits[1].avgPaceSecPerKm * 1.15) {
      i = 1;
    }

    while (i < splits.length - 1) {
      final workSplit = splits[i];
      final restSplit = splits[i + 1];

      // Work should be at least 15% faster than rest (lower paceSecPerKm)
      final paceRatio = restSplit.avgPaceSecPerKm > 0
          ? workSplit.avgPaceSecPerKm / restSplit.avgPaceSecPerKm
          : 1.0;

      if (paceRatio <= 0.85 && workSplit.distanceMeters >= 100) {
        reps.add(
          IntervalRep(
            repIndex: repCounter++,
            workDistanceMeters: workSplit.distanceMeters,
            workDurationSec: workSplit.durationSec,
            workPaceSecPerKm: workSplit.avgPaceSecPerKm,
            workAvgHeartRate: workSplit.avgHeartRate,
            restDistanceMeters: restSplit.distanceMeters,
            restDurationSec: restSplit.durationSec,
            restPaceSecPerKm: restSplit.avgPaceSecPerKm,
            restAvgHeartRate: restSplit.avgHeartRate,
          ),
        );
        i += 2;
      } else {
        i += 1;
      }
    }

    // Need at least 2 detected reps to qualify as an interval workout
    if (reps.length >= 2) {
      final totalWorkDist = reps.fold<double>(0.0, (sum, r) => sum + r.workDistanceMeters);
      final totalWorkSec = reps.fold<int>(0, (sum, r) => sum + r.workDurationSec);
      final avgWorkPace = totalWorkDist > 0 ? totalWorkSec / (totalWorkDist / 1000.0) : 0.0;

      final totalRestDist = reps.fold<double>(0.0, (sum, r) => sum + r.restDistanceMeters);
      final totalRestSec = reps.fold<int>(0, (sum, r) => sum + r.restDurationSec);
      final avgRestPace = totalRestDist > 0 ? totalRestSec / (totalRestDist / 1000.0) : 0.0;

      return IntervalAnalysisResult(
        isIntervalSession: true,
        reps: reps,
        totalWorkDistanceMeters: totalWorkDist,
        totalWorkDurationSec: totalWorkSec,
        avgWorkPaceSecPerKm: avgWorkPace,
        totalRestDistanceMeters: totalRestDist,
        totalRestDurationSec: totalRestSec,
        avgRestPaceSecPerKm: avgRestPace,
        detectionSource: 'laps',
      );
    }

    return const IntervalAnalysisResult(isIntervalSession: false);
  }

  /// Detects interval patterns from continuous GPS trackpoints.
  IntervalAnalysisResult _detectFromTrackPoints(
    ActivityRecord activity,
    List<TrackPointRecord> points,
  ) {
    if (points.length < 60) {
      return const IntervalAnalysisResult(isIntervalSession: false);
    }

    // Compute moving average speed (5-point smoothing)
    final smoothedSpeeds = <double>[];
    for (int i = 0; i < points.length; i++) {
      int start = (i - 2).clamp(0, points.length - 1);
      int end = (i + 2).clamp(0, points.length - 1);
      double sum = 0.0;
      int count = 0;
      for (int k = start; k <= end; k++) {
        sum += points[k].speedMps;
        count++;
      }
      smoothedSpeeds.add(sum / count);
    }

    // Median speed
    final sortedSpeeds = List<double>.from(smoothedSpeeds)..sort();
    final medianSpeed = sortedSpeeds[sortedSpeeds.length ~/ 2];
    if (medianSpeed < 1.5) {
      return const IntervalAnalysisResult(isIntervalSession: false);
    }

    final workThreshold = medianSpeed * 1.15; // 15% above median speed
    final restThreshold = medianSpeed * 0.90; // 10% below median speed

    final reps = <IntervalRep>[];
    bool inWork = false;
    int workStartIdx = 0;
    int restStartIdx = 0;
    int repCounter = 1;

    for (int i = 0; i < points.length; i++) {
      final speed = smoothedSpeeds[i];

      if (!inWork && speed >= workThreshold) {
        // Transition Rest -> Work
        if (repCounter > 1 && restStartIdx > 0 && i > restStartIdx) {
          // Finalize previous rest segment
          final prevWork = reps.last;
          final restPts = points.sublist(restStartIdx, i);
          final restDist = (points[i].distanceMeters - points[restStartIdx].distanceMeters).toDouble();
          final restSec = points[i].timestampUtc.difference(points[restStartIdx].timestampUtc).inSeconds;
          final restPace = (restDist > 0 && restSec > 0) ? restSec / (restDist / 1000.0) : 0.0;
          final restHrs = restPts.where((p) => p.heartRateBpm != null).map((p) => p.heartRateBpm!);
          final restAvgHr = restHrs.isNotEmpty ? restHrs.reduce((a, b) => a + b) / restHrs.length : null;

          // Update last rep with rest details
          reps[reps.length - 1] = IntervalRep(
            repIndex: prevWork.repIndex,
            workDistanceMeters: prevWork.workDistanceMeters,
            workDurationSec: prevWork.workDurationSec,
            workPaceSecPerKm: prevWork.workPaceSecPerKm,
            workAvgHeartRate: prevWork.workAvgHeartRate,
            workMaxHeartRate: prevWork.workMaxHeartRate,
            restDistanceMeters: restDist,
            restDurationSec: restSec,
            restPaceSecPerKm: restPace,
            restAvgHeartRate: restAvgHr,
          );
        }

        inWork = true;
        workStartIdx = i;
      } else if (inWork && speed <= restThreshold) {
        // Transition Work -> Rest
        final durationSec = points[i].timestampUtc.difference(points[workStartIdx].timestampUtc).inSeconds;
        final distM = (points[i].distanceMeters - points[workStartIdx].distanceMeters).toDouble();

        // Only register if work segment lasted at least 20 seconds and 80 meters
        if (durationSec >= 20 && distM >= 80) {
          final workPts = points.sublist(workStartIdx, i);
          final workPace = distM > 0 ? durationSec / (distM / 1000.0) : 0.0;
          final hrs = workPts.where((p) => p.heartRateBpm != null).map((p) => p.heartRateBpm!);
          final avgHr = hrs.isNotEmpty ? hrs.reduce((a, b) => a + b) / hrs.length : null;
          final maxHr = hrs.isNotEmpty ? hrs.reduce((a, b) => a > b ? a : b).toDouble() : null;

          reps.add(
            IntervalRep(
              repIndex: repCounter++,
              workDistanceMeters: distM,
              workDurationSec: durationSec,
              workPaceSecPerKm: workPace,
              workAvgHeartRate: avgHr,
              workMaxHeartRate: maxHr,
              restDistanceMeters: 0,
              restDurationSec: 0,
              restPaceSecPerKm: 0,
            ),
          );
          restStartIdx = i;
        }

        inWork = false;
      }
    }

    if (reps.length >= 2) {
      final totalWorkDist = reps.fold<double>(0.0, (sum, r) => sum + r.workDistanceMeters);
      final totalWorkSec = reps.fold<int>(0, (sum, r) => sum + r.workDurationSec);
      final avgWorkPace = totalWorkDist > 0 ? totalWorkSec / (totalWorkDist / 1000.0) : 0.0;

      final totalRestDist = reps.fold<double>(0.0, (sum, r) => sum + r.restDistanceMeters);
      final totalRestSec = reps.fold<int>(0, (sum, r) => sum + r.restDurationSec);
      final avgRestPace = totalRestDist > 0 ? totalRestSec / (totalRestDist / 1000.0) : 0.0;

      return IntervalAnalysisResult(
        isIntervalSession: true,
        reps: reps,
        totalWorkDistanceMeters: totalWorkDist,
        totalWorkDurationSec: totalWorkSec,
        avgWorkPaceSecPerKm: avgWorkPace,
        totalRestDistanceMeters: totalRestDist,
        totalRestDurationSec: totalRestSec,
        avgRestPaceSecPerKm: avgRestPace,
        detectionSource: 'trackpoints',
      );
    }

    return const IntervalAnalysisResult(isIntervalSession: false);
  }
}

