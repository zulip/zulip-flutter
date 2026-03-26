import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/route/channels.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/domains/unreads/unreads_service.dart';
import '../../../../get/services/store_service.dart';
import '../../../../model/topics.dart';
import '../../../../model/unreads.dart';
import '../../../utils/page.dart';

import '../topic_list_block.dart';
import 'topic_item.dart';

class TopicList extends StatefulWidget {
  const TopicList({super.key, required this.streamId});

  final int streamId;

  @override
  State<TopicList> createState() => _TopicListState();
}

class _TopicListState extends State<TopicList> {
  Topics? topicsModel;
  Unreads? unreadsModel;

  @override
  void initState() {
    super.initState();
    ever(StoreService.to.currentStore, (_) => _onStoreChanged());
    _onStoreChanged();
  }

  @override
  void dispose() {
    topicsModel?.removeListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    topicsModel?.removeListener(_modelChanged);
    topicsModel = StoreService.to.requireStore.topics
      ..addListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    final unreads = UnreadsService.to.unreads;
    if (unreads != null) {
      unreadsModel = unreads..addListener(_modelChanged);
    }
    _fetchTopics();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in `topicsModel` and `unreadsModel`.
    });
  }

  void _fetchTopics() async {
    // If the fetch succeeds, `topicsModel` will notify listeners.
    // Do nothing when the fetch fails; the topic-list will stay on
    // the loading screen, until the user navigates away and back.
    // TODO(design) show a nice error message on screen when this fails
    await topicsModel!.getChannelTopics(widget.streamId);
  }

  @override
  Widget build(BuildContext context) {
    final channelTopics = topicsModel!.channelTopics(widget.streamId);
    if (channelTopics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (channelTopics.isEmpty) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      return PageBodyEmptyContentPlaceholder(
        header: zulipLocalizations.topicListEmptyPlaceholderHeader,
      );
    }

    // This is adapted from parts of the build method on [_InboxPageState].
    final topicItems = <TopicItemData>[];
    for (final GetChannelTopicsEntry(:maxId, name: topic) in channelTopics) {
      final unreadMessageIds =
          unreadsModel!.streams[widget.streamId]?[topic] ?? <int>[];
      final countInTopic = unreadMessageIds.length;
      final hasMention = unreadMessageIds.any(
        (messageId) => unreadsModel!.mentions.contains(messageId),
      );
      topicItems.add(
        TopicItemData(
          topic: topic,
          unreadCount: countInTopic,
          hasMention: hasMention,
          maxId: maxId,
        ),
      );
    }

    return SafeArea(
      // Don't pad the bottom here; we want the list content to do that.
      bottom: false,
      child: ListView.builder(
        itemCount: topicItems.length,
        itemBuilder: (context, index) =>
            TopicItem(streamId: widget.streamId, data: topicItems[index]),
      ),
    );
  }
}
