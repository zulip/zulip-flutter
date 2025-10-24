import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Inspired by test code in the Flutter tree:
//   https://github.com/flutter/flutter/blob/53082f65b/packages/flutter/test/widgets/observer_tester.dart
//   https://github.com/flutter/flutter/blob/53082f65b/packages/flutter/test/widgets/navigator_test.dart

/// A trivial observer for testing the navigator.
class TestNavigatorObserver extends TransitionDurationObserver{
  void Function(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute)? onChangedTop;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPushed;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPopped;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onRemoved;
  void Function(Route<dynamic>? route, Route<dynamic>? previousRoute)? onReplaced;
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onStartUserGesture;
  void Function()? onStopUserGesture;

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);
    onChangedTop?.call(topRoute, previousTopRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onPushed?.call(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPopped?.call(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    onRemoved?.call(route, previousRoute);
  }

  @override
  void didReplace({ Route<dynamic>? oldRoute, Route<dynamic>? newRoute }) {
    super.didReplace(oldRoute: oldRoute, newRoute: newRoute);
    onReplaced?.call(newRoute, oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didStartUserGesture(route, previousRoute);
    onStartUserGesture?.call(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    super.didStopUserGesture();
    onStopUserGesture?.call();
  }
}
