import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';

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
class DialogStatus {
  const DialogStatus(this.closed);

  /// Resolves when the dialog is closed.
  final Future<void> closed;
}

/// Displays an [AlertDialog] with a dismiss button.
///
/// The [DialogStatus.closed] field of the return value can be used
/// for waiting for the dialog to be closed.
// This API is inspired by [ScaffoldManager.showSnackBar].  We wrap
// [showDialog]'s return value, a [Future], inside [DialogStatus]
// whose documentation can be accessed.  This helps avoid confusion when
// intepreting the meaning of the [Future].
DialogStatus showErrorDialog({
  required BuildContext context,
  required String title,
  String? message,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  final future = showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: message != null ? SingleChildScrollView(child: Text(message)) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: _dialogActionText(zulipLocalizations.errorDialogContinue)),
      ]));
  return DialogStatus(future);
}

void showSuggestedActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String? actionButtonText,
  required VoidCallback onActionButtonPress,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: _dialogActionText(zulipLocalizations.dialogCancel)),
        TextButton(
          onPressed: () {
            onActionButtonPress();
            Navigator.pop(context);
          },
          child: _dialogActionText(actionButtonText ?? zulipLocalizations.dialogContinue)),
      ]));
}
