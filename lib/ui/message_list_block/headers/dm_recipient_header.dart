import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../values/icons.dart';
import '../message_list.dart';
import '../../utils/store.dart';
import '../../values/theme.dart';
import '../message_list_block.dart';
import 'recipient_header_date.dart';

class DmRecipientHeader extends StatelessWidget {
  const DmRecipientHeader({
    super.key,
    required this.message,
    required this.narrow,
  });

  final MessageBase<DmConversation> message;
  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final String title;
    if (message.conversation.allRecipientIds.length > 1) {
      title = zulipLocalizations.messageListGroupYouAndOthers(
        message.conversation.allRecipientIds
            .where((id) => id != store.selfUserId)
            .map(store.userDisplayName)
            .sorted()
            .join(", "),
      );
    } else {
      title = zulipLocalizations.messageListGroupYouWithYourself;
    }

    final messageListTheme = MessageListTheme.of(context);
    final designVariables = DesignVariables.of(context);

    return GestureDetector(
      // When already in a DM narrow, disable tap interaction that would just
      // push a MessageListPage for the same DM narrow.
      // TODO(#1244) simplify by removing DM-narrow condition if we remove
      //   recipient headers in DM narrows
      onTap: narrow is DmNarrow
          ? null
          : () => Navigator.push(
              context,
              MessageListBlockPage.buildRoute(
                context: context,
                narrow: DmNarrow.ofMessage(
                  message,
                  selfUserId: store.selfUserId,
                ),
              ),
            ),
      child: ColoredBox(
        color: messageListTheme.dmRecipientHeaderBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  color: designVariables.title,
                  size: 16,
                  ZulipIcons.two_person,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: recipientHeaderTextStyle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RecipientHeaderDate(message: message),
            ],
          ),
        ),
      ),
    );
  }
}
