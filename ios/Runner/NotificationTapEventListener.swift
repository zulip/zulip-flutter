// Adapted from Pigeon's Swift example for @EventChannelApi:
//   https://github.com/flutter/packages/blob/2dff6213a/packages/pigeon/example/app/ios/Runner/AppDelegate.swift#L49-L74
class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  var eventSink: PigeonEventSink<NotificationTapEvent>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<NotificationTapEvent>) {
    eventSink = sink
  }

  func onNotificationTapEvent(payload: [AnyHashable : Any]) {
    eventSink?.success(IosNotificationTapEvent(payload: payload))
  }
}
