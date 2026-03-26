import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/store.dart';
import '../../../extensions/color.dart';
import '../../../themes/message_list_theme.dart';
import '../../../values/icons.dart';
import '../message_list.dart';
import '../../profile_block/profile.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/user.dart';
import '../message_list_block.dart';

class SenderRow extends StatelessWidget {
  const SenderRow({
    super.key,
    required this.message,
    required this.timestampStyle,
  });

  final MessageBase message;
  final MessageTimestampStyle timestampStyle;

  bool _showAsMuted(BuildContext context, PerAccountStore store) {
    final message = this.message;
    if (!store.isUserMuted(message.senderId)) return false;
    if (message is! Message) return false; // i.e., if an outbox message
    final revealedMutedMessagesState =
        MessageListBlockPage.maybeRevealedMutedMessagesOf(context);
    // The "unrevealed" state only exists in the message list,
    // and we show a sender row in at least one place outside the message list
    // (the message action sheet).
    if (revealedMutedMessagesState == null) return false;
    return !revealedMutedMessagesState.isMutedMessageRevealed(message.id);
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = requirePerAccountStore();
    final messageListTheme = MessageListTheme.of(context);
    final designVariables = DesignVariables.of(context);

    final sender = store.getUser(message.senderId);
    final timestamp = timestampStyle.format(
      message.timestamp,
      now: DateTime.now(),
      twentyFourHourTimeMode: store.userSettings.twentyFourHourTime,
      zulipLocalizations: zulipLocalizations,
    );

    final showAsMuted = _showAsMuted(context, store);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: localizedTextBaseline(context),
        children: [
          Flexible(
            child: GestureDetector(
              onTap: () => showAsMuted
                  ? null
                  : Navigator.push(
                      context,
                      ProfilePage.buildRoute(
                        context: context,
                        userId: message.senderId,
                      ),
                    ),
              child: Row(
                children: [
                  Avatar(
                    size: 32,
                    borderRadius: 3,
                    showPresence: false,
                    replaceIfMuted: showAsMuted,
                    userId: message.senderId,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message is Message
                          ? store.senderDisplayName(
                              message as Message,
                              replaceIfMuted: showAsMuted,
                            )
                          : store.userDisplayName(message.senderId),
                      style: TextStyle(
                        fontSize: 18,
                        height: (22 / 18),
                        color: showAsMuted
                            ? designVariables.title.withFadedAlpha(0.5)
                            : designVariables.title,
                      ).merge(weightVariableTextStyle(context, wght: 600)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  UserStatusEmoji(
                    userId: message.senderId,
                    size: 18,
                    padding: const EdgeInsetsDirectional.only(start: 5.0),
                  ),
                  if (sender?.isBot ?? false) ...[
                    const SizedBox(width: 5),
                    Icon(
                      ZulipIcons.bot,
                      size: 15,
                      color: messageListTheme.senderBotIcon,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(width: 4),
            Text(
              timestamp,
              style: TextStyle(
                color: messageListTheme.labelTime,
                fontSize: 16,
                height: (18 / 16),
                fontFeatures: const [
                  FontFeature.enable('c2sc'),
                  FontFeature.enable('smcp'),
                ],
              ).merge(weightVariableTextStyle(context)),
            ),
          ],
        ],
      ),
    );
  }
}
