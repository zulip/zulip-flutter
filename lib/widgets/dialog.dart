import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import 'actions.dart';

Widget _materialDialogActionText(String text) {
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

/// A platform-appropriate action for [AlertDialog.adaptive]'s [actions] param.
Widget _adaptiveAction({required VoidCallback onPressed, required String text}) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return TextButton(onPressed: onPressed, child: _materialDialogActionText(text));
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoDialogAction(onPressed: onPressed, child: Text(text));
  }
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

/// Displays an [AlertDialog] with a dismiss button
/// and optional "Learn more" button.
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
  Uri? learnMoreButtonUrl,
}) {
  final zulipLocalizations = ZulipLocalizations.of(context);
  final future = showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog.adaptive(
      title: Text(title),
      content: message != null ? SingleChildScrollView(child: Text(message)) : null,
      actions: [
        if (learnMoreButtonUrl != null)
          _adaptiveAction(
            onPressed: () => PlatformActions.launchUrl(context, learnMoreButtonUrl),
            text: zulipLocalizations.errorDialogLearnMore,
          ),
        _adaptiveAction(
          onPressed: () => Navigator.pop(context),
          text: zulipLocalizations.errorDialogContinue),
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
    builder: (BuildContext context) => AlertDialog.adaptive(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        _adaptiveAction(
          onPressed: () => Navigator.pop(context),
          text: zulipLocalizations.dialogCancel),
        _adaptiveAction(
          onPressed: () {
            onActionButtonPress();
            Navigator.pop(context);
          },
          text: actionButtonText ?? zulipLocalizations.dialogContinue),
      ]));
}
