package com.zulip.flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var notificationTapEventListener: NotificationTapEventListener? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    val maybeNotifPayload = maybeIntentExtrasData(intent)
    val api = NotificationHostApiImpl(maybeNotifPayload?.let { NotificationDataFromLaunch(it) })
    NotificationHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, api)

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(
      flutterEngine.dartExecutor.binaryMessenger, notificationTapEventListener!!
    )
  }

  override fun onNewIntent(intent: Intent) {
    val maybeExtrasData = maybeIntentExtrasData(intent)
    if (notificationTapEventListener != null && maybeExtrasData != null) {
      notificationTapEventListener!!.onNotificationTapEvent(NotificationTapEvent(payload = maybeExtrasData))
      return
    }

    super.onNewIntent(intent)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    notificationTapEventListener?.onEventsDone()
    notificationTapEventListener = null

    super.cleanUpFlutterEngine(flutterEngine)
  }

  private fun maybeIntentExtrasData(intent: Intent): Map<Any?, Any?>? {
    var extrasData: Map<Any?, Any?>? = null
    if (intent.action == Intent.ACTION_VIEW) {
      val intentUrl = intent.data
      if (intentUrl?.scheme == "zulip" && intentUrl.authority == "notification") {
        val bundle = intent.getBundleExtra("data")
        if (bundle != null) {
          extrasData =
            bundle.keySet().mapNotNull { key -> bundle.getString(key)?.let { key to it } }
              .toMap<Any?, Any?>()
        }
      }
    }
    return extrasData
  }
}

private class NotificationHostApiImpl(val maybeDataFromLaunch: NotificationDataFromLaunch?) :
  NotificationHostApi {
  override fun getNotificationDataFromLaunch(): NotificationDataFromLaunch? {
    return maybeDataFromLaunch
  }
}

private class NotificationTapEventListener : NotificationTapEventsStreamHandler() {
  private var eventSink: PigeonEventSink<NotificationTapEvent>? = null

  override fun onListen(p0: Any?, sink: PigeonEventSink<NotificationTapEvent>) {
    eventSink = sink
  }

  fun onNotificationTapEvent(data: NotificationTapEvent) {
    eventSink?.success(data)
  }

  fun onEventsDone() {
    eventSink?.endOfStream()
    eventSink = null
  }
}
