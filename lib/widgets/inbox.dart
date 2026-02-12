import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/channel.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'sticky_header.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';
import 'counter_badge.dart';

class InboxPageBody extends StatefulWidget {
  const InboxPageBody({super.key});

  @override
  State<InboxPageBody> createState() => _InboxPageState();
}


/// The interface for the state of an [InboxPageBody].
abstract class InboxPageState extends State<InboxPageBody> {
  bool get allDmsCollapsed;
  set allDmsCollapsed(bool value);

  void collapseStream(int streamId);
  void uncollapseStream(int streamId);
}

class _InboxPageState extends State<InboxPageBody> with PerAccountStoreAwareStateMixin<InboxPageBody> implements InboxPageState{
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
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final subscriptions = store.subscriptions;

    // TODO(#1065) make an incrementally-updated view-model for InboxPage
    final items = <_InboxListItem>[];

    // TODO efficiently include DM conversations that aren't recent enough
    //   to appear in recentDmConversationsView, but still have unreads in
    //   unreadsModel.
    final dmItems = <_InboxListItemDmConversation>[];
    for (final dmNarrow in recentDmConversationsModel!.sorted) {
      final countInNarrow = unreadsModel!.countInDmNarrow(dmNarrow);
      if (countInNarrow == 0) {
        continue;
      }
      final hasMention = unreadsModel!.dms[dmNarrow]!.any(
        (messageId) => unreadsModel!.mentions.contains(messageId));
      dmItems.add(_InboxListItemDmConversation(
        narrow: dmNarrow, count: countInNarrow, hasMention: hasMention));
    }
    if (dmItems.isNotEmpty) {
      items.add(_InboxListItemFolderHeader(
        label: zulipLocalizations.recentDmConversationsSectionHeader));
      items.addAll(dmItems);
    }

    final pinnedChannelSections = <_InboxListItemChannelSection>[];
    final otherChannelSections = <_InboxListItemChannelSection>[];
    for (final MapEntry(key: streamId, value: topics) in unreadsModel!.streams.entries) {
      final sub = subscriptions[streamId];
      // Filter out any straggling unreads in unsubscribed streams.
      // There won't normally be any, but it happens with certain infrequent
      // state changes, typically for less than a few hundred milliseconds.
      // See [Unreads].
      //
      // Also, we want to depend on the subscription data for things like
      // choosing the stream icon.
      if (sub == null) continue;

      final topicItems = <InboxChannelSectionTopicData>[];
      int countInStream = 0;
      bool streamHasMention = false;
      for (final MapEntry(key: topic, value: messageIds) in topics.entries) {
        if (!store.isTopicVisible(streamId, topic)) continue;
        final countInTopic = messageIds.length;
        final hasMention = messageIds.any((messageId) => unreadsModel!.mentions.contains(messageId));
        topicItems.add(InboxChannelSectionTopicData(
          topic: topic,
          count: countInTopic,
          hasMention: hasMention,
          lastUnreadId: messageIds.last,
        ));
        countInStream += countInTopic;
        streamHasMention |= hasMention;
      }
      if (countInStream == 0) {
        continue;
      }
      topicItems.sort((a, b) {
        final aLastUnreadId = a.lastUnreadId;
        final bLastUnreadId = b.lastUnreadId;
        return bLastUnreadId.compareTo(aLastUnreadId);
      });
      final section = _InboxListItemChannelSection(
        streamId: streamId,
        count: countInStream,
        hasMention: streamHasMention,
        items: topicItems,
      );
      if (sub.pinToTop) {
        pinnedChannelSections.add(section);
      } else {
        otherChannelSections.add(section);
      }
    }

    // TODO deduplicate sorting code within PINNED and OTHER;
    //   consider realm-level folders too
    if (pinnedChannelSections.isNotEmpty) {
      final label = zulipLocalizations.pinnedChannelsFolderName;
      items.add(_InboxListItemFolderHeader(label: label));
      pinnedChannelSections.sort((a, b) {
        final subA = subscriptions[a.streamId]!;
        final subB = subscriptions[b.streamId]!;

        return ChannelStore.compareChannelsByName(subA, subB);
      });
      items.addAll(pinnedChannelSections);
    }

