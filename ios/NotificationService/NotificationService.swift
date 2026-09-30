import Flutter
import Foundation
import Intents
import UIKit
import UserNotifications
import os

/// See docs:
///   https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension
///   https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications
class NotificationService: UNNotificationServiceExtension {
  private static let senderAvatarUrlKey = "sender_avatar_url"
  private static let senderIdKey = "sender_id"
  private static let senderNameKey = "sender_name"
  private static let notificationUrlKey = "notification_url"

  private let logger = Logger()
  private let deliveryLock = NSLock()
  private var hasDeliveredContent = false

  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  /// See docs: https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension/didreceive(_:withcontenthandler:)
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    deliveryLock.withLock { hasDeliveredContent = false }
    self.contentHandler = contentHandler
    bestAttemptContent =
      (request.content.mutableCopy() as? UNMutableNotificationContent)
    guard let bestAttemptContent = bestAttemptContent else {
      deliver(request.content, with: contentHandler)
      return
    }

    // iOS calls this method on a background thread, but a FlutterEngine must be
    // created and run on the main thread.  So hop to the main actor for that.
    //
    // This function will therefore return before `contentHandler` is called,
    // which is fine: all iOS asks is that it eventually get called, either by
    // the task below or by `serviceExtensionTimeWillExpire`.
    Task { @MainActor in
      let improvedContent = await DartNotificationService.didReceivePushNotification(
        NotificationContent(payload: bestAttemptContent.userInfo))
      if let improvedContent = improvedContent {
        bestAttemptContent.title = improvedContent.title
        bestAttemptContent.subtitle = improvedContent.subtitle
        bestAttemptContent.body = improvedContent.body
        switch improvedContent.sound {
        case .systemDefault:
          bestAttemptContent.sound = UNNotificationSound.default
        }
        bestAttemptContent.userInfo = improvedContent.userInfo as [AnyHashable: Any]
      }
      let content: UNNotificationContent
      if let improvedContent = improvedContent {
        content = await communicationNotificationContent(
          from: bestAttemptContent,
          userInfo: improvedContent.userInfo)
      } else {
        content = bestAttemptContent
      }
      deliver(content, with: contentHandler)
    }
  }

  /// Called by iOS when the `didReceive(_:withContentHandler:)` method doesn't
  /// call `contentHandler()` within a certain time limit (docs say 30 seconds).
  ///
  /// See docs: https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension/serviceextensiontimewillexpire()
  override func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler,
      let bestAttemptContent = bestAttemptContent
    {
      deliver(bestAttemptContent, with: contentHandler)
    }
  }

  /// The network completion and extension timeout can race to deliver content.
  private func deliver(
    _ content: UNNotificationContent,
    with handler: @escaping (UNNotificationContent) -> Void
  ) {
    let shouldDeliver = deliveryLock.withLock {
      if hasDeliveredContent { return false }
      hasDeliveredContent = true
      return true
    }
    if shouldDeliver { handler(content) }
  }

  /// Converts a normal notification into an iOS Communication Notification.
  /// Any failure returns the already-prepared normal notification.
  private func communicationNotificationContent(
    from content: UNMutableNotificationContent,
    userInfo: [String: Any?]
  ) async -> UNNotificationContent {
    guard
      let avatarUrlString = userInfo[Self.senderAvatarUrlKey] as? String,
      let avatarUrl = URL(string: avatarUrlString),
      avatarUrl.scheme == "https",
      let senderId = userInfo[Self.senderIdKey] as? String,
      let senderName = userInfo[Self.senderNameKey] as? String
    else {
      return content
    }

    var request = URLRequest(url: avatarUrl)
    request.timeoutInterval = 5

    guard
      let (imageData, response) = try? await URLSession.shared.data(for: request),
      let httpResponse = response as? HTTPURLResponse,
      (200..<300).contains(httpResponse.statusCode),
      imageData.count <= 2 * 1024 * 1024,
      UIImage(data: imageData) != nil
    else {
      return content
    }

    let avatar = INImage(imageData: imageData)
    let sender = INPerson(
      personHandle: INPersonHandle(value: senderId, type: .unknown),
      nameComponents: nil,
      displayName: senderName,
      image: avatar,
      contactIdentifier: nil,
      customIdentifier: senderId
    )

    let conversationIdentifier = userInfo[Self.notificationUrlKey] as? String
    let speakableGroupName =
      content.title.isEmpty
      ? nil
      : INSpeakableString(spokenPhrase: content.title)
    let intent = INSendMessageIntent(
      recipients: nil,
      outgoingMessageType: .outgoingMessageText,
      content: content.body,
      speakableGroupName: speakableGroupName,
      conversationIdentifier: conversationIdentifier,
      serviceName: "Zulip",
      sender: sender,
      attachments: nil
    )

    let interaction = INInteraction(intent: intent, response: nil)
    interaction.direction = .incoming

    do {
      try await interaction.donate()
      return try content.updating(from: intent)
    } catch {
      logger.debug("Unable to create Communication Notification: \(error.localizedDescription)")
      return content
    }
  }
}

/// The Dart side of this NotificationService, run in a headless FlutterEngine.
///
/// See `IosNotificationService` in lib/notifications/ios_service.dart.
///
/// This is isolated to the main actor because a FlutterEngine must be created
/// and run on the main thread.
///
/// See docs: https://api.flutter.dev/ios-embedder/interface_flutter_engine.html
@MainActor
enum DartNotificationService {
  private static let logger = Logger()

  /// Ask the Dart code what content to show for a push notification
  /// we received, or nil if it didn't give us any.
  static func didReceivePushNotification(
    _ content: NotificationContent
  ) async -> ImprovedNotificationContent? {
    // Initialise a headless FlutterEngine, and start executing Dart code
    // using a custom entrypoint.
    //
    // See docs:
    //   https://api.flutter.dev/ios-embedder/interface_flutter_engine.html#a4f74d860f311cb1a6c30a6411ca8e8ff
    //   https://api.flutter.dev/ios-embedder/interface_flutter_engine.html#a2ae6940c35afbdc5e1088aa9c1b26bbd
    let headlessEngine = FlutterEngine(
      name: "zulip_headless",
      project: nil,
      allowHeadlessExecution: true
    )
    let started = headlessEngine.run(
      withEntrypoint: "iosNotificationServiceMain",
      libraryURI: "package:zulip/notifications/ios_service.dart"
    )
    if !started {
      return nil  // TODO(log)
    }

    defer { headlessEngine.destroyContext() }

    IosNativeHostApiSetup.setUp(
      binaryMessenger: headlessEngine.binaryMessenger, api: IosNativeHostApiImpl())

    // Register Flutter plugins with the headless engine.
    GeneratedPluginRegistrant.register(with: headlessEngine)

    let iosNotifFlutterApi = IosNotifFlutterApi(
      binaryMessenger: headlessEngine.binaryMessenger
    )
    let result = await withCheckedContinuation { continuation in
      iosNotifFlutterApi.didReceivePushNotification(content: content) { result in
        continuation.resume(returning: result)
      }
    }

    switch result {
    case .success(let improvedNotificationContent):
      return improvedNotificationContent

    case .failure(let error):  // TODO(log)
      logger.debug(
        "IosNotifFlutterApi.didReceivePushNotification failed: \(error.localizedDescription)")
      return nil
    }
  }
}
