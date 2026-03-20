import 'package:flutter/material.dart' hide SearchBar;

import '../../../../api/model/model.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../model/message_list.dart';
import '../../../../model/narrow.dart';
import '../../../action_sheet.dart';
import '../../../color.dart';
import '../../../icons.dart';
import '../../../store.dart';
import '../../../text.dart';
import '../../../theme.dart';
import '../../message_list_block.dart';
import '../search_bar.dart';

class MessageListAppBarTitle extends StatelessWidget {
  const MessageListAppBarTitle({
    super.key,
    required this.narrow,
    required this.willCenterTitle,
  });

  final Narrow narrow;
  final bool willCenterTitle;

  Widget _buildStreamRow(BuildContext context, {ZulipStream? stream}) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    // A null [Icon.icon] makes a blank space.
    IconData? icon;
    Color? iconColor;
    if (stream != null) {
      icon = iconDataForStream(stream);
      iconColor = colorSwatchFor(
        context,
        store.subscriptions[stream.streamId],
      ).iconOnBarBackground;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      // TODO(design): The vertical alignment of the stream privacy icon is a bit ad hoc.
      //   For screenshots of some experiments, see:
      //     https://github.com/zulip/zulip-flutter/pull/219#discussion_r1281024746
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(size: 16, color: iconColor, icon),
        const SizedBox(width: 4),
        Flexible(
          child: Text(stream?.name ?? zulipLocalizations.unknownChannelName),
        ),
      ],
    );
  }

  Widget _buildTopicRow(
    BuildContext context, {
    required ZulipStream? stream,
    required TopicName topic,
  }) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final icon = stream == null
        ? null
        : iconDataForTopicVisibilityPolicy(
            store.topicVisibilityPolicy(stream.streamId, topic),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            topic.displayName ?? store.realmEmptyTopicDisplayName,
            style: TextStyle(
              fontSize: 13,
              fontStyle: topic.displayName == null ? FontStyle.italic : null,
            ).merge(weightVariableTextStyle(context)),
          ),
        ),
        if (icon != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Icon(
              icon,
              color: designVariables.title.withFadedAlpha(0.5),
              size: 14,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);

    switch (narrow) {
      case CombinedFeedNarrow():
        return Text(zulipLocalizations.combinedFeedPageTitle);

      case MentionsNarrow():
        return Text(zulipLocalizations.mentionsPageTitle);

      case StarredMessagesNarrow():
        return Text(zulipLocalizations.starredMessagesPageTitle);

      case ChannelNarrow(:var streamId):
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        final alignment = willCenterTitle
            ? Alignment.center
            : AlignmentDirectional.centerStart;
        return SizedBox(
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              showChannelActionSheet(context, channelId: streamId);
            },
            child: Align(
              alignment: alignment,
              child: _buildStreamRow(context, stream: stream),
            ),
          ),
        );

      case TopicNarrow(:var streamId, :var topic):
        final store = PerAccountStoreWidget.of(context);
        final stream = store.streams[streamId];
        final alignment = willCenterTitle
            ? Alignment.center
            : AlignmentDirectional.centerStart;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () {
                showChannelActionSheet(context, channelId: streamId);
              },
              child: Align(
                alignment: alignment,
                child: _buildStreamRow(context, stream: stream),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () {
                final someMessage = MessageListBlockPage.ancestorOf(
                  context,
                ).model?.messages.lastOrNull;
                // If someMessage is null, the topic action sheet won't have a
                // resolve/unresolve button. That seems OK; in that case we're
                // either still fetching messages (and the user can reopen the
                // sheet after that finishes) or there aren't any messages to
                // act on anyway.
                assert(
                  someMessage == null || narrow.containsMessage(someMessage)!,
                );
                showTopicActionSheet(
                  context,
                  channelId: streamId,
                  topic: topic,
                  someMessageIdInTopic: someMessage?.id,
                );
              },
              child: Align(
                alignment: alignment,
                child: _buildTopicRow(context, stream: stream, topic: topic),
              ),
            ),
          ],
        );

      case DmNarrow(:var otherRecipientIds):
        final store = PerAccountStoreWidget.of(context);
        if (otherRecipientIds.isEmpty) {
          return Text(zulipLocalizations.dmsWithYourselfPageTitle);
        } else {
          final names = otherRecipientIds.map(store.userDisplayName);
          // TODO show avatars
          return Text(
            zulipLocalizations.dmsWithOthersPageTitle(names.join(', ')),
          );
        }

      case KeywordSearchNarrow():
        assert(!willCenterTitle);
        return SearchBar(
          onSubmitted: (narrow) {
            MessageListBlockPage.ancestorOf(
              context,
            ).model!.renarrowAndFetch(narrow, AnchorCode.newest);
          },
        );
    }
  }
}
