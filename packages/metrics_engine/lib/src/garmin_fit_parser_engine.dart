import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';

import 'algorithms/best_effort_calculator.dart';
import 'algorithms/elevation_calculator.dart';
import 'algorithms/geo_utils.dart';
import 'algorithms/gps_spike_filter.dart';
import 'algorithms/hr_zone_calculator.dart';
import 'algorithms/moving_time_calculator.dart';
import 'algorithms/split_calculator.dart';
import 'fit_parser_contract.dart';
import 'models/enums.dart';
import 'models/hr_zone_config.dart';
import 'models/parsed_activity.dart';
import 'models/parsed_lap_split.dart';
import 'models/parsed_track_point.dart';

/// Pure Dart implementation of [FitParserEngine] backed by `fit_tool` (PRD M2-01..M2-09).
class GarminFitParserEngine implements FitParserEngine {
  const GarminFitParserEngine({
    this.spikeFilter = const GpsSpikeFilter(),
    this.movingTimeCalculator = const MovingTimeCalculator(),
    this.elevationCalculator = const ElevationCalculator(),
    this.splitCalculator = const SplitCalculator(),
    this.hrZoneCalculator = const HrZoneCalculator(),
    this.bestEffortCalculator = const BestEffortCalculator(),
  });

  final GpsSpikeFilter spikeFilter;
  final MovingTimeCalculator movingTimeCalculator;
  final ElevationCalculator elevationCalculator;
  final SplitCalculator splitCalculator;
  final HrZoneCalculator hrZoneCalculator;
  final BestEffortCalculator bestEffortCalculator;

