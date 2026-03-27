package com.zulip.flutter

import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.zulip.flutter.notifications.NotificationTapEventListener
import com.zulip.flutter.notifications.NotificationTapEventsStreamHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
  private var androidIntentEventListener: AndroidIntentEventListener? = null
  private var notificationTapEventListener: NotificationTapEventListener? = null
  private var backgroundChannel: MethodChannel? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    androidIntentEventListener = AndroidIntentEventListener()
    AndroidIntentEventsStreamHandler.register(
      flutterEngine.dartExecutor.binaryMessenger, androidIntentEventListener!!
    )
    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(
      flutterEngine.dartExecutor.binaryMessenger, notificationTapEventListener!!
    )

    // Setup background service channel
    backgroundChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zulip/background")
    backgroundChannel?.setMethodCallHandler { call, result ->
      when (call.method) {
        "startBackgroundService" -> {
          startBackgroundWorkManager()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }

    maybeHandleIntent(intent)
  }

  private fun startBackgroundWorkManager() {
    val workRequest = PeriodicWorkRequestBuilder<BackgroundWorker>(5, TimeUnit.MINUTES)
      .build()

    WorkManager.getInstance(applicationContext).enqueueUniquePeriodicWork(
      "zulip_background_fetch",
      ExistingPeriodicWorkPolicy.KEEP,
      workRequest
    )
  }

  override fun onNewIntent(intent: Intent) {
    if (maybeHandleIntent(intent)) {
      return
    }
    super.onNewIntent(intent)
  }

  /** Returns true just if we did handle the intent. */
  private fun maybeHandleIntent(intent: Intent?): Boolean {
    intent ?: return false
    when (intent.action) {
      // Share-to-Zulip
      Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE -> {
        androidIntentEventListener!!.handleSend(this, intent)
        return true
      }

      Intent.ACTION_VIEW -> {
        if (notificationTapEventListener!!.maybeHandleViewIntent(intent)) {
          // Notification tapped
          return true
        }

        // Let Flutter handle other intents, in particular the web-auth intents
        // have ACTION_VIEW, scheme "zulip", and authority "login".
        return false
      }

      // For other intents, let Flutter handle it.
      else -> return false
    }
  }
}

class BackgroundWorker(
  appContext: Context,
  workerParams: WorkerParameters
) : Worker(appContext, workerParams) {

  override fun doWork(): Result {
    // Notify Flutter about background fetch
    val backgroundChannel = MethodChannel(
      applicationContext,
      "zulip/background"
    )

    try {
      backgroundChannel.invokeMethod("onBackgroundFetch", null)
    } catch (e: Exception) {
      e.printStackTrace()
    }

    return Result.success()
  }
}
