import UIKit
import Flutter
import UserNotifications
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var notificationTapEventListener: NotificationTapEventListener?
  private var pushTokenChannel: FlutterMethodChannel?
  private var backgroundChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Set up method channels
    if let controller = window?.rootViewController as? FlutterViewController {
      pushTokenChannel = FlutterMethodChannel(
        name: "zulip/push_tokens",
        binaryMessenger: controller.binaryMessenger
      )
      
      backgroundChannel = FlutterMethodChannel(
        name: "zulip/background",
        binaryMessenger: controller.binaryMessenger
      )
      backgroundChannel?.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "startBackgroundFetch":
          self?.setupBackgroundFetch(application)
          result(nil)
        case "startBackgroundService":
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      
      // Signal Flutter that native is ready
      let readyChannel = FlutterMethodChannel(
        name: "zulip/ready",
        binaryMessenger: controller.binaryMessenger
      )
      readyChannel.invokeMethod("onNativeReady", arguments: nil)
    }

    UNUserNotificationCenter.current().delegate = self
    notificationTapEventListener = NotificationTapEventListener()

    // Register for remote push notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      }
    } else {
      let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }

    // Register for background fetch
    // Note: We'll also register when Flutter calls startBackgroundFetch
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupBackgroundFetch(_ application: UIApplication) {
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    print("AppDelegate: Background fetch enabled")
  }

  // Background fetch handler
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Call Flutter background fetch handler
    backgroundChannel?.invokeMethod("onBackgroundFetch", arguments: nil) { result in
      completionHandler(.newData)
    }
  }

  // Called when the app successfully registers for remote notifications
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("APNs device token: \(token)")
    
    // Send token to Flutter via method channel
    pushTokenChannel?.invokeMethod("onApnsTokenReceived", arguments: token)
  }

  // Called when the app fails to register for remote notifications
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }

  // Called when a background notification is received (iOS 10+)
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Handle background notification
    print("AppDelegate: Received background notification: \(userInfo)")
    
    // Check if it's a silent push (content-available: 1)
    if let contentAvailable = userInfo["content-available"] as? Int, contentAvailable == 1 {
      print("AppDelegate: Silent push received, fetching new messages...")
      
      // Call Flutter background fetch handler
      backgroundChannel?.invokeMethod("onSilentPush", arguments: userInfo) { result in
        completionHandler(.newData)
      }
    } else {
      // Regular notification tap
      print("AppDelegate: Regular notification tap")
      notificationTapEventListener?.onNotificationTapEvent(payload: userInfo)
      completionHandler(.newData)
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      let userInfo = response.notification.request.content.userInfo
      notificationTapEventListener?.onNotificationTapEvent(payload: userInfo)
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

private class IosNativeHostApiImpl: IosNativeHostApi {
  func setExcludedFromBackup(filePath: String) throws {
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true

    var url = URL(fileURLWithPath: filePath, isDirectory: false)
    try url.setResourceValues(resourceValues)
  }
}

// Handler for APNs device token
class NotificationApnsTokenHandler {
  static let shared = NotificationApnsTokenHandler()
  private var token: String?

  private init() {}

  func setToken(_ token: String) {
    self.token = token
    // Notify Flutter about the new token
    NotificationCenter.default.post(name: .apnsTokenReceived, object: token)
  }

  func getToken() -> String? {
    return token
  }
}

extension Notification.Name {
  static let apnsTokenReceived = Notification.Name("apnsTokenReceived")
}
