import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../get/app_pages.dart';

import '../../../../get/services/store_service.dart';
import '../../../../model/narrow.dart';
import '../../../values/icons.dart';
import '../../../values/theme.dart';
import '../../../widgets/action_sheet.dart';
import '../../../widgets/counter_badge.dart';
import '../inbox_section_data_model.dart';
import 'inbox_item_marker.dart';

@visibleForTesting
class InboxTopicItem extends StatelessWidget {
  const InboxTopicItem({super.key, required this.streamId, required this.data});

  final int streamId;
  final InboxChannelSectionTopicData data;

  @override
  Widget build(BuildContext context) {
    final InboxChannelSectionTopicData(
      :topic,
      :count,
      :hasMention,
      :lastUnreadId,
    ) = data;

    final store = requirePerAccountStore();

    final designVariables = DesignVariables.of(context);
    final visibilityIcon = iconDataForTopicVisibilityPolicy(
      store.topicVisibilityPolicy(streamId, topic),
    );

    Widget result = Material(
      color: designVariables
          .background, // TODO(design) check if this is the right variable
      child: InkWell(
        onTap: () {
          final narrow = TopicNarrow(streamId, topic);
          Get.toNamed<dynamic>(
            AppRoutes.topicList,
            arguments: {'narrow': narrow},
          );
        },
        onLongPress: () => showTopicActionSheet(
          context,
          channelId: streamId,
          topic: topic,
          someMessageIdInTopic: lastUnreadId,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 63),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    style: TextStyle(
                      fontSize: 17,
                      height: (20 / 17),
                      fontStyle: topic.displayName == null
                          ? FontStyle.italic
                          : null,
                      // TODO(design) check if this is the right variable
                      color: designVariables.labelMenuButton,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    topic.displayName ?? store.realmEmptyTopicDisplayName,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (hasMention) const InboxIconMarker(icon: ZulipIcons.at_sign),
              // TODO(design) copies the "@" marker color; is there a better color?
              if (visibilityIcon != null) InboxIconMarker(icon: visibilityIcon),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: CounterBadge(
                  // TODO(design) use CounterKind.quantity, following Figma
                  kind: CounterBadgeKind.unread,
                  channelIdForBackground: streamId,
                  count: count,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(container: true, child: result);
  }
}
