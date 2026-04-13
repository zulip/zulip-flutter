import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/channel.dart';
import '../model/narrow.dart';
import '../model/recent_dm_conversations.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'channel_colors.dart';
import 'color.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
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

    final channelSectionsByFolder = <UiChannelFolder, List<_InboxListItemChannelSection>>{};

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

      final uiChannelFolder = store.uiChannelFolder(streamId);
      (channelSectionsByFolder[uiChannelFolder] ??= [])
        .add(_InboxListItemChannelSection(
          streamId: streamId,
          count: countInStream,
          hasMention: streamHasMention,
          items: topicItems,
        ));
    }

    final sortedFolders = channelSectionsByFolder.keys.toList()
      ..sort(store.compareUiChannelFolders);

    for (final folder in sortedFolders) {
      items.add(_InboxListItemFolderHeader(
        label: folder.name(store: store, zulipLocalizations: zulipLocalizations)));
      final channelSections = channelSectionsByFolder[folder]!;
      channelSections.sort((a, b) {
        final subA = subscriptions[a.streamId]!;
        final subB = subscriptions[b.streamId]!;
        return ChannelStore.compareChannelsByName(subA, subB);
      });
      items.addAll(channelSections);
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

    // TODO(#2259) actually show the trailing markers;
    //   we use this just to anticipate doing that.
    const fontSize = InboxRowTrailingMarkers.fontSize;

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        color: designVariables.background, // TODO(design) check if this is the right variable
        border: Border(top: BorderSide(color: designVariables.borderBar)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(14, 10, 12, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, spacing: 8, children: [
          Expanded(
            child: Text(
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(
                color: designVariables.folderText,
                fontSize: fontSize,
                height: 20 / fontSize,
                letterSpacing: proportionalLetterSpacing(context, 0.02, baseFontSize: fontSize),
              ).merge(weightVariableTextStyle(context, wght: 700)),
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

    final backgroundColor = designVariables.background; // TODO(design) check if this is the right variable
    Widget result = Material(
      color: backgroundColor,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        // TODO(design) this is ad hoc
        highlightColor: designVariables.foreground.withFadedAlpha(0.05),
        onTap: () {
          Navigator.push(context,
            MessageListPage.buildRoute(context: context, narrow: narrow));
        },
        onLongPress: () => showDmActionSheet(context, narrow: narrow),
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44),
          child: Padding(padding: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              DmConversationAvatar(narrow: narrow, backgroundColor: backgroundColor),
              const SizedBox(width: 6),
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  style: TextStyle(
                    fontSize: InboxRowTrailingMarkers.fontSize,
                    height: (19 / InboxRowTrailingMarkers.fontSize),
                    color: designVariables.textMessage,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  title))),
              // 6 in Figma, but 8 is consistent with channel and topic rows
              const SizedBox(width: 8),
              InboxRowTrailingMarkers(
                hasMention: hasMention,
                unreadCountBadge: CounterBadge(
                  // TODO(design) use CounterKind.quantity, following Figma
                  kind: CounterBadgeKind.unread,
                  channelIdForBackground: null,
                  count: count)),
            ])))));

    return Semantics(container: true,
      child: result);
  }
}

@visibleForTesting
class InboxChannelHeaderItem extends StatelessWidget {
  const InboxChannelHeaderItem({
    super.key,
    this.isSticky = false,
    required this.subscription,
    required this.collapsed,
    required this.pageState,
    required this.count,
    required this.hasMention,
    required this.sectionContext,
  });

  /// Whether this is the widget that gets passed to [StickyHeaderItem.header].
  final bool isSticky;

  final Subscription subscription;
  final bool collapsed;
  final InboxPageState pageState;
  final int count;
  final bool hasMention;

  /// A build context within the [_StreamSection] or [_AllDmsSection].
  ///
  /// Used to ensure the [_StreamSection] or [_AllDmsSection] that encloses the
  /// current [InboxFolderHeaderItem] is visible after being collapsed through this
  /// [InboxFolderHeaderItem].
  final BuildContext sectionContext;

