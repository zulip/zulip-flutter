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

/// Displays an [AlertDialog] with a dismiss button.
///
/// Returns a [Future] that resolves when the dialog is closed.
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  String? message,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: message != null ? SingleChildScrollView(child: Text(message)) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: _dialogActionText(zulipLocalizations.errorDialogContinue)),
      ]));
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
