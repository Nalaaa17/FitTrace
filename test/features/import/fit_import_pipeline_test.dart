import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/features/feed/data/thumbnail_cache_service.dart';
import 'package:fit_trace/features/import/data/fit_archive_storage.dart';
import 'package:fit_trace/features/import/data/fit_import_pipeline.dart';
import 'package:fit_trace/features/import/domain/activity_import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;

Uint8List _buildFitBytes({
  required int points,
  required int stepSeconds,
  required double speedMps,
  bool includeGps = true,
  bool includeHr = true,
  SubSport subSport = SubSport.street,
  int startHourUtc = 0,
}) {
  final builder = FitFileBuilder(autoDefine: true);
  final t0 = DateTime.utc(2026, 11, 12, startHourUtc, 0, 0);

  builder.add(
    FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.garmin.value
      ..timeCreated = t0.millisecondsSinceEpoch,
  );

  var dist = 0.0;
  var lat = -6.2000;
  for (var i = 0; i < points; i++) {
    if (i > 0) {
      final seg = speedMps * stepSeconds;
      dist += seg;
      if (includeGps) lat += seg / 111111.0;
    }
    final rec = RecordMessage()
      ..timestamp = t0.millisecondsSinceEpoch + i * stepSeconds * 1000
      ..distance = dist
      ..enhancedSpeed = speedMps
      ..enhancedAltitude = 15.0 + i * 0.02
      ..cadence = 88;
    if (includeHr) rec.heartRate = 148 + (i % 20);
    if (includeGps) {
      rec
        ..positionLat = lat
        ..positionLong = 106.8000;
    }
    builder.add(rec);
  }

  final totalSec = (points - 1) * stepSeconds;
  builder.add(
    SessionMessage()
      ..timestamp = t0.millisecondsSinceEpoch + totalSec * 1000
      ..startTime = t0.millisecondsSinceEpoch
      ..sport = Sport.running
      ..subSport = subSport
      ..totalElapsedTime = totalSec.toDouble()
      ..totalTimerTime = totalSec.toDouble()
      ..totalDistance = dist
      ..totalCalories = 400,
  );

  return builder.build().toBytes();
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late FitArchiveStorage archiveStorage;
  late ThumbnailCacheService thumbnailService;
  late FitImportPipeline pipeline;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('fittrace_import_test_');
    archiveStorage = FitArchiveStorage(
      rootDirectoryResolver: () async =>
          Directory(p.join(tempRoot.path, 'archives')),
    );
    thumbnailService = ThumbnailCacheService(
      cacheDirectoryResolver: () async =>
          Directory(p.join(tempRoot.path, 'cache')),
    );
    pipeline = FitImportPipeline(
      db: db,
      archiveStorage: archiveStorage,
      tempDirectory: Directory(p.join(tempRoot.path, 'tmp')),
      onActivityPersisted: (id, parsed) async {
        if (parsed.hasGpsTrack) {
          await thumbnailService.renderAndCache(id, parsed.trackPoints);
        }
      },
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('imports batch with >30k marathon, indoor, and corrupt FIT without blocking, and detects duplicates', () async {
    final marathonBytes = _buildFitBytes(
      points: 31000,
      stepSeconds: 1,
      speedMps: 1.36,
      startHourUtc: 1,
    );
    final indoorBytes = _buildFitBytes(
      points: 120,
      stepSeconds: 3,
      speedMps: 2.8,
      includeGps: false,
      subSport: SubSport.treadmill,
      startHourUtc: 4,
    );
    final corruptBytes = Uint8List.fromList(<int>[0x0E, 0x10, 0xFF, 0x00, 0x01]);

    // Write 5K FIT to disk to verify File-based streaming SHA-256 import too.
    final outdoorFile = File(p.join(tempRoot.path, 'five_k.fit'));
    await outdoorFile.writeAsBytes(
      _buildFitBytes(points: 200, stepSeconds: 3, speedMps: 3.3, startHourUtc: 6),
    );

    final candidates = <ImportCandidate>[
      ImportCandidate(
        source: ActivitySource.manualImport,
        bytes: marathonBytes,
        suggestedTitle: 'Jakarta Marathon',
      ),
      ImportCandidate(
        source: ActivitySource.manualImport,
        bytes: indoorBytes,
      ),
      ImportCandidate(
        source: ActivitySource.manualImport,
        bytes: corruptBytes,
        suggestedTitle: 'Corrupt Run',
      ),
      ImportCandidate(
        source: ActivitySource.manualImport,
        file: outdoorFile,
      ),
    ];

    final progressEvents = <int>[];
    final summary = await pipeline.importCandidates(
      candidates,
      onProgress: (done, total) => progressEvents.add(done),
    );

    expect(summary.importedCount, 3);
    expect(summary.failedCount, 1);
    expect(summary.skippedCount, 0);
    expect(progressEvents, const <int>[1, 2, 3, 4]);

    final feed = await db.fetchFeedActivities(limit: 30);
    expect(feed, hasLength(4));

    final marathon = feed.firstWhere((a) => a.title == 'Jakarta Marathon');
    final marathonPoints = await db.getTrackPointsForActivity(marathon.id);
    expect(marathonPoints, hasLength(31000));
    expect(await thumbnailService.getExistingThumbnail(marathon.id), isNotNull);
    expect(marathon.originalFitPath, isNotNull);
    expect(await archiveStorage.readArchive(marathon.originalFitPath), marathonBytes);

    // Re-importing the exact same valid candidates skips all 3 duplicates via SHA-256.
    final dupSummary = await pipeline.importCandidates(<ImportCandidate>[
      ImportCandidate(source: ActivitySource.manualImport, bytes: marathonBytes),
      ImportCandidate(source: ActivitySource.manualImport, bytes: indoorBytes),
      ImportCandidate(source: ActivitySource.manualImport, file: outdoorFile),
    ]);
    expect(dupSummary.skippedCount, 3);
    expect(dupSummary.importedCount, 0);
  });

  test('streams candidate bytes, hashes while streaming, and cleans temp file', () async {
    final bytes = _buildFitBytes(points: 60, stepSeconds: 3, speedMps: 3.0);
    final streamSummary = await pipeline.importCandidates(<ImportCandidate>[
      ImportCandidate(
        source: ActivitySource.garminSync,
        garminActivityId: 777001,
        streamFactory: () => Stream<List<int>>.fromIterable(<List<int>>[
          bytes.sublist(0, bytes.length ~/ 2),
          bytes.sublist(bytes.length ~/ 2),
        ]),
      ),
    ]);

    expect(streamSummary.importedCount, 1);
    final tmpDir = Directory(p.join(tempRoot.path, 'tmp'));
    final leftover = await tmpDir.exists() ? await tmpDir.list().toList() : [];
    expect(leftover, isEmpty);

    // Verify 30-day archive pruning removes files older than 30 days.
    final act = await db.findByGarminActivityId(777001);
    expect(act, isNotNull);
    final archiveFile = File(act!.originalFitPath!);
    await archiveFile.setLastModified(
      DateTime.now().toUtc().subtract(const Duration(days: 35)),
    );

    final pruned = await archiveStorage.pruneExpiredArchives(db: db);
    expect(pruned, 1);
    final refreshed = await db.getActivityById(act.id);
    expect(refreshed!.originalFitPath, isNull);
  });
}