  void _onCollapseButtonTap() async {
    if (collapsed) {
      pageState.uncollapseStream(subscription.streamId);
    } else {
      await Scrollable.ensureVisible(
        sectionContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
      pageState.collapseStream(subscription.streamId);
    }
  }

  void _onLongPress() async {
    showChannelActionSheet(sectionContext, channelId: subscription.streamId);
  }

  BoxDecoration _solidBackground(ChannelColorSwatch swatch) =>
    BoxDecoration(color: swatch.barBackground);

  BoxDecoration _gradientBackground(ChannelColorSwatch swatch) => BoxDecoration(
    gradient: LinearGradient(
      begin: .topCenter,
      end: .bottomCenter,
      colors: [
        // TODO(design) is this the right color?
        //   https://chat.zulip.org/#narrow/channel/530-mobile-design/topic/channel.20folders.20in.20inbox.3A.20design/near/2422786
        swatch.barBackground,
        swatch.barBackground.withValues(alpha: 0),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final swatch = colorSwatchFor(context, subscription);

    Widget result = Material(
      color: designVariables.background, // TODO(design) check if this is the right variable
      child: DecoratedBox(
        decoration: (collapsed || isSticky)
          // TODO(design) settle whether to use a solid background:
          //   https://chat.zulip.org/#narrow/channel/530-mobile-design/topic/channel.20folders.20in.20inbox.3A.20design/near/2423220
          ? _solidBackground(swatch)
          : _gradientBackground(swatch),
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          // TODO(design) this is ad hoc
          highlightColor: swatch.barBackground.withFadedAlpha(0.5),
          // TODO use onRowTap to handle taps that are not on the collapse button.
          //   Probably we should give the collapse button a 44px or 48px square
          //   touch target:
          //     <https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/flutter.3A.20Mark-as-read/near/1680973>
          //   But that's in tension with the Figma, which gives these header rows
          //   40px min height.
          onTap: _onCollapseButtonTap,
          onLongPress: _onLongPress,
          child: Padding(padding: EdgeInsetsDirectional.fromSTEB(24, 8, 12, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Icon(size: 18,
                color: swatch.iconOnBarBackground,
                iconDataForStream(subscription)),
              const SizedBox(width: 8),
              // Pin the chevron to the end of the channel name.
              // Let the name grow until the chevron has no room after it,
              // truncating overflow with "...".
              Expanded(child: Row(mainAxisSize: .min, children: [
                Flexible(
                  child: Text(
                    style: TextStyle(
                      fontSize: InboxRowTrailingMarkers.fontSize,
                      height: (20 / InboxRowTrailingMarkers.fontSize),
                      color: designVariables.textMessage,
                    ).merge(weightVariableTextStyle(context, wght: 600)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    subscription.name)),
                if (collapsed) ...[
                  const SizedBox(width: 6),
                  Icon(size: 20,
                    color: designVariables.textMessage.withFadedAlpha(0.5),
                    ZulipIcons.chevron_down),
                ],
              ])),
              const SizedBox(width: 8),
              InboxRowTrailingMarkers(
                hasMention: hasMention,
                unreadCountBadge: CounterBadge(
                  // TODO(design) use CounterKind.quantity, following Figma
                  kind: CounterBadgeKind.unread,
                  channelIdForBackground: subscription.streamId,
                  count: count)),
            ])))));

    return Semantics(container: true,
      child: result);
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
    return StickyHeaderItem(
      header: InboxChannelHeaderItem(
        isSticky: true,
        subscription: subscription,
        count: data.count,
        hasMention: data.hasMention,
        collapsed: collapsed,
        pageState: pageState,
        sectionContext: context,
      ),
      child: Column(children: [
        InboxChannelHeaderItem(
          subscription: subscription,
          count: data.count,
          hasMention: data.hasMention,
          collapsed: collapsed,
          pageState: pageState,
          sectionContext: context,
        ),
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
    final subscription = store.subscriptions[streamId];
    final swatch = colorSwatchFor(context, subscription);

    final designVariables = DesignVariables.of(context);
    final visibilityIcon = iconDataForTopicVisibilityPolicy(
      store.topicVisibilityPolicy(streamId, topic));

    Widget result = Material(
      color: designVariables.background, // TODO(design) check if this is the right variable
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        // TODO(design) this is ad hoc
        highlightColor: swatch.barBackground.withFadedAlpha(0.25),
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
          child: Padding(padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
            child: Center(
              widthFactor: 1,
              child: Row(
                crossAxisAlignment: .baseline,
                textBaseline: localizedTextBaseline(context),
                children: [
                  SizedBox(
                    width: 42,
                    child: Align(
                      // When the system text-size setting rises,
                      // let the checkmark icon grow startward into the margin
                      // so the topic text stays aligned with channel-header text.
                      // (Note: "center" in .centerEnd is inert:
                      // this Align shrink-wraps to its child's height.)
                      alignment: .centerEnd,
                      child: topic.isResolved
                        ? InboxRowMarkerIcon(icon: ZulipIcons.check)
                        : null)),
                  SizedBox(width: 8),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      style: TextStyle(
                        fontSize: InboxRowTrailingMarkers.fontSize,
                        height: (20 / InboxRowTrailingMarkers.fontSize),
                        fontStyle: topic.displayName == null ? FontStyle.italic : null,
                        color: designVariables.textMessage,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      topic.unresolve().displayName ?? store.realmEmptyTopicDisplayName))),
                  const SizedBox(width: 8),
                  InboxRowTrailingMarkers(
                    hasMention: hasMention,
                    visibilityIcon: visibilityIcon,
                    unreadCountBadge: CounterBadge(
                      // TODO(design) use CounterKind.quantity, following Figma
                      kind: CounterBadgeKind.unread,
                      channelIdForBackground: streamId,
                      count: count)),
                ]))))));

    return Semantics(container: true,
      child: result);
  }
}

/// An [InlineIcon] styled for use as a marker in inbox rows.
///
/// This encapsulates style details that should stay in sync
/// across the inbox and topic-list pages.
class InboxRowMarkerIcon extends StatelessWidget {
  const InboxRowMarkerIcon({
    super.key,
    required this.icon,
    this.visible = true,
    this.padBefore = false,
    this.padAfter = false,
  });

