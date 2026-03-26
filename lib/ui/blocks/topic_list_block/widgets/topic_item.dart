// This is adapted from `_TopicItem` in lib/widgets/inbox.dart.
// TODO(#1527) see if we can reuse this in redesign
import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';
import '../../../extensions/color.dart';
import '../../message_list_block/message_list_block.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../../../widgets/action_sheet.dart';
import '../../../widgets/counter_badge.dart';
import '../topic_list_block.dart';

class TopicItem extends StatelessWidget {
  const TopicItem({super.key, required this.streamId, required this.data});

  final int streamId;
  final TopicItemData data;

  @override
  Widget build(BuildContext context) {
    final TopicItemData(:topic, :unreadCount, :hasMention, :maxId) = data;

    final store = requirePerAccountStore();
    final designVariables = DesignVariables.of(context);

    // `maxId` might be incorrect (see [Topics.channelTopics]).
    // Check if it refers to a message that's currently in the topic;
    // if not, we just won't have `someMessageIdInTopic` for the action sheet.
    final maxIdMessage = store.messages[maxId];
    final someMessageIdInTopic =
        (maxIdMessage != null &&
            TopicNarrow(streamId, topic).containsMessage(maxIdMessage))
        ? maxIdMessage.id
        : null;

    final visibilityPolicy = store.topicVisibilityPolicy(streamId, topic);
    final double opacity;
    switch (visibilityPolicy) {
      case UserTopicVisibilityPolicy.muted:
        opacity = 0.5;
      case UserTopicVisibilityPolicy.none:
      case UserTopicVisibilityPolicy.unmuted:
      case UserTopicVisibilityPolicy.followed:
        opacity = 1;
      case UserTopicVisibilityPolicy.unknown:
        assert(false);
        opacity = 1;
    }

    final visibilityIcon = iconDataForTopicVisibilityPolicy(visibilityPolicy);

    return Material(
      color: designVariables.bgMessageRegular,
      child: InkWell(
        onTap: () {
          final narrow = TopicNarrow(streamId, topic);
          Navigator.push(
            context,
            MessageListBlockPage.buildRoute(context: context, narrow: narrow),
          );
        },
        onLongPress: () => showTopicActionSheet(
          context,
          channelId: streamId,
          topic: topic,
          someMessageIdInTopic: someMessageIdInTopic,
        ),
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 40),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(6, 4, 12, 4),
            child: Row(
              spacing: 8,
              // In the Figma design, the text and icons on the topic item row
              // are aligned to the start on the cross axis
              // (i.e., `align-items: flex-start`).  The icons are padded down
              // 2px relative to the start, to visibly sit on the baseline.
              // To account for scaled text, we align everything on the row
              // to [CrossAxisAlignment.center] instead ([Row]'s default),
              // like we do for the topic items on the inbox page.
              // TODO(#1528): align to baseline (and therefore to first line of
              //   topic name), but with adjustment for icons
              // CZO discussion:
              //   https://chat.zulip.org/#narrow/channel/243-mobile-team/topic/topic.20list.20item.20alignment/near/2173252
              children: [
                // A null [Icon.icon] makes a blank space.
                _IconMarker(icon: topic.isResolved ? ZulipIcons.check : null),
                Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      style: TextStyle(
                        fontSize: 17,
                        height: 20 / 17,
                        fontStyle: topic.displayName == null
                            ? FontStyle.italic
                            : null,
                        color: designVariables.textMessage,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      topic.unresolve().displayName ??
                          store.realmEmptyTopicDisplayName,
                    ),
                  ),
                ),
                Opacity(
                  opacity: opacity,
                  child: Row(
                    spacing: 4,
                    children: [
                      if (hasMention)
                        const _IconMarker(icon: ZulipIcons.at_sign),
                      if (visibilityIcon != null)
                        _IconMarker(icon: visibilityIcon),
                      if (unreadCount > 0)
                        CounterBadge(
                          kind: CounterBadgeKind.unread,
                          count: unreadCount,
                          channelIdForBackground: null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconMarker extends StatelessWidget {
  const _IconMarker({required this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    // Since we align the icons to [CrossAxisAlignment.center], the top padding
    // from the Figma design is omitted.
    return Icon(
      icon,
      size: textScaler.clamp(maxScaleFactor: 1.5).scale(16),
      color: designVariables.textMessage.withFadedAlpha(0.4),
    );
  }
}
