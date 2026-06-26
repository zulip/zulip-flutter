import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A widget that recognizes double-tap gestures without participating in the
/// gesture arena.
///
/// This uses the same recognition algorithm as [DoubleTapGestureRecognizer].
///
/// This can be useful when adding an `onDoubleTap` handler to a
/// [GestureDetector] would be undesirable because it delays `onTap` handlers by
/// up to [kDoubleTapTimeout] to distinguish between single and double taps.
///
/// The tradeoff is that a double tap may trigger both this widget's callback
/// and another gesture handler in the tree that responds to one or both taps.
//
// May replace the usages of this widget if (one of) the following upstream
// issues are solved:
//   - https://github.com/flutter/flutter/issues/106170
//   - https://github.com/flutter/flutter/issues/110300
class DoubleTapListener extends StatefulWidget {
  const DoubleTapListener({
    super.key,
    this.onDoubleTap,
    this.behavior = .translucent,
    this.supportedDevices,
    this.allowedButtonsFilter = _defaultButtonAcceptBehavior,
    this.child,
  });

  /// Called when the user performs a double tap.
  ///
  /// If null, this widget does not recognize double taps.
  final VoidCallback? onDoubleTap;

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

  /// Filter deciding which input buttons are allowed to participate in
  /// double-tap recognition.
  ///
  /// Defaults to accepting only [kPrimaryButton].
  final AllowedButtonsFilter allowedButtonsFilter;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  // The default value for [allowedButtonsFilter].
  // Accept the input if, and only if, [kPrimaryButton] is pressed.
  static bool _defaultButtonAcceptBehavior(int buttons) => buttons == kPrimaryButton;

  @override
  State<DoubleTapListener> createState() => _DoubleTapListenerState();
}

class _DoubleTapListenerState extends State<DoubleTapListener> {
  Timer? _doubleTapTimer;
  _TapTracker? _firstTap;
  final _trackers = <int, _TapTracker>{};

  bool _isPointerAllowed(PointerDownEvent event) {
    if (_firstTap == null && widget.onDoubleTap == null) {
      return false;
    }

    final isAllowed = (widget.supportedDevices?.contains(event.kind) ?? true)
      && widget.allowedButtonsFilter(event.buttons);
    if (!isAllowed) {
      _reset();
    }
    return isAllowed;
  }

  void _handleDownEvent(PointerDownEvent event) {
    if (!_isPointerAllowed(event)) return;

    if (_firstTap != null) {
      if (!_firstTap!.isWithinBounds(event, kDoubleTapSlop)) {
        // Ignore out-of-bounds second taps.
        return;
      }
      if (!_firstTap!.hasElapsedMinTime() || !_firstTap!.hasSameButton(event)) {
        // Reset when the second tap is too close in time to the first one
        // (touch screens often detect touches intermittently),
        // or when buttons mismatch.
        _reset();
      }
    }
    _trackTap(event);
  }

  void _trackTap(PointerDownEvent event) {
    _stopDoubleTapTimer();
    _trackers[event.pointer] = _TapTracker(event);
  }

  void _handleMoveEvent(PointerMoveEvent event) {
    final tracker = _trackers[event.pointer];
    if (tracker == null) return;

    if (!tracker.isWithinBounds(event, kDoubleTapTouchSlop)) {
      _reject(tracker);
    }
  }

  void _handleUpEvent(PointerUpEvent event) {
    final tracker = _trackers[event.pointer];
    if (tracker == null) return;

    if (_firstTap == null) {
      _registerFirstTap(tracker);
    } else {
      _registerSecondTap(tracker);
    }
  }

  void _handleCancelEvent(PointerCancelEvent event) {
    final tracker = _trackers[event.pointer];
    if (tracker == null) return;

    _reject(tracker);
  }

  void _registerFirstTap(_TapTracker tracker) {
    _startDoubleTapTimer();
    _trackers.remove(tracker.pointer);
    _clearTrackers();
    _firstTap = tracker;
  }

  void _registerSecondTap(_TapTracker tracker) {
    _trackers.remove(tracker.pointer);
    widget.onDoubleTap?.call();
    _reset();
  }

  void _clearTrackers() {
    _trackers.values.toList().forEach(_reject);
    assert(_trackers.isEmpty);
  }

  void _startDoubleTapTimer() {
    _doubleTapTimer ??= Timer(kDoubleTapTimeout, _reset);
  }

  void _stopDoubleTapTimer() {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
  }

  void _reject(_TapTracker tracker) {
    _trackers.remove(tracker.pointer);
    if (_firstTap != null) {
      if (tracker == _firstTap) {
        _reset();
      } else {
        if (_trackers.isEmpty) {
          _reset();
        }
      }
    }
  }

  void _reset() {
    _stopDoubleTapTimer();
    if (_firstTap != null) {
      final tracker = _firstTap!;
      _firstTap = null;
      _reject(tracker);
    }
    _clearTrackers();
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleDownEvent,
      onPointerMove: _handleMoveEvent,
      onPointerUp: _handleUpEvent,
      onPointerCancel: _handleCancelEvent,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}

/// Tracks individual tap sequences as part of a double-tap gesture.
class _TapTracker {
  _TapTracker(PointerDownEvent event)
    : pointer = event.pointer,
      position = event.position,
      buttons = event.buttons,
      _doubleTapMinTimeCountdown = _Countdown(duration: kDoubleTapMinTime);

  final int pointer;
  final Offset position;
  final int buttons;
  final _Countdown _doubleTapMinTimeCountdown;

  bool isWithinBounds(PointerEvent event, double bounds) {
    final offset = event.position - position;
    return offset.distance <= bounds;
  }

  bool hasElapsedMinTime() {
    return _doubleTapMinTimeCountdown.timeout;
  }

  bool hasSameButton(PointerDownEvent event) {
    return event.buttons == buttons;
  }
}

/// Tracks whether the specified duration has elapsed since creation.
class _Countdown {
  _Countdown({required Duration duration}) {
    Timer(duration, _onTimeout);
  }

  bool get timeout => _timeout;
  bool _timeout = false;

  void _onTimeout() => _timeout = true;
}
