import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/feed/data/thumbnail_cache_service.dart';
import 'package:fit_trace/features/garmin_sync/application/garmin_sync_providers.dart';
import 'package:fit_trace/features/garmin_sync/data/network_policy_checker.dart';
import 'package:fit_trace/features/garmin_sync/data/runtime_permission_service.dart';
import 'package:fit_trace/features/garmin_sync/data/secure_cookie_store.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_connect_client.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session.dart';
import 'package:fit_trace/features/garmin_sync/domain/garmin_session_refresher.dart';
import 'package:fit_trace/features/import/application/import_providers.dart';
import 'package:fit_trace/features/import/data/fit_archive_storage.dart';
import 'package:fit_trace/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fit_trace/features/shell/presentation/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';

Uint8List _sampleValidFitBytes() {
  final builder = FitFileBuilder(autoDefine: true);
  final t0 = DateTime.utc(2026, 11, 10, 6, 0);
  builder.add(
    FileIdMessage()
      ..type = FileType.activity
      ..manufacturer = Manufacturer.garmin.value
      ..timeCreated = t0.millisecondsSinceEpoch,
  );
  for (var i = 0; i < 6; i++) {
    builder.add(
      RecordMessage()
        ..timestamp = t0.millisecondsSinceEpoch + i * 10000
        ..distance = i * 30.0
        ..enhancedSpeed = 3.0
        ..enhancedAltitude = 10.0
        ..heartRate = 150
        ..positionLat = -6.2 + (i * 0.0003)
        ..positionLong = 106.8,
    );
  }
  builder.add(
    SessionMessage()
      ..timestamp = t0.millisecondsSinceEpoch + 50000
      ..startTime = t0.millisecondsSinceEpoch
      ..sport = Sport.running
      ..subSport = SubSport.street
      ..totalElapsedTime = 50
      ..totalTimerTime = 50
      ..totalDistance = 150,
  );
  return builder.build().toBytes();
}

class _StubConnectivityReader implements ConnectivityReader {
  List<ConnectivityResult> results = const <ConnectivityResult>[
    ConnectivityResult.mobile,
  ];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;
}

class _StubBatteryReader implements BatteryChargingReader {
  bool charging = false;

  @override
  Future<bool> isCharging() async => charging;
}

class _StubPermissionService implements RuntimePermissionService {
  @override
  Future<RuntimePermissionsSnapshot> checkAll() async =>
      const RuntimePermissionsSnapshot(
        locationGranted: false,
        notificationGranted: false,
        storageGranted: false,
      );

  @override
  Future<RuntimePermissionsSnapshot> requestOptionalPermissions() async =>
      const RuntimePermissionsSnapshot(
        locationGranted: true,
        notificationGranted: true,
        storageGranted: true,
      );
}

class _StubGarminClient implements GarminConnectClient {
  ProbeStatus probeStatus = ProbeStatus.valid;
  List<GarminActivitySummary> activities = const <GarminActivitySummary>[];
  int probeCalls = 0;
  int pageCalls = 0;

  @override
  Future<SessionProbeResult> probeSession() async {
    probeCalls++;
    return SessionProbeResult(
      status: probeStatus,
      statusCode: probeStatus == ProbeStatus.valid ? 200 : 401,
      message: probeStatus == ProbeStatus.valid ? null : 'Token expired test',
    );
  }

  @override
  Future<List<GarminActivitySummary>> fetchActivitiesPage({
    required int start,
    int limit = 50,
  }) async {
    pageCalls++;
    if (start > 0) return const <GarminActivitySummary>[];
    return activities;
  }

  @override
  Stream<List<int>> downloadFitStream(int garminActivityId) async* {
    yield _sampleValidFitBytes();
  }
}

class _StubRefresher implements GarminSessionRefresher {
  @override
  Future<RefreshOutcome> attemptSilentRefresh() async =>
      RefreshOutcome.expiredOrLoginRequired;
}

