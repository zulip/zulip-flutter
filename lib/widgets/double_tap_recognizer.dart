// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the docs/THIRDPARTY file.

import 'dart:async';

import 'package:flutter/gestures.dart';

// Copied from the upstream Flutter repo, but adjusted to not participate
// in the gesture arena.
//   https://github.com/flutter/flutter/blob/ab7eb7aff/packages/flutter/lib/src/gestures/multitap.dart#L49-L382

/// Recognizes when the user has tapped the screen at the same location twice in
/// quick succession, without participating in the gesture arena.
///
/// This class is meant to be used in conjunction with a class that can receive
/// a [PointerDownEvent], such as [Listener] or [HitTestTarget]. To detect a
/// double tap, set [onDoubleTap]. Then, whenever the other class receives a
/// [PointerDownEvent], call [addPointer].
///
/// ```
///   final doubleTapRecognizer = DoubleTapRecognizer()
///     ..onDoubleTap = () {
///       // double tap detected
///     };
///   if (event is PointerDownEvent) {
///     doubleTapRecognizer.addPointer(event);
///   }
/// ```
///
/// Whenever a valid double tap is detected, [onDoubleTap] is called.
//
// TODO(upstream): Delete this class if Flutter gains a way to detect
//   double taps without delaying single taps:
//     https://github.com/flutter/flutter/issues/106170
//     https://github.com/flutter/flutter/issues/110300
class DoubleTapRecognizer {
  /// Create a recognizer for double taps that doesn't participate
  /// in the gesture arena.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  DoubleTapRecognizer({
    this.supportedDevices,
    this.allowedButtonsFilter = _defaultButtonAcceptBehavior,
  });

  // Implementation notes:
  //
  // The double tap recognizer can be in one of four states. There's no
  // explicit enum for the states, because they are already captured by
  // the state of existing fields. Specifically:
  //
  // 1. Waiting on first tap: In this state, the _trackers list is empty, and
  //    _firstTap is null.
  // 2. First tap in progress: In this state, the _trackers list contains all
  //    the states for taps that have begun but not completed. This list can
  //    have more than one entry if two pointers begin to tap.
  // 3. Waiting on second tap: In this state, one of the in-progress taps has
  //    completed successfully. The _trackers list is again empty, and
  //    _firstTap records the successful tap.
  // 4. Second tap in progress: Much like the "first tap in progress" state, but
  //    _firstTap is non-null. If a tap completes successfully while in this
  //    state, the callback is called and the state is reset.
  //
  // There are various other scenarios that cause the state to reset:
  //
  // - All in-progress taps are rejected (by time, distance, pointercancel, etc)
  // - The long timer between taps expires

  /// The kind of devices that are allowed to be recognized as provided by
  /// `supportedDevices` in the constructor, or the currently deprecated `kind`.
  /// These cannot both be set. If both are null, events from all device kinds will be
  /// tracked and recognized.
  Set<PointerDeviceKind>? supportedDevices;

  /// {@template flutter.gestures.multidrag._allowedButtonsFilter}
  /// Called when interaction starts. This limits the dragging behavior
  /// for custom clicks (such as scroll click). Its parameter comes
  /// from [PointerEvent.buttons].
  ///
  /// Due to how [kPrimaryButton], [kSecondaryButton], etc., use integers,
  /// bitwise operations can help filter how buttons are pressed.
  /// For example, if someone simultaneously presses the primary and secondary
  /// buttons, the default behavior will return false. The following code
  /// accepts any button press with primary:
  /// `(int buttons) => buttons & kPrimaryButton != 0`.
  ///
  /// When value is `(int buttons) => false`, allow no interactions.
  /// When value is `(int buttons) => true`, allow all interactions.
  ///
  /// Defaults to all buttons.
  /// {@endtemplate}
  final AllowedButtonsFilter allowedButtonsFilter;

  /// Called when the user has tapped the screen with a primary button at the
  /// same location twice in quick succession.
  ///
  /// This triggers when the pointer stops contacting the device after the
  /// second tap.
  ///
  /// See also:
  ///
  ///  * [allowedButtonsFilter], which decides which button will be allowed.
  GestureDoubleTapCallback? onDoubleTap;

  // The default value for [allowedButtonsFilter].
  // Accept the input if, and only if, [kPrimaryButton] is pressed.
  static bool _defaultButtonAcceptBehavior(int buttons) => buttons == kPrimaryButton;

  Timer? _doubleTapTimer;
  _TapTracker? _firstTap;
  final _trackers = <int, _TapTracker>{};

  void addPointer(PointerDownEvent event) {
    if (!isPointerAllowed(event)) return;
    addAllowedPointer(event);
  }

  bool isPointerAllowed(PointerDownEvent event) {
    if (_firstTap == null && onDoubleTap == null) {
      return false;
    }

    // If second tap is not allowed, reset the state.
    final isPointerAllowed = (supportedDevices?.contains(event.kind) ?? true)
      && allowedButtonsFilter(event.buttons);
    if (!isPointerAllowed) {
      _reset();
    }
    return isPointerAllowed;
  }

  void addAllowedPointer(PointerDownEvent event) {
    if (_firstTap != null) {
      if (!_firstTap!.isWithinGlobalTolerance(event, kDoubleTapSlop)) {
        // Ignore out-of-bounds second taps.
        return;
      } else if (!_firstTap!.hasElapsedMinTime() || !_firstTap!.hasSameButton(event)) {
        // Restart when the second tap is too close to the first (touch screens
        // often detect touches intermittently), or when buttons mismatch.
        _reset();
        return _trackTap(event);
      }
    }
    _trackTap(event);
  }

  void _trackTap(PointerDownEvent event) {
    _stopDoubleTapTimer();
    final tracker = _TapTracker(event);
    _trackers[event.pointer] = tracker;
    tracker.startTrackingPointer(_handleEvent, event.transform);
  }

  void _handleEvent(PointerEvent event) {
    final tracker = _trackers[event.pointer]!;
    if (event is PointerUpEvent) {
      if (_firstTap == null) {
        _registerFirstTap(tracker);
      } else {
        _registerSecondTap(tracker);
      }
    } else if (event is PointerMoveEvent) {
      if (!tracker.isWithinGlobalTolerance(event, kDoubleTapTouchSlop)) {
        _reject(tracker);
      }
    } else if (event is PointerCancelEvent) {
      _reject(tracker);
    }
  }

  void _reject(_TapTracker tracker) {
    _trackers.remove(tracker.pointer);
    tracker.cancelCountdown();
    _freezeTracker(tracker);
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

  void dispose() {
    _reset();
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

  void _registerFirstTap(_TapTracker tracker) {
    _startDoubleTapTimer();
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    _clearTrackers();
    _firstTap = tracker;
  }

  void _registerSecondTap(_TapTracker tracker) {
    _freezeTracker(tracker);
    _trackers.remove(tracker.pointer);
    tracker.cancelCountdown();
    onDoubleTap?.call();
    _reset();
  }

  void _clearTrackers() {
    _trackers.values.toList().forEach(_reject);
    assert(_trackers.isEmpty);
  }

  void _freezeTracker(_TapTracker tracker) {
    tracker.stopTrackingPointer(_handleEvent);
  }

  void _startDoubleTapTimer() {
    _doubleTapTimer ??= Timer(kDoubleTapTimeout, _reset);
  }

  void _stopDoubleTapTimer() {
    if (_doubleTapTimer != null) {
      _doubleTapTimer!.cancel();
      _doubleTapTimer = null;
    }
  }
}

/// TapTracker helps track individual tap sequences as part of a
/// larger gesture.
class _TapTracker {
  _TapTracker(PointerDownEvent event)
    : pointer = event.pointer,
      _initialGlobalPosition = event.position,
      initialButtons = event.buttons,
      _doubleTapMinTimeCountdown = _CountdownZoned(duration: kDoubleTapMinTime);

  final int pointer;
  final Offset _initialGlobalPosition;
  final int initialButtons;
  final _CountdownZoned _doubleTapMinTimeCountdown;

  bool _isTrackingPointer = false;

  void startTrackingPointer(PointerRoute route, Matrix4? transform) {
    if (!_isTrackingPointer) {
      _isTrackingPointer = true;
      GestureBinding.instance.pointerRouter.addRoute(pointer, route, transform);
    }
  }

  void stopTrackingPointer(PointerRoute route) {
    if (_isTrackingPointer) {
      _isTrackingPointer = false;
      GestureBinding.instance.pointerRouter.removeRoute(pointer, route);
    }
  }

  bool isWithinGlobalTolerance(PointerEvent event, double tolerance) {
    final offset = event.position - _initialGlobalPosition;
    return offset.distance <= tolerance;
  }

  bool hasElapsedMinTime() => _doubleTapMinTimeCountdown.timeout;

  bool hasSameButton(PointerDownEvent event) => event.buttons == initialButtons;

  void cancelCountdown() => _doubleTapMinTimeCountdown.cancel();
}

/// CountdownZoned tracks whether the specified duration has elapsed since
/// creation, honoring [Zone].
class _CountdownZoned {
  _CountdownZoned({required Duration duration})
    : _timer = Timer(duration, () {});

  final Timer _timer;

  bool get timeout => !_timer.isActive;

  void cancel() => _timer.cancel();
}
