import Flutter
import UIKit
import UserNotifications

private let messageNotificationCategory = "MESSAGE"
private let replyNotificationAction = "REPLY"
private let replyTextUserInfoKey = "reply_text"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let notificationTapEventListener = NotificationTapEventListener()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication
      .LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    let replyAction = UNTextInputNotificationAction(
      identifier: replyNotificationAction,
      title: "Reply",
      options: [],
      textInputButtonTitle: "Send",
      textInputPlaceholder: "Reply"
    )
    let messageCategory = UNNotificationCategory(
      identifier: messageNotificationCategory,
      actions: [replyAction],
      intentIdentifiers: [],
      options: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([messageCategory])

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let binaryMessenger = engineBridge.applicationRegistrar.messenger()

    IosNativeHostApiSetup.setUp(
      binaryMessenger: binaryMessenger, api: IosNativeHostApiImpl())

    NotificationTapEventsStreamHandler.register(
      with: binaryMessenger,
      streamHandler: notificationTapEventListener
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
    var userInfo = response.notification.request.content.userInfo
    if response.actionIdentifier == replyNotificationAction,
      let textResponse = response as? UNTextInputNotificationResponse
    {
      userInfo[replyTextUserInfoKey] = textResponse.userText
      notificationTapEventListener.onNotificationTapEvent(payload: userInfo)
    } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      notificationTapEventListener.onNotificationTapEvent(payload: userInfo)
    }
  }
}
