import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'actions.dart';

Widget _dialogActionText(String text) {
  return Text(
    text,

    // As suggested by
    //   https://api.flutter.dev/flutter/material/AlertDialog/actions.html :
    // > It is recommended to set the Text.textAlign to TextAlign.end
    // > for the Text within the TextButton, so that buttons whose
    // > labels wrap to an extra line align with the overall
    // > OverflowBar's alignment within the dialog.
    textAlign: TextAlign.end,
  );
}

/// Tracks the status of a dialog, in being still open or already closed.
///
/// Use [T] to identify the outcome of the interaction:
/// - Pass `void` for an informational dialog with just the option to dismiss.
/// - For confirmation dialogs with an option to dismiss
///   plus an option to proceed with an action, pass `bool`.
///   The action button should pass true for Navigator.pop's `result` argument.
/// - For dialogs with an option to dismiss plus multiple other options,
///   pass a custom enum.
/// For the latter two cases, a cancel button should call Navigator.pop
/// with null for the `result` argument, to match what Flutter does
/// when you dismiss the dialog by tapping outside its area.
///
/// See also:
///  * [showDialog], whose return value this class is intended to wrap.
class DialogStatus<T> {
  const DialogStatus(this.result);

  /// Resolves when the dialog is closed.
  ///
  /// If this completes with null, the dialog was dismissed.
  /// Otherwise, completes with a [T] identifying the interaction's outcome.
  ///
  /// See, e.g., [showSuggestedActionDialog].
  final Future<T?> result;
}

/// Displays an [AlertDialog] with a dismiss button
/// and optional "Learn more" button.
///
/// The [DialogStatus.result] field of the return value can be used
/// for waiting for the dialog to be closed.
///
/// The context argument is used to look up the [Navigator] for the dialog.
// This API is inspired by [ScaffoldManager.showSnackBar].  We wrap
// [showDialog]'s return value, a [Future], inside [DialogStatus]
// whose documentation can be accessed.  This helps avoid confusion when
// interpreting the meaning of the [Future].
DialogStatus<void> showErrorDialog({
  required BuildContext context,
  required String title,
  String? message,
  Uri? learnMoreButtonUrl,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  final future = showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: message != null ? SingleChildScrollView(child: Text(message)) : null,
      actions: [
        if (learnMoreButtonUrl != null)
          TextButton(
            onPressed: () => PlatformActions.launchUrl(context, learnMoreButtonUrl),
            child: _dialogActionText(zulipLocalizations.errorDialogLearnMore)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: _dialogActionText(zulipLocalizations.errorDialogContinue)),
      ]));
  return DialogStatus(future);
}

/// Displays an alert dialog with a cancel button and an action button.
///
/// The [DialogStatus.result] Future gives true if the action button was tapped.
/// If the dialog was canceled,
/// either with the cancel button or by tapping outside the dialog's area,
/// it completes with null.
///
/// The context argument is used to look up the [Navigator] for the dialog.
DialogStatus<bool> showSuggestedActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String? actionButtonText,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  final future = showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<bool>(context, null),
          child: _dialogActionText(zulipLocalizations.dialogCancel)),
        TextButton(
          onPressed: () => Navigator.pop<bool>(context, true),
          child: _dialogActionText(actionButtonText ?? zulipLocalizations.dialogContinue)),
      ]));
  return DialogStatus(future);
}
