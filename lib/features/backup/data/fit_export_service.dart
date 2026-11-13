import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../import/data/fit_archive_storage.dart';

typedef SaveFileBytesHandler = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  String? dialogTitle,
});

class FitExportPayload {
  const FitExportPayload({
    required this.bytes,
    required this.fileName,
    required this.isRegenerated,
  });

  final Uint8List bytes;
  final String fileName;
  final bool isRegenerated;
}

class _FitEncodeIsolateInput {
  const _FitEncodeIsolateInput({
    required this.title,
    required this.sportTypeCode,
    required this.startTimeMsUtc,
    required this.utcOffsetSeconds,
    required this.durationTotalSec,
    required this.durationMovingSec,
    required this.distanceMeters,
    required this.avgPaceSecPerKm,
    required this.avgHeartRate,
    required this.maxHeartRate,
    required this.avgCadence,
    required this.totalElevationGainM,
    required this.totalElevationLossM,
    required this.caloriesKcal,
    required this.isIndoor,
    required this.hasGpsTrack,
    required this.gpsQualityKey,
    required this.splitPacesSecPerKm,
    required this.zoneDurationsSec,
    required this.points,
    required this.splits,
  });

  final String title;
  final int sportTypeCode;
  final int startTimeMsUtc;
  final int utcOffsetSeconds;
  final int durationTotalSec;
  final int durationMovingSec;
  final double distanceMeters;
  final double avgPaceSecPerKm;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgCadence;
  final double totalElevationGainM;
  final double totalElevationLossM;
  final int caloriesKcal;
  final bool isIndoor;
  final bool hasGpsTrack;
  final String gpsQualityKey;
  final List<int> splitPacesSecPerKm;
  final List<int> zoneDurationsSec;
  final List<({int tsMs, double lat, double lng, double alt, double speed, int dist, int? hr, int? cad, int? zone})> points;
  final List<({int idx, double dist, int dur, double pace, double elev, double? hr, double? cad})> splits;
}

Uint8List _encodeFitInIsolate(_FitEncodeIsolateInput input) {
  final parsed = ParsedActivity(
    title: input.title,
    sportType: SportType.fromCode(input.sportTypeCode),
    startTimeUtc: DateTime.fromMillisecondsSinceEpoch(
      input.startTimeMsUtc,
      isUtc: true,
    ),
    utcOffsetSeconds: input.utcOffsetSeconds,
    durationTotalSec: input.durationTotalSec,
    durationMovingSec: input.durationMovingSec,
    distanceMeters: input.distanceMeters,
    avgPaceSecPerKm: input.avgPaceSecPerKm,
    avgHeartRate: input.avgHeartRate,
    maxHeartRate: input.maxHeartRate,
    avgCadence: input.avgCadence,
    totalElevationGainM: input.totalElevationGainM,
    totalElevationLossM: input.totalElevationLossM,
    caloriesKcal: input.caloriesKcal,
    isIndoor: input.isIndoor,
    hasGpsTrack: input.hasGpsTrack,
    gpsQuality: GpsQuality.fromStorageKey(input.gpsQualityKey),
    splitPacesSecPerKm: input.splitPacesSecPerKm,
    zoneDurationsSec: input.zoneDurationsSec,
    trackPoints: input.points
        .map(
          (pt) => ParsedTrackPoint(
            timestampUtc: DateTime.fromMillisecondsSinceEpoch(pt.tsMs, isUtc: true),
            latitudeDeg: pt.lat,
            longitudeDeg: pt.lng,
            altitudeM: pt.alt,
            speedMps: pt.speed,
            distanceMeters: pt.dist,
            heartRateBpm: pt.hr,
            cadenceRpm: pt.cad,
            hrZone: pt.zone,
          ),
        )
        .toList(growable: false),
    lapSplits: input.splits
        .map(
          (s) => ParsedLapSplit(
            splitIndex: s.idx,
            distanceMeters: s.dist,
            durationSec: s.dur,
            avgPaceSecPerKm: s.pace,
            elevationDeltaM: s.elev,
            avgHeartRate: s.hr,
            avgCadence: s.cad,
          ),
        )
        .toList(growable: false),
  );
  return const GarminFitEncoder().encodeActivity(parsed);
}

