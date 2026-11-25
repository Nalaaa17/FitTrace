import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/logging/app_logger.dart';
import '../../import/data/fit_archive_storage.dart';
import '../../import/data/fit_import_pipeline.dart';
import '../application/garmin_sync_engine.dart';
import '../application/garmin_sync_providers.dart';
import 'garmin_dio_client.dart';
import 'network_policy_checker.dart';
import 'secure_cookie_store.dart';
import 'webview_cookie_extractor.dart';
import 'webview_silent_session_refresher.dart';

/// Platform-agnostic periodic background sync configuration (`M1-10`, `ADR-003`).
class BackgroundSyncScheduleConfig {
  const BackgroundSyncScheduleConfig({
    required this.enabled,
    required this.intervalMinutes,
    required this.wifiOnly,
    required this.requireCharging,
  });

  /// Builds native WorkManager / BGTaskScheduler constraint config directly
  /// from [UserPreference] while enforcing Android's 15-minute minimum floor.
  factory BackgroundSyncScheduleConfig.fromPreferences(UserPreference prefs) {
    final effectiveEnabled =
        prefs.garminLoggedIn && prefs.backgroundSyncEnabled;
    final clampedMinutes =
        prefs.backgroundSyncIntervalMinutes < minAndroidIntervalMinutes
            ? minAndroidIntervalMinutes
            : prefs.backgroundSyncIntervalMinutes;
    return BackgroundSyncScheduleConfig(
      enabled: effectiveEnabled,
      intervalMinutes: clampedMinutes,
      wifiOnly: prefs.backgroundSyncWifiOnly,
      requireCharging: prefs.backgroundSyncRequireCharging,
    );
  }

  static const int minAndroidIntervalMinutes = 15;

  final bool enabled;
  final int intervalMinutes;
  final bool wifiOnly;
  final bool requireCharging;

  /// Android WorkManager constraint string (`CONNECTED` allows cellular + Wi-Fi).
  String get androidNetworkType => wifiOnly ? 'UNMETERED' : 'CONNECTED';

  Map<String, dynamic> toMethodArguments() => <String, dynamic>{
        'enabled': enabled,
        'intervalMinutes': intervalMinutes,
        'wifiOnly': wifiOnly,
        'requireCharging': requireCharging,
        'networkType': androidNetworkType,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundSyncScheduleConfig &&
          other.enabled == enabled &&
          other.intervalMinutes == intervalMinutes &&
          other.wifiOnly == wifiOnly &&
          other.requireCharging == requireCharging;

  @override
  int get hashCode => Object.hash(
        enabled,
        intervalMinutes,
        wifiOnly,
        requireCharging,
      );
}

abstract interface class BackgroundSyncScheduler {
  Future<void> applySchedule(BackgroundSyncScheduleConfig config);
}

class MethodChannelBackgroundSyncScheduler implements BackgroundSyncScheduler {
  const MethodChannelBackgroundSyncScheduler([
    this._channel = const MethodChannel('com.fittrace.app/background_sync'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> applySchedule(BackgroundSyncScheduleConfig config) async {
    try {
      await _channel.invokeMethod<bool>(
        'schedulePeriodicSync',
        config.toMethodArguments(),
      );
      AppLogger.info(
        'BackgroundSync',
        config.enabled
            ? 'Scheduled periodic sync (${config.intervalMinutes}m, '
                'network=${config.androidNetworkType}, charging=${config.requireCharging})'
            : 'Cancelled periodic background sync',
      );
    } on MissingPluginException {
      // Tests / desktop platforms without native scheduler plugin.
    } on PlatformException catch (error) {
      AppLogger.warn('BackgroundSync', 'Failed applying background sync schedule', error);
    }
  }
}

/// Runs headless Garmin incremental sync inside WorkManager / BGTaskScheduler.
Future<bool> executeHeadlessBackgroundSync({
  AppDatabase? database,
  SecureKeyValueStore? secureStore,
  NetworkPolicyChecker? policyChecker,
}) async {
  // In production WorkManager/BGTask invocations, boot a full Riverpod
  // ProviderContainer so background sync shares the DI graph and triggers
  // post-persist hooks (such as route thumbnail generation).
  if (database == null && secureStore == null && policyChecker == null) {
    final container = ProviderContainer();
    try {
      final db = container.read(appDatabaseProvider);
      final prefs = await db.getPreferences();
      if (!prefs.garminLoggedIn || !prefs.backgroundSyncEnabled) {
        return true;
      }

      final policy = await container
          .read(networkPolicyCheckerProvider)
          .evaluateForAutoSync(prefs);
      if (!policy.allowed) {
        AppLogger.info(
          'BackgroundSyncWorker',
          'Skipped background run: ${policy.skipReason}',
        );
        return true;
      }

      final result = await container.read(garminSyncEngineProvider).syncNow();
      AppLogger.info(
        'BackgroundSyncWorker',
        'Headless sync complete: ${result.summaryBannerText}',
      );
      return true;
    } on Object catch (error, stack) {
      AppLogger.error('BackgroundSyncWorker', 'Headless sync failed', error, stack);
      return false;
    } finally {
      container.dispose();
    }
  }

  final db = database ?? AppDatabase();
  final ownsDb = database == null;
  try {
    final prefs = await db.getPreferences();
    if (!prefs.garminLoggedIn || !prefs.backgroundSyncEnabled) {
      return true;
    }

    final checker = policyChecker ??
        NetworkPolicyChecker(
          connectivityReader: PluginConnectivityReader(),
          batteryReader: const MethodChannelBatteryChargingReader(),
        );
    final policy = await checker.evaluateForAutoSync(prefs);
    if (!policy.allowed) {
      AppLogger.info(
        'BackgroundSyncWorker',
        'Skipped background run: ${policy.skipReason}',
      );
      return true;
    }

    final cookieStore = SecureCookieStore(
      secureStore ?? FlutterSecureKeyValueStore(),
    );
    final client = DioGarminConnectClient(cookieStore: cookieStore);
    final refresher = WebViewSilentSessionRefresher(
      cookieStore: cookieStore,
      cookieExtractor: MethodChannelWebViewCookieExtractor(),
    );
    final importPipeline = FitImportPipeline(
      db: db,
      archiveStorage: FitArchiveStorage(),
    );
    final engine = GarminSyncEngine(
      db: db,
      client: client,
      refresher: refresher,
      importPipeline: importPipeline,
    );

    final result = await engine.syncNow();
    AppLogger.info(
      'BackgroundSyncWorker',
      'Headless sync complete: ${result.summaryBannerText}',
    );
    return result.failedCount == 0;
  } on Object catch (error) {
    AppLogger.warn('BackgroundSyncWorker', 'Headless background sync failed', error);
    return false;
  } finally {
    if (ownsDb) {
      await db.close();
    }
  }
}

