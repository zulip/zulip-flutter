
import 'package:flutter/foundation.dart';

/// Whether [debugLog] should do anything.
///
/// This has an effect only in a debug build.
bool debugLogEnabled = false;

/// Print a log message, if debug logging is enabled.
///
/// In a debug build, if [debugLogEnabled] is true, this prints the given
/// message to the log.  Otherwise it does nothing.
///
/// Typically we set [debugLogEnabled] so that this will print when running
/// the app in a debug build, but not when running tests.
///
/// Call sites of this function should be enclosed in `assert` expressions, so
/// that any interpolation to construct the message happens only in debug mode.
/// To help make that convenient, this function always returns true.
///
/// Example usage:
/// ```dart
///   assert(debugLog("Got frobnitz: $frobnitz"));
/// ```
bool debugLog(String message) {
  assert(() {
    // TODO(log): make it convenient to enable these logs in tests for debugging a failing test
    if (debugLogEnabled) {
      print(message); // ignore: avoid_print
    }
    return true;
  }());
  return true;
}

/// Print a piece of profiling data.
///
/// This should be called only in profile mode:
///  * In debug mode, any profiling results will be misleading.
///  * In release mode, we should avoid doing the computation to even produce
///    the [message] argument.
///
/// As a reminder of that, this function will throw in debug mode.
///
/// Example usage:
/// ```dart
///   final stopwatch = Stopwatch()..start();
///   final data = await someSlowOperation();
///   if (kProfileMode) {
///     final t = stopwatch.elapsed;
///     profilePrint("some-operation time: ${t.inMilliseconds}ms");
///   }
/// ```
void profilePrint(String message) {
  assert(kProfileMode, 'Use profilePrint only within `if (kProfileMode)`.');
  if (kReleaseMode) return;
  print(message); // ignore: avoid_print
}

// This should only be used for error reporting functions that allow the error
// to be cancelled programmatically.  The implementation is expected to handle
// `null` for the `message` parameter and promptly dismiss the reported errors.
typedef ReportErrorCancellablyCallback = void Function(String? message, {String? details});

typedef ReportErrorCallback = void Function(
  String title, {
  String? message,
  Uri? learnMoreButtonUrl,
});

/// Show the user an error message, without requiring them to interact with it.
///
/// Typically this shows a [SnackBar] containing the message.
/// If called before the app's widget tree is ready (see [ZulipApp.ready]),
/// then we give up on showing the message to the user,
/// and just log the message to the console.
///
/// If `message` is null, this will clear the existing [SnackBar]s if there
/// are any.  Useful for promptly dismissing errors.
///
/// If `details` is non-null, the [SnackBar] will contain a button that would
/// open a dialog containing the error details.
/// Prose in `details` should have final punctuation.
// This gets set in [ZulipApp].  We need this indirection to keep `lib/log.dart`
// from importing widget code, because the file is a dependency for the rest of
// the app.
ReportErrorCancellablyCallback reportErrorToUserBriefly = defaultReportErrorToUserBriefly;

/// Show the user a dismissable error message in a modal popup.
///
/// Typically this shows an [AlertDialog] with `title` as the title, `message`
/// as the body.  If called before the app's widget tree is ready
/// (see [ZulipApp.ready]), then we give up on showing the message to the user,
/// and just log the message to the console.
///
/// Prose in `message` should have final punctuation.
// This gets set in [ZulipApp].  We need this indirection to keep `lib/log.dart`
// from importing widget code, because the file is a dependency for the rest of
// the app.
ReportErrorCallback reportErrorToUserModally = defaultReportErrorToUserModally;

void defaultReportErrorToUserBriefly(String? message, {String? details}) {
  _reportErrorToConsole(message, details);
}

void defaultReportErrorToUserModally(
  String title, {
  String? message,
  Uri? learnMoreButtonUrl,
}) {
  _reportErrorToConsole(title, message);
}

void _reportErrorToConsole(String? message, String? details) {
  // Error dismissing is a no-op for the console.
  if (message == null) return;
  // If this callback is still in place, then the app's widget tree
  // hasn't mounted yet even as far as the [Navigator].
  // So there's not much we can do to tell the user;
  // just log, in case the user is actually a developer watching the console.
  assert(debugLog(message));
  if (details != null) assert(debugLog(details));
}
