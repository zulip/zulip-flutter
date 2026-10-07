import 'package:flutter/material.dart';

import '../api/exception.dart';
import '../api/model/attachment.dart';
import '../api/route/attachments.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'button.dart';
import 'dialog.dart';
import 'inset_shadow.dart';
import 'store.dart';
import 'theme.dart';

/// A confirmation dialog for deleting uploads detached from an edited message.
///
/// Use [show] to display this dialog.
class DeleteUploadedFilesDialog extends StatefulWidget {
  const DeleteUploadedFilesDialog({super.key, required this.attachments});

  final List<Attachment> attachments;

  static void show({
    required BuildContext pageContext,
    required List<Attachment> attachments,
  }) {
    final accountId = PerAccountStoreWidget.accountIdOf(pageContext);
    showDialog<void>(
      context: pageContext,
      builder: (context) => PerAccountStoreWidget(accountId: accountId,
        child: DeleteUploadedFilesDialog(attachments: attachments)));
  }

  @override
  State<DeleteUploadedFilesDialog> createState() => _DeleteUploadedFilesDialogState();
}

class _DeleteUploadedFilesDialogState extends State<DeleteUploadedFilesDialog> {
  late final _remaining = List<Attachment>.of(widget.attachments);
  bool _requestInProgress = false;

  Future<void> _submit() async {
    if (_requestInProgress) return;
    final route = ModalRoute.of(context)!;
    final connection = PerAccountStoreWidget.of(context).connection;
    setState(() => _requestInProgress = true);

    // A popped route can remain mounted during its exit animation.
    // Stop after the outstanding request if the user has dismissed the dialog.
    while (_remaining.isNotEmpty) {
      try {
        await removeAttachment(connection, attachmentId: _remaining.first.id);
      } catch (e) {
        if (!mounted || !route.isActive) return;
        setState(() => _requestInProgress = false);
        // Don't interrupt a route that has since covered this dialog.
        if (route.isCurrent) {
          showErrorDialog(context: context,
            title: ZulipLocalizations.of(context).errorDeleteUploadedFilesFailedTitle,
            message: e is ZulipApiException ? e.message : null);
        }
        return;
      }
      if (!mounted || !route.isActive) return;
      // Keep successful deletions out of subsequent retries and the file list.
      setState(() => _remaining.removeAt(0));
    }
    if (route.isCurrent) {
      Navigator.pop(context);
    } else {
      // Remove this completed dialog without popping the covering route.
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    return ZulipDialog(
      title: zulipLocalizations.deleteUploadedFilesDialogTitle,
      content: InsetShadowBox(
        top: 8, bottom: 8,
        color: designVariables.bgContextMenu,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            spacing: 16,
            children: [
              Text(zulipLocalizations.deleteUploadedFilesDialogMessage),
              for (final attachment in _remaining) Text(attachment.name),
            ]))),
      actions: [
        ZulipWebUiKitButton(
          intent: .info,
          attention: .low,
          label: zulipLocalizations.deleteUploadedFilesDialogCancel,
          onPressed: () => Navigator.pop(context)),
        ZulipWebUiKitButton(
          intent: .danger,
          attention: .medium,
          label: zulipLocalizations.deleteUploadedFilesDialogConfirm,
          onPressed: _requestInProgress ? null : _submit),
      ]);
  }
}
