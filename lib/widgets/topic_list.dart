import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'app_bar.dart';
import 'color.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'unread_count_badge.dart';

class TopicListPage extends StatelessWidget {
  const TopicListPage({super.key, required this.streamId});

  final int streamId;

  static AccountRoute<void> buildRoute({
    required BuildContext context,
    required int streamId,
  }) {
    return MaterialAccountWidgetRoute(
      context: context,
      page: TopicListPage(streamId: streamId));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final appBarBackgroundColor = colorSwatchFor(
      context, store.subscriptions[streamId]).barBackground;

    return PageRoot(child: Scaffold(
      appBar: ZulipAppBar(
        backgroundColor: appBarBackgroundColor,
        buildTitle: (willCenterTitle) =>
          _TopicListAppBarTitle(streamId: streamId, willCenterTitle: willCenterTitle),
        actions: [
          IconButton(
            icon: const Icon(ZulipIcons.message_feed),
            tooltip: zulipLocalizations.channelFeedButtonTooltip,
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: ChannelNarrow(streamId)))),
        ]),
      body: _TopicList(streamId: streamId)));
  }
}

// This is adapted from [MessageListAppBarTitle].
class _TopicListAppBarTitle extends StatelessWidget {
  const _TopicListAppBarTitle({
    required this.streamId,
    required this.willCenterTitle,
  });

  final int streamId;
  final bool willCenterTitle;

  Widget _buildStreamRow(BuildContext context) {
    // TODO(#1039) implement a consistent app bar design here
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    final store = PerAccountStoreWidget.of(context);
    final stream = store.streams[streamId];
    final channelIconColor = colorSwatchFor(context,
      store.subscriptions[streamId]).iconOnBarBackground;

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
            channelId: streamId,
            // We're already on the topic list.
            showTopicListButton: false);
        },
        child: Align(alignment: alignment,
          child: _buildStreamRow(context))));
  }
}

class _TopicList extends StatefulWidget {
  const _TopicList({required this.streamId});

  final int streamId;

  @override
  State<_TopicList> createState() => _TopicListState();
}

class _TopicListState extends State<_TopicList> with PerAccountStoreAwareStateMixin {
  Unreads? unreadsModel;
  // TODO(#1499): store the results on [ChannelStore], and keep them
  //   up-to-date by handling events
  List<GetStreamTopicsEntry>? lastFetchedTopics;

  @override
  void onNewStore() {
    unreadsModel?.removeListener(_modelChanged);
    final store = PerAccountStoreWidget.of(context);
    unreadsModel = store.unreads..addListener(_modelChanged);
    _fetchTopics();
  }

  @override
  void dispose() {
    unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in `unreadsModel`.
    });
  }

  void _fetchTopics() async {
    // Do nothing when the fetch fails; the topic-list will stay on
    // the loading screen, until the user navigates away and back.
    // TODO(design) show a nice error message on screen when this fails
    final store = PerAccountStoreWidget.of(context);
    final result = await getStreamTopics(store.connection,
      streamId: widget.streamId,
      allowEmptyTopicName: true);
    if (!mounted) return;
    setState(() {
      lastFetchedTopics = result.topics;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (lastFetchedTopics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // TODO(design) handle the rare case when `lastFetchedTopics` is empty

    // This is adapted from parts of the build method on [_InboxPageState].
    final topicItems = <_TopicItemData>[];
    for (final GetStreamTopicsEntry(:maxId, name: topic) in lastFetchedTopics!) {
      final unreadMessageIds =
        unreadsModel!.streams[widget.streamId]?[topic] ?? <int>[];
      final countInTopic = unreadMessageIds.length;
      final hasMention = unreadMessageIds.any((messageId) =>
        unreadsModel!.mentions.contains(messageId));
      topicItems.add(_TopicItemData(
        topic: topic,
        unreadCount: countInTopic,
        hasMention: hasMention,
        // `lastFetchedTopics.maxId` can become outdated when a new message
        // arrives or when there are message moves, until we re-fetch.
        // TODO(#1499): track changes to this
        maxId: maxId,
      ));
    }
    topicItems.sort((a, b) {
      final aMaxId = a.maxId;
      final bMaxId = b.maxId;
      return bMaxId.compareTo(aMaxId);
    });

    return SafeArea(
      // Don't pad the bottom here; we want the list content to do that.
      bottom: false,
      child: ListView.builder(
        itemCount: topicItems.length,
        itemBuilder: (context, index) =>
          _TopicItem(streamId: widget.streamId, data: topicItems[index])),
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
  const _TopicItem({required this.streamId, required this.data});

  final int streamId;
  final _TopicItemData data;

  @override
  Widget build(BuildContext context) {
    final _TopicItemData(
      :topic, :unreadCount, :hasMention, :maxId) = data;

    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

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
          Navigator.push(context,
            MessageListPage.buildRoute(context: context, narrow: narrow));
        },
        onLongPress: () => showTopicActionSheet(context,
          channelId: streamId,
          topic: topic,
          someMessageIdInTopic: maxId),
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
                Expanded(child: Opacity(
                  opacity: opacity,
                  child: Text(
                    style: TextStyle(
                      fontSize: 17,
                      height: 20 / 17,
                      fontStyle: topic.displayName == null ? FontStyle.italic : null,
                      color: designVariables.textMessage,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    topic.unresolve().displayName ?? store.realmEmptyTopicDisplayName))),
                Opacity(opacity: opacity, child: Row(
                  spacing: 4,
                  children: [
                    if (hasMention) const _IconMarker(icon: ZulipIcons.at_sign),
                    if (visibilityIcon != null) _IconMarker(icon: visibilityIcon),
                    if (unreadCount > 0)
                      UnreadCountBadge(
                        count: unreadCount,
                        channelIdForBackground: null),
                  ])),
              ])),
        )));
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
    return Icon(icon,
      size: textScaler.clamp(maxScaleFactor: 1.5).scale(16),
      color: designVariables.textMessage.withFadedAlpha(0.4));
  }
}
