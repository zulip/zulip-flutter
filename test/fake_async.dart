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
  StackTrace? stackTrace;
  bool completed = false;
  FakeAsync(initialTime: initialTime)
    ..run((async) {
        callback(async).then<void>((v) { value = v; completed = true; },
          onError: (Object? e, StackTrace? s) { error = e; stackTrace = s; completed = true; });
      })
    ..flushTimers();

  // TODO: if the future returned by [callback] completes with an error,
  //   it would be good to throw that error immediately rather than finish
  //   flushing timers.  (This probably requires [FakeAsync] to have a richer
  //   API, like a `fireNextTimer` that does one iteration of `flushTimers`.)
  //
  //   In particular, if flushing timers later causes an uncaught exception, the
  //   current behavior is that that uncaught exception gets printed first
  //   (while `flushTimers` is running), and then only later (after
  //   `flushTimers` has returned control to this function) do we throw the
  //   error that the [callback] future completed with.  That's confusing
  //   because it causes the exceptions to appear in test output in an order
  //   that's misleading about what actually happened.

  if (!completed) {
    throw TimeoutException(
      'A callback passed to awaitFakeAsync returned a Future that '
      'did not complete even after calling FakeAsync.flushTimers.');
  } else if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  } else {
    return value;
  }
}
