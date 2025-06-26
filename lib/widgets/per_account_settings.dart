import 'dart:async';

import 'package:flutter/material.dart';

import '../model/store.dart';
import 'store.dart';

typedef PerAccountSettingBuilderFn<T> = Widget Function(
  /// The value, whether from [PerAccountSettingBuilder.findValueInStore]
  /// or from local echo.
  T value,

  /// Calls [PerAccountSettingBuilder.sendValueToServer]
  /// and starts or extends a local-echo period.
  ///
  /// If extending a local-echo period, replaces the old local-echo value.
  ///
  /// This may be called any time. API requests are not debounced,
  /// and the server may handle them out of order.
  /// But the local echo minimizes flickering (see [localEchoMininum])
  /// while ensuring that the real in-store value is shown soon after the
  /// user finishes interacting, whether the request(s) succeeded or failed.
  void Function(T) handleRequestNewValue,
);

/// A stateful builder widget for toggles/etc.
/// that control per-account settings on the server,
/// with time-bounded local echo.
///
/// Specify the setting with [findValueInStore] and [sendValueToServer].
///
/// [builder] should use its value and change-handler params
/// instead of calling the store and API directly.
///
/// When called, [builder]'s [PerAccountSettingBuilderFn.handleRequestNewValue]
/// starts or extends a local-echo period.
/// During local echo, [builder] is passed the new value
/// instead of the value in the store.
/// Local echo will continue for at least [localEchoMininum]
/// after the current call. After that, it may end
/// - because the [findValueInStore] value changed after this call
///   (i.e. the event arrived), or
/// - because [sendValueToServer] failed, or
/// - because [localEchoIdleTimeout] elapsed and there wasn't another call.
class PerAccountSettingBuilder<T> extends StatefulWidget {
  const PerAccountSettingBuilder({
    super.key,
    required this.findValueInStore,
    required this.sendValueToServer,
    this.onError,
    required this.builder,
  });

  final T Function(PerAccountStore) findValueInStore;
  final Future<void> Function(T) sendValueToServer;
  final void Function(Object? e, T requestedValue)? onError;
  final PerAccountSettingBuilderFn<T> builder;

  /// The minimum time to spend in local echo,
  /// chosen to minimize flickers that are not caused by user input.
  ///
  /// The common case is when the API request fails quickly.
  ///
  /// (Another case is when spam-tapping a toggle switch,
  /// if a user wants to do that.
  /// The timer resets on [PerAccountSettingBuilderFn.handleRequestNewValue],
  /// so until the spam-taps are finished, the switch responds only to the taps,
  /// not to the event stream.
  /// Then when the taps stop, it settles to the value from the latest event.)
  static final Duration localEchoMininum = Duration(seconds: 1);

  static final Duration localEchoIdleTimeout = Duration(seconds: 3);

  @override
  State<PerAccountSettingBuilder<T>> createState() => _PerAccountSettingBuilderState();
}

class _PerAccountSettingBuilderState<T> extends State<PerAccountSettingBuilder<T>> with PerAccountStoreAwareStateMixin<PerAccountSettingBuilder<T>> {
  final _LocalEchoNotifier<T> _notifier = _LocalEchoNotifier();

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_notifierChanged);
  }

  late T? _prevValueFromStore;

  @override
  void onNewStore() {
    _prevValueFromStore = widget.findValueInStore(PerAccountStoreWidget.of(context));
    _notifier.stop();
  }

  @override
  void didChangeDependencies() {
    // On the first call, this sets _prevValueFromStore, via onNewStore.
    super.didChangeDependencies();

    final value = widget.findValueInStore(PerAccountStoreWidget.of(context));
    if (value != _prevValueFromStore) {
      _notifier.stop();
      _prevValueFromStore = value;
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _notifier.dispose();
    _disposed = true;
    super.dispose();
  }

  void _notifierChanged() {
    setState(() {
      // The actual state lives in _notifier.
    });
  }

  void _handleRequestNewValue(T value) async {
    _notifier.startOrExtend(value);

    try {
      await widget.sendValueToServer(value);
      if (_disposed) return;
      // Don't call _notifier.stop(). We do that when the event arrives,
      // causing the in-store value to change (see didChangeDependencies).
    } catch (e) {
      if (_disposed) return;
      await _notifier.stop();
      if (_disposed) return;
      if (widget.onError != null) {
        widget.onError!(e, value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Create the PerAccountStoreWidget dependency unconditionally.)
    final store = PerAccountStoreWidget.of(context);

    final value = switch (_notifier.value) {
      _LocalEchoValue<T>(:final value) => value,
      null => widget.findValueInStore(store),
    };

    return widget.builder(value, _handleRequestNewValue);
  }
}

class _LocalEchoNotifier<T> extends ValueNotifier<_LocalEchoValue<T>?> {
  factory _LocalEchoNotifier() {
    return _LocalEchoNotifier._(null);
  }

  _LocalEchoNotifier._(super.value);

  Timer? _lowerBoundTimer;
  Completer<void>? _lowerBoundCompleter;
  Timer? _upperBoundTimer;

  void startOrExtend(T newValue) {
    value = _LocalEchoValue(newValue);

    _lowerBoundCompleter ??= Completer();
    _lowerBoundTimer?.cancel();
    _lowerBoundTimer = Timer(PerAccountSettingBuilder.localEchoMininum, () {
      _lowerBoundCompleter!.complete();
      _lowerBoundCompleter = null;
    });

    _upperBoundTimer?.cancel();
    _upperBoundTimer = Timer(PerAccountSettingBuilder.localEchoIdleTimeout, () {
      value = null;
    });

  }

  Future<void> stop() async {
    if (_lowerBoundCompleter != null) {
      await _lowerBoundCompleter!.future;
      if (_disposed) return;
    }
    value = null;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _lowerBoundTimer?.cancel();
    _upperBoundTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}

/// A local-echo value.
///
/// May be null, subject to [T].
/// ("No local echo value" is represented by the absence of one of these.)
class _LocalEchoValue<T> {
  const _LocalEchoValue(this.value);
  final T value;

  @override
  bool operator ==(Object other) {
    if (other is! _LocalEchoValue<T>) return false;
    return value == other.value;
  }

  @override
  int get hashCode => Object.hash('_LocalEchoValue', value);
}
