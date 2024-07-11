import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/binding.dart';

/// Copies [data] to the clipboard and shows a popup on success.
///
/// Must have a [Scaffold] ancestor.
///
/// On newer Android the popup is defined and shown by the platform. On older
/// Android and on iOS, shows a [Snackbar] with [successContent].
///
/// In English, the text in [successContent] should be short, should start with
/// a capital letter, and should have no ending punctuation: "{noun} copied".
void copyWithPopup({
  required BuildContext context,
  required ClipboardData data,
  required Widget successContent,
}) async {
  await Clipboard.setData(data);
  final deviceInfo = await ZulipBinding.instance.deviceInfo;

  if (!context.mounted) return;

  final shouldShowSnackbar = switch (deviceInfo) {
    // Android 13+ shows its own popup on copying to the clipboard,
    // so we suppress ours, following the advice at:
    //   https://developer.android.com/develop/ui/views/touch-and-input/copy-paste#duplicate-notifications
    // TODO(android-sdk-33): Simplify this and dartdoc
    AndroidDeviceInfo(:var sdkInt) => sdkInt <= 32,
    _                              => true,
  };
  if (shouldShowSnackbar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: successContent));
  }
}