  @override
  ParsedActivity parseFitBytes(
    Uint8List bytes, {
    required HrZoneConfig hrZoneConfig,
    int? garminActivityId,
    String? fallbackTitle,
  }) {
    if (bytes.length < 14) {
      throw const FitParseException('FIT binary is empty or shorter than header.');
    }

    final FitFile fitFile;
    try {
      fitFile = FitFile.fromBytes(bytes, checkCrc: true);
    } on Object catch (error) {
      throw FitParseException('Failed to decode FIT binary: $error', error);
    }

    SessionMessage? session;
    ActivityMessage? activityMsg;
    var lapCount = 0;
    final rawHrv = <double>[];
    final rawRecords = <RawTrackSample>[];

    for (final record in fitFile.records) {
      if (record.isDefinition) continue;
      final message = record.message;

      if (message is SessionMessage) {
        session ??= message;
      } else if (message is LapMessage) {
        lapCount++;
      } else if (message is ActivityMessage) {
        activityMsg ??= message;
      } else if (message is HrvMessage) {
        final field = message.getField(HrvTimeField.ID);
        if (field != null && field.isValid()) {
          final dynamic values = field.getValues();
          if (values is List) {
            for (final rr in values) {
              if (rr is num && rr.isFinite && rr > 0) {
                rawHrv.add(rr.toDouble());
              }
            }
          }
        }
      } else if (message is RecordMessage) {
        final tsMs = message.timestamp;
        if (tsMs == null) continue;

        final lat = message.positionLat;
        final lng = message.positionLong;
        final validGps = GeoUtils.isValidCoordinate(lat, lng);

        final alt = message.enhancedAltitude ?? message.altitude ?? 0.0;
        final speed = message.enhancedSpeed ?? message.speed;
        final hr = message.heartRate;
        final cad = message.cadence;
        final dist = message.distance;

        rawRecords.add(
          RawTrackSample(
            timestampUtc: DateTime.fromMillisecondsSinceEpoch(tsMs, isUtc: true),
            latitudeDeg: validGps ? lat! : 0.0,
            longitudeDeg: validGps ? lng! : 0.0,
            hasValidGps: validGps,
            altitudeM: alt.isFinite ? alt : 0.0,
            speedMps: (speed != null && speed.isFinite && speed >= 0)
                ? speed
                : null,
            distanceMeters: (dist != null && dist.isFinite && dist >= 0)
                ? dist
                : null,
            heartRateBpm: (hr != null && hr > 0 && hr < 255) ? hr : null,
            cadenceRpm: (cad != null && cad >= 0 && cad < 255) ? cad : null,
          ),
        );
      }
    }

    final startTimeMs =
        session?.startTime ??
        (rawRecords.isNotEmpty
            ? rawRecords.first.timestampUtc.millisecondsSinceEpoch
            : activityMsg?.timestamp);
    if (startTimeMs == null) {
      throw const FitParseException(
        'FIT file contains neither session nor trackpoint timestamps.',
      );
    }

    final startTimeUtc = DateTime.fromMillisecondsSinceEpoch(
      startTimeMs,
      isUtc: true,
    );
    final utcOffsetSeconds = _resolveUtcOffsetSeconds(activityMsg);
    final sportType = _resolveSportType(session);

    final validGpsCount = rawRecords.where((r) => r.hasValidGps).length;
    final bool isIndoor = validGpsCount == 0;
    final bool hasGpsTrack;
    final GpsQuality gpsQuality;
    final List<RawTrackSample> cleanSamples;

    if (isIndoor) {
      rawRecords.sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
      cleanSamples = rawRecords;
      hasGpsTrack = false;
      gpsQuality = GpsQuality.none;
    } else {
      final gpsOnly = rawRecords.where((r) => r.hasValidGps).toList()
        ..sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));
      final spikeResult = spikeFilter.filter(gpsOnly);
      cleanSamples = spikeResult.samples;
      hasGpsTrack = cleanSamples.isNotEmpty;
      gpsQuality = spikeResult.gpsQuality;
    }

    final cumulativeDistances = _resolveCumulativeDistances(
      cleanSamples,
      hasGpsTrack: hasGpsTrack,
    );

    final timestamps = cleanSamples
        .map((s) => s.timestampUtc)
        .toList(growable: false);
    final sensorSpeeds = cleanSamples
        .map((s) => s.speedMps)
        .toList(growable: false);
    final rawAltitudes = cleanSamples
        .map((s) => s.altitudeM)
        .toList(growable: false);
    final heartRates = cleanSamples
        .map((s) => s.heartRateBpm)
        .toList(growable: false);

    final movingResult = movingTimeCalculator.calculate(
      timestampsUtc: timestamps,
      sensorSpeedsMps: sensorSpeeds,
      cumulativeDistancesM: cumulativeDistances,
    );
    final elevationSummary = elevationCalculator.calculate(rawAltitudes);
    final hrResult = hrZoneCalculator.calculate(
      timestampsUtc: timestamps,
      heartRatesBpm: heartRates,
      config: hrZoneConfig,
    );

    final trackPoints = List<ParsedTrackPoint>.generate(cleanSamples.length, (
      i,
    ) {
      final sample = cleanSamples[i];
      return ParsedTrackPoint(
        timestampUtc: sample.timestampUtc,
        latitudeDeg: sample.latitudeDeg,
        longitudeDeg: sample.longitudeDeg,
        altitudeM: sample.altitudeM,
        speedMps: movingResult.effectiveSpeedsMps[i],
        distanceMeters: cumulativeDistances[i].round(),
        heartRateBpm: sample.heartRateBpm,
        cadenceRpm: sample.cadenceRpm,
        hrZone: hrResult.pointZones[i],
      );
    }, growable: false);

    final lapSplits = trackPoints.length >= 2
        ? splitCalculator.calculate(
            trackPoints: trackPoints,
            cumulativeDistancesM: cumulativeDistances,
            movingIntervals: movingResult.movingIntervals,
            smoothedAltitudesM: elevationSummary.smoothedAltitudesM,
          )
        : const <ParsedLapSplit>[];

    final totalDistanceMeters = cumulativeDistances.isNotEmpty
        ? cumulativeDistances.last
        : (session?.totalDistance ?? 0.0);

    final int durationTotalSec = cleanSamples.length >= 2
        ? movingResult.totalElapsedSec
        : (session?.totalElapsedTime?.round() ?? 0);
    final int durationMovingSec = cleanSamples.length >= 2
        ? movingResult.movingTimeSec
        : (session?.totalTimerTime?.round() ?? durationTotalSec);

    final avgPaceSecPerKm = totalDistanceMeters > 0 && durationMovingSec > 0
        ? durationMovingSec / (totalDistanceMeters / 1000.0)
        : 0.0;

    final avgCadence = _resolveAverageCadence(cleanSamples, session);
    final bestEfforts = bestEffortCalculator.detect(
      trackPoints: trackPoints,
      summaryDistanceMeters: totalDistanceMeters,
      summaryMovingDurationSec: durationMovingSec,
    );
    final resolvedTitle =
        (fallbackTitle != null && fallbackTitle.trim().isNotEmpty)
        ? fallbackTitle.trim()
        : _defaultTitle(
            sportType,
            startTimeUtc.add(Duration(seconds: utcOffsetSeconds)),
          );

    return ParsedActivity(
      garminActivityId: garminActivityId,
      title: resolvedTitle,
      sportType: sportType,
      startTimeUtc: startTimeUtc,
      utcOffsetSeconds: utcOffsetSeconds,
      durationTotalSec: durationTotalSec,
      durationMovingSec: durationMovingSec,
      distanceMeters: totalDistanceMeters,
      avgPaceSecPerKm: avgPaceSecPerKm,
      avgHeartRate: hrResult.avgHeartRate ?? session?.avgHeartRate?.toDouble(),
      maxHeartRate: hrResult.maxHeartRate ?? session?.maxHeartRate?.toDouble(),
      avgCadence: avgCadence,
      totalElevationGainM: trackPoints.length >= 2
          ? elevationSummary.totalGainM
          : (session?.totalAscent?.toDouble() ?? 0.0),
      totalElevationLossM: trackPoints.length >= 2
          ? elevationSummary.totalLossM
          : (session?.totalDescent?.toDouble() ?? 0.0),
      caloriesKcal: session?.totalCalories ?? 0,
      isIndoor: isIndoor,
      hasGpsTrack: hasGpsTrack,
      gpsQuality: gpsQuality,
      splitPacesSecPerKm: lapSplits
          .map((s) => s.avgPaceSecPerKm.round())
          .toList(growable: false),
      zoneDurationsSec: hrResult.zoneDurationsSec,
      trackPoints: trackPoints,
      lapSplits: lapSplits,
      rawHrvIntervalsSec: rawHrv,
      fitLapCount: lapCount,
      bestEfforts: bestEfforts,
    );
  }

  int _resolveUtcOffsetSeconds(ActivityMessage? activityMsg) {
    final utcMs = activityMsg?.timestamp;
    final localFitSec = activityMsg?.localTimestamp;
    if (utcMs == null || localFitSec == null) return 0;

    final localMs = toMillisecondsSinceEpoch(localFitSec);
    final diffSec = ((localMs - utcMs) / 1000.0).round();
    if (diffSec < -43200 || diffSec > 50400) return 0;
    return diffSec;
  }

  SportType _resolveSportType(SessionMessage? session) {
    Sport? sport;
    SubSport? subSport;
    try {
      sport = session?.sport;
    } on ArgumentError {
      return SportType.other;
    }
    try {
      subSport = session?.subSport;
    } on ArgumentError {
      subSport = null;
    }
    if (sport == null) return SportType.run;

    if (sport == Sport.running) {
      if (subSport == SubSport.trail) return SportType.trailRun;
      if (subSport == SubSport.treadmill ||
          subSport == SubSport.indoorRunning) {
        return SportType.treadmill;
      }
      return SportType.run;
    }
    if (sport == Sport.fitnessEquipment &&
        (subSport == SubSport.treadmill ||
            subSport == SubSport.indoorRunning)) {
      return SportType.treadmill;
    }
    return SportType.other;
  }

  List<double> _resolveCumulativeDistances(
    List<RawTrackSample> samples, {
    required bool hasGpsTrack,
  }) {
    if (samples.isEmpty) return const <double>[];

    final distances = List<double>.filled(samples.length, 0.0, growable: false);
    final firstDist = samples.first.distanceMeters;
    distances[0] = (firstDist != null && firstDist >= 0) ? firstDist : 0.0;

    for (var i = 1; i < samples.length; i++) {
      final prev = samples[i - 1];
      final curr = samples[i];
      final prevCum = distances[i - 1];

      final rawDist = curr.distanceMeters;
      if (rawDist != null && rawDist >= prevCum) {
        distances[i] = rawDist;
        continue;
      }

      if (hasGpsTrack) {
        final delta = GeoUtils.haversineMeters(
          prev.latitudeDeg,
          prev.longitudeDeg,
          curr.latitudeDeg,
          curr.longitudeDeg,
        );
        distances[i] = prevCum + delta;
        continue;
      }

      final dtSec =
          curr.timestampUtc.difference(prev.timestampUtc).inMilliseconds /
          1000.0;
      final spd = curr.speedMps ?? prev.speedMps ?? 0.0;
      distances[i] = prevCum + math.max(0.0, spd * math.max(0.0, dtSec));
    }

    return distances;
  }

  double? _resolveAverageCadence(
    List<RawTrackSample> samples,
    SessionMessage? session,
  ) {
    var sum = 0.0;
    var count = 0;
    for (final s in samples) {
      final cad = s.cadenceRpm;
      if (cad != null && cad > 0) {
        sum += cad;
        count++;
      }
    }
    if (count > 0) return sum / count;
    return session?.avgRunningCadence?.toDouble() ??
        session?.avgCadence?.toDouble();
  }

  String _defaultTitle(SportType sportType, DateTime localTime) {
    if (sportType == SportType.treadmill) return 'Treadmill Run';
    if (sportType == SportType.trailRun) return 'Trail Run';
    if (sportType == SportType.other) return 'Activity';

    final hour = localTime.hour;
    if (hour >= 4 && hour < 11) return 'Morning Run';
    if (hour >= 11 && hour < 15) return 'Lunch Run';
    if (hour >= 15 && hour < 19) return 'Afternoon Run';
    return 'Night Run';
  }
}
