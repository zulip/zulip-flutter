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

    // Use `DesignVariables.mainBackground` color as the background color
    // of the default UIView.
    window?.backgroundColor = UIColor(named: "LaunchBackground");

    let controller = window?.rootViewController as! FlutterViewController

    // Retrieve the remote notification payload from launch options;
    // this will be null if the launch wasn't triggered by a notification.
    let notificationPayload = launchOptions?[.remoteNotification] as? [AnyHashable : Any]
    let api = NotificationHostApiImpl(notificationPayload.map { NotificationDataFromLaunch(payload: $0) })
    NotificationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: api)

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(with: controller.binaryMessenger, streamHandler: notificationTapEventListener!)

    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      let userInfo = response.notification.request.content.userInfo
      notificationTapEventListener!.onNotificationTapEvent(payload: userInfo)
    }
    completionHandler()
  }
}

private class NotificationHostApiImpl: NotificationHostApi {
  private let maybeDataFromLaunch: NotificationDataFromLaunch?

  init(_ maybeDataFromLaunch: NotificationDataFromLaunch?) {
    self.maybeDataFromLaunch = maybeDataFromLaunch
  }

  func getNotificationDataFromLaunch() -> NotificationDataFromLaunch? {
    maybeDataFromLaunch
  }
}

// Adapted from Pigeon's Swift example for @EventChannelApi:
//   https://github.com/flutter/packages/blob/2dff6213a/packages/pigeon/example/app/ios/Runner/AppDelegate.swift#L49-L74
class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationTapEvent>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<NotificationTapEvent>) {
    eventSink = sink
  }

  func onNotificationTapEvent(payload: [AnyHashable : Any]) {
    eventSink?.success(IosNotificationTapEvent(payload: payload))
  }
}
