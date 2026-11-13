import 'dart:io';

import 'package:drift/native.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/activity_detail/application/activity_detail_providers.dart';
import 'package:fit_trace/features/activity_detail/presentation/activity_detail_screen.dart';
import 'package:fit_trace/features/activity_detail/presentation/widgets/cached_osm_tile_provider.dart';
import 'package:fit_trace/features/feed/data/thumbnail_cache_service.dart';
import 'package:fit_trace/features/import/application/import_providers.dart';
import 'package:fit_trace/features/import/data/fit_archive_storage.dart';
import 'package:fit_trace/features/shell/presentation/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;

ParsedActivity _sampleOutdoorRun({
  required int index,
  SportType sportType = SportType.run,
  bool includeGps = true,
  bool includeHr = true,
}) {
  final start = DateTime.utc(2026, 11, 12, 0, 0).subtract(
    Duration(hours: index * 6),
  );
  final points = List<ParsedTrackPoint>.generate(25, (i) {
    return ParsedTrackPoint(
      timestampUtc: start.add(Duration(seconds: i * 30)),
      latitudeDeg: includeGps ? -6.2000 + i * 0.0005 : 0.0,
      longitudeDeg: includeGps ? 106.8000 + i * 0.0002 : 0.0,
      altitudeM: 12.0 + i * 0.8,
      speedMps: 3.2 + (i % 5) * 0.15,
      distanceMeters: i * 100,
      heartRateBpm: includeHr ? 145 + (i % 20) : null,
      cadenceRpm: 88,
      hrZone: includeHr ? 3 : null,
    );
  });

  return ParsedActivity(
    title: 'Run #$index',
    sportType: sportType,
    startTimeUtc: start,
    utcOffsetSeconds: 7 * 3600,
    durationTotalSec: 720,
    durationMovingSec: 720,
    distanceMeters: 2400,
    avgPaceSecPerKm: 300,
    avgHeartRate: includeHr ? 154 : null,
    maxHeartRate: includeHr ? 168 : null,
    avgCadence: 88,
    totalElevationGainM: 18,
    totalElevationLossM: 0,
    caloriesKcal: 180,
    isIndoor: !includeGps,
    hasGpsTrack: includeGps,
    gpsQuality: includeGps ? GpsQuality.good : GpsQuality.none,
    splitPacesSecPerKm: const <int>[305, 295, 300],
    zoneDurationsSec: includeHr
        ? const <int>[60, 120, 360, 150, 30]
        : const <int>[0, 0, 0, 0, 0],
    trackPoints: points,
    lapSplits: const <ParsedLapSplit>[
      ParsedLapSplit(
        splitIndex: 0,
        distanceMeters: 1000,
        durationSec: 305,
        avgPaceSecPerKm: 305,
        avgHeartRate: 149,
        avgCadence: 87,
        elevationDeltaM: 6,
      ),
      ParsedLapSplit(
        splitIndex: 1,
        distanceMeters: 1000,
        durationSec: 295,
        avgPaceSecPerKm: 295,
        avgHeartRate: 158,
        avgCadence: 89,
        elevationDeltaM: 8,
      ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('fittrace_ui_test_');

    // Seed 33 activities (32 outdoor + 1 treadmill) outside FakeAsync.
    for (var i = 0; i < 32; i++) {
      await db.insertParsedActivity(
        parsed: _sampleOutdoorRun(index: i),
        source: ActivitySource.manualImport,
        syncStatus: SyncStatus.localOnly,
        fitFileHash: 'hash_out_$i',
      );
    }
    await db.insertParsedActivity(
      parsed: _sampleOutdoorRun(
        index: 99,
        sportType: SportType.treadmill,
        includeGps: false,
        includeHr: false,
      ),
      source: ActivitySource.manualImport,
      syncStatus: SyncStatus.localOnly,
      fitFileHash: 'hash_indoor_99',
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets(
    'paginates feed 30/page, filters activities, and renders interactive detail analytics',
    (tester) async {
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              fitArchiveStorageProvider.overrideWithValue(
                FitArchiveStorage(
                  rootDirectoryResolver: () async =>
                      Directory(p.join(tempDir.path, 'archives')),
                ),
              ),
              thumbnailCacheServiceProvider.overrideWithValue(
                ThumbnailCacheService(
                  cacheDirectoryResolver: () async => tempDir,
                ),
              ),
              mapTileProviderFactoryProvider.overrideWithValue(
                () => CachedOsmTileProvider(
                  offlineOnly: true,
                  cacheDirectoryResolver: () async => tempDir,
                ),
              ),
            ],
            child: const FitTraceApp(home: MainShellScreen()),
          ),
        );

        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // First page shows newest item Run #0, while Run #31 is on page 2.
        expect(find.text('Run #0'), findsOneWidget);
        expect(find.text('Run #31'), findsNothing);

        // Scroll down past 30 items to trigger paging loadMore -> Run #31 appears.
        await tester.scrollUntilVisible(
          find.text('Run #31'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Run #31'), findsOneWidget);

        // Scroll back to top and open detail screen for Run #0.
        await tester.scrollUntilVisible(
          find.text('Run #0'),
          -500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.tap(find.text('Run #0'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();

        expect(find.text('2.40'), findsOneWidget);

        // Scroll inside detail ListView to inspect chart, splits table, and HR zones.
        final detailScrollable = find
            .descendant(
              of: find.byType(ActivityDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('GRAFIK ANALISIS'),
          300,
          scrollable: detailScrollable,
        );
        await tester.pump();
        expect(find.text('GRAFIK ANALISIS'), findsOneWidget);

        // Tap inside the synchronized chart canvas -> shows live readout pill.
        final chartPainterFinder = find.byKey(
          const ValueKey<String>('metrics_chart_canvas'),
        );
        await tester.ensureVisible(chartPainterFinder);
        await tester.pump();
        await tester.tap(chartPainterFinder);
        await tester.pump();
        expect(find.textContaining('km  •'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('SPLITS PER KILOMETER'),
          300,
          scrollable: detailScrollable,
        );
        await tester.pump();
        expect(find.text('SPLITS PER KILOMETER'), findsOneWidget);
        expect(find.text('BEST'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('DISTRIBUSI HR ZONE 1–5'),
          300,
          scrollable: detailScrollable,
        );
        await tester.pump();
        expect(find.text('DISTRIBUSI HR ZONE 1–5'), findsOneWidget);

        // Navigate back to Feed and verify Filter Sheet filters down to Treadmill.
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        await tester.tap(find.byTooltip('Filter Aktivitas'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.tap(find.text('Treadmill'));
        await tester.pump();
        await tester.tap(find.text('Terapkan Filter'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();

        expect(find.text('Run #99'), findsOneWidget);
        expect(find.text('Run #0'), findsNothing);

        // Open indoor activity detail without HR -> verifies indoor panel & empty HR state.
        await tester.tap(find.text('Run #99'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();

        expect(find.text('INDOOR — NO ROUTE'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Data detak jantung tidak tersedia pada aktivitas ini.'),
          300,
          scrollable: find
              .descendant(
                of: find.byType(ActivityDetailScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pump();
        expect(
          find.text('Data detak jantung tidak tersedia pada aktivitas ini.'),
          findsOneWidget,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(Duration.zero);
      }
    },
  );
}
