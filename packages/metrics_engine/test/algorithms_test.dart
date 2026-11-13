import 'package:metrics_engine/metrics_engine.dart';
import 'package:test/test.dart';

void main() {
  group('GeoUtils', () {
    test('converts FIT semicircles to decimal degrees accurately', () {
      // Jakarta (~ -6.2000 deg, 106.8166 deg)
      const latSemi = -73968881;
      const lngSemi = 1274371618;

      expect(GeoUtils.semicirclesToDegrees(latSemi), closeTo(-6.2, 1e-5));
      expect(GeoUtils.semicirclesToDegrees(lngSemi), closeTo(106.8166, 1e-5));
    });

    test('validates WGS-84 coordinate bounds', () {
      expect(GeoUtils.isValidCoordinate(-6.2, 106.8), isTrue);
      expect(GeoUtils.isValidCoordinate(-90.0, 180.0), isTrue);
      expect(GeoUtils.isValidCoordinate(90.001, 0.0), isFalse);
      expect(GeoUtils.isValidCoordinate(0.0, -180.001), isFalse);
      expect(GeoUtils.isValidCoordinate(double.nan, 10.0), isFalse);
      expect(GeoUtils.isValidCoordinate(null, 10.0), isFalse);
    });

    test('computes Haversine distance in meters', () {
      final meters = GeoUtils.haversineMeters(
        -6.200000,
        106.800000,
        -6.208993,
        106.800000,
      );
      expect(meters, closeTo(1000.0, 5.0));
    });
  });

  group('MovingTimeCalculator (M2-03)', () {
    test('excludes stops < 0.5 m/s lasting >= 10s while preserving brief pauses', () {
      final t0 = DateTime.utc(2026, 11, 12, 0, 0);
      final timestamps = <DateTime>[];
      final speeds = <double?>[];
      final distances = <double>[];

      var dist = 0.0;
      for (var sec = 0; sec <= 60; sec++) {
        timestamps.add(t0.add(Duration(seconds: sec)));
        // 0..19s: running 3.0 m/s
        // 20..34s: stopped 0.1 m/s (15 seconds -> >= 10s stopped)
        // 35..44s: running 3.0 m/s
        // 45..47s: brief 3-second traffic slow down 0.2 m/s (< 10s -> kept moving)
        // 48..60s: running 3.0 m/s
        final double v;
        if (sec >= 20 && sec <= 34) {
          v = 0.1;
        } else if (sec >= 45 && sec <= 47) {
          v = 0.2;
        } else {
          v = 3.0;
        }
        speeds.add(v);
        if (sec > 0) dist += v;
        distances.add(dist);
      }

      const calc = MovingTimeCalculator();
      final result = calc.calculate(
        timestampsUtc: timestamps,
        sensorSpeedsMps: speeds,
        cumulativeDistancesM: distances,
      );

      expect(result.totalElapsedSec, 60);
      // Stopped block (smoothed <0.5 m/s) covers ~11..15 seconds, so movingTime < 52s.
      expect(result.movingTimeSec, lessThanOrEqualTo(51));
      expect(result.movingTimeSec, greaterThanOrEqualTo(42));
    });
  });

  group('ElevationCalculator (M2-05)', () {
    test('suppresses <0.5m altimeter jitter and counts smoothed climb', () {
      // Flat with +/- 0.3m noise -> 0m gain
      final flatNoisy = List<double>.generate(
        20,
        (i) => 10.0 + (i.isEven ? 0.3 : -0.3),
      );
      const calc = ElevationCalculator();
      final flatRes = calc.calculate(flatNoisy);
      expect(flatRes.totalGainM, closeTo(0.0, 0.01));

      // Steady 10m climb then 6m descent
      final climbThenDescent = <double>[
        for (var i = 0; i <= 20; i++) 10.0 + i * 0.5,
        for (var i = 1; i <= 12; i++) 20.0 - i * 0.5,
      ];
      final climbRes = calc.calculate(climbThenDescent);
      expect(climbRes.totalGainM, greaterThan(7.5));
      expect(climbRes.totalLossM, greaterThan(3.5));

      final emptyRes = calc.calculate(const <double>[]);
      expect(emptyRes.totalGainM, 0.0);
      expect(emptyRes.totalLossM, 0.0);
    });
  });
}
