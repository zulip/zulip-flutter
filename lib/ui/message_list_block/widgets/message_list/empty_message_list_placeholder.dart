import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/narrow.dart';
import '../../../utils/actions.dart';
import '../../../utils/page.dart';
import '../../../utils/store.dart';

class EmptyMessageListPlaceholder extends StatelessWidget {
  const EmptyMessageListPlaceholder({super.key, required this.narrow});

  final Narrow narrow;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    switch (narrow) {
      case CombinedFeedNarrow():
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.emptyMessageListCombinedFeed,
        );

      case ChannelNarrow(:final streamId) || TopicNarrow(:final streamId):
        final channel = store.streams[streamId];
        if (channel == null) {
          return PageBodyEmptyContentPlaceholder(
            header: zulipLocalizations.emptyMessageListChannelUnavailable,
          );
        } else if (!store.selfHasContentAccess(channel)) {
          return PageBodyEmptyContentPlaceholder(
            headerWithLinkMarkup:
                zulipLocalizations.emptyMessageListChannelWithoutContentAccess,
            onTapHeaderLink: () => PlatformActions.launchUrl(
              context,
              store.tryResolveUrl('/help/channel-permissions')!,
            ),
          );
        } else {
          return PageBodyEmptyContentPlaceholder(
            header: zulipLocalizations.emptyMessageList,
          );
        }

      case DmNarrow(:final otherRecipientIds) when otherRecipientIds.isEmpty:
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.emptyMessageListSelfDmHeader,
          message: zulipLocalizations.emptyMessageListSelfDmMessage,
        );

      case DmNarrow(:final otherRecipientIds)
          when otherRecipientIds.length == 1:
        final user = store.getUser(otherRecipientIds.single);
        switch (user) {
          case null:
            return PageBodyEmptyContentPlaceholder(
              header: zulipLocalizations.emptyMessageListDmUnknownUser,
            );
          case User(isActive: false):
            return PageBodyEmptyContentPlaceholder(
              header: zulipLocalizations.emptyMessageListDmDeactivatedUser(
                store.userDisplayName(user.userId, replaceIfMuted: false),
              ),
            );
          case User():
            final displayName = store.userDisplayName(
              user.userId,
              replaceIfMuted: false,
            );
            return PageBodyEmptyContentPlaceholder(
              header: zulipLocalizations.emptyMessageListDm(displayName),
              message: store.isUserMuted(user.userId)
                  ? null
                  : zulipLocalizations.emptyMessageListDmStartConversation,
            );
        }

      case DmNarrow(:final otherRecipientIds)
          when otherRecipientIds.any((userId) {
            final user = store.getUser(userId);
            return user != null && !user.isActive;
          }):
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.emptyMessageListGroupDmDeactivatedUser,
        );

      case DmNarrow():
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.emptyMessageListGroupDm,
          message: zulipLocalizations.emptyMessageListDmStartConversation,
        );

      case MentionsNarrow():
        return PageBodyEmptyContentPlaceholder(
          headerWithLinkMarkup:
              zulipLocalizations.emptyMessageListMentionsHeader,
          onTapHeaderLink: () => PlatformActions.launchUrl(
            context,
            store.tryResolveUrl('/help/mention-a-user-or-group')!,
          ),
          message: store.zulipFeatureLevel >= 224
              // This string mentions @topic, which is new in Server 8.
              ? zulipLocalizations.emptyMessageListMentionsMessage
              : null,
        ); // TODO(server-8)

      case StarredMessagesNarrow():
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.emptyMessageListStarredHeader,
          messageWithLinkMarkup: zulipLocalizations
              .emptyMessageListStarredMessage(
                zulipLocalizations.actionSheetOptionStarMessage,
              ),
          onTapMessageLink: () => PlatformActions.launchUrl(
            context,
            store.tryResolveUrl('/help/star-a-message')!,
          ),
        );

      case KeywordSearchNarrow():
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.emptyMessageListSearch,
        );
    }
  }
}
