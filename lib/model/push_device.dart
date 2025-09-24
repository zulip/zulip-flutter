import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/route/notifications.dart';
import '../notifications/receive.dart';
import 'binding.dart';
import 'store.dart';

/// Manages telling the server this device's push token,
/// and tracking the server's responses on the status of push devices.
// TODO(#1764) do that tracking of responses
class PushDeviceManager extends PerAccountStoreBase {
  PushDeviceManager({required super.core}) {
    _registerTokenAndSubscribe();
  }

  bool _disposed = false;

  /// Cleans up resources and tells the instance not to make new API requests.
  ///
  /// After this is called, the instance is not in a usable state
  /// and should be abandoned.
  void dispose() {
    assert(!_disposed);
    NotificationService.instance.token.removeListener(_registerToken);
    _disposed = true;
  }

  /// Send this client's notification token to the server, now and if it changes.
  // TODO(#322) save acked token, to dedupe updating it on the server
  // TODO(#323) track the addFcmToken/etc request, warn if not succeeding
  // TODO it would be nice to register the token before even registerQueue:
  //   https://github.com/zulip/zulip-flutter/pull/325#discussion_r1365982807
  void _registerTokenAndSubscribe() async {
    _debugMaybePause();
    if (_debugRegisterTokenProceed != null) {
      await _debugRegisterTokenProceed!.future;
    }

    NotificationService.instance.token.addListener(_registerToken);
    await _registerToken();

    _debugRegisterTokenCompleted?.complete();
  }

  Completer<void>? _debugRegisterTokenProceed;
  Completer<void>? _debugRegisterTokenCompleted;

  void _debugMaybePause() {
    assert(() {
      if (debugAutoPause) {
        _debugRegisterTokenProceed = Completer();
        _debugRegisterTokenCompleted = Completer();
      }
      return true;
    }());
  }

  /// Unpause registering the token (after [debugAutoPause]),
  /// returning a future that completes when any immediate request is completed.
  ///
  /// This has no effect if [debugAutoPause] was false
  /// when this instance was constructed,
  /// and therefore no effect outside of debug mode.
  Future<void> debugUnpauseRegisterToken() async {
    _debugRegisterTokenProceed!.complete();
    await _debugRegisterTokenCompleted!.future;
  }

  /// In debug mode, controls whether new instances should pause
  /// before registering the token with the server.
  ///
  /// When paused, token registration can be unpaused
  /// with [debugUnpauseRegisterToken].
  ///
  /// Outside of debug mode, this is always false and the setter has no effect.
  static bool get debugAutoPause {
    bool result = false;
    assert(() {
      result = _debugAutoPause;
      return true;
    }());
    return result;
  }
  static bool _debugAutoPause = false;
  static set debugAutoPause(bool value) {
    assert(() {
      _debugAutoPause = value;
      return true;
    }());
  }

  Future<void> _registerToken() async {
    final token = NotificationService.instance.token.value;
    if (token == null) return;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await addFcmToken(connection, token: token);

      case TargetPlatform.iOS:
        final packageInfo = await ZulipBinding.instance.packageInfo;
        await addApnsToken(connection,
          token: token,
          appid: packageInfo!.packageName);

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        assert(false);
    }
  }
}
