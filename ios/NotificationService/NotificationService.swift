import Flutter
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent =
      (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let bestAttemptContent = bestAttemptContent else {
      contentHandler(request.content)
      return
    }

    // Modify the notification content here...
    // bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"

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
      contentHandler(request.content)
      return
    }

    GeneratedPluginRegistrant.register(with: headlessEngine)

    // FlutterEngine even in the headless mode assumes that the event loop of
    // current thread is being polled by the system. Which is not the case in
    // the NotificationService extension, so here we manually poll the event loop.
    // See discussion:
    //   https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/Running.20Dart.20code.20in.20iOS.20Notification.20Service.20Extension/with/2370721
    // TODO let FlutterEngine itself handle this, or expose an API that makes
    //   this easier, maybe with something like:
    //     https://github.com/flutter/flutter/pull/181645

    // Adapted from: https://github.com/flutter/flutter/blob/65b1ec407/engine/src/flutter/fml/platform/darwin/message_loop_darwin.mm#L44-L62
    loop: while true {
      let result = CFRunLoopRunInMode(.defaultMode, 1, true)

      switch result {
      case .handledSource:
        // Keep polling until there are events in the event loop.
        continue

      case .finished, .stopped, .timedOut:
        break loop

      @unknown default:
        fatalError()
      }
    }

    headlessEngine.destroyContext()

    contentHandler(bestAttemptContent)
  }

  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler,
      let bestAttemptContent = bestAttemptContent
    {
      contentHandler(bestAttemptContent)
    }
  }
}
