import 'package:flutter/material.dart';

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

// TODO(i18n): title, message, and action-button text
void showErrorDialog({required BuildContext context, required String title, String? message}) {
  showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: message != null ? SingleChildScrollView(child: Text(message)) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: _dialogActionText('OK')),
        ]));
}
