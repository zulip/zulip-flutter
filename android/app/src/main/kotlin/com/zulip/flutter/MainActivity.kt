package com.zulip.flutter

import android.content.Intent
import com.zulip.flutter.notifications.NotificationTapEventListener
import com.zulip.flutter.notifications.NotificationTapEventsStreamHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var androidIntentEventListener: AndroidIntentEventListener? = null
  private var notificationTapEventListener: NotificationTapEventListener? = null

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

    maybeHandleIntent(intent)
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
