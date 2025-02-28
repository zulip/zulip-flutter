import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }

    let notificationData = launchOptions?[.remoteNotification] as? [AnyHashable : Any]
    let api = NotificationHostApiImpl(notificationData.map { NotificationPayloadForOpen(payload: $0) })
    NotificationHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: api)

    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
