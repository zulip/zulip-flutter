import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'sticky_header.dart';
import 'store.dart';
import 'text.dart';
import 'unread_count_badge.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  static Route<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(context: context,
      page: const InboxPage());
  }

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with PerAccountStoreAwareStateMixin<InboxPage> {
  Unreads? unreadsModel;
  RecentDmConversationsView? recentDmConversationsModel;

  get allDmsCollapsed => _allDmsCollapsed;
  bool _allDmsCollapsed = false;
  set allDmsCollapsed(value) {
    setState(() {
      _allDmsCollapsed = value;
    });
  }

  get collapsedStreamIds => _collapsedStreamIds;
  final Set<int> _collapsedStreamIds = {};
  void collapseStream(int streamId) {
    setState(() {
      _collapsedStreamIds.add(streamId);
    });
  }
  void uncollapseStream(int streamId) {
    setState(() {
      _collapsedStreamIds.remove(streamId);
    });
  }

  @override
  void onNewStore() {
    final newStore = PerAccountStoreWidget.of(context);
    unreadsModel?.removeListener(_modelChanged);
    unreadsModel = newStore.unreads..addListener(_modelChanged);
    recentDmConversationsModel?.removeListener(_modelChanged);
    recentDmConversationsModel = newStore.recentDmConversationsView
      ..addListener(_modelChanged);
  }

  @override
  void dispose() {
    unreadsModel?.removeListener(_modelChanged);
    recentDmConversationsModel?.removeListener(_modelChanged);
    super.dispose();
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
      collapsedStreamIds.removeWhere((streamId) =>
        !unreadsModel!.streams.containsKey(streamId));
      if (unreadsModel!.dms.isEmpty) {
        allDmsCollapsed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final subscriptions = store.subscriptions;

    // TODO(perf) make an incrementally-updated view-model for InboxPage
    final sections = <_InboxSectionData>[];

    // TODO efficiently include DM conversations that aren't recent enough
    //   to appear in recentDmConversationsView, but still have unreads in
    //   unreadsModel.
    final dmItems = <(DmNarrow, int)>[];
    int allDmsCount = 0;
    for (final dmNarrow in recentDmConversationsModel!.sorted) {
      final countInNarrow = unreadsModel!.countInDmNarrow(dmNarrow);
      if (countInNarrow == 0) {
        continue;
      }
      dmItems.add((dmNarrow, countInNarrow));
      allDmsCount += countInNarrow;
    }
    if (allDmsCount > 0) {
      sections.add(_AllDmsSectionData(allDmsCount, dmItems));
    }

    final sortedUnreadStreams = unreadsModel!.streams.entries
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
      final topicItems = <(String, int, int)>[];
      int countInStream = 0;
      for (final MapEntry(key: topic, value: messageIds) in topics.entries) {
        if (!store.isTopicVisible(streamId, topic)) continue;
        final countInTopic = messageIds.length;
        topicItems.add((topic, countInTopic, messageIds.last));
        countInStream += countInTopic;
      }
      if (countInStream == 0) {
        continue;
      }
      topicItems.sort((a, b) {
        final (_, _, aLastUnreadId) = a;
        final (_, _, bLastUnreadId) = b;
        return bLastUnreadId.compareTo(aLastUnreadId);
      });
      sections.add(_StreamSectionData(streamId, countInStream, topicItems));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: SafeArea(
        // Don't pad the bottom here; we want the list content to do that.
        bottom: false,
        child: StickyHeaderListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            switch (section) {
              case _AllDmsSectionData():
                return _AllDmsSection(
                  data: section,
                  collapsed: allDmsCollapsed,
                  pageState: this,
                );
              case _StreamSectionData(:var streamId):
                final collapsed = collapsedStreamIds.contains(streamId);
                return _StreamSection(data: section, collapsed: collapsed, pageState: this);
            }
          })));
  }
}

sealed class _InboxSectionData {
  const _InboxSectionData();
}

class _AllDmsSectionData extends _InboxSectionData {
  final int count;
  final List<(DmNarrow, int)> items;

  const _AllDmsSectionData(this.count, this.items);
}

