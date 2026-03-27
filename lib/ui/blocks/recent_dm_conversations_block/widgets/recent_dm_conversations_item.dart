import 'package:flutter/material.dart';

import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../../../widgets/counter_badge.dart';
import '../../../widgets/user.dart';
import '../recent_dm_conversations.dart';

class RecentDmConversationsItem extends StatelessWidget {
  const RecentDmConversationsItem({
    super.key,
    required this.narrow,
    required this.unreadCount,
    required this.onDmSelect,
  });

  final DmNarrow narrow;
  final int unreadCount;
  final OnDmSelectCallback onDmSelect;

  static const double _avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final store = requirePerAccountStore();
    final designVariables = DesignVariables.of(context);

    final InlineSpan title;
    final Widget avatar;
    int? userIdForPresence;
    switch (narrow.otherRecipientIds) {
      // TODO dedupe with DM items in [InboxPage]
      case []:
        title = TextSpan(
          text: store.selfUser.fullName,
          children: [
            UserStatusEmoji.asWidgetSpan(
              userId: store.selfUserId,
              fontSize: 17,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ],
        );
        avatar = AvatarImage(userId: store.selfUserId, size: _avatarSize);
      case [var otherUserId]:
        title = TextSpan(
          text: store.userDisplayName(otherUserId),
          children: [
            UserStatusEmoji.asWidgetSpan(
              userId: otherUserId,
              fontSize: 17,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ],
        );
        avatar = AvatarImage(userId: otherUserId, size: _avatarSize);
        userIdForPresence = otherUserId;
      default:
        title = TextSpan(
          // TODO(i18n): List formatting, like you can do in JavaScript:
          //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya'])
          //   // 'Chris、Greg、Alya'
          text: narrow.otherRecipientIds.map(store.userDisplayName).join(', '),
        );
        avatar = ColoredBox(
          color: designVariables.avatarPlaceholderBg,
          child: Center(
            child: Icon(
              color: designVariables.avatarPlaceholderIcon,
              ZulipIcons.group_dm,
            ),
          ),
        );
    }

    // TODO(design) check if this is the right variable
    final backgroundColor = designVariables.background;
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () => onDmSelect(narrow),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 0),
              child: AvatarShape(
                size: _avatarSize,
                borderRadius: 99,
                backgroundColor: userIdForPresence != null
                    ? backgroundColor
                    : null,
                userIdForPresence: userIdForPresence,
                child: avatar,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.15,
                        // TODO(design) check if this is the right variable
                        color: designVariables.labelMenuButton,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      title,
                    ),
                    // TODO Добавить последнее сообщение чата
                    Text('', maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            unreadCount > 0
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: CounterBadge(
                      kind: CounterBadgeKind.unread,
                      channelIdForBackground: null,
                      count: unreadCount,
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
