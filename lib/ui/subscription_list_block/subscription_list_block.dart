import 'package:flutter/material.dart';

import '../../api/model/model.dart';
import '../../generated/l10n/zulip_localizations.dart';
import '../../model/channel.dart';
import '../../model/narrow.dart';
import '../../model/unreads.dart';
import '../all_channels_block/all_channels.dart';
import '../widgets/button.dart';
import '../values/icons.dart';
import '../message_list_block/message_list_block.dart';
import '../utils/page.dart';
import '../utils/store.dart';
import 'widgets/subscription_list.dart';
import 'widgets/subscription_list_header.dart';

typedef OnChannelSelectCallback = void Function(ChannelNarrow narrow);

// Прокручиваемый список подписанных потоков. - переводчик
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
  State<SubscriptionListPageBody> createState() =>
      _SubscriptionListPageBodyState();
}

class _SubscriptionListPageBodyState extends State<SubscriptionListPageBody>
    with PerAccountStoreAwareStateMixin<SubscriptionListPageBody> {
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
      Navigator.push(
        context,
        MessageListBlockPage.buildRoute(context: context, narrow: narrow),
      );
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

    final includeAllChannelsButton =
        widget.allowGoToAllChannels
        // See Help Center doc:
        //   https://zulip.com/help/configure-who-can-subscribe
        // > Guests can never subscribe themselves to a channel.
        // (Web also hides the corresponding link for guests;
        // see web/templates/left_sidebar.hbs.)
        &&
        store.selfUser.role.isAtLeast(UserRole.member);

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
          messageWithLinkMarkup: zulipLocalizations
              .channelsEmptyPlaceholderMessage(
                zulipLocalizations.allChannelsPageTitle,
              ),
          onTapMessageLink: () => Navigator.push(
            context,
            AllChannelsPage.buildRoute(context: context),
          ),
        );
      } else {
        return PageBodyEmptyContentPlaceholder(
          header: zulipLocalizations.channelsEmptyPlaceholderHeader,
        );
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
            SubscriptionListHeader(
              label: zulipLocalizations.pinnedSubscriptionsLabel,
            ),
            SubscriptionList(
              unreadsModel: unreadsModel,
              subscriptions: pinned,
              showTopicListButtonInActionSheet:
                  widget.showTopicListButtonInActionSheet,
              onChannelSelect: _handleChannelSelect,
            ),
          ],
          if (unpinned.isNotEmpty) ...[
            SubscriptionListHeader(
              label: zulipLocalizations.unpinnedSubscriptionsLabel,
            ),
            SubscriptionList(
              unreadsModel: unreadsModel,
              subscriptions: unpinned,
              showTopicListButtonInActionSheet:
                  widget.showTopicListButtonInActionSheet,
              onChannelSelect: _handleChannelSelect,
            ),
          ],

          if (includeAllChannelsButton) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: MenuButtonsShape(
                  buttons: [
                    ZulipMenuItemButton(
                      style: ZulipMenuItemButtonStyle.menu,
                      label: zulipLocalizations.navButtonAllChannels,
                      icon: ZulipIcons.chevron_right,
                      onPressed: () => Navigator.push(
                        context,
                        AllChannelsPage.buildRoute(context: context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // This ensures last item in scrollable can settle in an unobstructed area.
          // (Noop in the home-page case; see comment on `bottom: false` arg in
          // use of `SafeArea` above.)
          const SliverSafeArea(
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}
