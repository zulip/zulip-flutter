// Adapted from Pigeon's Swift example for @EventChannelApi:
//   https://github.com/flutter/packages/blob/2dff6213a/packages/pigeon/example/app/ios/Runner/AppDelegate.swift#L49-L74
class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationTapEvent>?
  var buffer: [NotificationTapEvent] = []

  override func onListen(
    withArguments arguments: Any?,
    sink: PigeonEventSink<NotificationTapEvent>
  ) {
    eventSink = sink
    if !buffer.isEmpty {
      buffer.forEach {
        sink.success($0)
      }
      buffer.removeAll()
    }
  }

  override func onCancel(withArguments arguments: Any?) {
    if let eventSink = self.eventSink {
      eventSink.endOfStream()
      self.eventSink = nil
    }
  }

  func onNotificationTapEvent(payload: [AnyHashable: Any]) {
    let event = IosNotificationTapEvent(payload: payload)
    if let eventSink = self.eventSink {
      eventSink.success(event)
    } else {
      buffer.append(event)
    }
  }
}
