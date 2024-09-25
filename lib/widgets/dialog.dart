import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

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

/// A wrapper providing access to the status of an [AlertDialog].
///
/// See also:
///  * [showDialog], whose return value this class is intended to wrap.
class DialogStatusController {
  const DialogStatusController(this._closed);

  /// Resolves when the dialog is closed.
  Future<void> get closed => _closed;
  final Future<void> _closed;
}

/// Displays an [AlertDialog] with a dismiss button.
///
/// Returns a [DialogStatusController]. Useful for checking if the dialog has
/// been closed.
// This API is inspired by [ScaffoldManager.showSnackBar].  We wrap
// [showDialog]'s return value, a [Future], inside [DialogStatusController]
// whose documentation can be accessed.  This helps avoid confusion when
// intepreting the meaning of the [Future].
DialogStatusController showErrorDialog({
  required BuildContext context,
  required String title,
  String? message,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  final future = showDialog<void>(
    context: context,
    builder: (BuildContext context) => SingleChildScrollView(
      child: AlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: _dialogActionText(zulipLocalizations.errorDialogContinue)),
        ])));
  return DialogStatusController(future);
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
          onPressed: onActionButtonPress,
          child: _dialogActionText(actionButtonText ?? zulipLocalizations.dialogContinue)),
      ]));
}
