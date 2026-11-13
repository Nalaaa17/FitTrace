import 'package:metrics_engine/metrics_engine.dart';
import 'package:test/test.dart';

void main() {
  group('BestEffortCalculator (M2-10)', () {
    test('detects fastest contiguous 5K & 10K inside a negative-split half marathon', () {
      const calculator = BestEffortCalculator();
      final t0 = DateTime.utc(2026, 11, 1, 5, 0, 0);

      // 22 km run (~22,000 points, 1 point per meter-second simplification: 220 points every 100m):
      // km 0..11 @ 6:00/km (36s per 100m)
      // km 11..22 @ 4:00/km (24s per 100m) -> fastest 5K & 10K should come from second half!
      final points = <ParsedTrackPoint>[];
      var elapsedSec = 0;
      for (var step = 0; step <= 220; step++) {
        final distM = step * 100;
        if (step > 0) {
          final isFastHalf = distM > 11000;
          elapsedSec += isFastHalf ? 24 : 36;
        }
        final speedMps = step == 0 ? 100 / 36.0 : (distM > 11000 ? 100 / 24.0 : 100 / 36.0);
        points.add(
          ParsedTrackPoint(
            timestampUtc: t0.add(Duration(seconds: elapsedSec)),
            latitudeDeg: -6.2 + step * 0.0008,
            longitudeDeg: 106.8,
            altitudeM: 10,
            speedMps: speedMps,
            distanceMeters: distM,
          ),
        );
      }

      final efforts = calculator.detect(trackPoints: points);
      final fiveK = efforts.firstWhere(
        (e) => e.distance == BestEffortDistance.fiveK,
      );
      final tenK = efforts.firstWhere(
        (e) => e.distance == BestEffortDistance.tenK,
      );
      final hm = efforts.firstWhere(
        (e) => e.distance == BestEffortDistance.halfMarathon,
      );

      // 5K @ 4:00/km = 1200s (20:00)
      expect(fiveK.durationSec, inInclusiveRange(1195, 1205));
      expect(fiveK.startDistanceMeters, greaterThanOrEqualTo(11000));
      // 10K @ 4:00/km = 2400s (40:00)
      expect(tenK.durationSec, inInclusiveRange(2395, 2405));
      expect(hm.durationSec, greaterThan(6000));
      // No marathon covered in 22 km run.
      expect(
        efforts.where((e) => e.distance == BestEffortDistance.marathon),
        isEmpty,
      );
    });
  });

  group('VdotPredictor (M2-11)', () {
    test('estimates realistic VO2max & monotonic race predictions from 5K effort', () {
      const predictor = VdotPredictor();
      // 20:00 5K -> classic VDOT ~49.8
      final est20Min = predictor.estimateFromSamples(const <PerformanceSample>[
        PerformanceSample(
          title: 'Morning 5K Tempo',
          distanceMeters: 5000,
          durationSec: 20 * 60,
        ),
      ]);
      expect(est20Min, isNotNull);
      expect(est20Min!.isEstimate, isTrue);
      expect(est20Min.vo2Max, inInclusiveRange(48.0, 52.0));
      expect(est20Min.predictions.length, 4);

      final p5k = est20Min.predictions[0];
      final p10k = est20Min.predictions[1];
      final pHm = est20Min.predictions[2];
      final pFm = est20Min.predictions[3];

      expect(p5k.predictedDurationSec, inInclusiveRange(1190, 1210));
      expect(p10k.predictedDurationSec, inInclusiveRange(2450, 2550));
      expect(pHm.predictedPaceSecPerKm, greaterThan(p10k.predictedPaceSecPerKm));
      expect(pFm.predictedPaceSecPerKm, greaterThan(pHm.predictedPaceSecPerKm));

      // Faster benchmark produces strictly higher VO2max.
      final est18Min = predictor.estimateFromSamples(const <PerformanceSample>[
        PerformanceSample(
          title: 'Fast 5K',
          distanceMeters: 5000,
          durationSec: 18 * 60,
        ),
      ]);
      expect(est18Min!.vo2Max, greaterThan(est20Min.vo2Max));
    });

    test('returns null when only runs shorter than 1.5 km exist', () {
      const predictor = VdotPredictor();
      final res = predictor.estimateFromSamples(const <PerformanceSample>[
        PerformanceSample(
          title: 'Short Shakeout',
          distanceMeters: 1200,
          durationSec: 360,
        ),
      ]);
      expect(res, isNull);
    });
  });
}

