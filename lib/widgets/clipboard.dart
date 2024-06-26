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

  if (!context.mounted) return;

  final shouldShowSnackbar = switch (ZulipBinding.instance.deviceInfo) {
    // Android 13+ shows its own popup on copying to the clipboard,
    // so we suppress ours, following the advice at:
    //   https://developer.android.com/develop/ui/views/touch-and-input/copy-paste#duplicate-notifications
    // TODO(android-sdk-33): Simplify this and dartdoc
    AndroidDeviceInfo(:var sdkInt) => sdkInt <= 32,
    // Otherwise always display the snackbar if:
    //  1. It's any other os/device than Android.
    //  2. deviceInfo == null, meaning there was a failure while fetching
    //     the deviceInfo, so we don't know which os/device variant the
    //     app is running on.
    _                              => true,
  };
  if (shouldShowSnackbar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: successContent));
  }
}
