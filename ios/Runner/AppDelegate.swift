import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self

    // Handle launch of application from the notification.
    let controller = window.rootViewController as! FlutterViewController
    if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable : Any],
       let payload = ApnsPayload(fromJson: remoteNotification),
       let routeUrl = internalRouteUrlFromNotification(payload: payload) {
      // https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/defaultRouteName.html
      // TODO(?) FlutterViewController.setInitialRoute is deprecated (warning visible in Xcode)
      //   but the above doc mentions using it.
      controller.setInitialRoute(routeUrl.absoluteString)
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // Allow only `zulip://login` external urls.
  override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
     if url.scheme == "zulip" && url.host == "login" {
       return super.application(application, open: url, options: options)
     }
     return false
   }

  // Handle notification tap while the app is running.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let payload = ApnsPayload(fromJson: response.notification.request.content.userInfo),
       let routeUrl = internalRouteUrlFromNotification(payload: payload) {
       let controller = window.rootViewController as! FlutterViewController
      controller.pushRoute(routeUrl.absoluteString)
      completionHandler()
    }
  }
}

// https://github.com/zulip/zulip/blob/aa8f47774f08b6fc5d947ae97cafefcf7dfb8bef/zerver/lib/push_notifications.py#L1087
struct ApnsPayload {
  enum Narrow {
    case topicNarrow(channelId: Int, topic: String)
    case dmNarrow(allRecipientIds: [Int])
  }

  let realmUrl: String
  let userId: Int
  let narrow: Narrow

  init?(fromJson payload: [AnyHashable : Any]) {
    guard let aps = payload["aps"] as? [String : Any],
          let customData = aps["custom"] as? [String : Any],
          let zulipData = customData["zulip"] as? [String : Any],
          let realmUrl = (
            zulipData["realm_url"] as? String ?? zulipData["realm_url"] as? String
          ),
          let userId = zulipData["user_id"] as? Int,
          let senderId = zulipData["sender_id"] as? Int,
          let recipientType = zulipData["recipient_type"] as? String
    else {
      return nil
    }

    var narrow: Narrow
    switch recipientType {
    case "stream":
      guard let streamId = zulipData["stream_id"] as? Int,
            let topic = zulipData["topic"] as? String else {
        return nil
      }

      narrow = Narrow.topicNarrow(channelId: streamId, topic: topic)

    case "private":
      var allRecipientIds = Set<Int>()

      if let pmUsersStr = zulipData["pm_users"] as? String {
        for str in pmUsersStr.split(separator: ",") {
          guard let recipientId = Int(str, radix: 10) else {
            return nil
          }
          allRecipientIds.insert(recipientId)
        }
      } else {
        allRecipientIds.formUnion([senderId, userId])
      }

      narrow = Narrow.dmNarrow(allRecipientIds: allRecipientIds.sorted(by: <))

    default:
      return nil
    }

    self.realmUrl = realmUrl
    self.userId = userId
    self.narrow = narrow
  }
}

func internalRouteUrlFromNotification(payload: ApnsPayload) -> URL? {
  var components = URLComponents()
  components.scheme = "zulip"
  components.host = "notification"

  var queryItems = [
    URLQueryItem(name: "realm_url", value: payload.realmUrl),
    URLQueryItem(name: "user_id", value: String(payload.userId)),
  ]

  switch payload.narrow {
  case .topicNarrow(channelId: let channelId, topic: let topic):
    queryItems.append(contentsOf: [
      URLQueryItem(name: "narrow_type", value: "topic"),
      URLQueryItem(name: "channel_id", value: String(channelId)),
      URLQueryItem(name: "topic", value: topic),
    ])

  case .dmNarrow(allRecipientIds: let allRecipientIds):
    queryItems.append(
      contentsOf: [
        URLQueryItem(name: "narrow_type", value: "dm"),
        URLQueryItem(
          name: "all_recipient_ids",
          value: allRecipientIds.map{ String($0) }.joined(separator: ",")),
      ]
    )
  }
  components.queryItems = queryItems
  return components.url
}
