import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationTapEventListener: NotificationTapEventListener?
  private var notificationHostApi: NotificationHostApiImpl?

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
    notificationHostApi = api
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

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    // When the app is in the foreground, normally apply the notification's
    // badge value to the app icon, display it as a banner over the app, and
    // show it in the Notification Center list (#408 / #2306).
    //
    // Exception: if the user is already viewing the same conversation the
    // notification is for, suppress banner/list/sound so the in-app message
    // list is the only UI update. Other conversations still alert.
    // See docs: https://developer.apple.com/documentation/usernotifications/unnotificationpresentationoptions
    if shouldSuppressForegroundAlert(for: notification) {
      return []
    }
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

  /// Whether a foreground notification should be silenced because its
  /// conversation matches the message list currently open in the UI.
  private func shouldSuppressForegroundAlert(for notification: UNNotification)
    -> Bool
  {
    guard let openKey = notificationHostApi?.openConversationKeyForNotifSuppression
    else {
      return false
    }
    guard
      let notifKey = Self.conversationKeyForNotifSuppression(
        from: notification.request.content.userInfo)
    else {
      return false
    }
    return openKey == notifKey
  }

  private static func intValue(_ value: Any?) -> Int? {
    switch value {
    case let i as Int:
      return i
    case let n as NSNumber:
      return n.intValue
    case let s as String:
      return Int(s)
    default:
      return nil
    }
  }

  /// Builds the same conversation key Dart uses in
  /// `NotificationOpenPayload.conversationKeyForNotifSuppression`,
  /// from an APNs / improved-notification userInfo dictionary.
  static func conversationKeyForNotifSuppression(from userInfo: [AnyHashable: Any])
    -> String?
  {
    // E2EE path: IosNotificationService puts a zulip://notification URL here.
    if let notificationUrl = userInfo["notification_url"] as? String,
      let key = conversationKey(fromNotificationUrlString: notificationUrl)
    {
      return key
    }

    // Legacy plaintext APNs payload. Numeric fields arrive as NSNumber.
    guard let zulip = userInfo["zulip"] as? [String: Any],
      let userId = intValue(zulip["user_id"])
    else {
      return nil
    }
    let realmUrlString =
      (zulip["realm_url"] as? String) ?? (zulip["realm_uri"] as? String)
    guard let realmUrlString,
      let realmOrigin = URL(string: realmUrlString)?.zulipOriginString
    else {
      return nil
    }

    let recipientType = zulip["recipient_type"] as? String
    switch recipientType {
    case "stream":
      guard let streamId = intValue(zulip["stream_id"]),
        let topic = zulip["topic"] as? String
      else {
        return nil
      }
      return
        "\(realmOrigin)|\(userId)|topic:\(streamId):\(topic.lowercased())"
    case "private":
      if let pmUsers = zulip["pm_users"] as? String {
        let ids =
          pmUsers
          .split(separator: ",")
          .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
          .sorted()
        let idsStr = ids.map(String.init).joined(separator: ",")
        return "\(realmOrigin)|\(userId)|dm:\(idsStr)"
      }
      guard let senderId = intValue(zulip["sender_id"]) else { return nil }
      // Match Dart DmNarrow.withUser: sorted unique ids including self.
      let uniqueIds = Array(Set([userId, senderId])).sorted()
      let idsStr = uniqueIds.map(String.init).joined(separator: ",")
      return "\(realmOrigin)|\(userId)|dm:\(idsStr)"
    default:
      return nil
    }
  }

  private static func conversationKey(fromNotificationUrlString urlString: String)
    -> String?
  {
    guard let url = URL(string: urlString),
      url.scheme == "zulip",
      url.host == "notification",
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      return nil
    }
    let query = Dictionary(
      uniqueKeysWithValues: (components.queryItems ?? []).compactMap {
        item -> (String, String)? in
        guard let value = item.value else { return nil }
        return (item.name, value)
      })
    guard let realmUrlString = query["realm_url"],
      let realmOrigin = URL(string: realmUrlString)?.zulipOriginString,
      let userId = query["user_id"],
      let narrowType = query["narrow_type"]
    else {
      return nil
    }
    switch narrowType {
    case "topic":
      guard let channelId = query["channel_id"],
        let topic = query["topic"]
      else {
        return nil
      }
      return
        "\(realmOrigin)|\(userId)|topic:\(channelId):\(topic.lowercased())"
    case "dm":
      guard let allRecipientIds = query["all_recipient_ids"] else { return nil }
      return "\(realmOrigin)|\(userId)|dm:\(allRecipientIds)"
    default:
      return nil
    }
  }
}

extension URL {
  /// Matches Dart `Uri.origin` for http(s) URLs used in conversation keys.
  ///
  /// Omits the port when it is the scheme default (80 for http, 443 for https),
  /// same as Dart's `Uri.origin`.
  fileprivate var zulipOriginString: String? {
    guard let scheme = scheme?.lowercased(), let host = host else { return nil }
    let defaultPort: Int?
    switch scheme {
    case "http": defaultPort = 80
    case "https": defaultPort = 443
    default: defaultPort = nil
    }
    if let port = port, port != defaultPort {
      return "\(scheme)://\(host):\(port)"
    }
    return "\(scheme)://\(host)"
  }
}

private class NotificationHostApiImpl: NotificationHostApi {
  private let maybeDataFromLaunch: NotificationDataFromLaunch?

  /// See [NotificationHostApi.setOpenConversationKeyForNotifSuppression].
  var openConversationKeyForNotifSuppression: String?

  init(_ maybeDataFromLaunch: NotificationDataFromLaunch?) {
    self.maybeDataFromLaunch = maybeDataFromLaunch
  }

  func getNotificationDataFromLaunch() -> NotificationDataFromLaunch? {
    maybeDataFromLaunch
  }

  func setOpenConversationKeyForNotifSuppression(conversationKey: String?) {
    openConversationKeyForNotifSuppression = conversationKey
  }
}

// Adapted from Pigeon's Swift example for @EventChannelApi:
//   https://github.com/flutter/packages/blob/2dff6213a/packages/pigeon/example/app/ios/Runner/AppDelegate.swift#L49-L74
class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationTapEvent>?

  override func onListen(
    withArguments arguments: Any?,
    sink: PigeonEventSink<NotificationTapEvent>
  ) {
    eventSink = sink
  }

  func onNotificationTapEvent(payload: [AnyHashable: Any]) {
    eventSink?.success(IosNotificationTapEvent(payload: payload))
  }
}
