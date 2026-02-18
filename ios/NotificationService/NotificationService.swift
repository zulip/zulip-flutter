//
//  NotificationService.swift
//  NotificationService
//
//  Created by Rajesh Malviya on 18/02/26.
//

import Flutter
import UserNotifications
import os.log

class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override init() {
    os_log("NotificationService: pid=\(getpid())")
    os_log("NotificationService.init: thread=\(Thread.current)")
  }

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    os_log("NotificationService.didReceive: thread=\(Thread.current)")
    self.contentHandler = contentHandler
    bestAttemptContent =
      (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let bestAttemptContent = bestAttemptContent else {
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
    os_log("headlessEngine.run: started=\(String(describing: started))")

    GeneratedPluginRegistrant.register(with: headlessEngine)

    // FlutterEngine even in the headless mode assumes that the event loop of
    // current thread is being polled by the system. Which is not the case in
    // Notification Service Extension, so here we manually poll the event loop.
    // See discussion:
    //   https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/Running.20Dart.20code.20in.20iOS.20Notification.20Service.20Extension/with/2370721

    // Adapted from: https://github.com/flutter/flutter/blob/65b1ec407/engine/src/flutter/fml/platform/darwin/message_loop_darwin.mm#L44-L62
    loop: while true {
      os_log("loop: CFRunLoopRunInMode(…)")

      let result = CFRunLoopRunInMode(.defaultMode, 1, true)
      os_log("loop: result=\(String(describing: result))")

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
    os_log("Done destroying headlessEngine")

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
