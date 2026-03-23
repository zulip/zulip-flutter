import 'package:flutter/material.dart';

import '../../../../../../../generated/l10n/zulip_localizations.dart';
import '../../../../../../../model/message.dart';
import '../../../../../../extensions/color.dart';
import '../../../../../../values/text.dart';
import '../../../../../../values/theme.dart';
import 'restore_outbox_message_gesture_detector.dart';

class OutboxMessageStatusRow extends StatelessWidget {
  const OutboxMessageStatusRow({
    super.key,
    required this.localMessageId,
    required this.outboxMessageState,
  });

  final int localMessageId;
  final OutboxMessageState outboxMessageState;

  @override
  Widget build(BuildContext context) {
    switch (outboxMessageState) {
      case OutboxMessageState.hidden:
        assert(
          false,
          'Hidden OutboxMessage messages should not appear in message lists',
        );
        return SizedBox.shrink();

      case OutboxMessageState.waiting:
        final designVariables = DesignVariables.of(context);
        return Padding(
          padding: const EdgeInsetsGeometry.only(bottom: 2),
          child: LinearProgressIndicator(
            minHeight: 2,
            color: designVariables.foreground.withFadedAlpha(0.5),
            backgroundColor: designVariables.foreground.withFadedAlpha(0.2),
          ),
        );

      case OutboxMessageState.failed:
      case OutboxMessageState.waitPeriodExpired:
        final designVariables = DesignVariables.of(context);
        final zulipLocalizations = ZulipLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RestoreOutboxMessageGestureDetector(
            localMessageId: localMessageId,
            child: Text(
              zulipLocalizations.messageNotSentLabel,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: designVariables.btnLabelAttLowIntDanger,
                fontSize: 12,
                height: 12 / 12,
                letterSpacing: proportionalLetterSpacing(
                  context,
                  0.05,
                  baseFontSize: 12,
                ),
              ),
            ),
          ),
        );
    }
  }
}
