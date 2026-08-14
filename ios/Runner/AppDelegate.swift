import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationTapEventListener: NotificationTapEventListener?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication
      .LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Use `DesignVariables.mainBackground` color as the background color
    // of the default UIView.
    window?.backgroundColor = UIColor(named: "LaunchBackground")

    let controller = window?.rootViewController as! FlutterViewController

    IosNativeHostApiSetup.setUp(
      binaryMessenger: controller.binaryMessenger, api: IosNativeHostApiImpl())

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(
      with: controller.binaryMessenger,
      streamHandler: notificationTapEventListener!
    )

    UNUserNotificationCenter.current().delegate = self

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    // When the app is in the foreground, apply the notification's badge value
    // to the app icon, display it as a banner over the app, and show it in
    // the Notification Center list.
    // See docs: https://developer.apple.com/documentation/usernotifications/unnotificationpresentationoptions
    return [.badge, .banner, .list]
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
  ) async {
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      let userInfo = response.notification.request.content.userInfo
      notificationTapEventListener!.onNotificationTapEvent(payload: userInfo)
    }
  }
}
