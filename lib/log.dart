
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

typedef ReportErrorCallback = void Function(String? message, {String? details});

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
// This gets set in [ZulipApp].  We need this indirection to keep `lib/log.dart`
// from importing widget code, because the file is a dependency for the rest of
// the app.
ReportErrorCallback reportErrorToUserBriefly = defaultReportErrorToUserBriefly;

void defaultReportErrorToUserBriefly(String? message, {String? details}) {
  // Error dismissing is a no-op to the default handler.
  if (message == null) return;
  // If this callback is still in place, then the app's widget tree
  // hasn't mounted yet even as far as the [Navigator].
  // So there's not much we can do to tell the user;
  // just log, in case the user is actually a developer watching the console.
  assert(debugLog(message));
  if (details != null) assert(debugLog(details));
}