Future<Uint8List> _runEncodeFitIsolate(_FitEncodeIsolateInput input) {
  return Isolate.run(() => _encodeFitInIsolate(input));
}

/// Exports activities back to `.FIT` binary (`PRD M5-01`, `ADR-004`):
/// - Returns bit-identical archive when `.fit.gz` (< 30 days) exists on disk
/// - Regenerates valid `.FIT` binary in an Isolate from SQLite records otherwise
class FitExportService {
  FitExportService({
    required this.db,
    required this.archiveStorage,
    SaveFileBytesHandler? saveFileHandler,
  }) : _saveFileHandler = saveFileHandler ?? FilePicker.saveFile;

  final AppDatabase db;
  final FitArchiveStorage archiveStorage;
  final SaveFileBytesHandler _saveFileHandler;

  Future<FitExportPayload> buildFitBytes(int activityId) async {
    final activity = await db.getActivityById(activityId);
    if (activity == null) {
      throw StateError('Aktivitas #$activityId tidak ditemukan.');
    }

    final safeName = activity.title
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fileName = '${safeName.isEmpty ? 'fittrace' : safeName}_${activity.id}.fit';

    final archived = await archiveStorage.readArchive(activity.originalFitPath);
    if (archived != null && archived.isNotEmpty) {
      return FitExportPayload(
        bytes: archived,
        fileName: fileName,
        isRegenerated: false,
      );
    }

    final rawPoints = await db.getTrackPointsForActivity(activityId);
    final rawSplits = await db.getLapSplitsForActivity(activityId);

    final input = _FitEncodeIsolateInput(
      title: activity.title,
      sportTypeCode: activity.sportType,
      startTimeMsUtc: activity.startTimeUtc.toUtc().millisecondsSinceEpoch,
      utcOffsetSeconds: activity.utcOffsetSeconds,
      durationTotalSec: activity.durationTotalSec,
      durationMovingSec: activity.durationMovingSec,
      distanceMeters: activity.distanceMeters,
      avgPaceSecPerKm: activity.avgPaceSecPerKm,
      avgHeartRate: activity.avgHeartRate,
      maxHeartRate: activity.maxHeartRate,
      avgCadence: activity.avgCadence,
      totalElevationGainM: activity.totalElevationGainM,
      totalElevationLossM: activity.totalElevationLossM,
      caloriesKcal: activity.caloriesKcal,
      isIndoor: activity.isIndoor,
      hasGpsTrack: activity.hasGpsTrack,
      gpsQualityKey: activity.gpsQuality,
      splitPacesSecPerKm: activity.splitPacesSecPerKm,
      zoneDurationsSec: activity.zoneDurationsSec,
      points: rawPoints
          .map(
            (pt) => (
              tsMs: pt.timestampUtc.toUtc().millisecondsSinceEpoch,
              lat: pt.latitudeDeg,
              lng: pt.longitudeDeg,
              alt: pt.altitudeM,
              speed: pt.speedMps,
              dist: pt.distanceMeters,
              hr: pt.heartRateBpm,
              cad: pt.cadenceRpm,
              zone: pt.hrZone,
            ),
          )
          .toList(growable: false),
      splits: rawSplits
          .map(
            (s) => (
              idx: s.splitIndex,
              dist: s.distanceMeters,
              dur: s.durationSec,
              pace: s.avgPaceSecPerKm,
              elev: s.elevationDeltaM,
              hr: s.avgHeartRate,
              cad: s.avgCadence,
            ),
          )
          .toList(growable: false),
    );

    final regenerated = await _runEncodeFitIsolate(input);
    return FitExportPayload(
      bytes: regenerated,
      fileName: fileName,
      isRegenerated: true,
    );
  }

  Future<({Uri? savedUri, FitExportPayload payload})> exportAndSaveFit(
    int activityId,
  ) async {
    final payload = await buildFitBytes(activityId);
    final savedUri = await _saveFileHandler(
      fileName: payload.fileName,
      bytes: payload.bytes,
      mimeType: 'application/octet-stream',
      dialogTitle: 'Simpan File .FIT',
    );
    return (savedUri: savedUri, payload: payload);
  }
}