  final IconData icon;
  final bool visible;
  final bool padBefore;
  final bool padAfter;

  @override
  Widget build(BuildContext context) {
    return InlineIcon(
      icon: icon,
      fontSize: InboxRowTrailingMarkers.fontSize,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5),
      color: DesignVariables.of(context).textMessage.withFadedAlpha(0.4),
      visible: visible,
      padBefore: padBefore,
      padAfter: padAfter,
    );
  }
}

/// A short, baseline-aligned row, optionally containing
/// an unread badge, @ icon, and topic visibility icon.
///
/// This encapsulates the baseline alignment and a few style choices
/// that should be consistent between the inbox and the topic-list page.
class InboxRowTrailingMarkers extends StatelessWidget {
  const InboxRowTrailingMarkers({
    super.key,
    this.hasMention = false,
    this.visibilityIcon,
    this.unreadCountBadge,
  });

  final bool hasMention;
  final IconData? visibilityIcon;
  final Widget? unreadCountBadge;

  /// The font size used for the row's text, and therefore for the icons here.
  static const fontSize = 17.0;

  Widget _buildIcon(BuildContext context, IconData icon, {required bool padAfter}) {
    return InboxRowMarkerIcon(icon: icon, padAfter: padAfter);
  }

  @override
  Widget build(BuildContext context) {
    final hasBadge = unreadCountBadge != null;
    final hasVisibility = visibilityIcon != null;
    return Row(
      mainAxisSize: .min,
      crossAxisAlignment: .baseline,
      textBaseline: localizedTextBaseline(context),
      children: [
        if (hasMention)
          _buildIcon(context, ZulipIcons.at_sign,
            padAfter: hasVisibility || hasBadge),
        if (hasVisibility)
          _buildIcon(context, visibilityIcon!, padAfter: hasBadge),
        ?unreadCountBadge,
      ]);
  }
}
