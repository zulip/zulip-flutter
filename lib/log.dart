import 'package:flutter/material.dart';

import 'widgets/app.dart';

/// Whether [debugLog] should do anything.
///
/// This has an effect only in a debug build.
bool debugLogEnabled = false;

/// Used for log inspection in tests.
@visibleForTesting
List<String>? logHistory;

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
    logHistory?.add(message);
    return true;
  }());
  return true;
}

/// Display an error message.
///
/// This shows a [SnackBar] containing the message after app startup,
/// otherwise logs it to the console.
///
/// See also: [ZulipApp._reportErrorToUserBriefly]
void Function(String message) reportErrorToUserBriefly = _defaultReportErrorToUser;

/// Display an error message in a dialog.
///
/// This shows a dialog containing the message after app startup,
/// otherwise logs it to the console.
///
/// See also: [ZulipApp._reportErrorToUserBriefly]
void Function(String message) reportErrorToUserInDialog = _defaultReportErrorToUser;

void _defaultReportErrorToUser(String message) {
  // If this callback is still in place, then the app's widget tree
  // hasn't mounted yet even as far as the [Navigator].
  // So there's not much we can do to tell the user;
  // just log, in case the user is actually a developer watching the console.
  assert(debugLog(message));
}