    if (otherChannelSections.isNotEmpty) {
      final label = zulipLocalizations.otherChannelsFolderName;
      items.add(_InboxListItemFolderHeader(label: label));
      otherChannelSections.sort((a, b) {
        final subA = subscriptions[a.streamId]!;
        final subB = subscriptions[b.streamId]!;

        return ChannelStore.compareChannelsByName(subA, subB);
      });
      items.addAll(otherChannelSections);
    }

    if (items.isEmpty) {
      return PageBodyEmptyContentPlaceholder(
        // TODO(#315) add e.g. "You might be interested in recent conversations."
        header: zulipLocalizations.inboxEmptyPlaceholderHeader,
        message: zulipLocalizations.inboxEmptyPlaceholderMessage);
    }

    return SafeArea( // horizontal insets
      child: StickyHeaderListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          switch (item) {
            case _InboxListItemFolderHeader():
              return InboxFolderHeaderItem(label: item.label);
            case _InboxListItemDmConversation(:final narrow, :final count, :final hasMention):
              return InboxDmItem(narrow: narrow, count: count, hasMention: hasMention);
            case _InboxListItemChannelSection(:var streamId):
              final collapsed = collapsedStreamIds.contains(streamId);
              return _StreamSection(data: item, collapsed: collapsed, pageState: this);
          }
        }));
  }
}

sealed class _InboxListItem {
  const _InboxListItem();
}

class _InboxListItemFolderHeader extends _InboxListItem {
  const _InboxListItemFolderHeader({required this.label});

  /// The label for this folder, not yet uppercased.
  final String label;

  // TODO count, hasMention
}

class _InboxListItemDmConversation extends _InboxListItem {
  const _InboxListItemDmConversation({
    required this.narrow,
    required this.count,
    required this.hasMention,
  });

  final DmNarrow narrow;
  final int count;
  final bool hasMention;
}

class _InboxListItemChannelSection extends _InboxListItem {
  const _InboxListItemChannelSection({
    required this.streamId,
    required this.count,
    required this.hasMention,
    required this.items,
  });

  final int streamId;
  final int count;
  final bool hasMention;
  final List<InboxChannelSectionTopicData> items;
}

@visibleForTesting
class InboxChannelSectionTopicData {
  final TopicName topic;
  final int count;
  final bool hasMention;
  final int lastUnreadId;

  const InboxChannelSectionTopicData({
    required this.topic,
    required this.count,
    required this.hasMention,
    required this.lastUnreadId,
  });
}

abstract class _HeaderItem extends StatelessWidget {
  final bool collapsed;
  final InboxPageState pageState;
  final int count;
  final bool hasMention;

  /// A build context within the [_StreamSection] or [_AllDmsSection].
  ///
  /// Used to ensure the [_StreamSection] or [_AllDmsSection] that encloses the
  /// current [_HeaderItem] is visible after being collapsed through this
  /// [_HeaderItem].
  final BuildContext sectionContext;

  const _HeaderItem({
    super.key,
    required this.collapsed,
    required this.pageState,
    required this.count,
    required this.hasMention,
    required this.sectionContext,
  });

  String title(ZulipLocalizations zulipLocalizations);
  IconData get icon;
  Color collapsedIconColor(BuildContext context);
  Color uncollapsedIconColor(BuildContext context);
  Color uncollapsedBackgroundColor(BuildContext context);

  /// A channel ID, if this represents a channel, else null.
  int? get channelId;