void main() {
  testWidgets(
    'complete onboarding carousel -> permissions -> manual only hides Garmin sync from Feed',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              runtimePermissionServiceProvider.overrideWithValue(
                _StubPermissionService(),
              ),
            ],
            child: const FitTraceApp(home: OnboardingScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Privasi Lokal Penuh'), findsOneWidget);
        await tester.tap(find.text('Lanjut'));
        await tester.pumpAndSettle();

        expect(find.text('Analisis Lari Garmin'), findsOneWidget);
        await tester.tap(find.text('Lanjut'));
        await tester.pumpAndSettle();

        expect(find.text('Bagikan ke Story'), findsOneWidget);
        await tester.tap(find.text('Mulai Pengaturan'));
        await tester.pumpAndSettle();

        expect(find.text('IZIN RUNTIME (OPSIONAL)'), findsOneWidget);
        await tester.tap(find.text('Berikan Izin Opsional'));
        await tester.pumpAndSettle();
        expect(find.text('AKTIF'), findsNWidgets(3));

        await tester.tap(find.text('Lewati — Mode Import Manual Only'));
        await tester.pumpAndSettle();

        expect(find.text('BELUM ADA AKTIVITAS LARI'), findsOneWidget);
        // PRD §2.2: Garmin sync UI hidden until user logs in.
        expect(find.byTooltip('Sinkronkan Garmin'), findsNothing);
        expect(find.text('Sinkronkan Garmin'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(Duration.zero);
        await tester.runAsync(db.close);
      }
    },
  );

  testWidgets(
    'Feed displays re-login banner when session expires and recovers failed Garmin download on retry',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final client = _StubGarminClient()..probeStatus = ProbeStatus.expired;
      final kvStore = InMemorySecureKeyValueStore();
      late Directory tempDir;

      try {
        await tester.runAsync(() async {
          tempDir = await Directory.systemTemp.createTemp('fittrace_ui_sync_');
          await db.getPreferences();
          await db.updatePreferences(
            UserPreferencesTableCompanion(
              onboardingCompleted: const Value(true),
              garminLoggedIn: const Value(true),
              lastSyncAt: Value(
                DateTime.now().toUtc().subtract(const Duration(minutes: 25)),
              ),
            ),
          );
          await db.upsertSyncFailedActivity(
            garminActivityId: 424242,
            title: 'Tempo Failure Run',
            sportType: SportType.run,
          );
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              fitArchiveStorageProvider.overrideWithValue(
                FitArchiveStorage(rootDirectoryResolver: () async => tempDir),
              ),
              thumbnailCacheServiceProvider.overrideWithValue(
                ThumbnailCacheService(cacheDirectoryResolver: () async => tempDir),
              ),
              secureKeyValueStoreProvider.overrideWithValue(kvStore),
              garminConnectClientProvider.overrideWithValue(client),
              garminSessionRefresherProvider.overrideWithValue(_StubRefresher()),
              connectivityReaderProvider.overrideWithValue(
                _StubConnectivityReader(),
              ),
              batteryChargingReaderProvider.overrideWithValue(
                _StubBatteryReader(),
              ),
            ],
            child: const FitTraceApp(home: MainShellScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();

        // Auto-sync triggered because >10 min threshold over cellular + battery,
        // failed probe with expired session -> shows persistent re-login banner.
        expect(client.probeCalls, 1);
        expect(find.text('Login Ulang'), findsOneWidget);
        expect(find.text('FAILED'), findsOneWidget);

        // Once session recovers, tapping Coba lagi re-downloads and marks SYNCED.
        client.probeStatus = ProbeStatus.valid;
        await tester.tap(find.text('Coba lagi'));
        await tester.pump();
        for (var i = 0; i < 40; i++) {
          if (find.text('SYNCED').evaluate().isNotEmpty &&
              find.text('Login Ulang').evaluate().isEmpty) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }

        expect(find.text('SYNCED'), findsOneWidget);
        expect(find.text('Login Ulang'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(Duration.zero);
        await tester.runAsync(() async {
          await db.close();
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
      }
    },
  );

  test('verifyAndSaveLoginSession never persists invalid cookies, and auto-sync enforces ADR-003 & 60s debounce', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final kvStore = InMemorySecureKeyValueStore();
    final client = _StubGarminClient()
      ..probeStatus = ProbeStatus.expired
      ..activities = <GarminActivitySummary>[];
    final connectivity = _StubConnectivityReader();
    final battery = _StubBatteryReader();

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secureKeyValueStoreProvider.overrideWithValue(kvStore),
        garminConnectClientProvider.overrideWithValue(client),
        garminSessionRefresherProvider.overrideWithValue(_StubRefresher()),
        connectivityReaderProvider.overrideWithValue(connectivity),
        batteryChargingReaderProvider.overrideWithValue(battery),
      ],
    );

    try {
      final controller = container.read(garminSyncControllerProvider.notifier);
      final candidate = GarminSessionBundle(
        cookies: <String, GarminCookieEntry>{
          'SESSIONID': const GarminCookieEntry(name: 'SESSIONID', value: 'bad'),
        },
        capturedAtUtc: DateTime.now().toUtc(),
      );

      // Failed probe rejects & never stores cookies or marks logged in.
      final failedLogin = await controller.verifyAndSaveLoginSession(candidate);
      expect(failedLogin.success, isFalse);
      expect(await container.read(secureCookieStoreProvider).loadSession(), isNull);
      expect((await db.getPreferences()).garminLoggedIn, isFalse);

      // Valid probe saves session & sets garminLoggedIn = true.
      client.probeStatus = ProbeStatus.valid;
      final okLogin = await controller.verifyAndSaveLoginSession(candidate);
      expect(okLogin.success, isTrue);
      expect(await container.read(secureCookieStoreProvider).loadSession(), isNotNull);

      await db.updatePreferences(
        UserPreferencesTableCompanion(
          onboardingCompleted: const Value(true),
          lastSyncAt: Value(
            DateTime.utc(2026, 11, 10, 10, 0),
          ),
        ),
      );

      // Cellular + non-charging allowed by ADR-003 defaults when > 10 min threshold.
      final t1 = DateTime.utc(2026, 11, 10, 10, 12);
      await controller.maybeAutoSyncOnResume(nowUtc: t1);
      expect(client.pageCalls, 1);

      // Call again within 60s -> blocked by debounce.
      await db.updatePreferences(
        UserPreferencesTableCompanion(
          lastSyncAt: Value(DateTime.utc(2026, 11, 10, 9, 0)),
        ),
      );
      await controller.maybeAutoSyncOnResume(
        nowUtc: t1.add(const Duration(seconds: 30)),
      );
      expect(client.pageCalls, 1);

      // User restricts to Wi-Fi only -> mobile data skips auto-sync after debounce.
      await db.updatePreferences(
        const UserPreferencesTableCompanion(backgroundSyncWifiOnly: Value(true)),
      );
      await controller.maybeAutoSyncOnResume(
        nowUtc: t1.add(const Duration(seconds: 90)),
      );
      expect(client.pageCalls, 1);

      // Switch to Wi-Fi -> auto-sync runs cleanly.
      connectivity.results = const <ConnectivityResult>[ConnectivityResult.wifi];
      await controller.maybeAutoSyncOnResume(
        nowUtc: t1.add(const Duration(seconds: 180)),
      );
      expect(client.pageCalls, 2);
    } finally {
      container.dispose();
      await db.close();
    }
  });
}
