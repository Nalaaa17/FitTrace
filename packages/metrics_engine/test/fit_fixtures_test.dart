import 'dart:isolate';
import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:test/test.dart';

Uint8List _buildRunFitBytes({
  required int pointCount,
  required int stepSeconds,
  required double speedMps,
  bool includeGps = true,
  bool includeHr = true,
  bool includeHrv = false,
  Sport sport = Sport.running,
  SubSport subSport = SubSport.street,
  int utcOffsetHours = 0,
  int? injectSpikeAtIndex,
  int? injectInvalidCoordAtIndex,
  int pauseStartSec = -1,
  int pauseEndSec = -1,
}) {
  final builder = FitFileBuilder(autoDefine: true);
  final startUtc = DateTime.utc(2026, 11, 12, 0, 0, 0);

  final fileId = FileIdMessage()
    ..type = FileType.activity
    ..manufacturer = Manufacturer.garmin.value
    ..timeCreated = startUtc.millisecondsSinceEpoch;
  builder.add(fileId);

  var distMeters = 0.0;
  var lat = -6.200000;
  const lng = 106.800000;
  // ~1 deg lat = 111,111 m
  const metersPerDegLat = 111111.0;

  for (var i = 0; i < pointCount; i++) {
    final elapsedSec = i * stepSeconds;
    final tsMs = startUtc.millisecondsSinceEpoch + elapsedSec * 1000;
    final isPaused = elapsedSec >= pauseStartSec && elapsedSec <= pauseEndSec;
    final currentSpeed = isPaused ? 0.0 : speedMps;

    if (i > 0) {
      final segDist = currentSpeed * stepSeconds;
      distMeters += segDist;
      if (includeGps) {
        lat += segDist / metersPerDegLat;
      }
    }

    final record = RecordMessage()
      ..timestamp = tsMs
      ..distance = distMeters
      ..enhancedSpeed = currentSpeed
      ..enhancedAltitude = 10.0 + (i * 0.05)
      ..cadence = isPaused ? 0 : 88;

    if (includeHr) {
      record.heartRate = 140 + (i % 35);
    }

    if (includeGps) {
      if (i == injectInvalidCoordAtIndex) {
        record
          ..positionLat = 95.5 // invalid > 90
          ..positionLong = 106.8;
      } else if (i == injectSpikeAtIndex) {
        record
          ..positionLat = lat + 0.01 // ~1.1 km jump in 1 step -> spike!
          ..positionLong = lng;
      } else {
        record
          ..positionLat = lat
          ..positionLong = lng;
      }
    }

    builder.add(record);
  }

  if (includeHrv) {
    builder.add(HrvMessage()..time = <double>[0.812, 0.805, 0.798]);
  }

  final totalSec = (pointCount - 1) * stepSeconds;
  final lap = LapMessage()
    ..timestamp = startUtc.millisecondsSinceEpoch + totalSec * 1000
    ..startTime = startUtc.millisecondsSinceEpoch
    ..totalElapsedTime = totalSec.toDouble()
    ..totalTimerTime = totalSec.toDouble()
    ..totalDistance = distMeters;
  builder.add(lap);

  final session = SessionMessage()
    ..timestamp = startUtc.millisecondsSinceEpoch + totalSec * 1000
    ..startTime = startUtc.millisecondsSinceEpoch
    ..sport = sport
    ..subSport = subSport
    ..totalElapsedTime = totalSec.toDouble()
    ..totalTimerTime = totalSec.toDouble()
    ..totalDistance = distMeters
    ..totalCalories = 320;
  builder.add(session);

  final endUtcMs = startUtc.millisecondsSinceEpoch + totalSec * 1000;
  final localFitSec = toSecondsSince1989Epoch(
    endUtcMs + utcOffsetHours * 3600 * 1000,
  );
  final activity = ActivityMessage()
    ..timestamp = endUtcMs
    ..localTimestamp = localFitSec
    ..numSessions = 1
    ..totalTimerTime = totalSec.toDouble();
  builder.add(activity);

  return builder.build().toBytes();
}

