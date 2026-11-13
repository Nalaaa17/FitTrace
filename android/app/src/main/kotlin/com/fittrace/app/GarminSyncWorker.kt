package com.fittrace.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Android WorkManager worker for ADR-003 periodic Garmin incremental sync.
 * Launches the headless Dart entrypoint `backgroundSyncMain` with default
 * CONNECTED network + non-charging constraints (configurable in Settings).
 */
class GarminSyncWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val latch = CountDownLatch(1)
        val succeeded = AtomicBoolean(true)
        val mainHandler = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null

        mainHandler.post {
            try {
                val loader = FlutterLoader()
                if (!loader.initialized()) {
                    loader.startInitialization(applicationContext)
                    loader.ensureInitializationComplete(applicationContext, null)
                }

                val createdEngine = FlutterEngine(applicationContext)
                engine = createdEngine
                MethodChannel(
                    createdEngine.dartExecutor.binaryMessenger,
                    "com.fittrace.app/background_sync_worker",
                ).setMethodCallHandler { call, result ->
                    if (call.method == "complete") {
                        succeeded.set(call.argument<Boolean>("success") ?: true)
                        result.success(true)
                        latch.countDown()
                    } else {
                        result.notImplemented()
                    }
                }

                val entrypoint = DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    "backgroundSyncMain",
                )
                createdEngine.dartExecutor.executeDartEntrypoint(entrypoint)
            } catch (_: Exception) {
                succeeded.set(false)
                latch.countDown()
            }
        }

        val completedInTime = try {
            latch.await(90, TimeUnit.SECONDS)
        } catch (_: InterruptedException) {
            false
        }

        mainHandler.post {
            engine?.destroy()
        }

        return if (completedInTime && succeeded.get()) Result.success() else Result.retry()
    }
}

