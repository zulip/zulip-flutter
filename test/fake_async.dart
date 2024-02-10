import 'dart:async';

import 'package:fake_async/fake_async.dart';

/// Run [callback] to completion in a [Zone] where all asynchrony is
/// controlled by an instance of [FakeAsync].
///
/// See [FakeAsync.run] for details on what it means that all asynchrony is
/// controlled by an instance of [FakeAsync].
///
/// After calling [callback], this function uses [FakeAsync.flushTimers] to
/// advance the computation started by [callback], and then expects the
/// [Future] that was returned by [callback] to have completed.
///
/// If that future completed with a value, that value is returned.
/// If it completed with an error, that error is thrown.
/// If it hasn't completed, a [TimeoutException] is thrown.
T awaitFakeAsync<T>(Future<T> Function(FakeAsync async) callback,
    {DateTime? initialTime}) {
  late final T value;
  Object? error;
  bool completed = false;
  FakeAsync(initialTime: initialTime)
    ..run((async) {
        callback(async).then<void>((v) { value = v; completed = true; })
                       .catchError((e) { error = e; completed = true; });
      })
    ..flushTimers();

  if (!completed) {
    throw TimeoutException(
      'A callback passed to awaitFakeAsync returned a Future that '
      'did not complete even after calling FakeAsync.flushTimers.');
  } else if (error != null) {
    throw error!;
  } else {
    return value;
  }
}
