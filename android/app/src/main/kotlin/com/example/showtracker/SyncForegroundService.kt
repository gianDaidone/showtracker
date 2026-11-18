package com.example.showtracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/** Un solo engine/container Dart: nessun isolate o database secondario. */
object SyncRuntime {
    const val ENGINE = "showtracker_main"
    const val CHANNEL = "sync_progress"
    // Gli ID TMDB sono positivi. Non collide con le notifiche episodio.
    const val NOTIFICATION = -17841
    var running = false
    var channel: MethodChannel? = null
    private var pendingStart: ((Boolean) -> Unit)? = null

    fun started(available: Boolean) {
        val callback = pendingStart
        pendingStart = null
        callback?.invoke(available)
    }

    private fun notificationsAllowed(app: Context): Boolean {
        val manager = app.getSystemService(NotificationManager::class.java)
        val channelAllowed = Build.VERSION.SDK_INT < 26 ||
            manager.getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
        return NotificationManagerCompat.from(app).areNotificationsEnabled() && channelAllowed
    }

    fun install(engine: FlutterEngine, context: Context) {
        FlutterEngineCache.getInstance().put(ENGINE, engine)
        val app = context.applicationContext
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "showtracker/sync").also { bridge ->
            bridge.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        createChannel(app)
                        pendingStart = { available ->
                            result.success(mapOf("available" to available,
                                "notifications" to notificationsAllowed(app)))
                        }
                        try {
                            val intent = Intent(app, SyncForegroundService::class.java)
                            if (Build.VERSION.SDK_INT >= 26) app.startForegroundService(intent)
                            else app.startService(intent)
                        } catch (_: RuntimeException) { started(false) }
                    }
                    "update" -> {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        if (running) {
                            // startService aggiorna solo un servizio già foreground.
                            val intent = Intent(app, SyncForegroundService::class.java)
                                .putExtra("title", args["title"] as? String)
                                .putExtra("body", args["body"] as? String)
                                .putExtra("total", (args["total"] as? Number)?.toInt() ?: -1)
                                .putExtra("processed", (args["processed"] as? Number)?.toInt() ?: 0)
                                .putExtra("finished", args["finished"] == true)
                            try { app.startService(intent) } catch (_: RuntimeException) {
                                if (args["finished"] == true) publish(app, args)
                            }
                        } else publish(app, args)
                        result.success(null)
                    }
                    "settings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= 26) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, app.packageName)
                        } else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${app.packageName}"))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        try { app.startActivity(intent); result.success(null) }
                        catch (_: RuntimeException) { result.success(null) }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, "Sincronizzazione", NotificationManager.IMPORTANCE_LOW)
            )
        }
    }
    fun publish(app: Context, args: Map<*, *>) {
        createChannel(app)
        val notification = notification(app, args["title"] as? String ?: "Sincronizzazione",
            args["body"] as? String ?: "", (args["total"] as? Number)?.toInt() ?: -1,
            (args["processed"] as? Number)?.toInt() ?: 0, args["finished"] == true)
        try { app.getSystemService(NotificationManager::class.java).notify(NOTIFICATION, notification) }
        catch (_: SecurityException) { }
    }

    fun notification(context: Context, title: String, body: String, total: Int, processed: Int, finished: Boolean): Notification {
        val open = PendingIntent.getActivity(context, 17841,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra("show_sync", true),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(context, SyncRuntime.CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title).setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open).setOnlyAlertOnce(true)
            .setOngoing(!finished).setAutoCancel(finished)
            .setProgress(if (total < 0) 0 else total, processed, total < 0 && !finished)
            .build()
    }


}

class SyncForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    private val watchdog = Handler(Looper.getMainLooper())
    private val deadline = Runnable { stopForTimeout() }

    override fun onCreate() {
        super.onCreate()
        SyncRuntime.createChannel(this)
    }

    private fun promote(): Boolean {
        return try {
            val notification = SyncRuntime.notification(this, "Sincronizzazione in corso", "Preparazione del trasferimento…", -1, 0, false)
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(SyncRuntime.NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            } else startForeground(SyncRuntime.NOTIFICATION, notification)
            SyncRuntime.running = true
            watchdog.postDelayed(deadline, 10 * 60 * 1000L)
            wakeLock = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ShowTracker:sync")
                .apply { setReferenceCounted(false); acquire(10 * 60 * 1000L) }
            true
        } catch (_: RuntimeException) {
            SyncRuntime.running = false
            releaseResources()
            stopSelf()
            false
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.hasExtra("title") != true) {
            val available = SyncRuntime.running || promote()
            SyncRuntime.started(available)
            if (!available) return START_NOT_STICKY
        }
        if (!SyncRuntime.running) return START_NOT_STICKY
        if (intent?.hasExtra("title") == true) {
            val finished = intent.getBooleanExtra("finished", false)
            val notification = SyncRuntime.notification(this,
                intent.getStringExtra("title") ?: "Sincronizzazione in corso",
                intent.getStringExtra("body") ?: "",
                intent.getIntExtra("total", -1), intent.getIntExtra("processed", 0), finished
            )
            try { getSystemService(NotificationManager::class.java).notify(SyncRuntime.NOTIFICATION, notification) }
            catch (_: SecurityException) { /* POST_NOTIFICATIONS negato: l'import continua. */ }
            if (finished) {
                if (Build.VERSION.SDK_INT >= 24) stopForeground(STOP_FOREGROUND_DETACH)
                else @Suppress("DEPRECATION") stopForeground(false)
                SyncRuntime.running = false
                releaseResources()
                stopSelf(startId)
            }
        }
        return START_NOT_STICKY
    }

    override fun onTimeout(startId: Int, fgsType: Int) {
        stopForTimeout()
    }

    private fun stopForTimeout() {
        SyncRuntime.channel?.invokeMethod("timeout", null)
        SyncRuntime.publish(this, mapOf("title" to "Sincronizzazione da completare",
            "body" to "Tempo disponibile terminato. I dati salvati sono conservati: riapri l’app per riprovare.",
            "finished" to true))
        if (Build.VERSION.SDK_INT >= 24) stopForeground(STOP_FOREGROUND_DETACH)
        else @Suppress("DEPRECATION") stopForeground(false)
        SyncRuntime.running = false
        releaseResources()
        stopSelf()
    }

    private fun releaseResources() {
        watchdog.removeCallbacks(deadline)
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    override fun onDestroy() {
        SyncRuntime.running = false
        SyncRuntime.started(false)
        releaseResources()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
