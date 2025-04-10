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
/// See also:
///  * [showDialog], whose return value this class is intended to wrap.
class DialogStatus<T> {
  const DialogStatus(this.closed);

  /// Resolves when the dialog is closed.
  final Future<T?> closed;
}

/// Displays an [AlertDialog] with a dismiss button
/// and optional "Learn more" button.
///
/// The [DialogStatus.closed] field of the return value can be used
/// for waiting for the dialog to be closed.
// This API is inspired by [ScaffoldManager.showSnackBar].  We wrap
// [showDialog]'s return value, a [Future], inside [DialogStatus]
// whose documentation can be accessed.  This helps avoid confusion when
// intepreting the meaning of the [Future].
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

DialogStatus<SuggestedActionDialogResult> showSuggestedActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String? actionButtonText,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  final future = showDialog<SuggestedActionDialogResult>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<SuggestedActionDialogResult>(context,
            SuggestedActionDialogResult.cancel),
          child: _dialogActionText(zulipLocalizations.dialogCancel)),
        TextButton(
          onPressed: () => Navigator.pop<SuggestedActionDialogResult>(context,
            SuggestedActionDialogResult.doAction),
          child: _dialogActionText(actionButtonText ?? zulipLocalizations.dialogContinue)),
      ]));
  return DialogStatus(future);
}

enum SuggestedActionDialogResult {
  cancel,
  doAction,
}
