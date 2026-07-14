import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'double_tap_recognizer.dart';

/// A widget that detects double-tap gestures without participating in the
/// gesture arena.
///
/// This can be useful when adding an `onDoubleTap` handler to a
/// [GestureDetector] would be undesirable because it delays `onTap` handlers by
/// up to [kDoubleTapTimeout] to distinguish between single and double taps.
///
/// The tradeoff is that a double tap may trigger both this widget's callback
/// and another gesture handler in the tree that responds to one or both taps.
///
/// See also:
///   * [DoubleTapRecognizer], which this widget uses internally to recognize
///     double taps without participating in the gesture arena.
//
// TODO(upstream): Delete this class if Flutter gains a way to detect
//   double taps without delaying single taps:
//     https://github.com/flutter/flutter/issues/106170
//     https://github.com/flutter/flutter/issues/110300
class DoubleTapListener extends StatefulWidget {
  const DoubleTapListener({
    super.key,
    this.behavior = .translucent,
    this.supportedDevices,
    this.onDoubleTap,
    this.child,
  });

  /// How this listener should behave during hit testing when deciding
  /// how the hit test propagates to children and whether to consider targets
  /// behind this one.
  ///
  /// Defaults to [HitTestBehavior.translucent].
  ///
  /// See [HitTestBehavior] for the allowed values and their meanings.
  final HitTestBehavior behavior;

  /// The kind of devices that are allowed to be recognized.
  ///
  /// If set to null, events from all device types will be recognized. Defaults to null.
  final Set<PointerDeviceKind>? supportedDevices;

  /// Called when the user performs a double tap.
  ///
  /// If null, this widget does not recognize double taps.
  final VoidCallback? onDoubleTap;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  State<DoubleTapListener> createState() => _DoubleTapListenerState();
}

class _DoubleTapListenerState extends State<DoubleTapListener> {
  late final DoubleTapRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = DoubleTapRecognizer()
      ..supportedDevices = widget.supportedDevices
      ..onDoubleTap = widget.onDoubleTap;
  }

  @override
  void didUpdateWidget(covariant DoubleTapListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recognizer
      ..supportedDevices = widget.supportedDevices
      ..onDoubleTap = widget.onDoubleTap;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _recognizer.addPointer,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}
