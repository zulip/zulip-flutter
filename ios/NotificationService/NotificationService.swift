import Flutter
import UserNotifications
import os

/// See docs:
///   https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension
///   https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications
class NotificationService: UNNotificationServiceExtension {
  let logger = Logger()

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
      contentHandler(request.content)  // TODO(log)
      return
    }

    IosNativeHostApiSetup.setUp(
      binaryMessenger: headlessEngine.binaryMessenger, api: IosNativeHostApiImpl())

    // Register Flutter plugins with the headless engine.
    GeneratedPluginRegistrant.register(with: headlessEngine)

    let iosNotifFlutterApi = IosNotifFlutterApi(
      binaryMessenger: headlessEngine.binaryMessenger
    )

    var loopRunning = true
    iosNotifFlutterApi.didReceivePushNotification(
      content: NotificationContent(payload: bestAttemptContent.userInfo)
    ) { result in
      defer { loopRunning = false }

      switch result {
      case .success(let improvedNotificationContent):
        bestAttemptContent.title = improvedNotificationContent.title
        bestAttemptContent.subtitle = improvedNotificationContent.subtitle
        bestAttemptContent.body = improvedNotificationContent.body
        bestAttemptContent.userInfo = improvedNotificationContent.userInfo as [AnyHashable : Any]
        contentHandler(bestAttemptContent)

      case .failure(let error):  // TODO(log)
        self.logger.debug(
          "IosNotifFlutterApi.didReceivePushNotification failed: \(error.localizedDescription)")
        contentHandler(bestAttemptContent)
      }
    }

    // FlutterEngine even in the headless mode assumes that the event loop of
    // current thread is being polled by the system. Which is not the case in
    // the NotificationService extension, so here we manually poll the event loop.
    // See discussion:
    //   https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/Running.20Dart.20code.20in.20iOS.20Notification.20Service.20Extension/with/2370721
    // TODO(upstream) let FlutterEngine itself handle this, or expose an API
    //   that makes this easier, maybe with something like:
    //     https://github.com/flutter/flutter/pull/181645

    // Adapted from: https://github.com/flutter/flutter/blob/65b1ec407/engine/src/flutter/fml/platform/darwin/message_loop_darwin.mm#L44-L62
    let kDistantFuture = 1.0e10
    while loopRunning {
      let result = CFRunLoopRunInMode(.defaultMode, kDistantFuture, true)

      switch result {
      case .timedOut:
        // This should never be reachable because the timeout is 1e10 seconds
        // (~316 years). But continue looping here, matching the upstream
        // implementation.
        continue

      case .handledSource:
        // Keep polling until there are events in the event loop.
        continue

      case .finished, .stopped:
        loopRunning = false

      @unknown default:  // TODO(log)
        logger.debug("Unknown result from CFRunLoopRunInMode: \(String(describing: result))")
        continue
      }
    }

    headlessEngine.destroyContext()
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
