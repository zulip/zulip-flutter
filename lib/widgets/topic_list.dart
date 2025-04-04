import 'package:flutter/material.dart';

import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import '../model/topic_list.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'app_bar.dart';
import 'channel_colors.dart';
import 'dialog.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
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
  TopicListView? _model;
  Unreads? _unreadsModel;

  @override
  void onNewStore() {
    _unreadsModel?.removeListener(_modelChanged);
    final store = PerAccountStoreWidget.of(context);
    _unreadsModel = store.unreads..addListener(_modelChanged);

    _model?.dispose();
    _model = TopicListView(store: store, streamId: widget.streamId);
    _model!.addListener(_modelChanged);
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    try {
      await _model!.fetchTopics();
      if (_model!.hasError && mounted) {
        final zulipLocalizations = ZulipLocalizations.of(context);
        showErrorDialog(
          context: context,
          title: zulipLocalizations.errorFetchingTopics,
          message: _model!.errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
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
    _model?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null || _model!.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_model!.topics == null || _model!.topics!.isEmpty) {
      return Center(
        child: Text(ZulipLocalizations.of(context).noTopicsInChannel,
          style: TextStyle(
            color: DesignVariables.of(context).labelMenuButton,
            fontSize: 16,
          )),
      );
    }

    final sortedTopics = List<GetStreamTopicsEntry>.from(_model!.topics!);
    sortedTopics.sort((a, b) => b.maxId.compareTo(a.maxId));

    return SafeArea(
      child: ListView.builder(
        itemCount: sortedTopics.length,
        itemBuilder: (context, index) {
          final topic = sortedTopics[index];
          return TopicListItem(
            streamId: widget.streamId,
            topic: topic,
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
    required this.topic,
  });

  final int streamId;
  final GetStreamTopicsEntry topic;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    final unreads = store.unreads.countInNarrow(
      TopicNarrow(streamId, topic.name)
    );
    final hasUnreads = unreads > 0;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MessageListPage.buildRoute(
            context: context,
            narrow: TopicNarrow(streamId, topic.name),
          ));
        },
        onLongPress: () {
          showTopicActionSheet(
            context,
            channelId: streamId,
            topic: topic.name,
            someMessageIdInTopic: null,
          );
        },
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(width: 28),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: SizedBox(
              height: 16,
              width: 16,
              child: topic.name.displayName.startsWith('✔')
                ? Icon(
                    ZulipIcons.check,
                    size: 12,
                    color: designVariables.textMessage,
                  )
                : null,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      topic.name.displayName.startsWith('✔')
                          ? topic.name.displayName.substring(2).trim()
                          : topic.name.displayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: (20 / 17),
                        color: designVariables.textMessage,
                        fontStyle: topic.name.displayName == 'general chat'
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasUnreads) ...[
                    UnreadCountBadge(
                      count: unreads,
                      backgroundColor: designVariables.bgCounterUnread,
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
