package com.zulip.flutter.notifications

import android.content.Intent
import android.net.Uri

class NotificationTapEventListener : NotificationTapEventsStreamHandler() {
  private var eventSink: PigeonEventSink<NotificationTapEvent>? = null
  private val buffer = mutableListOf<NotificationTapEvent>()

  override fun onListen(p0: Any?, sink: PigeonEventSink<NotificationTapEvent>) {
    eventSink = sink
    if (buffer.isNotEmpty()) {
      buffer.forEach { sink.success(it) }
      buffer.clear()
    }
  }

  override fun onCancel(p0: Any?) {
    if (eventSink != null) {
      eventSink!!.endOfStream()
      eventSink = null
    }
  }

  private fun onNotificationTapEvent(dataUrl: Uri) {
    val event = AndroidNotificationTapEvent(dataUrl.toString())
    if (eventSink != null) {
      eventSink!!.success(event)
    } else {
      buffer.add(event)
    }
  }

  /**
   * Recognize if the ACTION_VIEW intent came from tapping a notification; handle it if so.
   *
   * If the intent is recognized, sends a notification tap event via
   * the Pigeon event stream to the Dart layer and returns true.
   * Else does nothing and returns false.
   *
   * Do not call if `intent.action` is not ACTION_VIEW.
   */
  fun maybeHandleViewIntent(intent: Intent): Boolean {
    assert(intent.action == Intent.ACTION_VIEW)

    val url = intent.data
    if (url?.scheme == "zulip" && url.authority == "notification") {
      onNotificationTapEvent(url)
      return true
    }

    return false
  }
}
