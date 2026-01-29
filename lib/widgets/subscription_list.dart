import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../model/channel.dart';
import '../model/narrow.dart';
import '../model/unreads.dart';
import 'action_sheet.dart';
import 'all_channels.dart';
import 'button.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'theme.dart';
import 'counter_badge.dart';

typedef OnChannelSelectCallback = void Function(ChannelNarrow narrow);

/// Scrollable listing of subscribed streams.
class SubscriptionListPageBody extends StatefulWidget {
  const SubscriptionListPageBody({
    super.key,
    this.showTopicListButtonInActionSheet = true,
    this.hideChannelsIfUserCantSendMessage = false,
    this.allowGoToAllChannels = true,
    this.onChannelSelect,
  });

  // TODO refactor this widget to avoid reuse of the whole page,
  //   avoiding the need for these flags, callback(s), and the below
  //   handling of safe-area at this level of abstraction.
  //   See discussion:
  //     https://github.com/zulip/zulip-flutter/pull/1774#discussion_r2249032503
  final bool showTopicListButtonInActionSheet;
  final bool hideChannelsIfUserCantSendMessage;
  final bool allowGoToAllChannels;

  /// Callback to invoke when the user selects a channel from the list.
  ///
  /// If null, the default behavior is to navigate to the channel feed.
  final OnChannelSelectCallback? onChannelSelect;

  // TODO(#412) add onTopicSelect

  @override
  State<SubscriptionListPageBody> createState() => _SubscriptionListPageBodyState();
}

class _SubscriptionListPageBodyState extends State<SubscriptionListPageBody> with PerAccountStoreAwareStateMixin<SubscriptionListPageBody> {
  Unreads? unreadsModel;

  @override
  void onNewStore() {
    unreadsModel?.removeListener(_modelChanged);
    unreadsModel = PerAccountStoreWidget.of(context).unreads
      ..addListener(_modelChanged);
  }

  @override
  void dispose() {
    unreadsModel?.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in [unreadsModel].
      // This method was called because that just changed.
    });
  }

  void _sortSubs(List<Subscription> list) {
    list.sort((a, b) {
      if (a.isMuted && !b.isMuted) return 1;
      if (!a.isMuted && b.isMuted) return -1;

      return ChannelStore.compareChannelsByName(a, b);
    });
  }

  void _handleChannelSelect(ChannelNarrow narrow) {
    if (widget.onChannelSelect case final onChannelSelect?) {
      onChannelSelect(narrow);
    } else {
      Navigator.push(context,
        MessageListPage.buildRoute(context: context,
          narrow: narrow));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Design referenced from:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=171-12359&mode=design&t=4d0vykoYQ0KGpFuu-0

    // This is an initial version with "Pinned" and "Unpinned"
    // sections following behavior in mobile. Recalculating
    // groups and sorting on every `build` here: it performs well
    // enough and not worth optimizing as it will be replaced
    // with a different behavior:
    // TODO: Implement new grouping behavior and design, see discussion at:
    //   https://chat.zulip.org/#narrow/stream/101-design/topic/UI.20redesign.3A.20left.20sidebar/near/1540147

    // TODO: Implement collapsible topics

    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final includeAllChannelsButton = widget.allowGoToAllChannels
      // See Help Center doc:
      //   https://zulip.com/help/configure-who-can-subscribe
      // > Guests can never subscribe themselves to a channel.
      // (Web also hides the corresponding link for guests;
      // see web/templates/left_sidebar.hbs.)
      && store.selfUser.role.isAtLeast(UserRole.member);

    final List<Subscription> pinned = [];
    final List<Subscription> unpinned = [];
    final now = DateTime.now();
    for (final subscription in store.subscriptions.values) {
      if (widget.hideChannelsIfUserCantSendMessage) {
        if (!store.selfCanSendMessage(inChannel: subscription, byDate: now)) {
          continue;
        }
      }
      if (subscription.pinToTop) {
        pinned.add(subscription);
      } else {
        unpinned.add(subscription);
      }
    }
    _sortSubs(pinned);
    _sortSubs(unpinned);

    if (pinned.isEmpty && unpinned.isEmpty) {
      if (includeAllChannelsButton) {
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.channelsEmptyPlaceholderHeader,
          messageWithLinkMarkup:
            zulipLocalizations.channelsEmptyPlaceholderMessage(
              zulipLocalizations.allChannelsPageTitle),
          onTapMessageLink: () => Navigator.push(context,
            AllChannelsPage.buildRoute(context: context)));
      } else {
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.channelsEmptyPlaceholderHeader);
      }
    }

    return SafeArea(
      // Don't pad the bottom here; we want the list content to do that.
      //
      // When this page is used in the context of the home page, this
      // param and the below use of `SliverSafeArea` would be noop, because
      // `Scaffold.bottomNavigationBar` in the home page handles that for us.
      // But this page is also used for share-to-zulip page, so we need this
      // to be handled here.
      //
      // Other *PageBody widgets don't handle this because they aren't
      // (re-)used outside the context of the home page.
      bottom: false,
      child: CustomScrollView(
        slivers: [
          if (pinned.isNotEmpty) ...[
            _SubscriptionListHeader(label: zulipLocalizations.pinnedSubscriptionsLabel),
            _SubscriptionList(
              unreadsModel: unreadsModel,
              subscriptions: pinned,
              showTopicListButtonInActionSheet: widget.showTopicListButtonInActionSheet,
              onChannelSelect: _handleChannelSelect),
          ],
          if (unpinned.isNotEmpty) ...[
            _SubscriptionListHeader(label: zulipLocalizations.unpinnedSubscriptionsLabel),
            _SubscriptionList(
              unreadsModel: unreadsModel,
              subscriptions: unpinned,
              showTopicListButtonInActionSheet: widget.showTopicListButtonInActionSheet,
              onChannelSelect: _handleChannelSelect),
          ],

          if (includeAllChannelsButton) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: MenuButtonsShape(buttons: [
                  ZulipMenuItemButton(
                    style: ZulipMenuItemButtonStyle.menu,
                    label: zulipLocalizations.navButtonAllChannels,
                    icon: ZulipIcons.chevron_right,
                    onPressed: () => Navigator.push(context,
                      AllChannelsPage.buildRoute(context: context))),
                ]))),
          ],

          // This ensures last item in scrollable can settle in an unobstructed area.
          // (Noop in the home-page case; see comment on `bottom: false` arg in
          // use of `SafeArea` above.)
          const SliverSafeArea(sliver: SliverToBoxAdapter(child: SizedBox.shrink())),
        ]));
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
      // This color comes from the Figma screen for the "@" marker.
      child: Icon(icon, size: 14, color: designVariables.inboxItemIconMarker));
  }
}

