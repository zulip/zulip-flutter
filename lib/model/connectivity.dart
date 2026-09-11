import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../log.dart';
import 'binding.dart';

/// Watches the device's network connectivity,
/// for signs that connections in use may have silently gone dead.
///
/// The main way a connection dies with neither end closing it
/// is a network change: the device moves from Wi-Fi to cellular, say.
/// On such a change, a consumer will want to give up on
/// connections it opened before the change,
/// and retry on the new network.
///
/// To do that, a consumer records [updateCount]
/// when it opens a connection, and listens on [retrySignals].
/// On an event, if [updateCount] has moved
/// since the connection was opened,
/// the network may have changed under it:
/// give up on the connection and retry.
/// (A change impeaches only connections that predate it;
/// a connection opened after the change
/// already uses the post-change network.)
class ConnectivityMonitor {
  ConnectivityMonitor() {
    _connectivitySubscription = ZulipBinding.instance.connectivityChanges
      .listen(_handleConnectivityUpdate,
        onError: (Object e) {
          // Connectivity-triggered retries are an optimization; without
          // them, consumers still recover via their own timeouts.
          assert(debugLog('Error on connectivity stream: $e')); // TODO(log)
        });
    _lifecycleSubscription = ZulipBinding.instance.appLifecycleStateChanges
      .listen(_handleAppLifecycleStateChange);
    // Establish a baseline, so that a subsequent update can be recognized
    // as an actual change.  (The stream may or may not send the current
    // state as its first event; asking directly works either way.)
    // Not awaited: nothing needs to wait for this,
    // and a change that lands first simply becomes the baseline.
    unawaited(_recheckConnectivity());
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  /// The device's network connectivity, per the latest update we've seen,
  /// or null if we haven't seen one yet.
  Set<ConnectivityResult>? _lastResults;

  /// The number of connectivity updates recorded so far,
  /// the first of them being a baseline rather than a change.
  ///
  /// A consumer of [retrySignals] records this value
  /// when opening a connection,
  /// to recognize later whether the network may have changed under it;
  /// see the class doc.
  int get updateCount => _updateCount;
  int _updateCount = 0;

  /// Counter guarding [_recheckConnectivity] results against staleness.
  ///
  /// Advances on every update handled (even one recording no change)
  /// and at the start of every recheck,
  /// so that a recheck's result is used
  /// only if nothing fresher could have arrived meanwhile.
  int _updateEpoch = 0;

  /// A paced signal to give up on connections
  /// that predate the latest network change,
  /// and retry on the current network.
  ///
  /// An event is emitted when the network changes,
  /// to a state with connectivity --
  /// but at most one per [retrySignalCooldown]:
  /// when connectivity flaps rapidly
  /// (repeated handoffs in a moving vehicle, say),
  /// signaling every change would mean
  /// consumers retrying at the flapping rate.
  /// A change during the cooldown is still recorded immediately
  /// (see [updateCount]), and is signaled when the cooldown ends.
  Stream<void> get retrySignals => _retrySignalsController.stream;
  final _retrySignalsController = StreamController<void>.broadcast();

  /// The floor on the spacing of [retrySignals] events.
  static const retrySignalCooldown = Duration(seconds: 10);

  // A timer, rather than a comparison of wall-clock timestamps, so that
  // a clock step -- as when NTP corrects the clock just after a network
  // change -- cannot distort the cooldown.
  Timer? _cooldownTimer;

  /// Whether a change was recorded while [_cooldownTimer] was running,
  /// so that a retry signal is due when the cooldown ends.
  bool _retrySignalDeferred = false;

  /// Handle an update on the device's network connectivity,
  /// from [ZulipBinding.connectivityChanges] or [_recheckConnectivity].
  void _handleConnectivityUpdate(List<ConnectivityResult> result) {
    assert(!_disposed); // The subscription is canceled in [dispose].
    _updateEpoch++;
    // The list is the active network's transports, in the plugin's
    // fixed check order; the order carries no meaning, so compare as sets.
    final resultSet = result.toSet();
    final previous = _lastResults;
    if (setEquals(previous, resultSet)) return;
    _lastResults = resultSet;
    _updateCount++;
    if (previous == null) return; // Just a baseline, not a change.
    if (resultSet.contains(ConnectivityResult.none)) {
      // With no connectivity, a retry cannot succeed.  Signal nothing,
      // and act when connectivity comes back.
      return;
    }
    if (_cooldownTimer != null) {
      // Connectivity is flapping; don't signal every change.
      _retrySignalDeferred = true;
      return;
    }
    _emitRetrySignal();
  }

  /// Emit a [retrySignals] event, and start the cooldown;
  /// when the cooldown ends, emit again if a change was deferred to then.
  void _emitRetrySignal() {
    _cooldownTimer = Timer(retrySignalCooldown, () {
      _cooldownTimer = null;
      if (!_retrySignalDeferred) return;
      _retrySignalDeferred = false;
      if (_lastResults!.contains(ConnectivityResult.none)) return;
      _emitRetrySignal();
    });
    _retrySignalsController.add(null);
  }

  /// Fetch the current connectivity state, and handle it
  /// like an update from [ZulipBinding.connectivityChanges],
  /// unless a newer update arrives first.
  Future<void> _recheckConnectivity() async {
    final epochBefore = ++_updateEpoch;
    final List<ConnectivityResult> result;
    try {
      result = await ZulipBinding.instance.checkConnectivity();
    } catch (e) { // TODO(log)
      assert(debugLog('Error in checkConnectivity: $e'));
      return;
    }
    if (_disposed) return;
    if (_updateEpoch != epochBefore) {
      // An update arrived, or a newer recheck began, while we were checking.
      // Ours is a snapshot from before that, so may be stale; discard it.
      return;
    }
    _handleConnectivityUpdate(result);
  }

  void _handleAppLifecycleStateChange(AppLifecycleState state) {
    assert(!_disposed); // The subscription is canceled in [dispose].
    if (state != .resumed) return;
    // Connectivity updates can be dropped while the app is in the
    // background, rather than delivered on returning to the foreground
    // (see [ZulipBinding.connectivityChanges]).  So check whether the
    // network changed while we were away.
    unawaited(_recheckConnectivity());
  }

  bool _disposed = false;

  void dispose() {
    assert(!_disposed);
    _connectivitySubscription?.cancel();
    _lifecycleSubscription?.cancel();
    _cooldownTimer?.cancel();
    _retrySignalsController.close();
    _disposed = true;
  }
}
