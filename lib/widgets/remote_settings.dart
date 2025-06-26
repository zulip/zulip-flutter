import 'dart:async';

import 'package:flutter/material.dart';

import '../basic.dart';
import '../model/store.dart';
import 'store.dart';

/// A builder function for [RemoteSettingBuilder.builder]
/// that creates a toggle, or radio buttons, etc.
///
/// [value] is the value, whether from [RemoteSettingBuilder.findValueInStore]
/// or from local echo.
///
/// [handleRequestNewValue] calls [RemoteSettingBuilder.sendValueToServer]
/// and starts or extends a local-echo period.
/// If extending a local-echo period, it replaces the old local-echo value.
///
/// [handleRequestNewValue] may be called any time.
/// API requests are not debounced,
/// and the server may handle them out of order.
/// But the local echo minimizes flickering (see [localEchoMinimum])
/// while ensuring that the real in-store value is shown soon after the
/// user finishes interacting, whether the request(s) succeeded or failed.
typedef RemoteSettingBuilderFn<T> =
  Widget Function(T value, void Function(T) handleRequestNewValue);

/// A stateful builder widget for toggles/etc.
/// that control per-account settings on the server,
/// with time-bounded local echo.
///
/// Specify the setting with [findValueInStore] and [sendValueToServer].
///
/// [builder] should use its value and change-handler params
/// instead of calling the store and API directly.
///
/// When called, [builder]'s [RemoteSettingBuilderFn.handleRequestNewValue]
/// starts or extends a local-echo period.
/// During local echo, [builder] is passed the new value
/// instead of the value in the store.
/// Local echo will continue for at least [localEchoMinimum]
/// after the current call. After that, it may end
/// - because the [findValueInStore] value changed after this call
///   (i.e. the event arrived), or
/// - because [sendValueToServer] failed, or
/// - because [localEchoIdleTimeout] elapsed and there wasn't another call.
class RemoteSettingBuilder<T> extends StatefulWidget {
  const RemoteSettingBuilder({
    super.key,
    required this.findValueInStore,
    required this.sendValueToServer,
    this.onError,
    required this.builder,
  });

  final T Function(PerAccountStore) findValueInStore;
  final Future<void> Function(T) sendValueToServer;
  final void Function(Object? e, T requestedValue)? onError;
  final RemoteSettingBuilderFn<T> builder;

  /// The minimum time to spend in local echo,
  /// chosen to minimize flickers that are not caused by user input.
  ///
  /// The common case is when the API request fails quickly.
  ///
  /// (Another case is when spam-tapping a toggle switch,
  /// if a user wants to do that.
  /// The timer resets on [RemoteSettingBuilderFn.handleRequestNewValue],
  /// so until the spam-taps are finished, the switch responds only to the taps,
  /// not to the event stream.
  /// Then when the taps stop, it settles to the value from the latest event.)
  static final Duration localEchoMinimum = Duration(seconds: 1);

  static final Duration localEchoIdleTimeout = Duration(seconds: 3);

  @override
  State<RemoteSettingBuilder<T>> createState() => _RemoteSettingBuilderState();
}

class _RemoteSettingBuilderState<T> extends State<RemoteSettingBuilder<T>> with PerAccountStoreAwareStateMixin<RemoteSettingBuilder<T>> {
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
    } catch (e) { // TODO(log)
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
    final store = PerAccountStoreWidget.of(context);

    final value = _notifier.value.orElse(() => widget.findValueInStore(store));
    return widget.builder(value, _handleRequestNewValue);
  }
}

/// A [ValueNotifier] for whether local echo is active, and with what value.
///
/// The [ValueNotifier.value] is an [Option].
/// When it is [OptionSome], local echo is active with [OptionSome.value].
/// When it is [OptionNone], local echo is not active.
///
/// Use [startOrExtend] and [stop] to control local echo.
class _LocalEchoNotifier<T> extends ValueNotifier<Option<T>> {
  _LocalEchoNotifier() : super(OptionNone());

  Timer? _lowerBoundTimer;
  Completer<void>? _lowerBoundCompleter;
  Timer? _upperBoundTimer;

  /// Start a local-echo session or extend the timers of an existing session.
  void startOrExtend(T newValue) {
    value = OptionSome(newValue);

    _lowerBoundCompleter ??= Completer();
    _lowerBoundTimer?.cancel();
    _lowerBoundTimer = Timer(RemoteSettingBuilder.localEchoMinimum, () {
      _lowerBoundCompleter!.complete();
      _lowerBoundCompleter = null;
    });

    _upperBoundTimer?.cancel();
    _upperBoundTimer = Timer(RemoteSettingBuilder.localEchoIdleTimeout, () {
      value = OptionNone();
    });
  }

  /// Request that a local-echo session, if any, be stopped as soon as possible.
  ///
  /// The session will be stopped either immediately or
  /// [RemoteSettingBuilder.localEchoMinimum] after the last [startOrExtend] call,
  /// whichever is later.
  ///
  /// The returned [Future] resolves when the session is stopped.
  Future<void> stop() async {
    if (_lowerBoundCompleter != null) {
      await _lowerBoundCompleter!.future;
      if (_disposed) return;
    }
    value = OptionNone();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _lowerBoundCompleter?.complete();
    _lowerBoundTimer?.cancel();
    _upperBoundTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
