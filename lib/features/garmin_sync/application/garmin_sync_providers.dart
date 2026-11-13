import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../import/application/import_providers.dart';
import '../../import/domain/activity_import_source.dart';
import '../data/background_sync_scheduler.dart';
import '../data/garmin_dio_client.dart';
import '../data/network_policy_checker.dart';
import '../data/runtime_permission_service.dart';
import '../data/secure_cookie_store.dart';
import '../data/webview_cookie_extractor.dart';
import '../data/webview_silent_session_refresher.dart';
import '../domain/garmin_connect_client.dart';
import '../domain/garmin_session.dart';
import '../domain/garmin_session_refresher.dart';
import 'garmin_sync_engine.dart';

final secureKeyValueStoreProvider = Provider<SecureKeyValueStore>((ref) {
  return FlutterSecureKeyValueStore();
});

final secureCookieStoreProvider = Provider<SecureCookieStore>((ref) {
  return SecureCookieStore(ref.watch(secureKeyValueStoreProvider));
});

final webViewCookieExtractorProvider = Provider<WebViewCookieExtractor>((ref) {
  return MethodChannelWebViewCookieExtractor();
});

final garminConnectClientProvider = Provider<GarminConnectClient>((ref) {
  return DioGarminConnectClient(
    cookieStore: ref.watch(secureCookieStoreProvider),
  );
});

final garminSessionRefresherProvider = Provider<GarminSessionRefresher>((ref) {
  return WebViewSilentSessionRefresher(
    cookieStore: ref.watch(secureCookieStoreProvider),
    cookieExtractor: ref.watch(webViewCookieExtractorProvider),
  );
});

final runtimePermissionServiceProvider = Provider<RuntimePermissionService>((ref) {
  return const DeviceRuntimePermissionService();
});

final connectivityReaderProvider = Provider<ConnectivityReader>((ref) {
  return PluginConnectivityReader();
});

final batteryChargingReaderProvider = Provider<BatteryChargingReader>((ref) {
  return const MethodChannelBatteryChargingReader();
});

final backgroundSyncSchedulerProvider = Provider<BackgroundSyncScheduler>((ref) {
  return const MethodChannelBackgroundSyncScheduler();
});

final networkPolicyCheckerProvider = Provider<NetworkPolicyChecker>((ref) {
  return NetworkPolicyChecker(
    connectivityReader: ref.watch(connectivityReaderProvider),
    batteryReader: ref.watch(batteryChargingReaderProvider),
  );
});

/// ADR-003: responsive app-open/resume auto-sync threshold between 5–15 minutes.
final autoSyncThresholdProvider = Provider<Duration>((ref) {
  return const Duration(minutes: 10);
});

/// ADR-003: minimum interval between auto-sync triggers on app open/resume.
final autoSyncDebounceProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 60);
});

/// Injectable UTC clock for deterministic tests and sync timestamps.
final clockNowProvider = Provider<ClockNow>((ref) {
  return () => DateTime.now().toUtc();
});

final garminSyncEngineProvider = Provider<GarminSyncEngine>((ref) {
  return GarminSyncEngine(
    db: ref.watch(appDatabaseProvider),
    client: ref.watch(garminConnectClientProvider),
    refresher: ref.watch(garminSessionRefresherProvider),
    importPipeline: ref.watch(fitImportPipelineProvider),
    nowUtc: ref.watch(clockNowProvider),
  );
});

class GarminSyncState {
  const GarminSyncState({
    this.authStatus = GarminAuthStatus.disconnected,
    this.isSyncing = false,
    this.statusMessage,
    this.completed = 0,
    this.total = 0,
    this.lastResult,
    this.errorMessage,
  });

  final GarminAuthStatus authStatus;
  final bool isSyncing;
  final String? statusMessage;
  final int completed;
  final int total;
  final SyncResult? lastResult;
  final String? errorMessage;

  bool get needsUserAttention =>
      authStatus == GarminAuthStatus.reloginRequired ||
      authStatus == GarminAuthStatus.challengeRequired;