class _StreamSectionData extends _InboxSectionData {
  final int streamId;
  final int count;
  final List<(String, int, int)> items;

  const _StreamSectionData(this.streamId, this.count, this.items);
}

abstract class _HeaderItem extends StatelessWidget {
  final bool collapsed;
  final _InboxPageState pageState;
  final int count;

  const _HeaderItem({
    required this.collapsed,
    required this.pageState,
    required this.count,
  });

  String get title;
  IconData get icon;
  Color get collapsedIconColor;
  Color get uncollapsedIconColor;
  Color get uncollapsedBackgroundColor;
  Color? get unreadCountBadgeBackgroundColor;

  void Function() get onCollapseButtonTap;
  void Function() get onRowTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: collapsed ? Colors.white : uncollapsedBackgroundColor,
      child: InkWell(
        // TODO use onRowTap to handle taps that are not on the collapse button.
        //   Probably we should give the collapse button a 44px or 48px square
        //   touch target:
        //     <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680973>
        //   But that's in tension with the Figma, which gives these header rows
        //   40px min height.
        onTap: onCollapseButtonTap,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: const EdgeInsets.all(10),
            child: Icon(size: 20, color: const Color(0x7F1D2E48),
              collapsed ? ZulipIcons.arrow_right : ZulipIcons.arrow_down)),
          Icon(size: 18, color: collapsed ? collapsedIconColor : uncollapsedIconColor,
            icon),
          const SizedBox(width: 5),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              style: const TextStyle(
                fontFamily: kDefaultFontFamily,
                fontSize: 17,
                height: (20 / 17),
                color: Color(0xFF222222),
              ).merge(weightVariableTextStyle(context, wght: 600, wghtIfPlatformRequestsBold: 900)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              title))),
          const SizedBox(width: 12),
          // TODO(#384) for streams, show @-mention indicator when it applies
          Padding(padding: const EdgeInsetsDirectional.only(end: 16),
            child: UnreadCountBadge(backgroundColor: unreadCountBadgeBackgroundColor, bold: true,
              count: count)),
        ])));
  }
}

class _AllDmsHeaderItem extends _HeaderItem {
  const _AllDmsHeaderItem({
    required super.collapsed,
    required super.pageState,
    required super.count,
  });

  @override get title => 'Direct messages'; // TODO(i18n)
  @override get icon => ZulipIcons.user;
  @override get collapsedIconColor => const Color(0xFF222222);
  @override get uncollapsedIconColor => const Color(0xFF222222);
  @override get uncollapsedBackgroundColor => const Color(0xFFF3F0E7);
  @override get unreadCountBadgeBackgroundColor => null;

  @override get onCollapseButtonTap => () {
    pageState.allDmsCollapsed = !collapsed;
  };
  @override get onRowTap => onCollapseButtonTap; // TODO open all-DMs narrow?
}

class _AllDmsSection extends StatelessWidget {
  const _AllDmsSection({
    required this.data,
    required this.collapsed,
    required this.pageState,
  });

  final _AllDmsSectionData data;
  final bool collapsed;
  final _InboxPageState pageState;

  @override
  Widget build(BuildContext context) {
    final header = _AllDmsHeaderItem(
      count: data.count,
      collapsed: collapsed,
      pageState: pageState,
    );
    return StickyHeaderItem(
      header: header,
      child: Column(children: [
        header,
        if (!collapsed) ...data.items.map((item) {
          final (narrow, count) = item;
          return _DmItem(
            narrow: narrow,
            count: count,
            allDmsCount: data.count,
            pageState: pageState,
          );
        }),
      ]));
  }
}

class _DmItem extends StatelessWidget {
  const _DmItem({
    required this.narrow,
    required this.count,
    required this.allDmsCount,
    required this.pageState
  });

  final DmNarrow narrow;
  final int count;
  final int allDmsCount;
  final _InboxPageState pageState;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final selfUser = store.users[store.account.userId]!;

    final title = switch (narrow.otherRecipientIds) { // TODO dedupe with [RecentDmConversationsItem]
      [] => selfUser.fullName,
      [var otherUserId] => store.users[otherUserId]?.fullName ?? '(unknown user)',

      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Shu'])
      //   // 'Chris、Greg、Alya、Shu'
      _ => narrow.otherRecipientIds.map((id) => store.users[id]?.fullName ?? '(unknown user)').join(', '),
    };

