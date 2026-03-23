import 'package:flutter/material.dart';

import '../../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../values/text.dart';
import '../../../../../values/theme.dart';
import 'restore_edit_message_gesture_detector.dart';

class EditMessageStatusRow extends StatelessWidget {
  const EditMessageStatusRow({
    super.key,
    required this.messageId,
    required this.status,
  });

  final int messageId;
  final bool status;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final baseTextStyle = TextStyle(
      fontSize: 12,
      height: 12 / 12,
      letterSpacing: proportionalLetterSpacing(context, 0.05, baseFontSize: 12),
    );

    return switch (status) {
      // TODO parse markdown and show new content as local echo?
      false => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 1.5,
          children: [
            Text(
              style: baseTextStyle.copyWith(
                color: designVariables.btnLabelAttLowIntInfo,
              ),
              textAlign: TextAlign.end,
              zulipLocalizations.savingMessageEditLabel,
            ),
            // TODO instead place within bottom outer padding:
            //   https://github.com/zulip/zulip-flutter/pull/1498#discussion_r2087576108
            LinearProgressIndicator(
              minHeight: 2,
              color: designVariables.foreground.withValues(alpha: 0.5),
              backgroundColor: designVariables.foreground.withValues(
                alpha: 0.2,
              ),
            ),
          ],
        ),
      ),
      true => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RestoreEditMessageGestureDetector(
          messageId: messageId,
          child: Text(
            style: baseTextStyle.copyWith(
              color: designVariables.btnLabelAttLowIntDanger,
            ),
            textAlign: TextAlign.end,
            zulipLocalizations.savingMessageEditFailedLabel,
          ),
        ),
      ),
    };
  }
}
