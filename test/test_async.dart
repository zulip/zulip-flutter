import 'package:test_api/hooks.dart';

/// Ensure the test runner will wait for the given future to complete
/// before considering the current test complete.
///
/// Consider using this function, instead of `await`, when a test invokes
/// a check which is asynchronous and has no interaction with other tasks
/// the test will do later.
///
/// Use `await`, instead of this function, when it matters what order the
/// rest of the test's logic runs in relative to the asynchronous work
/// represented by the given future.  In particular, when calling a function
/// that performs setup for later logic in the test, the returned future
/// should always be awaited.
void finish(Future<void> future) {
  final outstandingWork = TestHandle.current.markPending();
  future.whenComplete(outstandingWork.complete);
}
