package com.fittrace.app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.WebStorage
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
                registerHeadlessChannels(createdEngine)
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

    private fun registerHeadlessChannels(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.fittrace.app/webview_cookies",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCookies" -> {
                    val urls = call.argument<List<String>>("urls").orEmpty()
                    val cookieManager = CookieManager.getInstance()
                    cookieManager.flush()
                    val map = mutableMapOf<String, String>()
                    for (url in urls) {
                        val raw = cookieManager.getCookie(url)
                        if (!raw.isNullOrBlank()) {
                            map[url] = raw
                        }
                    }
                    result.success(map)
                }
                "flushCookies" -> {
                    CookieManager.getInstance().flush()
                    result.success(true)
                }
                "clearDomStorage" -> {
                    WebStorage.getInstance().deleteAllData()
                    val cookieManager = CookieManager.getInstance()
                    cookieManager.removeAllCookies(null)
                    cookieManager.flush()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.fittrace.app/device_state",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isCharging" -> result.success(isDeviceCharging())
                else -> result.notImplemented()
            }
        }
    }

    private fun isDeviceCharging(): Boolean {
        val statusIntent = applicationContext.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        ) ?: return false
        val status = statusIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
    }
}

