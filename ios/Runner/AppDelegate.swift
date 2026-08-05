import Flutter
import UIKit
import UserNotifications

private let messageNotificationCategory = "MESSAGE"
private let replyNotificationAction = "REPLY"
private let replyTextUserInfoKey = "reply_text"

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

    // Retrieve the remote notification payload from launch options;
    // this will be null if the launch wasn't triggered by a notification.
    let notificationPayload =
      launchOptions?[.remoteNotification] as? [AnyHashable: Any]
    let api = NotificationHostApiImpl(
      notificationPayload.map { NotificationDataFromLaunch(payload: $0) }
    )
    NotificationHostApiSetup.setUp(
      binaryMessenger: controller.binaryMessenger,
      api: api
    )

    notificationTapEventListener = NotificationTapEventListener()
    NotificationTapEventsStreamHandler.register(
      with: controller.binaryMessenger,
      streamHandler: notificationTapEventListener!
    )

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
      notificationTapEventListener?.onNotificationTapEvent(payload: userInfo)
    } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      notificationTapEventListener?.onNotificationTapEvent(payload: userInfo)
    }
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
  private var pendingReplyPayloads: [[AnyHashable: Any]] = []

  override func onListen(
    withArguments arguments: Any?,
    sink: PigeonEventSink<NotificationTapEvent>
  ) {
    eventSink = sink
    for payload in pendingReplyPayloads {
      sink.success(IosNotificationTapEvent(payload: payload))
    }
    pendingReplyPayloads.removeAll()
  }

  func onNotificationTapEvent(payload: [AnyHashable: Any]) {
    guard let eventSink else {
      if payload[replyTextUserInfoKey] != nil {
        pendingReplyPayloads.append(payload)
      }
      return
    }
    eventSink.success(IosNotificationTapEvent(payload: payload))
  }
}
