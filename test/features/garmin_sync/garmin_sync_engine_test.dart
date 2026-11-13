import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/error/app_failure.dart';
import 'package:fit_trace/core/logging/app_logger.dart';
import 'package:fit_trace/features/garmin_sync/application/garmin_sync_engine.dart';
import 'package:fit_trace/features/garmin_sync/data/garmin_dio_client.dart';
import 'package:fit_trace/features/garmin_sync/data/secure_cookie_store.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_connect_client.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session_refresher.dart';
import 'package:fit_trace/features/import/data/fit_archive_storage.dart';
import 'package:fit_trace/features/import/data/fit_import_pipeline.dart';
import 'package:fit_trace/features/import/domain/activity_import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';

Uint8List _encodeFitRun({
  required int seedOffsetMinutes,
  int points = 8,
  double speedMps = 3.2,
}) {
  final builder = FitFileBuilder(autoDefine: true);
  final t0 = DateTime.utc(2026, 10, 1, 0, 0).add(
    Duration(minutes: seedOffsetMinutes),
  );

  builder.add(
    FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.garmin.value
      ..timeCreated = t0.millisecondsSinceEpoch,
  );

  var dist = 0.0;
  var lat = -6.2000;
  const stepSec = 10;
  for (var i = 0; i < points; i++) {
    if (i > 0) {
      final seg = speedMps * stepSec;
      dist += seg;
      lat += seg / 111111.0;
    }
    builder.add(
      RecordMessage()
        ..timestamp = t0.millisecondsSinceEpoch + i * stepSec * 1000
        ..distance = dist
        ..enhancedSpeed = speedMps
        ..enhancedAltitude = 12.0 + i * 0.1
        ..cadence = 86
        ..heartRate = 152
        ..positionLat = lat
        ..positionLong = 106.8000,
    );
  }

  final totalSec = (points - 1) * stepSec;
  builder.add(
    SessionMessage()
      ..timestamp = t0.millisecondsSinceEpoch + totalSec * 1000
      ..startTime = t0.millisecondsSinceEpoch
      ..sport = Sport.running
      ..subSport = SubSport.street
      ..totalElapsedTime = totalSec.toDouble()
      ..totalTimerTime = totalSec.toDouble()
      ..totalDistance = dist
      ..totalCalories = 250,
  );
  return builder.build().toBytes();
}

