package com.fittrace.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.CookieManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.fittrace.app/share_intent"
        private const val EVENT_CHANNEL = "com.fittrace.app/share_intent_events"
        private const val COOKIE_CHANNEL = "com.fittrace.app/webview_cookies"
        private const val DEVICE_STATE_CHANNEL = "com.fittrace.app/device_state"
        private const val STORY_SHARE_CHANNEL = "com.fittrace.app/story_share"
        private const val BACKGROUND_SYNC_CHANNEL = "com.fittrace.app/background_sync"
        private const val NOTIFICATIONS_CHANNEL = "com.fittrace.app/notifications"
        private const val BACKGROUND_SYNC_WORK_NAME = "fittrace_garmin_periodic_sync"
        private const val BACKUP_REMINDER_CHANNEL_ID = "fittrace_backup_reminders"
        private const val BACKUP_REMINDER_NOTIFICATION_ID = 4102
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var initialSharedPaths: List<String> = emptyList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialSharedPaths = extractSharedFiles(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val paths = extractSharedFiles(intent)
        if (paths.isNotEmpty()) {
            eventSink?.success(paths)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedFiles" -> {
                        result.success(initialSharedPaths)
                        initialSharedPaths = emptyList()
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COOKIE_CHANNEL)
            .setMethodCallHandler { call, result ->
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
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_STATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isCharging" -> result.success(isDeviceCharging())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORY_SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isInstagramInstalled" -> result.success(isInstagramInstalled())
                    "shareToInstagramStory" -> {
                        val backgroundPath = call.argument<String>("backgroundPath")
                        val stickerPath = call.argument<String>("stickerPath")
                        val topColorHex = call.argument<String>("topColorHex") ?: "#0A0A0A"
                        val bottomColorHex = call.argument<String>("bottomColorHex") ?: "#0A0A0A"
                        val appId = call.argument<String>("appId") ?: packageName
                        result.success(
                            shareToInstagramStory(
                                backgroundPath = backgroundPath,
                                stickerPath = stickerPath,
                                topColorHex = topColorHex,
                                bottomColorHex = bottomColorHex,
                                appId = appId,
                            )
                        )
                    }
                    "saveToGallery" -> {
                        val filePath = call.argument<String>("filePath")
                        val displayName = call.argument<String>("displayName")
                            ?: "fittrace_story_${System.currentTimeMillis()}.png"
                        if (filePath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "Path PNG tidak ditemukan.", null)
                        } else {
                            try {
                                val savedUri = savePngToGallery(filePath, displayName)
                                result.success(savedUri)
                            } catch (e: Exception) {
                                result.error("SAVE_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_SYNC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedulePeriodicSync" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val intervalMinutes = (call.argument<Int>("intervalMinutes") ?: 15).coerceAtLeast(15)
                        val wifiOnly = call.argument<Boolean>("wifiOnly") ?: false
                        val requireCharging = call.argument<Boolean>("requireCharging") ?: false
                        configureBackgroundSync(
                            enabled = enabled,
                            intervalMinutes = intervalMinutes.toLong(),
                            wifiOnly = wifiOnly,
                            requireCharging = requireCharging,
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showBackupReminder" -> {
                        val title = call.argument<String>("title") ?: "Backup FitTrace"
                        val body = call.argument<String>("body") ?: "Sudah > 30 hari sejak backup lokal terakhir."
                        result.success(showLocalBackupReminder(title, body))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun configureBackgroundSync(
        enabled: Boolean,
        intervalMinutes: Long,
        wifiOnly: Boolean,
        requireCharging: Boolean,
    ) {
        val workManager = WorkManager.getInstance(applicationContext)
        if (!enabled) {
            workManager.cancelUniqueWork(BACKGROUND_SYNC_WORK_NAME)
            return
        }

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(
                if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED,
            )
            .setRequiresCharging(requireCharging)
            .build()

        val request = PeriodicWorkRequestBuilder<GarminSyncWorker>(
            intervalMinutes,
            TimeUnit.MINUTES,
        )
            .setConstraints(constraints)
            .build()

        workManager.enqueueUniquePeriodicWork(
            BACKGROUND_SYNC_WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    private fun showLocalBackupReminder(title: String, body: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                BACKUP_REMINDER_CHANNEL_ID,
                "Pengingat Backup Lokal",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Mengingatkan pengguna secara lokal jika backup ZIP melebihi 30 hari."
            }
            manager?.createNotificationChannel(channel)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }

        val notification = NotificationCompat.Builder(this, BACKUP_REMINDER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(this).notify(BACKUP_REMINDER_NOTIFICATION_ID, notification)
        return true
    }

    private fun isInstagramInstalled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    INSTAGRAM_PACKAGE,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(INSTAGRAM_PACKAGE, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun shareToInstagramStory(
        backgroundPath: String?,
        stickerPath: String?,
        topColorHex: String,
        bottomColorHex: String,
        appId: String,
    ): String {
        if (!isInstagramInstalled()) {
            return "not_installed"
        }

        val authority = "$packageName.fileprovider"
        val bgUri = backgroundPath?.let { path ->
            val file = File(path)
            if (file.exists()) FileProvider.getUriForFile(this, authority, file) else null
        }
        val stickerUri = stickerPath?.let { path ->
            val file = File(path)
            if (file.exists()) FileProvider.getUriForFile(this, authority, file) else null
        }

        if (bgUri == null && stickerUri == null) {
            return "failed"
        }

        val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
            `package` = INSTAGRAM_PACKAGE
            putExtra("source_application", appId)
            putExtra("com.instagram.platform.extra.APPLICATION_ID", appId)
            putExtra("top_background_color", topColorHex)
            putExtra("bottom_background_color", bottomColorHex)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        if (bgUri != null) {
            intent.setDataAndType(bgUri, "image/png")
            grantUriPermission(
                INSTAGRAM_PACKAGE,
                bgUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            intent.clipData = ClipData.newRawUri("", bgUri)
        } else {
            intent.type = "image/png"
        }

        if (stickerUri != null) {
            intent.putExtra("interactive_asset_uri", stickerUri)
            grantUriPermission(
                INSTAGRAM_PACKAGE,
                stickerUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            if (bgUri == null) {
                intent.clipData = ClipData.newRawUri("", stickerUri)
            }
        }

        if (intent.resolveActivity(packageManager) == null) {
            return "not_installed"
        }

        return try {
            startActivity(intent)
            "launched"
        } catch (_: Exception) {
            "failed"
        }
    }

    private fun savePngToGallery(filePath: String, displayName: String): String {
        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            throw IllegalStateException("File sumber tidak ditemukan: $filePath")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/FitTrace",
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                values,
            ) ?: throw IllegalStateException("Gagal membuat entri MediaStore.")

            contentResolver.openOutputStream(uri)?.use { outStream ->
                FileInputStream(sourceFile).use { inStream ->
                    inStream.copyTo(outStream)
                }
            } ?: throw IllegalStateException("Gagal membuka stream keluaran galeri.")

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return uri.toString()
        }

        @Suppress("DEPRECATION")
        val picturesDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_PICTURES,
        )
        val fitTraceDir = File(picturesDir, "FitTrace").apply { mkdirs() }
        val destFile = File(fitTraceDir, displayName)
        FileInputStream(sourceFile).use { inStream ->
            FileOutputStream(destFile).use { outStream ->
                inStream.copyTo(outStream)
            }
        }
        MediaScannerConnection.scanFile(
            this,
            arrayOf(destFile.absolutePath),
            arrayOf("image/png"),
            null,
        )
        return destFile.absolutePath
    }

    private fun isDeviceCharging(): Boolean {
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
    }

    private fun extractSharedFiles(intent: Intent?): List<String> {
        if (intent == null) return emptyList()
        val uris = mutableListOf<Uri>()

        when (intent.action) {
            Intent.ACTION_SEND -> {
                getParcelableUri(intent, Intent.EXTRA_STREAM)?.let { uris.add(it) }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                getParcelableUriList(intent, Intent.EXTRA_STREAM)?.let { uris.addAll(it) }
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { uris.add(it) }
            }
            else -> return emptyList()
        }

        if (uris.isEmpty()) return emptyList()

        val cacheFolder = File(cacheDir, "shared_imports").apply { mkdirs() }
        val copiedPaths = mutableListOf<String>()
        for (uri in uris) {
            copyUriToCache(uri, cacheFolder)?.let { copiedPaths.add(it) }
        }
        return copiedPaths
    }

    @Suppress("DEPRECATION")
    private fun getParcelableUri(intent: Intent, key: String): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(key, Uri::class.java)
        } else {
            intent.getParcelableExtra(key)
        }
    }

    @Suppress("DEPRECATION")
    private fun getParcelableUriList(intent: Intent, key: String): ArrayList<Uri>? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(key, Uri::class.java)
        } else {
            intent.getParcelableArrayListExtra(key)
        }
    }

    private fun copyUriToCache(uri: Uri, targetDir: File): String? {
        return try {
            val rawName = resolveDisplayName(uri) ?: "shared_${System.currentTimeMillis()}.fit"
            val safeName = rawName.replace(Regex("[^A-Za-z0-9._-]"), "_")
            val destFile = File(targetDir, "${System.currentTimeMillis()}_$safeName")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            destFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveDisplayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) return cursor.getString(idx)
                }
            }
        return uri.lastPathSegment
    }
}