class _SubscriptionListHeader extends StatelessWidget {
  const _SubscriptionListHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final line = Expanded(child: Divider(
      color: designVariables.subscriptionListHeaderLine));

    return SliverToBoxAdapter(
      child: ColoredBox(
        color: designVariables.mainBackground,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            line,
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Source Sans 3',
                  color: designVariables.textMessage,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: (20 / 17),
                  letterSpacing: 0,
                ))),
            const SizedBox(width: 8),
            line,
            const SizedBox(width: 16),
          ])));
  }
}

class _SubscriptionList extends StatelessWidget {
  const _SubscriptionList({
    required this.unreadsModel,
    required this.subscriptions,
    required this.showTopicListButtonInActionSheet,
    required this.onChannelSelect,
  });

  final Unreads? unreadsModel;
  final List<Subscription> subscriptions;
  final bool showTopicListButtonInActionSheet;
  final OnChannelSelectCallback onChannelSelect;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: subscriptions.length,
      itemBuilder: (BuildContext context, int index) {
        final subscription = subscriptions[index];
        final unreadCount = unreadsModel!.countInChannel(subscription.streamId);
        final showMutedUnreadBadge = unreadCount == 0
          && unreadsModel!.countInChannelNarrow(subscription.streamId) > 0;

        // Check if any unread messages in this channel are mentions
        bool hasMention = false;
        final streamUnreads = unreadsModel!.streams[subscription.streamId];
        if (streamUnreads != null) {
          for (final messageIds in streamUnreads.values) {
            if (messageIds.any((messageId) => unreadsModel!.mentions.contains(messageId))) {
              hasMention = true;
              break;
            }
          }
        }

        return SubscriptionItem(subscription: subscription,
          unreadCount: unreadCount,
          hasMention: hasMention,
          showMutedUnreadBadge: showMutedUnreadBadge,
          showTopicListButtonInActionSheet: showTopicListButtonInActionSheet,
          onChannelSelect: onChannelSelect);
    });
  }
}

@visibleForTesting
class SubscriptionItem extends StatelessWidget {
  const SubscriptionItem({
    super.key,
    required this.subscription,
    required this.unreadCount,
    required this.hasMention,
    required this.showMutedUnreadBadge,
    required this.showTopicListButtonInActionSheet,
    required this.onChannelSelect,
  });

  final Subscription subscription;
  final int unreadCount;
  final bool hasMention;
  final bool showMutedUnreadBadge;
  final bool showTopicListButtonInActionSheet;
  final OnChannelSelectCallback onChannelSelect;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final swatch = colorSwatchFor(context, subscription);
    final hasUnreads = (unreadCount > 0);
    final opacity = subscription.isMuted ? 0.55 : 1.0;
    return Material(
      color: designVariables.mainBackground,
      child: InkWell(
        onTap: () => onChannelSelect(ChannelNarrow(subscription.streamId)),
        onLongPress: () => showChannelActionSheet(context,
          channelId: subscription.streamId,
          showTopicListButton: showTopicListButtonInActionSheet),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Opacity(
              opacity: opacity,
              child: Icon(
                size: 18,
                // Lock icons (private channels) use a fixed color #90C1C7 per design spec,
                // while other icons follow the assigned channel theme color.
                color: subscription.inviteOnly
                  ? const Color(0xff90C1C7)
                  : swatch.iconOnPlainBackground,
                iconDataForStream(subscription)))),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              // TODO(design): unclear whether bold text is applied to all subscriptions
              //   or only those with unreads:
              //   https://github.com/zulip/zulip-flutter/pull/397#pullrequestreview-1742524205
              child: Opacity(
                opacity: opacity,
                child: Text(
                  style: TextStyle(
                    fontFamily: 'Source Sans 3', // Explicitly match Figma typography
                    fontSize: 18,
                    height: (20 / 18),
                    color: designVariables.textMessage,
                    fontWeight: subscription.isMuted ? FontWeight.normal : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  subscription.name)))),
          if (hasUnreads) ...[
            const SizedBox(width: 12),
            if (hasMention) _IconMarker(icon: ZulipIcons.at_sign),
            CounterBadge(
              kind: CounterBadgeKind.unread,
              count: unreadCount,
              channelIdForBackground: null),
          ] else if (showMutedUnreadBadge) ...[
            const SizedBox(width: 12),
            if (hasMention) _IconMarker(icon: ZulipIcons.at_sign),
            const MutedUnreadBadge(),
          ],
          const SizedBox(width: 16),
        ])));
  }
}
