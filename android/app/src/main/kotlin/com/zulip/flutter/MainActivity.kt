package com.zulip.flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var androidIntentEventListener: AndroidIntentEventListener? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    androidIntentEventListener = AndroidIntentEventListener()
    AndroidIntentEventsStreamHandler.register(
      flutterEngine.dartExecutor.binaryMessenger,
      androidIntentEventListener!!
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

      // For other intents, let Flutter handle it.
      else -> return false
    }
  }
}