  Future<void> onCollapseButtonTap() async {
    if (!collapsed) {
      await Scrollable.ensureVisible(
        sectionContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  Future<void> onRowTap();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);
    Widget result = Material(
      color: collapsed
        ? designVariables.background // TODO(design) check if this is the right variable
        : uncollapsedBackgroundColor(context),
      child: InkWell(
        // TODO use onRowTap to handle taps that are not on the collapse button.
        //   Probably we should give the collapse button a 44px or 48px square
        //   touch target:
        //     <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680973>
        //   But that's in tension with the Figma, which gives these header rows
        //   40px min height.
        onTap: onCollapseButtonTap,
        onLongPress: this is _LongPressable
          ? (this as _LongPressable).onLongPress
          : null,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: const EdgeInsets.all(10),
            child: Icon(size: 20, color: designVariables.sectionCollapseIcon,
              collapsed ? ZulipIcons.arrow_right : ZulipIcons.arrow_down)),
          Icon(size: 18,
            color: collapsed
              ? collapsedIconColor(context)
              : uncollapsedIconColor(context),
            icon),
          const SizedBox(width: 5),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              style: TextStyle(
                fontSize: 17,
                height: (20 / 17),
                // TODO(design) check if this is the right variable
                color: designVariables.labelMenuButton,
              ).merge(weightVariableTextStyle(context, wght: 600)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              title(zulipLocalizations)))),
          const SizedBox(width: 12),
          if (hasMention) const _IconMarker(icon: ZulipIcons.at_sign),
          Padding(padding: const EdgeInsetsDirectional.only(end: 16),
            child: CounterBadge(
              // TODO(design) use CounterKind.quantity, following Figma
              kind: CounterBadgeKind.unread,
              channelIdForBackground: channelId,
              count: count)),
        ])));

    return Semantics(container: true,
      child: result);
  }
}

@visibleForTesting
class InboxFolderHeaderItem extends StatelessWidget {
  const InboxFolderHeaderItem({super.key, required this.label});

  /// The label for this folder header, not yet uppercased.
  ///
  /// The implementation will call [String.toUpperCase] on this.
  final String label;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    Widget result = ColoredBox(
      color: designVariables.background, // TODO(design) check if this is the right variable
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(14, 8, 12, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, spacing: 8, children: [
          Expanded(
            child: Text(
              style: TextStyle(
                color: designVariables.folderText,
                fontSize: 16,
                height: 20 / 16,
                letterSpacing: proportionalLetterSpacing(context, 0.02, baseFontSize: 16),
              ).merge(weightVariableTextStyle(context, wght: 600)),
              label.toUpperCase())),
        ])));

    return Semantics(container: true,
      child: result);
  }
}

@visibleForTesting
class InboxDmItem extends StatelessWidget {
  const InboxDmItem({
    super.key,
    required this.narrow,
    required this.count,
    required this.hasMention,
  });

  final DmNarrow narrow;
  final int count;
  final bool hasMention;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);

    // TODO write a test where a/the recipient is muted
    final title = switch (narrow.otherRecipientIds) { // TODO dedupe with [RecentDmConversationsItem]
      [] => store.selfUser.fullName,
      [var otherUserId] => store.userDisplayName(otherUserId),

      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Shu'])
      //   // 'Chris、Greg、Alya、Shu'
      _ => narrow.otherRecipientIds.map(store.userDisplayName).join(', '),
    };

    Widget result = Material(
      color: designVariables.background, // TODO(design) check if this is the right variable
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
                style: TextStyle(
                  fontSize: 17,
                  height: (20 / 17),
                  // TODO(design) check if this is the right variable
                  color: designVariables.labelMenuButton,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                title))),
            const SizedBox(width: 12),
            if (hasMention) const  _IconMarker(icon: ZulipIcons.at_sign),
            Padding(padding: const EdgeInsetsDirectional.only(end: 16),
              child: CounterBadge(
                // TODO(design) use CounterKind.quantity, following Figma
                kind: CounterBadgeKind.unread,
                channelIdForBackground: null,
                count: count)),
          ]))));

    return Semantics(container: true,
      child: result);
  }
}

mixin _LongPressable on _HeaderItem {
  // TODO(#1272) move to _HeaderItem base class
  //   when DM headers become long-pressable; remove mixin
  Future<void> onLongPress();
}

@visibleForTesting
class InboxChannelHeaderItem extends _HeaderItem with _LongPressable {
  final Subscription subscription;

  const InboxChannelHeaderItem({
    super.key,
    required this.subscription,
    required super.collapsed,
    required super.pageState,
    required super.count,
    required super.hasMention,
    required super.sectionContext,
  });