void main() {
  const parser = GarminFitParserEngine();
  final defaultHrConfig = HrZoneConfig.resolve(hrMaxManual: 190);

  group('GarminFitParserEngine 8 FIT fixture scenarios', () {
    test('1. 5K outdoor run extracts splits, HR zones, elevation, and raw HRV', () {
      // 501 points x 3s x 3.333 m/s ~= 5000 m in 1500s
      final bytes = _buildRunFitBytes(
        pointCount: 501,
        stepSeconds: 3,
        speedMps: 10.0 / 3.0,
        includeHrv: true,
        utcOffsetHours: 7,
      );

      final result = parser.parseFitBytes(
        bytes,
        hrZoneConfig: defaultHrConfig,
        garminActivityId: 1001,
      );

      expect(result.garminActivityId, 1001);
      expect(result.sportType, SportType.run);
      expect(result.isIndoor, isFalse);
      expect(result.hasGpsTrack, isTrue);
      expect(result.gpsQuality, GpsQuality.good);
      expect(result.distanceMeters, closeTo(5000, 15));
      expect(result.durationMovingSec, 1500);
      expect(result.avgPaceSecPerKm, closeTo(300, 2));
      expect(result.lapSplits, hasLength(5));
      expect(result.splitPacesSecPerKm, hasLength(5));
      expect(result.totalElevationGainM, greaterThan(20));
      expect(result.zoneDurationsSec.reduce((a, b) => a + b), greaterThan(1400));
      expect(result.rawHrvIntervalsSec, hasLength(3));
      expect(result.fitLapCount, 1);
      expect(result.caloriesKcal, 320);
      expect(result.avgCadence, closeTo(88, 0.1));
    });

    test('2. Marathon >30,000 trackpoints parses cleanly in Isolate', () async {
      // 32,000 points x 1s x 1.32 m/s = 42,238.68 m (~42.2K)
      final bytes = _buildRunFitBytes(
        pointCount: 32000,
        stepSeconds: 1,
        speedMps: 1.32,
      );

      final result = await Isolate.run(
        () => parser.parseFitBytes(bytes, hrZoneConfig: defaultHrConfig),
      );

      expect(result.trackPoints, hasLength(32000));
      expect(result.distanceMeters, closeTo(42238, 10));
      // 42 full 1km splits + 1 trailing ~238m split = 43 splits
      expect(result.lapSplits, hasLength(43));
    });

    test('3. Indoor treadmill run without GPS sets isIndoor and keeps splits/HR', () {
      final bytes = _buildRunFitBytes(
        pointCount: 301,
        stepSeconds: 3,
        speedMps: 2.8,
        includeGps: false,
        subSport: SubSport.treadmill,
      );

      final result = parser.parseFitBytes(bytes, hrZoneConfig: defaultHrConfig);

      expect(result.sportType, SportType.treadmill);
      expect(result.isIndoor, isTrue);
      expect(result.hasGpsTrack, isFalse);
      expect(result.gpsQuality, GpsQuality.none);
      expect(result.distanceMeters, closeTo(2520, 5));
      expect(result.lapSplits, hasLength(3));
      expect(result.avgHeartRate, isNotNull);
      expect(result.title, 'Treadmill Run');
    });

    test('4. Run without heart rate data leaves HR metrics empty cleanly', () {
      final bytes = _buildRunFitBytes(
        pointCount: 101,
        stepSeconds: 3,
        speedMps: 3.0,
        includeHr: false,
      );

      final result = parser.parseFitBytes(bytes, hrZoneConfig: defaultHrConfig);

      expect(result.avgHeartRate, isNull);
      expect(result.maxHeartRate, isNull);
      expect(result.zoneDurationsSec, const <int>[0, 0, 0, 0, 0]);
      expect(result.trackPoints.every((p) => p.hrZone == null), isTrue);
    });

    test('5. GPS spike outlier (>15 m/s) is dropped and flags gpsQuality degraded', () {
      final bytes = _buildRunFitBytes(
        pointCount: 60,
        stepSeconds: 3,
        speedMps: 3.0,
        injectSpikeAtIndex: 25,
      );

      final result = parser.parseFitBytes(bytes, hrZoneConfig: defaultHrConfig);

      expect(result.gpsQuality, GpsQuality.degraded);
      expect(result.trackPoints.length, lessThan(60));
    });

    test('6. Invalid coordinate out of bounds is dropped on outdoor run', () {
      final bytes = _buildRunFitBytes(
        pointCount: 40,
        stepSeconds: 3,
        speedMps: 3.0,
        injectInvalidCoordAtIndex: 10,
      );

      final result = parser.parseFitBytes(bytes, hrZoneConfig: defaultHrConfig);

      expect(result.hasGpsTrack, isTrue);
      expect(result.trackPoints, hasLength(39));
    });

    test('7. Corrupt CRC or truncated FIT bytes throw FitParseException', () {
      final valid = _buildRunFitBytes(
        pointCount: 10,
        stepSeconds: 3,
        speedMps: 3.0,
      );
      final badCrc = Uint8List.fromList(valid);
      badCrc[badCrc.length - 1] ^= 0xFF;

      expect(
        () => parser.parseFitBytes(badCrc, hrZoneConfig: defaultHrConfig),
        throwsA(isA<FitParseException>()),
      );
      expect(
        () => parser.parseFitBytes(
          Uint8List.fromList(<int>[1, 2, 3]),
          hrZoneConfig: defaultHrConfig,
        ),
        throwsA(isA<FitParseException>()),
      );
    });

    test('8. Cross-timezone localTimestamp (+7h) and >=10s stop exclusion', () {
      // 121 points x 2s = 240s elapsed, with 20s pause from 100s..120s
      final bytes = _buildRunFitBytes(
        pointCount: 121,
        stepSeconds: 2,
        speedMps: 3.0,
        utcOffsetHours: 7,
        pauseStartSec: 100,
        pauseEndSec: 120,
      );

      final result = parser.parseFitBytes(bytes, hrZoneConfig: defaultHrConfig);

      expect(result.utcOffsetSeconds, 7 * 3600);
      expect(result.startTimeLocal, DateTime.utc(2026, 11, 12, 7, 0, 0));
      expect(result.durationTotalSec, 240);
      expect(result.durationMovingSec, lessThan(230));
    });

    test('supports trailRun, cycling fallback, custom title, and missing distance field', () {
      final trailBytes = _buildRunFitBytes(
        pointCount: 40,
        stepSeconds: 3,
        speedMps: 2.5,
        subSport: SubSport.trail,
      );
      final trail = parser.parseFitBytes(
        trailBytes,
        hrZoneConfig: defaultHrConfig,
        fallbackTitle: 'Sentul Trail',
      );
      expect(trail.sportType, SportType.trailRun);
      expect(trail.title, 'Sentul Trail');

      // Build FIT without RecordMessage.distance -> fallback to Haversine
      final builder = FitFileBuilder(autoDefine: true);
      final t0 = DateTime.utc(2026, 11, 12, 6, 0);
      for (var i = 0; i < 20; i++) {
        builder.add(
          RecordMessage()
            ..timestamp = t0.millisecondsSinceEpoch + i * 3000
            ..positionLat = -6.2 + (i * 0.0001)
            ..positionLong = 106.8,
        );
      }
      builder.add(
        SessionMessage()
          ..startTime = t0.millisecondsSinceEpoch
          ..sport = Sport.cycling,
      );
      final noDist = parser.parseFitBytes(
        builder.build().toBytes(),
        hrZoneConfig: defaultHrConfig,
      );
      expect(noDist.sportType, SportType.other);
      expect(noDist.distanceMeters, greaterThan(180));

      // Indoor speed fallback when distance field is omitted
      final indoorBuilder = FitFileBuilder(autoDefine: true);
      for (var i = 0; i < 10; i++) {
        indoorBuilder.add(
          RecordMessage()
            ..timestamp = t0.millisecondsSinceEpoch + i * 2000
            ..enhancedSpeed = 3.0,
        );
      }
      final indoorNoDist = parser.parseFitBytes(
        indoorBuilder.build().toBytes(),
        hrZoneConfig: defaultHrConfig,
      );
      expect(indoorNoDist.isIndoor, isTrue);
      expect(indoorNoDist.distanceMeters, closeTo(54.0, 0.1));

      // Empty FIT (FileId only, no timestamps) throws FitParseException
      final emptyBuilder = FitFileBuilder(autoDefine: true)
        ..add(FileIdMessage()..type = FileType.activity);
      expect(
        () => parser.parseFitBytes(
          emptyBuilder.build().toBytes(),
          hrZoneConfig: defaultHrConfig,
        ),
        throwsA(isA<FitParseException>()),
      );
    });
  });
}
