import 'dart:math' as math;

import 'package:metrics_engine/metrics_engine.dart';
import 'package:test/test.dart';

void main() {
  group('DouglasPeucker', () {
    test('simplifies 45,000-point marathon route quickly while keeping corners', () {
      const pointCount = 45000;
      final lats = List<double>.filled(pointCount, 0.0);
      final lngs = List<double>.filled(pointCount, 0.0);

      // L-shaped marathon course with subtle GPS oscillation (< 0.4 m) and sharp 90-deg turn.
      for (var i = 0; i < pointCount; i++) {
        final t = i / (pointCount - 1);
        final jitter = (i % 2 == 0 ? 1 : -1) * 0.000002;
        if (t < 0.5) {
          lats[i] = -6.2000 + t * 0.2;
          lngs[i] = 106.8000 + jitter;
        } else {
          lats[i] = -6.1000 + jitter;
          lngs[i] = 106.8000 + (t - 0.5) * 0.2;
        }
      }

      final sw = Stopwatch()..start();
      final keptOverview = DouglasPeucker.simplifyLatLngIndices(
        latitudes: lats,
        longitudes: lngs,
        toleranceMeters: 5.0,
      );
      final keptStreet = DouglasPeucker.simplifyLatLngIndices(
        latitudes: lats,
        longitudes: lngs,
        toleranceMeters: 1.0,
      );
      sw.stop();

      expect(keptOverview.first, 0);
      expect(keptOverview.last, pointCount - 1);
      expect(keptOverview.length, lessThan(200));
      expect(keptStreet.length, greaterThanOrEqualTo(keptOverview.length));

      // Verify sharp 90-degree apex corner around midpoint is preserved.
      final hasMidCorner = keptOverview.any(
        (idx) => (idx - pointCount ~/ 2).abs() < 10,
      );
      expect(hasMidCorner, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('preserves gentle curve deviation exceeding tolerance', () {
      final lats = List<double>.generate(100, (i) => -6.2 + i * 0.0001);
      final lngs = List<double>.generate(
        100,
        (i) => 106.8 + math.sin(i / 99 * math.pi) * 0.001, // ~111m arc
      );

      final kept = DouglasPeucker.simplifyLatLngIndices(
        latitudes: lats,
        longitudes: lngs,
        toleranceMeters: 3.0,
      );
      expect(kept.length, greaterThan(4));
      expect(kept.length, lessThan(40));
    });
  });

  group('GarminFitEncoder round-trip', () {
    test('regenerates outdoor GPS activity and preserves metrics on re-parse', () {
      final t0 = DateTime.utc(2026, 11, 12, 0, 0);
      final points = List<ParsedTrackPoint>.generate(30, (i) {
        return ParsedTrackPoint(
          timestampUtc: t0.add(Duration(seconds: i * 10)),
          latitudeDeg: -6.2000 + i * 0.0003,
          longitudeDeg: 106.8000 + (i * 0.00005),
          altitudeM: 20.0 + i * 0.4,
          speedMps: 3.4,
          distanceMeters: i * 34,
          heartRateBpm: 145 + (i % 15),
          cadenceRpm: 88,
        );
      });

      final original = ParsedActivity(
        title: 'Regenerated 1K Run',
        sportType: SportType.run,
        startTimeUtc: t0,
        utcOffsetSeconds: 25200, // UTC+7
        durationTotalSec: 290,
        durationMovingSec: 290,
        distanceMeters: 986,
        avgPaceSecPerKm: 294.1,
        avgHeartRate: 152,
        maxHeartRate: 159,
        avgCadence: 88,
        totalElevationGainM: 11.6,
        totalElevationLossM: 0,
        caloriesKcal: 85,
        isIndoor: false,
        hasGpsTrack: true,
        gpsQuality: GpsQuality.good,
        splitPacesSecPerKm: const <int>[294],
        zoneDurationsSec: const <int>[0, 0, 150, 140, 0],
        trackPoints: points,
        lapSplits: const <ParsedLapSplit>[
          ParsedLapSplit(
            splitIndex: 0,
            distanceMeters: 986,
            durationSec: 290,
            avgPaceSecPerKm: 294.1,
            elevationDeltaM: 11.6,
            avgHeartRate: 152,
            avgCadence: 88,
          ),
        ],
      );

      final fitBytes = const GarminFitEncoder().encodeActivity(original);
      expect(fitBytes.length, greaterThan(100));

      final reparsed = const GarminFitParserEngine().parseFitBytes(
        fitBytes,
        hrZoneConfig: HrZoneConfig.resolve(),
        fallbackTitle: original.title,
      );

      expect(reparsed.trackPoints.length, 30);
      expect(reparsed.isIndoor, isFalse);
      expect(reparsed.hasGpsTrack, isTrue);
      expect(reparsed.utcOffsetSeconds, 25200);
      expect(reparsed.distanceMeters, closeTo(986, 5));
      expect(reparsed.avgHeartRate, closeTo(152, 2));
      expect(reparsed.caloriesKcal, 85);
    });

    test('regenerates indoor treadmill activity without GPS or HR cleanly', () {
      final t0 = DateTime.utc(2026, 11, 12, 12, 0);
      final points = List<ParsedTrackPoint>.generate(20, (i) {
        return ParsedTrackPoint(
          timestampUtc: t0.add(Duration(seconds: i * 15)),
          latitudeDeg: 0,
          longitudeDeg: 0,
          altitudeM: 0,
          speedMps: 2.8,
          distanceMeters: i * 42,
        );
      });

      final indoor = ParsedActivity(
        title: 'Treadmill Test',
        sportType: SportType.treadmill,
        startTimeUtc: t0,
        utcOffsetSeconds: 0,
        durationTotalSec: 285,
        durationMovingSec: 285,
        distanceMeters: 798,
        avgPaceSecPerKm: 357.1,
        totalElevationGainM: 0,
        totalElevationLossM: 0,
        caloriesKcal: 62,
        isIndoor: true,
        hasGpsTrack: false,
        gpsQuality: GpsQuality.none,
        splitPacesSecPerKm: const <int>[357],
        zoneDurationsSec: const <int>[0, 0, 0, 0, 0],
        trackPoints: points,
        lapSplits: const <ParsedLapSplit>[],
      );

      final bytes = const GarminFitEncoder().encodeActivity(indoor);
      final reparsed = const GarminFitParserEngine().parseFitBytes(
        bytes,
        hrZoneConfig: HrZoneConfig.resolve(),
        fallbackTitle: 'Treadmill Test',
      );

      expect(reparsed.isIndoor, isTrue);
      expect(reparsed.hasGpsTrack, isFalse);
      expect(reparsed.sportType, SportType.treadmill);
      expect(reparsed.trackPoints.length, 20);
      expect(reparsed.avgHeartRate, isNull);
    });
  });
}
