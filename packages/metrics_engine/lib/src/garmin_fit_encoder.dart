import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';

import 'models/enums.dart';
import 'models/parsed_activity.dart';

/// Pure Dart binary `.FIT` activity regenerator used when original `.fit.gz`
/// archive has expired (> 30 days) or is unavailable (`PRD M5-01`, `ADR-004`).
class GarminFitEncoder {
  const GarminFitEncoder();

  Uint8List encodeActivity(ParsedActivity activity) {
    final builder = FitFileBuilder(autoDefine: true);
    final startMs = activity.startTimeUtc.toUtc().millisecondsSinceEpoch;
    final endMs =
        startMs + (activity.durationTotalSec > 0 ? activity.durationTotalSec * 1000 : 0);

    builder.add(
      FileIdMessage()
        ..type = FileType.activity
        ..manufacturer = Manufacturer.garmin.value
        ..product = 0
        ..timeCreated = startMs,
    );

    final includeGps = !activity.isIndoor && activity.hasGpsTrack;
    for (final pt in activity.trackPoints) {
      final rec = RecordMessage()
        ..timestamp = pt.timestampUtc.toUtc().millisecondsSinceEpoch
        ..distance = pt.distanceMeters.toDouble()
        ..enhancedAltitude = pt.altitudeM
        ..enhancedSpeed = pt.speedMps;

      if (includeGps) {
        rec
          ..positionLat = pt.latitudeDeg
          ..positionLong = pt.longitudeDeg;
      }
      if (pt.heartRateBpm != null && pt.heartRateBpm! > 0 && pt.heartRateBpm! < 255) {
        rec.heartRate = pt.heartRateBpm!;
      }
      if (pt.cadenceRpm != null && pt.cadenceRpm! >= 0 && pt.cadenceRpm! < 255) {
        rec.cadence = pt.cadenceRpm!;
      }
      builder.add(rec);
    }

    var lapCursorMs = startMs;
    for (final split in activity.lapSplits) {
      final lapEndMs = lapCursorMs + split.durationSec * 1000;
      final lap = LapMessage()
        ..startTime = lapCursorMs
        ..timestamp = lapEndMs
        ..totalElapsedTime = split.durationSec.toDouble()
        ..totalTimerTime = split.durationSec.toDouble()
        ..totalDistance = split.distanceMeters;
      if (split.avgHeartRate != null && split.avgHeartRate! > 0) {
        lap.avgHeartRate = split.avgHeartRate!.round().clamp(1, 254);
      }
      if (split.avgCadence != null && split.avgCadence! >= 0) {
        lap.avgCadence = split.avgCadence!.round().clamp(0, 254);
      }
      if (split.elevationDeltaM > 0) {
        lap.totalAscent = split.elevationDeltaM.round();
      } else if (split.elevationDeltaM < 0) {
        lap.totalDescent = split.elevationDeltaM.abs().round();
      }
      builder.add(lap);
      lapCursorMs = lapEndMs;
    }

    final (sport, subSport) = _mapSport(activity);
    final session = SessionMessage()
      ..startTime = startMs
      ..timestamp = endMs
      ..sport = sport
      ..subSport = subSport
      ..totalElapsedTime = activity.durationTotalSec.toDouble()
      ..totalTimerTime = activity.durationMovingSec.toDouble()
      ..totalDistance = activity.distanceMeters
      ..totalAscent = activity.totalElevationGainM.round()
      ..totalDescent = activity.totalElevationLossM.round()
      ..totalCalories = activity.caloriesKcal.clamp(0, 65535);
    if (activity.avgHeartRate != null && activity.avgHeartRate! > 0) {
      session.avgHeartRate = activity.avgHeartRate!.round().clamp(1, 254);
    }
    if (activity.maxHeartRate != null && activity.maxHeartRate! > 0) {
      session.maxHeartRate = activity.maxHeartRate!.round().clamp(1, 254);
    }
    if (activity.avgCadence != null && activity.avgCadence! >= 0) {
      session.avgCadence = activity.avgCadence!.round().clamp(0, 254);
    }
    builder.add(session);

    final localMs = endMs + activity.utcOffsetSeconds * 1000;
    builder.add(
      ActivityMessage()
        ..timestamp = endMs
        ..localTimestamp = toSecondsSince1989Epoch(localMs)
        ..totalTimerTime = activity.durationMovingSec.toDouble()
        ..numSessions = 1,
    );

    return builder.build().toBytes();
  }

  static (Sport, SubSport) _mapSport(ParsedActivity activity) {
    switch (activity.sportType) {
      case SportType.run:
        return activity.isIndoor
            ? (Sport.running, SubSport.indoorRunning)
            : (Sport.running, SubSport.street);
      case SportType.trailRun:
        return (Sport.running, SubSport.trail);
      case SportType.treadmill:
        return (Sport.running, SubSport.treadmill);
      case SportType.other:
        return (Sport.generic, SubSport.generic);
    }
  }
}

