import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/domains/channels/channels_service.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../../model/recent_dm_conversations.dart';
import '../../../model/unreads.dart';
import '../../utils/page.dart';
import '../../widgets/sticky_header.dart';

import 'inbox_controller.dart';
import 'inbox_section_data_model.dart';
import 'widgets/all_dms_section.dart';
import 'widgets/inbox_strean_section.dart';

class InboxPageBody extends StatelessWidget {
  const InboxPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InboxController>(
      init: InboxController(),
      builder: (controller) {
        return Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final unreadsModel = controller.unreadsModel;
          final recentDmConversationsModel =
              controller.recentDmConversationsModel;

          if (unreadsModel == null || recentDmConversationsModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _InboxContent(
            controller: controller,
            unreadsModel: unreadsModel,
            recentDmConversationsModel: recentDmConversationsModel,
          );
        });
      },
    );
  }
}

class _InboxContent extends StatelessWidget {
  final InboxController controller;
  final Unreads unreadsModel;
  final RecentDmConversationsView recentDmConversationsModel;

  const _InboxContent({
    required this.controller,
    required this.unreadsModel,
    required this.recentDmConversationsModel,
  });

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = StoreService.to.requireStore;
    final subscriptions = ChannelsService.to.subscriptions;

    final sections = <InboxSectionData>[];

    final dmItems = <(DmNarrow, int, bool)>[];
    int allDmsCount = 0;
    bool allDmsHasMention = false;
    for (final dmNarrow in recentDmConversationsModel.sorted) {
      final countInNarrow = unreadsModel.countInDmNarrow(dmNarrow);
      if (countInNarrow == 0) {
        continue;
      }
      final hasMention = unreadsModel.dms[dmNarrow]!.any(
        (messageId) => unreadsModel.mentions.contains(messageId),
      );
      if (hasMention) allDmsHasMention = true;
      dmItems.add((dmNarrow, countInNarrow, hasMention));
      allDmsCount += countInNarrow;
    }
    if (allDmsCount > 0) {
      sections.add(AllDmsSectionData(allDmsCount, allDmsHasMention, dmItems));
    }

    final sortedUnreadStreams =
        unreadsModel.streams.entries
            .where((entry) => subscriptions.containsKey(entry.key))
            .toList()
          ..sort((a, b) {
            final subA = subscriptions[a.key]!;
            final subB = subscriptions[b.key]!;

            if (subA.pinToTop != subB.pinToTop) {
              return subA.pinToTop ? -1 : 1;
            }

            return subA.name.toLowerCase().compareTo(subB.name.toLowerCase());
          });

    for (final MapEntry(key: streamId, value: topics) in sortedUnreadStreams) {
      final topicItems = <InboxChannelSectionTopicData>[];
      int countInStream = 0;
      bool streamHasMention = false;
      for (final MapEntry(key: topic, value: messageIds) in topics.entries) {
        if (!store.isTopicVisible(streamId, topic)) continue;
        final countInTopic = messageIds.length;
        final hasMention = messageIds.any(
          (messageId) => unreadsModel.mentions.contains(messageId),
        );
        if (hasMention) streamHasMention = true;
        topicItems.add(
          InboxChannelSectionTopicData(
            topic: topic,
            count: countInTopic,
            hasMention: hasMention,
            lastUnreadId: messageIds.last,
          ),
        );
        countInStream += countInTopic;
      }
      if (countInStream == 0) {
        continue;
      }
      topicItems.sort((a, b) {
        final aLastUnreadId = a.lastUnreadId;
        final bLastUnreadId = b.lastUnreadId;
        return bLastUnreadId.compareTo(aLastUnreadId);
      });
      sections.add(
        StreamSectionData(
          streamId,
          countInStream,
          streamHasMention,
          topicItems,
        ),
      );
    }

    if (sections.isEmpty) {
      return PageBodyEmptyContentPlaceholder(
        header: zulipLocalizations.inboxEmptyPlaceholderHeader,
        message: zulipLocalizations.inboxEmptyPlaceholderMessage,
      );
    }

    return SafeArea(
      child: StickyHeaderListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          switch (section) {
            case AllDmsSectionData():
              return AllDmsSection(
                data: section,
                collapsed: controller.allDmsCollapsed,
                pageState: controller,
              );
            case StreamSectionData(:var streamId):
              final collapsed = controller.isStreamCollapsed(streamId);
              return InboxStreamSection(
                data: section,
                collapsed: collapsed,
                pageState: controller,
              );
          }
        },
      ),
    );
  }
}
