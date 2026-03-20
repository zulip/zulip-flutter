import 'package:flutter/material.dart';

import '../../../api/model/model.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/narrow.dart';
import '../../action_sheet.dart';
import '../../color.dart';
import '../../icons.dart';
import '../../message_list.dart';
import '../../store.dart';
import '../../theme.dart';
import '../message_list_block.dart';
import 'recipient_header_date.dart';

class StreamMessageRecipientHeader extends StatelessWidget {
  const StreamMessageRecipientHeader({
    super.key,
    required this.message,
    required this.narrow,
  });

  final MessageBase<StreamConversation> message;
  final Narrow narrow;

  static bool _containsDifferentChannels(Narrow narrow) {
    switch (narrow) {
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        return true;

      case ChannelNarrow():
      case TopicNarrow():
      case DmNarrow():
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // For design specs, see:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=538%3A20849&mode=dev
    //   https://github.com/zulip/zulip-mobile/issues/5511
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final messageListTheme = MessageListTheme.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final streamId = message.conversation.streamId;
    final topic = message.conversation.topic;

    final swatch = colorSwatchFor(context, store.subscriptions[streamId]);
    final backgroundColor = swatch.barBackground;
    final iconColor = swatch.iconOnBarBackground;

    final Widget streamWidget;
    if (!_containsDifferentChannels(narrow)) {
      streamWidget = const SizedBox(width: 16);
    } else {
      final stream = store.streams[streamId];
      final streamName =
          stream?.name ??
          message.conversation.displayRecipient ??
          zulipLocalizations.unknownChannelName; // TODO(log)

      streamWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MessageListBlockPage.buildRoute(
            context: context,
            narrow: ChannelNarrow(streamId),
          ),
        ),
        onLongPress: () => showChannelActionSheet(context, channelId: streamId),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              // Figma specifies 5px horizontal spacing around an icon that's
              // 18x18 and includes 1px padding.  The icon SVG is flush with
              // the edges, so make it 16x16 with 6px horizontal padding.
              // Bottom padding added here to shift icon up to
              // match alignment with text visually.
              padding: const EdgeInsets.only(left: 6, right: 6, bottom: 3),
              child: Icon(
                size: 16,
                color: iconColor,
                // A null [Icon.icon] makes a blank space.
                stream != null ? iconDataForStream(stream) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                streamName,
                style: recipientHeaderTextStyle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              // Figma has 5px horizontal padding around an 8px wide icon.
              // Icon is 16px wide here so horizontal padding is 1px.
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                size: 16,
                color: messageListTheme.streamRecipientHeaderChevronRight,
                ZulipIcons.chevron_right,
              ),
            ),
          ],
        ),
      );
    }

    final topicWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Flexible(
            child: Text(
              topic.displayName ?? store.realmEmptyTopicDisplayName,
              // TODO: Give a way to see the whole topic (maybe a
              //   long-press interaction?)
              overflow: TextOverflow.ellipsis,
              style: recipientHeaderTextStyle(
                context,
                fontStyle: topic.displayName == null ? FontStyle.italic : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            size: 14,
            color: designVariables.title.withFadedAlpha(0.5),
            // A null [Icon.icon] makes a blank space.
            iconDataForTopicVisibilityPolicy(
              store.topicVisibilityPolicy(streamId, topic),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      // When already in a topic narrow, disable tap interaction that would just
      // push a MessageListPage for the same topic narrow.
      // TODO(#1039) simplify by removing topic-narrow condition if we remove
      //   recipient headers in topic narrows
      onTap: narrow is TopicNarrow
          ? null
          : () => Navigator.push(
              context,
              MessageListBlockPage.buildRoute(
                context: context,
                narrow: TopicNarrow.ofMessage(message),
              ),
            ),
      onLongPress: () => showTopicActionSheet(
        context,
        channelId: streamId,
        topic: topic,
        someMessageIdInTopic: message.id,
      ),
      child: ColoredBox(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TODO(#282): Long stream name will break layout; find a fix.
            streamWidget,
            Expanded(child: topicWidget),
            // TODO topic links?
            // Then web also has edit/resolve/mute buttons. Skip those for mobile.
            RecipientHeaderDate(message: message),
          ],
        ),
      ),
    );
  }
}
