import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'features/garmin_sync/data/background_sync_scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global Flutter framework error hook (Widget build/layout crashes)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FlutterFrameworkError',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
  };

  // 2. Global platform/isolate async error hook
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error('PlatformAsyncError', error.toString(), error, stack);
    return true; // Marked as handled so process doesn't terminate silently
  };

  // 3. User-friendly fallback widget when a widget tree throws during rendering
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF121212),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 44,
              ),
              const SizedBox(height: 14),
              const Text(
                'Terjadi Kendala Tampilan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode
                    ? details.exceptionAsString()
                    : 'Aplikasi mengalami kendala sementara. Silakan segarkan atau buka kembali halaman.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

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