  @override String title(ZulipLocalizations zulipLocalizations) =>
    subscription.name;
  @override IconData get icon => iconDataForStream(subscription);
  @override Color collapsedIconColor(context) =>
    colorSwatchFor(context, subscription).iconOnPlainBackground;
  @override Color uncollapsedIconColor(context) =>
    colorSwatchFor(context, subscription).iconOnBarBackground;
  @override Color uncollapsedBackgroundColor(context) =>
    colorSwatchFor(context, subscription).barBackground;
  @override int? get channelId => subscription.streamId;

  @override Future<void> onCollapseButtonTap() async {
    await super.onCollapseButtonTap();
    if (collapsed) {
      pageState.uncollapseStream(subscription.streamId);
    } else {
      pageState.collapseStream(subscription.streamId);
    }
  }
  @override Future<void> onRowTap() => onCollapseButtonTap(); // TODO open channel narrow

  @override
  Future<void> onLongPress() async {
    showChannelActionSheet(sectionContext, channelId: subscription.streamId);
  }
}

class _StreamSection extends StatelessWidget {
  const _StreamSection({
    required this.data,
    required this.collapsed,
    required this.pageState,
  });

  final _InboxListItemChannelSection data;
  final bool collapsed;
  final _InboxPageState pageState;

  @override
  Widget build(BuildContext context) {
    final subscription = PerAccountStoreWidget.of(context).subscriptions[data.streamId]!;
    final header = InboxChannelHeaderItem(
      subscription: subscription,
      count: data.count,
      hasMention: data.hasMention,
      collapsed: collapsed,
      pageState: pageState,
      sectionContext: context,
    );
    return StickyHeaderItem(
      header: header,
      child: Column(children: [
        header,
        if (!collapsed) ...data.items.map((item) {
          return InboxTopicItem(streamId: data.streamId, data: item);
        }),
      ]));
  }
}

@visibleForTesting
class InboxTopicItem extends StatelessWidget {
  const InboxTopicItem({
    super.key,
    required this.streamId,
    required this.data,
  });

  final int streamId;
  final InboxChannelSectionTopicData data;

  @override
  Widget build(BuildContext context) {
    final InboxChannelSectionTopicData(
      :topic, :count, :hasMention, :lastUnreadId) = data;

    final store = PerAccountStoreWidget.of(context);

    final designVariables = DesignVariables.of(context);
    final visibilityIcon = iconDataForTopicVisibilityPolicy(
      store.topicVisibilityPolicy(streamId, topic));

    Widget result = Material(
      color: designVariables.background, // TODO(design) check if this is the right variable
      child: InkWell(
        onTap: () {
          final narrow = TopicNarrow(streamId, topic);
          Navigator.push(context,
            MessageListPage.buildRoute(context: context, narrow: narrow));
        },
        onLongPress: () => showTopicActionSheet(context,
          channelId: streamId,
          topic: topic,
          someMessageIdInTopic: lastUnreadId),
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 34),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(width: 63),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                style: TextStyle(
                  fontSize: 17,
                  height: (20 / 17),
                  fontStyle: topic.displayName == null ? FontStyle.italic : null,
                  // TODO(design) check if this is the right variable
                  color: designVariables.labelMenuButton,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                topic.displayName ?? store.realmEmptyTopicDisplayName))),
            const SizedBox(width: 12),
            if (hasMention) const _IconMarker(icon: ZulipIcons.at_sign),
            // TODO(design) copies the "@" marker color; is there a better color?
            if (visibilityIcon != null) _IconMarker(icon: visibilityIcon),
            Padding(padding: const EdgeInsetsDirectional.only(end: 16),
              child: CounterBadge(
                // TODO(design) use CounterKind.quantity, following Figma
                kind: CounterBadgeKind.unread,
                channelIdForBackground: streamId,
                count: count)),
          ]))));

    return Semantics(container: true,
      child: result);
  }
}

class _IconMarker extends StatelessWidget {
  const _IconMarker({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    // Design for icon markers based on Figma screen:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=224-16386&mode=design&t=JsNndFQ8fKFH0SjS-0
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      // This color comes from the Figma screen for the "@" marker, but not
      // the topic visibility markers.
      child: Icon(icon, size: 14, color: designVariables.inboxItemIconMarker));
  }
}
