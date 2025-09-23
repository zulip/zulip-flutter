import '../notifications/receive.dart';
import 'store.dart';

/// Manages telling the server this device's push token,
/// and tracking the server's responses on the status of push devices.
// TODO(#1764) do that tracking of responses
class PushDeviceManager extends PerAccountStoreBase {
  PushDeviceManager({required super.core}) {
    if (!debugAutoRegisterToken) {
      return;
    }
    registerToken();
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
  ///
  /// TODO The returned future isn't especially meaningful (it may or may not
  ///   mean we actually sent the token).  Make it just `void` once we fix the
  ///   one test that relies on the future.
  // TODO(#322) save acked token, to dedupe updating it on the server
  // TODO(#323) track the addFcmToken/etc request, warn if not succeeding
  Future<void> registerToken() async {
    NotificationService.instance.token.addListener(_registerToken);
    await _registerToken();
  }

  Future<void> _registerToken() async {
    // TODO it would be nice to register the token before even registerQueue:
    //   https://github.com/zulip/zulip-flutter/pull/325#discussion_r1365982807
    await NotificationService.instance.registerToken(connection);
  }

  /// In debug mode, controls whether [registerToken] should be called
  /// immediately in the constructor.
  ///
  /// Outside of debug mode, this is always true and the setter has no effect.
  static bool get debugAutoRegisterToken {
    bool result = true;
    assert(() {
      result = _debugAutoRegisterToken;
      return true;
    }());
    return result;
  }
  static bool _debugAutoRegisterToken = true;
  static set debugAutoRegisterToken(bool value) {
    assert(() {
      _debugAutoRegisterToken = value;
      return true;
    }());
  }
}
