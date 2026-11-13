import 'dart:math' as math;

import '../models/enums.dart';
import 'geo_utils.dart';

/// Raw track sample prior to spike filtering and enrichment.
class RawTrackSample {
  const RawTrackSample({
    required this.timestampUtc,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.hasValidGps,
    required this.altitudeM,
    required this.speedMps,
    required this.distanceMeters,
    this.heartRateBpm,
    this.cadenceRpm,
  });

  final DateTime timestampUtc;
  final double latitudeDeg;
  final double longitudeDeg;
  final bool hasValidGps;
  final double altitudeM;
  final double? speedMps;
  final double? distanceMeters;
  final int? heartRateBpm;
  final int? cadenceRpm;
}

class SpikeFilterResult {
  const SpikeFilterResult({
    required this.samples,
    required this.droppedOutliersCount,
    required this.gpsQuality,
  });

  final List<RawTrackSample> samples;
  final int droppedOutliersCount;
  final GpsQuality gpsQuality;
}

/// Drops GPS outlier spikes (>15 m/s or >2x sustained running speed) per PRD §7.
class GpsSpikeFilter {
  const GpsSpikeFilter();

  static const double absoluteMaxRunningSpeedMps = 15.0;

  SpikeFilterResult filter(List<RawTrackSample> samples) {
    if (samples.length < 2) {
      return SpikeFilterResult(
        samples: samples,
        droppedOutliersCount: 0,
        gpsQuality: samples.isEmpty ? GpsQuality.none : GpsQuality.good,
      );
    }

    final sustainedSpeed = _estimateSustainedSpeedMps(samples);
    final dynamicCap = sustainedSpeed >= 1.5
        ? math.min(absoluteMaxRunningSpeedMps, sustainedSpeed * 2.0)
        : absoluteMaxRunningSpeedMps;

    final kept = <RawTrackSample>[samples.first];
    var dropped = 0;

    for (var i = 1; i < samples.length; i++) {
      final candidate = samples[i];
      final anchor = kept.last;
      final dtSec =
          candidate.timestampUtc.difference(anchor.timestampUtc).inMilliseconds /
          1000.0;

      if (dtSec <= 0) {
        dropped++;
        continue;
      }

      final segmentMeters = GeoUtils.haversineMeters(
        anchor.latitudeDeg,
        anchor.longitudeDeg,
        candidate.latitudeDeg,
        candidate.longitudeDeg,
      );
      final impliedSpeedMps = segmentMeters / dtSec;

      if (impliedSpeedMps > absoluteMaxRunningSpeedMps ||
          impliedSpeedMps > dynamicCap) {
        dropped++;
        continue;
      }

      kept.add(candidate);
    }

    return SpikeFilterResult(
      samples: kept,
      droppedOutliersCount: dropped,
      gpsQuality: dropped > 0 ? GpsQuality.degraded : GpsQuality.good,
    );
  }

  double _estimateSustainedSpeedMps(List<RawTrackSample> samples) {
    final speeds = <double>[];
    for (var i = 1; i < samples.length; i++) {
      final prev = samples[i - 1];
      final curr = samples[i];
      final dtSec =
          curr.timestampUtc.difference(prev.timestampUtc).inMilliseconds /
          1000.0;
      if (dtSec <= 0) continue;

      final dist = GeoUtils.haversineMeters(
        prev.latitudeDeg,
        prev.longitudeDeg,
        curr.latitudeDeg,
        curr.longitudeDeg,
      );
      final v = dist / dtSec;
      if (v >= 0.8 && v <= absoluteMaxRunningSpeedMps) {
        speeds.add(v);
      }
    }

    if (speeds.isEmpty) return 0.0;
    speeds.sort();
    return speeds[speeds.length ~/ 2];
  }
}

