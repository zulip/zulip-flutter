import Flutter
import UIKit

// Adapted from Pigeon's Swift example for @EventChannelApi:
//   https://github.com/flutter/packages/blob/2dff6213a/packages/pigeon/example/app/ios/Runner/AppDelegate.swift#L49-L74
class NotificationTapEventListener: NotificationTapEventsStreamHandler {
  private var eventSink: PigeonEventSink<NotificationTapEvent>?
  private var buffer: [NotificationTapEvent] = []

  override init() {
    super.init()

    // iOS can tear down the Dart-side consumer of this stream without it having a chance to call
    // `onCancel`. In particular, to reclaim resources, iOS can disconnect a UIScene while the app
    // is in the background --
    //   https://developer.apple.com/documentation/uikit/managing-your-app-s-life-cycle
    // -- which causes the Flutter view controller to destroy its Flutter engine:
    //   https://github.com/flutter/flutter/blob/a29b620b7/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController.mm#L1025-L1030
    //   https://github.com/flutter/flutter/blob/a29b620b7/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController.mm#L1064-L1067
    // When the app is foregrounded again, the Dart side is re-created, and this listener is
    // registered with the new engine:
    //   https://github.com/flutter/flutter/blob/a29b620b7/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController.mm#L284-L304
    // Until the new Dart side subscribes, this listener still holds the sink from the old one.
    // An event sent there would be dropped ("Communicating on a dead channel") if the engine has
    // been freed from memory; if it's been destroyed but not yet freed, the app would crash.
    // So to ensure events on this stream reach their new Dart-side consumer, watch for the scene
    // being disconnected, to start buffering events for the new sink.
    // (The app has a single scene. With several, this would have to check which scene's
    // engine the sink belongs to.)
    _ = NotificationCenter.default.addObserver(
      forName: UIScene.didDisconnectNotification, object: nil, queue: nil
    ) { [weak self] _ in self?.reset() }
  }

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
    eventSink?.endOfStream()
    reset()
  }

  /// Forget the current sink, so events buffer until the next `onListen`.
  private func reset() {
    eventSink = nil
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