    return StickyHeaderItem(
      header: _AllDmsHeaderItem(
        count: allDmsCount,
        collapsed: false,
        pageState: pageState,
      ),
      allowOverflow: true,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            Navigator.push(context,
              MessageListPage.buildRoute(context: context, narrow: narrow));
          },
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 34),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(width: 63),
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  style: const TextStyle(
                    fontFamily: kDefaultFontFamily,
                    fontSize: 17,
                    height: (20 / 17),
                    color: Color(0xFF222222),
                  ).merge(weightVariableTextStyle(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  title))),
              const SizedBox(width: 12),
              Padding(padding: const EdgeInsetsDirectional.only(end: 16),
                child: UnreadCountBadge(backgroundColor: null,
                  count: count)),
            ])))));
  }
}

class _StreamHeaderItem extends _HeaderItem {
  final Subscription subscription;

  const _StreamHeaderItem({
    required this.subscription,
    required super.collapsed,
    required super.pageState,
    required super.count,
  });

  @override get title => subscription.name;
  @override get icon => iconDataForStream(subscription);
  @override get collapsedIconColor => subscription.colorSwatch().iconOnPlainBackground;
  @override get uncollapsedIconColor => subscription.colorSwatch().iconOnBarBackground;
  @override get uncollapsedBackgroundColor =>
    subscription.colorSwatch().barBackground;
  @override get unreadCountBadgeBackgroundColor =>
    subscription.colorSwatch().unreadCountBadgeBackground;

  @override get onCollapseButtonTap => () {
    if (collapsed) {
      pageState.uncollapseStream(subscription.streamId);
    } else {
      pageState.collapseStream(subscription.streamId);
    }
  };
  @override get onRowTap => onCollapseButtonTap; // TODO open stream narrow
}

class _StreamSection extends StatelessWidget {
  const _StreamSection({
    required this.data,
    required this.collapsed,
    required this.pageState,
  });

  final _StreamSectionData data;
  final bool collapsed;
  final _InboxPageState pageState;

  @override
  Widget build(BuildContext context) {
    final subscription = PerAccountStoreWidget.of(context).subscriptions[data.streamId]!;
    final header = _StreamHeaderItem(
      subscription: subscription,
      count: data.count,
      collapsed: collapsed,
      pageState: pageState,
    );
    return StickyHeaderItem(
      header: header,
      child: Column(children: [
        header,
        if (!collapsed) ...data.items.map((item) {
          final (topic, count, _) = item;
          return _TopicItem(
            streamId: data.streamId,
            topic: topic,
            count: count,
            streamCount: data.count,
            pageState: pageState,
          );
        }),
      ]));
  }
}

class _TopicItem extends StatelessWidget {
  const _TopicItem({
    required this.streamId,
    required this.topic,
    required this.count,
    required this.streamCount,
    required this.pageState,
  });

  final int streamId;
  final String topic;
  final int count;
  final int streamCount;
  final _InboxPageState pageState;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final subscription = store.subscriptions[streamId]!;

    return StickyHeaderItem(
      header: _StreamHeaderItem(
        subscription: subscription,
        count: streamCount,
        collapsed: false,
        pageState: pageState,
      ),
      allowOverflow: true,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            final narrow = TopicNarrow(streamId, topic);
            Navigator.push(context,
              MessageListPage.buildRoute(context: context, narrow: narrow));
          },
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 34),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(width: 63),
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  style: const TextStyle(
                    fontFamily: kDefaultFontFamily,
                    fontSize: 17,
                    height: (20 / 17),
                    color: Color(0xFF222222),
                  ).merge(weightVariableTextStyle(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  topic))),
              const SizedBox(width: 12),
              // TODO(#384) show @-mention indicator when it applies
              Padding(padding: const EdgeInsetsDirectional.only(end: 16),
                child: UnreadCountBadge(backgroundColor: subscription.colorSwatch(),
                  count: count)),
            ])))));
  }
}
