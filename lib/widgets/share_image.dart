import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'dialog.dart';

void shareImageFromUrl(
    {required Uri url, required BuildContext context}) async {
  final zulipLocalizations = ZulipLocalizations.of(context);
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      Share.shareXFiles([
        XFile.fromData(bytes, mimeType: 'image/${_getFileExtension(url.path)}')
      ]);
    } else {
      if (!context.mounted) return;
      await showErrorDialog(
          context: context, title: zulipLocalizations.errorCouldNotFetchImage);
    }
  } catch (e) {
    if (!context.mounted) return;
    await showErrorDialog(
        context: context,
        title: zulipLocalizations.errorCouldNotConnectToInternet);
  }
}

String _getFileExtension(String path) {
  return path.split('.').last.toLowerCase();
}
