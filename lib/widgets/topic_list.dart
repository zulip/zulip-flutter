import 'package:flutter/material.dart';

import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'app_bar.dart';
import 'channel_colors.dart';
import 'color.dart';
import 'dialog.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'unread_count_badge.dart';

class TopicListPage extends StatelessWidget {
  const TopicListPage({super.key, required this.streamId});

  static AccountRoute<void> buildRoute({int? accountId, BuildContext? context,
      required int streamId}) {
    return MaterialAccountWidgetRoute(accountId: accountId, context: context,
      page: TopicListPage(streamId: streamId));
  }

  final int streamId;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return PageRoot(child: Scaffold(
      appBar: ZulipAppBar(
        buildTitle: (willCenterTitle) => _TopicListAppBarTitle(
          streamId: streamId,
          willCenterTitle: willCenterTitle
        ),
        backgroundColor: () {
          final store = PerAccountStoreWidget.of(context);
          final subscription = store.subscriptions[streamId];
          if (subscription == null) return Colors.transparent;

          return Theme.of(context).brightness == Brightness.light
              ? ChannelColorSwatches.light.forBaseColor(subscription.color).barBackground
              : ChannelColorSwatches.dark.forBaseColor(subscription.color).barBackground;
        }(),
        shape: Border(bottom: BorderSide(
          color: designVariables.borderBar,
          width: 1,
        )),
        actions: [
          IconButton(
            icon: const Icon(ZulipIcons.message_feed),
            onPressed: () {
              Navigator.push(context, MessageListPage.buildRoute(
                context: context,
                narrow: ChannelNarrow(streamId),
              ));
            },
          ),
        ],
      ),
      body: TopicListPageBody(streamId: streamId),
    ));
  }
}

class _TopicListAppBarTitle extends StatelessWidget {
  const _TopicListAppBarTitle({
    required this.streamId,
    required this.willCenterTitle,
  });

  final int streamId;
  final bool willCenterTitle;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final stream = store.streams[streamId];
    final subscription = store.subscriptions[streamId];
    final designVariables = DesignVariables.of(context);

    final iconData = subscription != null ? iconDataForStream(subscription) : null;
    final alignment = willCenterTitle
      ? Alignment.center
      : AlignmentDirectional.centerStart;

    return SizedBox(
      width: double.infinity,
      child: Align(alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(size: 16, iconData),
            const SizedBox(width: 4),
            Flexible(child: Row(
              children: [
                Text(
                  stream?.name ?? zulipLocalizations.unknownChannelName,
                  style: recipientHeaderTextStyle(context),
                ),
                const SizedBox(width: 10),
                Icon(ZulipIcons.chevron_down, size: 10, color: designVariables.icon),
              ],
            )),
          ]))
    );
  }
}

class TopicListPageBody extends StatefulWidget {
  const TopicListPageBody({super.key, required this.streamId});

  final int streamId;

  @override
  State<TopicListPageBody> createState() => _TopicListPageBodyState();
}

class _TopicListPageBodyState extends State<TopicListPageBody>
    with PerAccountStoreAwareStateMixin<TopicListPageBody> {
  bool _isLoading = true;
  List<GetStreamTopicsEntry>? _topics;
  Unreads? _unreadsModel;

  @override
  void onNewStore() {
    _unreadsModel?.removeListener(_modelChanged);
    _unreadsModel = PerAccountStoreWidget.of(context).unreads
      ..addListener(_modelChanged);
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final store = PerAccountStoreWidget.of(context);
      final response = await getStreamTopics(store.connection, streamId: widget.streamId);

      if (!mounted) return;

      final sortedTopics = response.topics;
      sortedTopics.sort((a, b) => b.maxId.compareTo(a.maxId));

      setState(() {
        _topics = sortedTopics;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final zulipLocalizations = ZulipLocalizations.of(context);
      showErrorDialog(
        context: context,
        title: zulipLocalizations.errorFetchingTopics,
        message: e.toString());
    }
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in the models.
      // This method was called because they just changed.
    });
  }

  @override
  void dispose() {
    _unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_topics == null || _topics!.isEmpty) {
      return Center(
        child: Text(ZulipLocalizations.of(context).noTopicsInChannel,
          style: TextStyle(
            color: DesignVariables.of(context).labelMenuButton,
            fontSize: 16,
          )),
      );
    }

    return SafeArea(
      child: ListView.builder(
        itemCount: _topics!.length,
        itemBuilder: (context, index) {
          final topic = _topics![index];
          return TopicListItem(
            streamId: widget.streamId,
            topicEntry: topic,
          );
        },
      ),
    );
  }
}

class TopicListItem extends StatelessWidget {
  const TopicListItem({
    super.key,
    required this.streamId,
    required this.topicEntry,
  });

  final int streamId;
  final GetStreamTopicsEntry topicEntry;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    final unreads = store.unreads.countInNarrow(
      TopicNarrow(streamId, topicEntry.name)
    );
    final hasUnreads = unreads > 0;

    bool hasMention = false;
    if (hasUnreads) {
      final unreadMessageIds = store.unreads.streams[streamId]?[topicEntry.name] ?? [];
      hasMention = unreadMessageIds.any(
        (messageId) => store.unreads.mentions.contains(messageId));
    }

    final visibilityIcon = iconDataForTopicVisibilityPolicy(
      store.topicVisibilityPolicy(streamId, topicEntry.name));

    final isMutedInStream = !store.isTopicVisibleInStream(streamId, topicEntry.name);

    return Material(
      color: designVariables.bgMessageRegular,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MessageListPage.buildRoute(
            context: context,
            narrow: TopicNarrow(streamId, topicEntry.name),
          ));
        },
        onLongPress: () {
          showTopicActionSheet(
            context,
            channelId: streamId,
            topic: topicEntry.name,
            someMessageIdInTopic: topicEntry.maxId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 28),
            topicEntry.name.isResolved
              ? Opacity(
                opacity: 0.4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Icon(
                      ZulipIcons.check,
                      size: 16,
                      color: designVariables.textMessage,
                    ),
                ),
              )
              : SizedBox.square(dimension: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(topicEntry.name.unresolve().displayName,
                style: TextStyle(
                  fontSize: 17,
                  height: (20 / 17),
                  color: isMutedInStream? designVariables.textMessage.withFadedAlpha(0.5)
                    : designVariables.textMessage,
                ).merge(weightVariableTextStyle(context, wght: 400)))),
            const SizedBox(width: 8),
            Opacity(
              opacity: isMutedInStream ? 0.5 : 1,
              child: Row(spacing: 4,
                children: [
                  if (hasMention) const _IconMarker(icon: ZulipIcons.at_sign),
                  if (visibilityIcon != null) _IconMarker(icon: visibilityIcon),
                  if (hasUnreads) UnreadCountBadge(count: unreads,
                    backgroundColor: designVariables.bgCounterUnread, bold: true)]),
            ),
            const SizedBox(width: 12),
          ]),
        )));
  }
}

class _IconMarker extends StatelessWidget {
  const _IconMarker({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return Opacity(opacity: 0.4,
      child: Icon(icon, size: 16, color: designVariables.textMessage),
    );
  }
}
