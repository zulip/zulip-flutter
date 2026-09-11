import Flutter
import UserNotifications
import os

/// See docs:
///   https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension
///   https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications
class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  /// See docs: https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension/didreceive(_:withcontenthandler:)
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent =
      (request.content.mutableCopy() as? UNMutableNotificationContent)
    guard let bestAttemptContent = bestAttemptContent else {
      contentHandler(request.content)  // TODO(log)
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
      contentHandler(bestAttemptContent)
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
      contentHandler(bestAttemptContent)  // TODO(log)
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

  /// The headless FlutterEngine, if we've started one in this process.
  ///
  /// The other notifications this process handles will reuse it, like on
  /// Android where package:firebase_messaging starts one background engine
  /// and later notifications run in its isolate.
  private static var engine: FlutterEngine?

  /// The headless FlutterEngine, starting one if we haven't already,
  /// or nil if it wouldn't start.
  private static func startedEngine() -> FlutterEngine? {
    if let engine = engine {
      return engine
    }

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

    IosNativeHostApiSetup.setUp(
      binaryMessenger: headlessEngine.binaryMessenger, api: IosNativeHostApiImpl())

    // Register Flutter plugins with the headless engine.
    GeneratedPluginRegistrant.register(with: headlessEngine)

    engine = headlessEngine
    return headlessEngine
  }

  /// Ask the Dart code what content to show for a push notification
  /// we received, or nil if it didn't give us any.
  static func didReceivePushNotification(
    _ content: NotificationContent
  ) async -> ImprovedNotificationContent? {
    guard let engine = startedEngine() else {
      return nil
    }

    let iosNotifFlutterApi = IosNotifFlutterApi(
      binaryMessenger: engine.binaryMessenger
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
