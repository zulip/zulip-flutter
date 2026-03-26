import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/domains/channels/channels_service.dart';
import '../../../get/services/domains/unreads/unreads_service.dart';
import '../../../get/services/store_service.dart';
import '../../../model/narrow.dart';
import '../../../model/recent_dm_conversations.dart';
import '../../../model/unreads.dart';
import '../../utils/page.dart';
import '../../widgets/sticky_header.dart';

import 'inbox_section_data_model.dart';
import 'widgets/all_dms_section.dart';
import 'widgets/inbox_strean_section.dart';

class InboxPageBody extends StatefulWidget {
  const InboxPageBody({super.key});

  @override
  State<InboxPageBody> createState() => InboxPageState();
}

/// The interface for the state of an [InboxPageBody].
abstract class InboxPageStateTemplate extends State<InboxPageBody> {
  bool get allDmsCollapsed;
  set allDmsCollapsed(bool value);

  void collapseStream(int streamId);
  void uncollapseStream(int streamId);
}

class InboxPageState extends State<InboxPageBody>
    implements InboxPageStateTemplate {
  Unreads? unreadsModel;
  RecentDmConversationsView? recentDmConversationsModel;

  @override
  bool get allDmsCollapsed => _allDmsCollapsed;
  bool _allDmsCollapsed = false;
  @override
  set allDmsCollapsed(bool value) {
    setState(() {
      _allDmsCollapsed = value;
    });
  }

  Set<int> get collapsedStreamIds => _collapsedStreamIds;
  final Set<int> _collapsedStreamIds = {};
  @override
  void collapseStream(int streamId) {
    setState(() {
      _collapsedStreamIds.add(streamId);
    });
  }

  @override
  void uncollapseStream(int streamId) {
    setState(() {
      _collapsedStreamIds.remove(streamId);
    });
  }

  @override
  void initState() {
    super.initState();
    ever(StoreService.to.currentStore, (_) => _onStoreChanged());
    _onStoreChanged();
  }

  @override
  void dispose() {
    unreadsModel?.removeListener(_modelChanged);
    recentDmConversationsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    unreadsModel?.removeListener(_modelChanged);
    final unreads = UnreadsService.to.unreads;
    if (unreads != null) {
      unreadsModel = unreads..addListener(_modelChanged);
    }
    recentDmConversationsModel?.removeListener(_modelChanged);
    recentDmConversationsModel =
        StoreService.to.requireStore.recentDmConversationsView
          ..addListener(_modelChanged);
  }

  void _modelChanged() {
    setState(() {
      // Much of the state lives in [unreadsModel] and
      // [recentDmConversationsModel].
      // This method was called because one of those just changed.
      //
      // We also update some state that lives locally: we reset a collapsible
      // row's collapsed state when it's cleared of unreads.
      // TODO(perf) handle those updates efficiently
      collapsedStreamIds.removeWhere(
        (streamId) => !unreadsModel!.streams.containsKey(streamId),
      );
      if (unreadsModel!.dms.isEmpty) {
        allDmsCollapsed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = StoreService.to.requireStore;
    final subscriptions = ChannelsService.to.subscriptions;

    // TODO(#1065) make an incrementally-updated view-model for InboxPage
    final sections = <InboxSectionData>[];

    // TODO efficiently include DM conversations that aren't recent enough
    //   to appear in recentDmConversationsView, but still have unreads in
    //   unreadsModel.
    final dmItems = <(DmNarrow, int, bool)>[];
    int allDmsCount = 0;
    bool allDmsHasMention = false;
    for (final dmNarrow in recentDmConversationsModel!.sorted) {
      final countInNarrow = unreadsModel!.countInDmNarrow(dmNarrow);
      if (countInNarrow == 0) {
        continue;
      }
      final hasMention = unreadsModel!.dms[dmNarrow]!.any(
        (messageId) => unreadsModel!.mentions.contains(messageId),
      );
      if (hasMention) allDmsHasMention = true;
      dmItems.add((dmNarrow, countInNarrow, hasMention));
      allDmsCount += countInNarrow;
    }
    if (allDmsCount > 0) {
      sections.add(AllDmsSectionData(allDmsCount, allDmsHasMention, dmItems));
    }

    final sortedUnreadStreams =
        unreadsModel!.streams.entries
            // Filter out any straggling unreads in unsubscribed streams.
            // There won't normally be any, but it happens with certain infrequent
            // state changes, typically for less than a few hundred milliseconds.
            // See [Unreads].
            //
            // Also, we want to depend on the subscription data for things like
            // choosing the stream icon.
            .where((entry) => subscriptions.containsKey(entry.key))
            .toList()
          ..sort((a, b) {
            final subA = subscriptions[a.key]!;
            final subB = subscriptions[b.key]!;

            // TODO "pin" icon on the stream row? dividers in the list?
            if (subA.pinToTop != subB.pinToTop) {
              return subA.pinToTop ? -1 : 1;
            }

            // TODO(i18n) something like JS's String.prototype.localeCompare
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
          (messageId) => unreadsModel!.mentions.contains(messageId),
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
        // TODO(#315) add e.g. "You might be interested in recent conversations."
        header: zulipLocalizations.inboxEmptyPlaceholderHeader,
        message: zulipLocalizations.inboxEmptyPlaceholderMessage,
      );
    }

    return SafeArea(
      // horizontal insets
      child: StickyHeaderListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          switch (section) {
            case AllDmsSectionData():
              return AllDmsSection(
                data: section,
                collapsed: allDmsCollapsed,
                pageState: this,
              );
            case StreamSectionData(:var streamId):
              final collapsed = collapsedStreamIds.contains(streamId);
              return InboxStreamSection(
                data: section,
                collapsed: collapsed,
                pageState: this,
              );
          }
        },
      ),
    );
  }
}
