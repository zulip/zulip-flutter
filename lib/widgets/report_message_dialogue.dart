import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/store.dart';
import 'dialog.dart';
import 'text.dart';
import 'theme.dart';

Future<bool?> showReportMessageDialog({
  required BuildContext context,
  required int messageId,
  required PerAccountStore store,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) =>
        ReportMessageDialog(messageId: messageId, store: store),
  );
}

class ReportMessageDialog extends StatefulWidget {
  const ReportMessageDialog({
    super.key,
    required this.messageId,
    required this.store,
  });

  final int messageId;
  final PerAccountStore store;

  @override
  State<ReportMessageDialog> createState() => _ReportMessageDialogState();
}

class _ReportMessageDialogState extends State<ReportMessageDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'other' && _detailsController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  void _handleSubmit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    final reasons = <String, String>{
      'spam': 'Spam',
      'harassment': 'Harassment',
      'other': 'Other',
    };

    return AlertDialog(
      backgroundColor: designVariables.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Text(
        zulipLocalizations.reportMessageDialogTitle,
        style: TextStyle(
          fontSize: 20,
          height: 24 / 20,
          color: designVariables.title,
        ).merge(weightVariableTextStyle(context, wght: 600)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: designVariables.bannerBgIntInfo,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: designVariables.bannerTextIntInfo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your report will be sent to the private moderation requests channel for this organization.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        color: designVariables.bannerTextIntInfo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'What\'s the problem with this message?',
              style: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                color: designVariables.labelMenuButton,
              ).merge(weightVariableTextStyle(context, wght: 600)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: designVariables.borderBar),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedReason,
                hint: Text(
                  'Select a reason',
                  style: TextStyle(
                    fontSize: 15,
                    color: designVariables.labelTime,
                  ),
                ),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: designVariables.icon),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: reasons.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 15,
                        color: designVariables.labelMenuButton,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Can you provide more details?',
              style: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                color: designVariables.labelMenuButton,
              ).merge(weightVariableTextStyle(context, wght: 600)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLength: 1000,
              maxLines: 4,
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                color: designVariables.textInput,
              ),
              decoration: InputDecoration(
                hintText: 'Optional',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: designVariables.labelTime,
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: designVariables.composeBoxBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: designVariables.borderBar),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: designVariables.borderBar),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: designVariables.contextMenuItemBg,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: Text(
                zulipLocalizations.dialogCancel,
                style: TextStyle(
                  fontSize: 15,
                  color: designVariables.labelMenuButton,
                ).merge(weightVariableTextStyle(context, wght: 600)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _canSubmit ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSubmit
                    ? designVariables.contextMenuItemBgDanger
                    : designVariables.borderBar,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                zulipLocalizations.reportMessageDialogConfirmButton,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ).merge(weightVariableTextStyle(context, wght: 600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
