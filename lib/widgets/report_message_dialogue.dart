import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../api/core.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/store.dart';
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
  bool _isSubmitting = false;

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

  void _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final payload = {
      'report_type': RawParameter(_selectedReason!),
      if (_detailsController.text.trim().isNotEmpty)
        'description': _detailsController.text
            .trim(),
    };

    try {
      await widget.store.connection.post<Map<String, dynamic>>(
        'messages/${widget.messageId}/report',
        (json) => json,
        'messages/${widget.messageId}/report',
        payload,
      );

      toastification.show(
        type: ToastificationType.success,
        foregroundColor: Colors.white,
        title: Text("Sent !"),
        description: Text("Report has been sent successfully"),
        backgroundColor: Colors.green.withValues(alpha: 0.4),
        icon: const Icon(Icons.check_circle, color: Colors.black),
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: true,
        progressBarTheme: ProgressIndicatorThemeData(
          linearTrackColor: Colors.green,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        alignment: Alignment.topRight,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {

      toastification.show(
        type: ToastificationType.error,
        title: Text("Report Issue"),
        description: Text("Failed to send report. Please try again."),
        backgroundColor: Colors.red.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.error, color: Colors.black),
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: true,
        progressBarTheme: ProgressIndicatorThemeData(
          linearTrackColor: Colors.red,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        alignment: Alignment.topRight,
      );
    } finally {
      if (mounted){
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    final reasons = <String, String>{
      'spam': 'Spam',
      'harassment': 'Harassment',
      'inappropriate': 'Inappropriate',
      'norms': 'Community norms violation',
      'other': 'Other',
    };

    final reasonIcons = <String, IconData>{
      'spam': Icons.report_gmailerrorred,
      'harassment': Icons.warning_amber_rounded,
      'inappropriate': Icons.block_rounded,
      'norms': Icons.gavel_rounded,
      'other': Icons.more_horiz,
    };

    return AlertDialog(
      backgroundColor: designVariables.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: designVariables.contextMenuItemBgDanger.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.flag_rounded,
              size: 24,
              color: designVariables.contextMenuItemBgDanger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              zulipLocalizations.reportMessageDialogTitle,
              style: TextStyle(
                fontSize: 20,
                height: 24 / 20,
                color: designVariables.title,
              ).merge(weightVariableTextStyle(context, wght: 600)),
            ),
          ),
        ],
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
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: designVariables.bannerTextIntInfo.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: designVariables.bannerTextIntInfo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your report will be sent to the private moderation requests channel for this organization.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: designVariables.bannerTextIntInfo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'What\'s the problem with this message?',
              style: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                color: designVariables.labelMenuButton,
              ).merge(weightVariableTextStyle(context, wght: 600)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: designVariables.bgSearchInput,
                border: Border.all(
                  color: _selectedReason != null
                      ? designVariables.contextMenuItemBg.withValues(alpha: 0.3)
                      : designVariables.borderBar,
                  width: _selectedReason != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                hint: Row(
                  children: [
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: designVariables.labelTime,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select a reason',
                      style: TextStyle(
                        fontSize: 15,
                        color: designVariables.labelTime,
                      ),
                    ),
                  ],
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: designVariables.icon,
                  size: 24,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                dropdownColor: designVariables.background,
                items: reasons.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(
                          reasonIcons[entry.key],
                          size: 20,
                          color: designVariables.icon,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 15,
                            color: designVariables.labelMenuButton,
                          ).merge(weightVariableTextStyle(context, wght: 500)),
                        ),
                      ],
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
            const SizedBox(height: 24),
            Text(
              'Can you provide more details?',
              style: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                color: designVariables.labelMenuButton,
              ).merge(weightVariableTextStyle(context, wght: 600)),
            ),
            const SizedBox(height: 10),
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
                hintText: 'Optional - Add any additional context...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: designVariables.labelTime,
                ),
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: designVariables.bgSearchInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: designVariables.borderBar),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: designVariables.borderBar),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
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
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSubmit
                    ? designVariables.contextMenuItemBgDanger
                    : designVariables.borderBar,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: _canSubmit ? 2 : 0,
                shadowColor: designVariables.contextMenuItemBgDanger.withValues(
                  alpha: 0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    zulipLocalizations.reportMessageDialogConfirmButton,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ).merge(weightVariableTextStyle(context, wght: 600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
