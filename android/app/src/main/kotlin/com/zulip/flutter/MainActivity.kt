package com.zulip.flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var notificationTapEventListener: NotificationTapEventListener? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    val maybeNotifPayload = maybeIntentToNotificationPayload(intent)
    val api = NotificationHostApiImpl(maybeNotifPayload)
    NotificationHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, api)

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(
      flutterEngine.dartExecutor.binaryMessenger, notificationTapEventListener!!
    )
  }

  override fun onNewIntent(intent: Intent) {
    val maybeNotifData = maybeIntentToNotificationPayload(intent)
    if (notificationTapEventListener != null && maybeNotifData != null) {
      notificationTapEventListener!!.onNotificationTapEvent(maybeNotifData)
      return
    }

    super.onNewIntent(intent)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    notificationTapEventListener?.onEventsDone()
    notificationTapEventListener = null

    super.cleanUpFlutterEngine(flutterEngine)
  }

  private fun maybeIntentToNotificationPayload(intent: Intent): NotificationPayloadForOpen? {
    var notifData: NotificationPayloadForOpen? = null
    if (intent.action == Intent.ACTION_VIEW) {
      val intentUrl = intent.data
      if (intentUrl?.scheme == "zulip" && intentUrl.authority == "notification") {
        val bundle = intent.getBundleExtra("data")
        if (bundle != null) {
          val payload =
            bundle.keySet().mapNotNull { key -> bundle.getString(key)?.let { key to it } }
              .toMap<Any?, Any?>()
          notifData = NotificationPayloadForOpen(payload)
        }
      }
    }
    return notifData
  }
}

private class NotificationHostApiImpl(val maybeNotifPayload: NotificationPayloadForOpen?) :
  NotificationHostApi {
  override fun getNotificationDataFromLaunch(): NotificationPayloadForOpen? {
    return maybeNotifPayload
  }
}

private class NotificationTapEventListener : NotificationTapEventsStreamHandler() {
  private var eventSink: PigeonEventSink<NotificationPayloadForOpen>? = null

  override fun onListen(p0: Any?, sink: PigeonEventSink<NotificationPayloadForOpen>) {
    eventSink = sink
  }

  fun onNotificationTapEvent(data: NotificationPayloadForOpen) {
    eventSink?.success(data)
  }

  fun onEventsDone() {
    eventSink?.endOfStream()
    eventSink = null
  }
}
