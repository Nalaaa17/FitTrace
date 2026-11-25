import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';

class NetworkPolicyDecision {
  const NetworkPolicyDecision({
    required this.allowed,
    this.skipReason,
  });

  final bool allowed;
  final String? skipReason;
}

abstract interface class ConnectivityReader {
  Future<List<ConnectivityResult>> checkConnectivity();
}

class PluginConnectivityReader implements ConnectivityReader {
  PluginConnectivityReader([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();
}

abstract interface class BatteryChargingReader {
  Future<bool> isCharging();
}

class MethodChannelBatteryChargingReader implements BatteryChargingReader {
  const MethodChannelBatteryChargingReader([
    this._channel = const MethodChannel('com.fittrace.app/device_state'),
  ]);

  final MethodChannel _channel;

  @override
  Future<bool> isCharging() async {
    try {
      final value = await _channel.invokeMethod<bool>('isCharging');
      return value ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      AppLogger.warn('DeviceState', 'Battery charging query failed', error);
      return false;
    }
  }
}

/// Evaluates ADR-003 network & power constraints before auto-sync runs:
/// - Allows both Wi-Fi and cellular data unless `backgroundSyncWifiOnly` is true
/// - Allows non-charging state unless `backgroundSyncRequireCharging` is true
class NetworkPolicyChecker {
  const NetworkPolicyChecker({
    required this.connectivityReader,
    required this.batteryReader,
  });

  final ConnectivityReader connectivityReader;
  final BatteryChargingReader batteryReader;

  Future<NetworkPolicyDecision> evaluateForAutoSync(UserPreference prefs) async {
    if (!prefs.backgroundSyncEnabled) {
      return const NetworkPolicyDecision(
        allowed: false,
        skipReason: 'Sinkronisasi otomatis dinonaktifkan di Pengaturan.',
      );
    }

    List<ConnectivityResult> results;
    try {
      results = await connectivityReader.checkConnectivity();
    } on MissingPluginException {
      results = const <ConnectivityResult>[ConnectivityResult.none];
    } on Object catch (error) {
      AppLogger.warn('NetworkPolicy', 'Connectivity check failed', error);
      results = const <ConnectivityResult>[ConnectivityResult.none];
    }

    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) {
      return const NetworkPolicyDecision(
        allowed: false,
        skipReason: 'Tidak ada koneksi internet.',
      );
    }

    if (prefs.backgroundSyncWifiOnly) {
      final hasWifi = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
      if (!hasWifi) {
        return const NetworkPolicyDecision(
          allowed: false,
          skipReason: 'Menunggu jaringan Wi-Fi (sesuai pengaturan).',
        );
      }
    }

    if (prefs.backgroundSyncRequireCharging) {
      final charging = await batteryReader.isCharging();
      if (!charging) {
        return const NetworkPolicyDecision(
          allowed: false,
          skipReason: 'Menunggu perangkat diisi daya (sesuai pengaturan).',
        );
      }
    }

    return const NetworkPolicyDecision(allowed: true);
  }
}