Uint8List _wrapInZip(String filename, Uint8List fitBytes) {
  final archive = Archive()
    ..addFile(ArchiveFile.bytes(filename, fitBytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

class _FakeGarminClient implements GarminConnectClient {
  final List<SessionProbeResult> probeResponses = <SessionProbeResult>[];
  List<GarminActivitySummary> allActivities = <GarminActivitySummary>[];
  final Map<int, Uint8List> fitPayloads = <int, Uint8List>{};
  final Map<int, List<Object>> scriptedDownloadErrors = <int, List<Object>>{};
  final List<int> downloadedIds = <int>[];
  final List<int> pageStartsRequested = <int>[];
  int probeCalls = 0;

  @override
  Future<SessionProbeResult> probeSession() async {
    probeCalls++;
    if (probeResponses.isNotEmpty) {
      return probeResponses.removeAt(0);
    }
    return const SessionProbeResult(status: ProbeStatus.valid, statusCode: 200);
  }

  @override
  Future<List<GarminActivitySummary>> fetchActivitiesPage({
    required int start,
    int limit = 50,
  }) async {
    pageStartsRequested.add(start);
    if (start >= allActivities.length) {
      return const <GarminActivitySummary>[];
    }
    final end = (start + limit).clamp(0, allActivities.length);
    return allActivities.sublist(start, end);
  }

  @override
  Stream<List<int>> downloadFitStream(int garminActivityId) async* {
    downloadedIds.add(garminActivityId);
    final errors = scriptedDownloadErrors[garminActivityId];
    if (errors != null && errors.isNotEmpty) {
      final err = errors.removeAt(0);
      if (err is Exception || err is Error) {
        throw err;
      }
      throw ImportFailure(err.toString());
    }
    final bytes = fitPayloads[garminActivityId] ?? _encodeFitRun(seedOffsetMinutes: garminActivityId);
    final mid = bytes.length ~/ 2;
    yield bytes.sublist(0, mid);
    yield bytes.sublist(mid);
  }
}

class _FakeSessionRefresher implements GarminSessionRefresher {
  _FakeSessionRefresher(this.outcome);

  RefreshOutcome outcome;
  int calls = 0;

  @override
  Future<RefreshOutcome> attemptSilentRefresh() async {
    calls++;
    return outcome;
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late FitArchiveStorage archiveStorage;
  late FitImportPipeline importPipeline;
  late _FakeGarminClient client;
  late _FakeSessionRefresher refresher;
  late List<Duration> recordedDelays;
  late GarminSyncEngine engine;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fittrace_sync_test_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.getPreferences();
    archiveStorage = FitArchiveStorage(
      rootDirectoryResolver: () async => tempDir,
    );
    importPipeline = FitImportPipeline(
      db: db,
      archiveStorage: archiveStorage,
      tempDirectory: tempDir,
    );
    client = _FakeGarminClient();
    refresher = _FakeSessionRefresher(RefreshOutcome.expiredOrLoginRequired);
    recordedDelays = <Duration>[];
    engine = GarminSyncEngine(
      db: db,
      client: client,
      refresher: refresher,
      importPipeline: importPipeline,
      delayScheduler: (d) async => recordedDelays.add(d),
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('GarminSyncEngine', () {
    test('syncs 55 activities (30+) with 50/page pagination, ZIP unwrap, 10-burst pauses, and zero duplicates on re-sync', () async {
      final baseTime = DateTime.utc(2026, 11, 1, 6, 0);
      client.allActivities = List<GarminActivitySummary>.generate(55, (i) {
        final id = 50000 + i;
        final fit = _encodeFitRun(seedOffsetMinutes: i * 10);
        // Half raw .FIT, half Garmin .ZIP-wrapped .FIT.
        client.fitPayloads[id] = i.isEven ? _wrapInZip('${id}_ACTIVITY.fit', fit) : fit;
        return GarminActivitySummary(
          activityId: id,
          activityName: 'Morning Run #$i',
          startTimeUtc: baseTime.add(Duration(minutes: i * 10)),
          sportType: SportType.run,
          distanceMeters: 1000,
          durationTotalSec: 300,
        );
      });

      final firstResult = await engine.syncNow();
      expect(firstResult.importedCount, 55);
      expect(firstResult.updatedCount, 0);
      expect(firstResult.skippedCount, 0);
      expect(firstResult.failedCount, 0);
      expect(client.pageStartsRequested, <int>[0, 50]);

      // 55 downloads -> burst pauses at items 10, 20, 30, 40, 50 => 5 delays of 2s.
      expect(
        recordedDelays.where((d) => d == const Duration(seconds: 2)).length,
        5,
      );

      final feedRows = await db.fetchFeedActivities(limit: 100, offset: 0);
      expect(feedRows.length, 55);
      expect(feedRows.every((r) => r.syncStatus == SyncStatus.synced.storageKey), isTrue);

      // Second sync immediately skips already-synced activities without downloading.
      client.downloadedIds.clear();
      client.pageStartsRequested.clear();
      recordedDelays.clear();

      final secondResult = await engine.syncNow();
      expect(secondResult.importedCount, 0);
      expect(secondResult.skippedCount, 55);
      expect(client.downloadedIds, isEmpty);
      expect((await db.fetchFeedActivities(limit: 100, offset: 0)).length, 55);
    });

    test('deduplicates manual import matching Garmin SHA-256 without creating duplicate row', () async {
      final rawFit = _encodeFitRun(seedOffsetMinutes: 300);
      await importPipeline.importCandidates(<ImportCandidate>[
        ImportCandidate(
          source: ActivitySource.manualImport,
          bytes: rawFit,
          suggestedTitle: 'Manual Lari Pagi',
        ),
      ]);
      expect((await db.fetchFeedActivities()).length, 1);

      const garminId = 778899;
      client.fitPayloads[garminId] = rawFit;
      client.allActivities = <GarminActivitySummary>[
        GarminActivitySummary(
          activityId: garminId,
          activityName: 'Garmin Lari Pagi',
          startTimeUtc: DateTime.utc(2026, 11, 2, 6, 0),
          sportType: SportType.run,
        ),
      ];

      final res = await engine.syncNow();
      expect(res.importedCount, 0);
      expect(res.skippedCount, 1);

      final rows = await db.fetchFeedActivities();
      expect(rows.length, 1);
      expect(rows.single.garminActivityId, garminId);
    });

    test('retries HTTP 429 probe with exponential backoff up to 5x then throws RateLimitFailure', () async {
      client.probeResponses.addAll(const <SessionProbeResult>[
        SessionProbeResult(status: ProbeStatus.rateLimited, statusCode: 429),
        SessionProbeResult(status: ProbeStatus.rateLimited, statusCode: 429),
        SessionProbeResult(status: ProbeStatus.rateLimited, statusCode: 429),
        SessionProbeResult(status: ProbeStatus.rateLimited, statusCode: 429),
        SessionProbeResult(status: ProbeStatus.valid, statusCode: 200),
      ]);

      await engine.ensureValidSession();
      expect(
        recordedDelays,
        const <Duration>[
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
          Duration(seconds: 16),
        ],
      );

      recordedDelays.clear();
      client.probeResponses.addAll(List<SessionProbeResult>.filled(
        5,
        const SessionProbeResult(status: ProbeStatus.rateLimited, statusCode: 429),
      ));
      await expectLater(engine.ensureValidSession(), throwsA(isA<RateLimitFailure>()));
    });

    test('triggers silent refresh once on 401/403 and fails cleanly when expired or challenged', () async {
      // Case 1: silent refresh recovers session seamlessly.
      client.probeResponses.addAll(const <SessionProbeResult>[
        SessionProbeResult(status: ProbeStatus.expired, statusCode: 401),
        SessionProbeResult(status: ProbeStatus.valid, statusCode: 200),
      ]);
      refresher.outcome = RefreshOutcome.refreshed;

      await engine.ensureValidSession();
      expect(refresher.calls, 1);

      // Case 2: silent refresh fails -> SyncAuthFailure.
      client.probeResponses.add(
        const SessionProbeResult(status: ProbeStatus.expired, statusCode: 403),
      );
      refresher.outcome = RefreshOutcome.expiredOrLoginRequired;
      await expectLater(engine.ensureValidSession(), throwsA(isA<SyncAuthFailure>()));

      // Case 3: Cloudflare / CAPTCHA challenge -> GarminChallengeException without bypass.
      client.probeResponses.add(
        const SessionProbeResult(
          status: ProbeStatus.challengeRequired,
          statusCode: 403,
        ),
      );
      await expectLater(
        engine.ensureValidSession(),
        throwsA(isA<GarminChallengeException>()),
      );
    });

    test('retries download 3x (2s->4s->8s), marks syncFailed on exhaustion, and recovers on retry', () async {
      const garminId = 91919;
      client.allActivities = <GarminActivitySummary>[
        GarminActivitySummary(
          activityId: garminId,
          activityName: 'Trail Recovery',
          startTimeUtc: DateTime.utc(2026, 11, 5, 7, 0),
          sportType: SportType.trailRun,
        ),
      ];
      client.scriptedDownloadErrors[garminId] = <Object>[
        const SocketException('Temporary drop 1'),
        const SocketException('Temporary drop 2'),
        const SocketException('Temporary drop 3'),
        const SocketException('Temporary drop 4'),
      ];

      final res = await engine.syncNow();
      expect(res.failedCount, 1);
      expect(res.importedCount, 0);
      expect(
        recordedDelays,
        const <Duration>[
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
        ],
      );

      final stored = await db.findByGarminActivityId(garminId);
      expect(stored, isNotNull);
      expect(stored!.syncStatus, SyncStatus.failed.storageKey);

      // Stats exclude failed download placeholders.
      final stats = await db.getAggregateStats();
      expect(stats.activityCount, 0);

      // Recovery on next retry.
      client.fitPayloads[garminId] = _encodeFitRun(seedOffsetMinutes: 120);
      final retryOutcome = await engine.retryFailedActivity(stored.id);
      expect(retryOutcome.type, ImportOutcomeType.reparsed);

      final recovered = await db.findByGarminActivityId(garminId);
      expect(recovered!.syncStatus, SyncStatus.synced.storageKey);
    });

    test('aborts batch immediately with StorageFullFailure on ENOSPC without retry loop', () async {
      const garminId = 88881;
      client.allActivities = <GarminActivitySummary>[
        GarminActivitySummary(
          activityId: garminId,
          activityName: 'Full Disk Run',
          startTimeUtc: DateTime.utc(2026, 11, 6, 7, 0),
          sportType: SportType.run,
        ),
      ];
      client.scriptedDownloadErrors[garminId] = <Object>[
        const FileSystemException(
          'Write failed',
          '/tmp/fit.tmp',
          OSError('No space left on device', 28),
        ),
      ];

      await expectLater(engine.syncNow(), throwsA(isA<StorageFullFailure>()));
      expect(recordedDelays, isEmpty);
    });
  });

  group('SecureCookieStore & DioGarminConnectClient', () {
    test('stores cookies encrypted via SecureKeyValueStore, redacts toString, and rejects HTTP', () async {
      final kvStore = InMemorySecureKeyValueStore();
      final cookieStore = SecureCookieStore(kvStore);

      await cookieStore.mergeSetCookieHeaders(
        requestUri: Uri.parse('https://connect.garmin.com/modern'),
        setCookieHeaders: const <String>[
          'SESSIONID=superSecretCookie999; Path=/; HttpOnly; Secure',
          'GARMIN-SSO-GUID=guidSecret888; Domain=.garmin.com; Path=/; Secure',
        ],
      );

      final loaded = await cookieStore.loadSession();
      expect(loaded, isNotNull);
      expect(loaded!.cookies.keys, containsAll(<String>['SESSIONID', 'GARMIN-SSO-GUID']));
      // Security: toString() & logger scrub must never expose cookie values.
      expect(loaded.toString(), isNot(contains('superSecretCookie999')));
      expect(loaded.toString(), isNot(contains('guidSecret888')));
      expect(
        AppLogger.scrub('Set-Cookie: SESSIONID=superSecretCookie999; Secure'),
        isNot(contains('superSecretCookie999')),
      );

      // Strict HTTPS rejection on client construction.
      expect(
        () => DioGarminConnectClient(
          cookieStore: cookieStore,
          baseUrl: 'http://connect.garmin.com',
        ),
        throwsA(isA<SyncAuthFailure>()),
      );

      await cookieStore.clearSession();
      expect(await cookieStore.loadSession(), isNull);
    });
  });
}