  GarminSyncState copyWith({
    GarminAuthStatus? authStatus,
    bool? isSyncing,
    String? Function()? statusMessage,
    int? completed,
    int? total,
    SyncResult? Function()? lastResult,
    String? Function()? errorMessage,
  }) {
    return GarminSyncState(
      authStatus: authStatus ?? this.authStatus,
      isSyncing: isSyncing ?? this.isSyncing,
      statusMessage:
          statusMessage != null ? statusMessage() : this.statusMessage,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class GarminSyncController extends Notifier<GarminSyncState> {
  DateTime? _lastAutoAttemptAtUtc;
  BackgroundSyncScheduleConfig? _lastAppliedSchedule;

  @override
  GarminSyncState build() {
    final initialPrefs = ref.read(userPreferencesProvider).value;
    final initialLoggedIn = initialPrefs?.garminLoggedIn ?? false;
    if (initialPrefs != null) {
      _reconcileBackgroundSchedule(initialPrefs);
    }

    ref.listen<AsyncValue<UserPreference>>(userPreferencesProvider, (prev, next) {
      final prefs = next.value;
      if (prefs == null) return;
      _reconcileBackgroundSchedule(prefs);

      final nextLoggedIn = prefs.garminLoggedIn;
      final target = nextLoggedIn
          ? (state.needsUserAttention
              ? state.authStatus
              : GarminAuthStatus.connected)
          : GarminAuthStatus.disconnected;
      if (state.authStatus != target) {
        state = state.copyWith(authStatus: target);
      }
    });

    return GarminSyncState(
      authStatus: initialLoggedIn
          ? GarminAuthStatus.connected
          : GarminAuthStatus.disconnected,
    );
  }

  void _reconcileBackgroundSchedule(UserPreference prefs) {
    final config = BackgroundSyncScheduleConfig.fromPreferences(prefs);
    if (_lastAppliedSchedule == config) return;
    _lastAppliedSchedule = config;
    Future<void>.microtask(
      () => ref.read(backgroundSyncSchedulerProvider).applySchedule(config),
    );
  }

  /// Probes candidate cookies captured from WebView BEFORE persisting (`PRD §2.2`).
  ///
  /// Returns `(ok, message)` so the login screen displays actionable feedback
  /// when probe fails without writing invalid cookies to storage.
  Future<({bool success, String? errorMessage})> verifyAndSaveLoginSession(
    GarminSessionBundle candidateBundle,
  ) async {
    final cookieStore = ref.read(secureCookieStoreProvider);
    final client = ref.read(garminConnectClientProvider);
    final db = ref.read(appDatabaseProvider);

    final previousSession = await cookieStore.loadSession();
    try {
      await cookieStore.saveSession(candidateBundle);
      final probe = await client.probeSession();
      if (probe.status != ProbeStatus.valid) {
        if (previousSession != null) {
          await cookieStore.saveSession(previousSession);
        } else {
          await cookieStore.clearSession();
        }
        return (
          success: false,
          errorMessage: probe.message ??
              'Validasi sesi Garmin gagal (HTTP ${probe.statusCode ?? '-'}).',
        );
      }

      await db.updatePreferences(
        const UserPreferencesTableCompanion(garminLoggedIn: Value(true)),
      );
      state = state.copyWith(
        authStatus: GarminAuthStatus.connected,
        errorMessage: () => null,
      );
      return const (success: true, errorMessage: null);
    } on Object catch (error) {
      if (previousSession != null) {
        await cookieStore.saveSession(previousSession);
      } else {
        await cookieStore.clearSession();
      }
      return (
        success: false,
        errorMessage: 'Gagal memvalidasi akun Garmin: $error',
      );
    }
  }

  /// Runs manual or automatic synchronization against Garmin Connect.
  Future<SyncResult?> syncNow({bool isAutoSync = false}) async {
    if (state.isSyncing) return null;

    final db = ref.read(appDatabaseProvider);
    final prefs = await db.getPreferences();
    if (!prefs.garminLoggedIn) {
      return null;
    }

    if (isAutoSync) {
      final policy =
          await ref.read(networkPolicyCheckerProvider).evaluateForAutoSync(prefs);
      if (!policy.allowed) {
        AppLogger.info(
          'GarminSyncController',
          'Auto-sync skipped: ${policy.skipReason}',
        );
        return null;
      }
    }

    state = state.copyWith(
      isSyncing: true,
      statusMessage: () => 'Memulai sinkronisasi Garmin...',
      completed: 0,
      total: 0,
      errorMessage: () => null,
    );

    try {
      final engine = ref.read(garminSyncEngineProvider);
      final result = await engine.syncNow(
        onProgress: (status, completed, total) {
          state = state.copyWith(
            statusMessage: () => status,
            completed: completed,
            total: total,
          );
        },
      );
      if (!isAutoSync) {
        _lastAutoAttemptAtUtc = ref.read(clockNowProvider)();
      }
      state = state.copyWith(
        authStatus: GarminAuthStatus.connected,
        isSyncing: false,
        statusMessage: () => null,
        lastResult: () => result,
        errorMessage: () => null,
      );
      return result;
    } on GarminChallengeException catch (error) {
      state = state.copyWith(
        authStatus: GarminAuthStatus.challengeRequired,
        isSyncing: false,
        statusMessage: () => null,
        errorMessage: () => error.message,
      );
      return null;
    } on SyncAuthFailure catch (error) {
      state = state.copyWith(
        authStatus: GarminAuthStatus.reloginRequired,
        isSyncing: false,
        statusMessage: () => null,
        errorMessage: () => error.message,
      );
      return null;
    } on StorageFullFailure catch (error) {
      state = state.copyWith(
        isSyncing: false,
        statusMessage: () => null,
        errorMessage: () => error.message,
      );
      return null;
    } on Object catch (error) {
      AppLogger.warn('GarminSyncController', 'Garmin sync error', error);
      state = state.copyWith(
        isSyncing: false,
        statusMessage: () => null,
        errorMessage: () => error.toString(),
      );
      return null;
    }
  }

  /// ADR-003 app-open / lifecycle resume trigger (`> 10 min` threshold, `60s` debounce).
  Future<SyncResult?> maybeAutoSyncOnResume({DateTime? nowUtc}) async {
    if (state.isSyncing) return null;

    final now = (nowUtc ?? ref.read(clockNowProvider)()).toUtc();
    final debounce = ref.read(autoSyncDebounceProvider);
    if (_lastAutoAttemptAtUtc != null &&
        now.difference(_lastAutoAttemptAtUtc!) < debounce) {
      return null;
    }

    final prefs = await ref.read(appDatabaseProvider).getPreferences();
    if (!prefs.onboardingCompleted ||
        !prefs.garminLoggedIn ||
        !prefs.backgroundSyncEnabled) {
      return null;
    }

    final threshold = ref.read(autoSyncThresholdProvider);
    final lastSync = prefs.lastSyncAt?.toUtc();
    final staleEnough =
        lastSync == null || now.difference(lastSync) > threshold;
    if (!staleEnough) {
      return null;
    }

    _lastAutoAttemptAtUtc = now;
    return syncNow(isAutoSync: true);
  }

  Future<ImportOutcome> retryFailedActivity(int activityId) async {
    try {
      final engine = ref.read(garminSyncEngineProvider);
      final outcome = await engine.retryFailedActivity(activityId);
      state = state.copyWith(
        authStatus: GarminAuthStatus.connected,
        errorMessage: () =>
            outcome.type == ImportOutcomeType.failed ? outcome.errorMessage : null,
      );
      return outcome;
    } on GarminChallengeException catch (error) {
      state = state.copyWith(
        authStatus: GarminAuthStatus.challengeRequired,
        errorMessage: () => error.message,
      );
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: 'Verifikasi Diperlukan',
        activityId: activityId,
        errorMessage: error.message,
      );
    } on SyncAuthFailure catch (error) {
      state = state.copyWith(
        authStatus: GarminAuthStatus.reloginRequired,
        errorMessage: () => error.message,
      );
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: 'Sesi Kedaluwarsa',
        activityId: activityId,
        errorMessage: error.message,
      );
    } on StorageFullFailure catch (error) {
      state = state.copyWith(errorMessage: () => error.message);
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: 'Penyimpanan Penuh',
        activityId: activityId,
        errorMessage: error.message,
      );
    }
  }

  Future<void> disconnectGarmin() async {
    await ref.read(secureCookieStoreProvider).clearSession();
    await ref.read(webViewCookieExtractorProvider).clearAllWebViewCookies();
    await ref.read(appDatabaseProvider).updatePreferences(
      const UserPreferencesTableCompanion(garminLoggedIn: Value(false)),
    );
    _lastAutoAttemptAtUtc = null;
    state = const GarminSyncState(authStatus: GarminAuthStatus.disconnected);
  }
}

final garminSyncControllerProvider =
    NotifierProvider<GarminSyncController, GarminSyncState>(
  GarminSyncController.new,
);

