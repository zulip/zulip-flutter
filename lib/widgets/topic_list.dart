import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/topics.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'app_bar.dart';
import 'icons.dart';
import 'inbox.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'counter_badge.dart';

class TopicListPage extends StatelessWidget {
  const TopicListPage({super.key, required this.channelId});

  final int channelId;

  static AccountRoute<void> buildRoute({
    required BuildContext context,
    required int channelId,
  }) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: TopicListPage(channelId: channelId));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final appBarBackgroundColor = colorSwatchFor(
      context, store.subscriptions[channelId]).barBackground;

    return PageRoot(child: Scaffold(
      appBar: ZulipAppBar(
        backgroundColor: appBarBackgroundColor,
        buildTitle: (willCenterTitle) =>
          _TopicListAppBarTitle(channelId: channelId, willCenterTitle: willCenterTitle),
        actions: [
          IconButton(
            icon: const Icon(ZulipIcons.message_feed),
            tooltip: zulipLocalizations.channelFeedButtonTooltip,
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: ChannelNarrow(channelId)))),
        ]),
      body: _TopicList(channelId: channelId)));
  }
}

// This is adapted from [MessageListAppBarTitle].
class _TopicListAppBarTitle extends StatelessWidget {
  const _TopicListAppBarTitle({
    required this.channelId,
    required this.willCenterTitle,
  });

  final int channelId;
  final bool willCenterTitle;

  Widget _buildStreamRow(BuildContext context) {
    // TODO(#1039) implement a consistent app bar design here
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final stream = store.streams[channelId];
    final channelIconColor = colorSwatchFor(context,
      store.subscriptions[channelId]).iconOnBarBackground;

    // A null [Icon.icon] makes a blank space.
    final icon = stream != null ? iconDataForStream(stream) : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      // TODO(design): The vertical alignment of the stream privacy icon is a bit ad hoc.
      //   For screenshots of some experiments, see:
      //     https://github.com/zulip/zulip-flutter/pull/219#discussion_r1281024746
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: Icon(size: 18, icon, color: channelIconColor)),
        Flexible(child: Text(
          stream?.name ?? zulipLocalizations.unknownChannelName,
          style: TextStyle(
            fontSize: 20,
            height: 30 / 20,
            color: designVariables.title,
          ).merge(weightVariableTextStyle(context, wght: 600)))),
      ]);
  }

  @override
  Widget build(BuildContext context) {
    final alignment = willCenterTitle
      ? Alignment.center
      : AlignmentDirectional.centerStart;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          showChannelActionSheet(context,
            channelId: channelId,
            // We're already on the topic list.
            showTopicListButton: false);
        },
        child: Align(alignment: alignment,
          child: _buildStreamRow(context))));
  }
}

class _TopicList extends StatefulWidget {
  const _TopicList({required this.channelId});

  final int channelId;

  @override
  State<_TopicList> createState() => _TopicListState();
}

class _TopicListState extends State<_TopicList> with PerAccountStoreAwareStateMixin {
  Topics? topicsModel;
  Unreads? unreadsModel;

  @override
  void onNewStore() {
    final newStore = PerAccountStoreWidget.of(context);
    topicsModel?.removeListener(_modelChanged);
    topicsModel = newStore.topics..addListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    unreadsModel = newStore.unreads..addListener(_modelChanged);
    _fetchTopics();
  }

  @override
  void dispose() {
    topicsModel?.removeListener(_modelChanged);
    unreadsModel?.removeListener(_modelChanged);
    super.dispose();
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
    await topicsModel!.getChannelTopics(widget.channelId);
  }

  @override
  Widget build(BuildContext context) {
    final channelTopics = topicsModel!.channelTopics(widget.channelId);
    if (channelTopics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (channelTopics.isEmpty) {
      final zulipLocalizations = ZulipLocalizations.of(context);
      return PageBodyEmptyContentPlaceholder(
        header: zulipLocalizations.topicListEmptyPlaceholderHeader);
    }

    // This is adapted from parts of the build method on [_InboxPageState].
    final topicItems = <_TopicItemData>[];
    for (final GetChannelTopicsEntry(:maxId, name: topic) in channelTopics) {
      final unreadMessageIds =
        unreadsModel!.streams[widget.channelId]?[topic] ?? <int>[];
      final countInTopic = unreadMessageIds.length;
      final hasMention = unreadMessageIds.any((messageId) =>
        unreadsModel!.mentions.contains(messageId));
      topicItems.add(_TopicItemData(
        topic: topic,
        unreadCount: countInTopic,
        hasMention: hasMention,
        maxId: maxId,
      ));
    }

    return SafeArea(
      // Don't pad the bottom here; we want the list content to do that.
      bottom: false,
      child: ListView.builder(
        itemCount: topicItems.length,
        itemBuilder: (context, index) =>
          _TopicItem(channelId: widget.channelId, data: topicItems[index])),
    );
  }
}

class _TopicItemData {
  final TopicName topic;
  final int unreadCount;
  final bool hasMention;
  final int maxId;

  const _TopicItemData({
    required this.topic,
    required this.unreadCount,
    required this.hasMention,
    required this.maxId,
  });
}

// This is adapted from `_TopicItem` in lib/widgets/inbox.dart.
// TODO(#1527) see if we can reuse this in redesign
class _TopicItem extends StatelessWidget {
  const _TopicItem({required this.channelId, required this.data});

  final int channelId;
  final _TopicItemData data;

  @override
  Widget build(BuildContext context) {
    final _TopicItemData(
      :topic, :unreadCount, :hasMention, :maxId) = data;

    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    // `maxId` might be incorrect (see [Topics.channelTopics]).
    // Check if it refers to a message that's currently in the topic;
    // if not, we just won't have `someMessageIdInTopic` for the action sheet.
    final maxIdMessage = store.messages[maxId];
    final someMessageIdInTopic =
      (maxIdMessage != null && TopicNarrow(channelId, topic).containsMessage(maxIdMessage))
        ? maxIdMessage.id
        : null;

    final visibilityPolicy = store.topicVisibilityPolicy(channelId, topic);
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
          final narrow = TopicNarrow(channelId, topic);
          Navigator.push(context,
            MessageListPage.buildRoute(context: context, narrow: narrow));
        },
        onLongPress: () => showTopicActionSheet(context,
          channelId: channelId,
          topic: topic,
          someMessageIdInTopic: someMessageIdInTopic),
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 40),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(6, 4, 12, 4),
            child: Center(
              widthFactor: 1,
              child: Row(
                spacing: 8,
                crossAxisAlignment: .baseline,
                textBaseline: localizedTextBaseline(context),
                children: [
                  InboxRowMarkerIcon(
                    icon: ZulipIcons.check,
                    visible: topic.isResolved),
                  Expanded(child: Opacity(
                    opacity: opacity,
                    child: Text(
                      style: TextStyle(
                        fontSize: InboxRowTrailingMarkers.fontSize,
                        height: 20 / InboxRowTrailingMarkers.fontSize,
                        fontStyle: topic.displayName == null ? FontStyle.italic : null,
                        color: designVariables.textMessage,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      topic.unresolve().displayName ?? store.realmEmptyTopicDisplayName))),
                  Opacity(opacity: opacity,
                    child: InboxRowTrailingMarkers(
                      hasMention: hasMention,
                      visibilityIcon: visibilityIcon,
                      unreadCountBadge: unreadCount == 0 ? null :
                        CounterBadge(
                          kind: CounterBadgeKind.unread,
                          count: unreadCount,
                          channelIdForBackground: null))),
                ]))))));
  }
}
