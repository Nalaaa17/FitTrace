import 'dart:math' as math;

import '../models/hr_zone_config.dart';

class HrZoneResult {
  const HrZoneResult({
    required this.pointZones,
    required this.zoneDurationsSec,
    required this.avgHeartRate,
    required this.maxHeartRate,
  });

  final List<int?> pointZones;
  final List<int> zoneDurationsSec;
  final double? avgHeartRate;
  final double? maxHeartRate;
}

/// Computes HR Zone 1..5 per trackpoint and total duration per zone (PRD M2-06).
class HrZoneCalculator {
  const HrZoneCalculator();

  HrZoneResult calculate({
    required List<DateTime> timestampsUtc,
    required List<int?> heartRatesBpm,
    required HrZoneConfig config,
  }) {
    final n = timestampsUtc.length;
    if (n == 0) {
      return const HrZoneResult(
        pointZones: <int?>[],
        zoneDurationsSec: <int>[0, 0, 0, 0, 0],
        avgHeartRate: null,
        maxHeartRate: null,
      );
    }

    final pointZones = List<int?>.filled(n, null, growable: false);
    final zoneMs = List<int>.filled(5, 0, growable: false);

    var hrSum = 0.0;
    var hrCount = 0;
    int? maxHr;

    for (var i = 0; i < n; i++) {
      final hr = heartRatesBpm[i];
      if (hr != null && hr > 0) {
        final zone = config.zoneForHeartRate(hr);
        pointZones[i] = zone;
        hrSum += hr;
        hrCount++;
        if (maxHr == null || hr > maxHr) {
          maxHr = hr;
        }
      }
    }

    for (var i = 1; i < n; i++) {
      final zone = pointZones[i] ?? pointZones[i - 1];
      if (zone == null) continue;
      final dtMs = math.max(
        0,
        timestampsUtc[i].difference(timestampsUtc[i - 1]).inMilliseconds,
      );
      zoneMs[zone - 1] += dtMs;
    }

    final zoneDurationsSec = zoneMs
        .map((ms) => (ms / 1000.0).round())
        .toList(growable: false);

    return HrZoneResult(
      pointZones: pointZones,
      zoneDurationsSec: zoneDurationsSec,
      avgHeartRate: hrCount > 0 ? hrSum / hrCount : null,
      maxHeartRate: maxHr?.toDouble(),
    );
  }
}

