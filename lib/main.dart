import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/garmin_sync/data/background_sync_scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FitTraceApp()));
}

/// Native WorkManager / BGTaskScheduler headless entrypoint (`M1-10`, `ADR-003`).
@pragma('vm:entry-point')
Future<void> backgroundSyncMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ok = await executeHeadlessBackgroundSync();
  const workerChannel = MethodChannel('com.fittrace.app/background_sync_worker');
  try {
    await workerChannel.invokeMethod<void>('complete', <String, dynamic>{
      'success': ok,
    });
  } on MissingPluginException {
    // Expected if invoked outside native worker wrapper.
  }
}
