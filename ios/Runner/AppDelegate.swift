import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationTapEventListener: NotificationTapEventListener?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    // Retrieve the remote notification data from launch options,
    // this will be null if the launch wasn't triggered by a notification.
    let notificationData = launchOptions?[.remoteNotification] as? [AnyHashable : Any]
    let api = NotificationHostApiImpl(notificationData.map { NotificationPayloadForOpen(payload: $0) })
    NotificationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: api)

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(with: controller.binaryMessenger, streamHandler: notificationTapEventListener!)

    // Setup handler for notification tap while the app is running.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let listener = notificationTapEventListener {
      let userInfo = response.notification.request.content.userInfo
      listener.onNotificationTapEvent(data: NotificationPayloadForOpen(payload: userInfo))
      completionHandler()
    }
  }
}

private class NotificationHostApiImpl: NotificationHostApi {
  private let maybeNotifPayload: NotificationPayloadForOpen?

  init(_ maybeNotifPayload: NotificationPayloadForOpen?) {
    self.maybeNotifPayload = maybeNotifPayload
  }

  func getNotificationDataFromLaunch() -> NotificationPayloadForOpen? {
    maybeNotifPayload
  }
}

class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationPayloadForOpen>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<NotificationPayloadForOpen>) {
    eventSink = sink
  }

  func onNotificationTapEvent(data: NotificationPayloadForOpen) {
    if let eventSink = eventSink {
      eventSink.success(data)
    }
  }

  func onEventsDone() {
    eventSink?.endOfStream()
    eventSink = nil
  }
}
