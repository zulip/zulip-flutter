import 'package:flutter/widgets.dart';

// Inspired by test code in the Flutter tree:
//   https://github.com/flutter/flutter/blob/53082f65b/packages/flutter/test/widgets/observer_tester.dart
//   https://github.com/flutter/flutter/blob/53082f65b/packages/flutter/test/widgets/navigator_test.dart

/// A trivial observer for testing the navigator.
class TestNavigatorObserver extends NavigatorObserver {
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPushed;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPopped;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onRemoved;
  void Function(Route<dynamic>? route, Route<dynamic>? previousRoute)? onReplaced;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onStartUserGesture;
  void Function()? onStopUserGesture;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPushed?.call(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPopped?.call(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRemoved?.call(route, previousRoute);
  }

  @override
  void didReplace({ Route<dynamic>? oldRoute, Route<dynamic>? newRoute }) {
    onReplaced?.call(newRoute, oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onStartUserGesture?.call(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    onStopUserGesture?.call();
  }
}
