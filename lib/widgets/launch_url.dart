import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/binding.dart';
import '../model/internal_link.dart';
import 'dialog.dart';
import 'message_list.dart';
import 'store.dart';

/// Handles showing an error dialog with a customizable message.
Future<void> _showError(BuildContext context, String? message, String urlString) {
  return showErrorDialog(
    context: context,
    title: 'Unable to open link',
    message: [
      'Link could not be opened: $urlString',
      if (message != null) message,
    ].join("\n\n"));
}

/// Launches a URL without considering a realm base URL.
void launchUrlWithoutRealm(BuildContext context, Uri url) async {
  bool launched = false;
  String? errorMessage;
  try {
    launched = await ZulipBinding.instance.launchUrl(url,
      mode: switch (defaultTargetPlatform) {
        // On iOS we prefer LaunchMode.externalApplication because (for
        // HTTP URLs) LaunchMode.platformDefault uses SFSafariViewController,
        // which gives an awkward UX as described here:
        //  https://chat.zulip.org/#narrow/stream/48-mobile/topic/in-app.20browser/near/1169118
        TargetPlatform.iOS => UrlLaunchMode.externalApplication,
        _ => UrlLaunchMode.platformDefault,
      });
  } on PlatformException catch (e) {
    errorMessage = e.message;
  }
  if (!launched) {
    if (!context.mounted) return;
    await _showError(context, errorMessage, url.toString());
  }
}

/// Launches a URL considering a realm base URL.
void launchUrlWithRealm(BuildContext context, String urlString) async {
  final store = PerAccountStoreWidget.of(context);
  final url = store.tryResolveUrl(urlString);
  if (url == null) { // TODO(log)
    await _showError(context, null, urlString);
    return;
  }

  final internalNarrow = parseInternalLink(url, store);
  if (internalNarrow != null) {
    Navigator.push(context,
      MessageListPage.buildRoute(context: context, narrow: internalNarrow));
    return;
  }

  launchUrlWithoutRealm(context, url);
}
