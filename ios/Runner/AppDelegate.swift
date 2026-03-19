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

    IosNativeHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: IosNativeHostApiImpl())

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

private class IosNativeHostApiImpl: IosNativeHostApi {
  func setExcludedFromBackup(filePath: String) throws {
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true

    var url = URL(fileURLWithPath: filePath, isDirectory: false)
    try url.setResourceValues(resourceValues)
  }
}
