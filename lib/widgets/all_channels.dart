import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import '../model/channel.dart';
import 'action_sheet.dart';
import 'actions.dart';
import 'app_bar.dart';
import 'button.dart';
import 'icons.dart';
import 'page.dart';
import 'remote_settings.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

/// The "All channels" page.
///
/// See Figma:
///   https://www.figma.com/design/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=7723-6411&m=dev
// The Figma shows this page with both a back button and the bottom nav bar,
// with "#" highlighted, as though it's in a stack with "Subscribed channels"
// that lives in the home page "#" tab.
// We skip making that sub-stack and just make this an ordinary page
// that gets pushed onto the main stack, with no bottom nav bar.
class AllChannelsPage extends StatelessWidget {
  const AllChannelsPage({super.key});

  static AccountRoute<void> buildRoute({required BuildContext context}) {
    return MaterialAccountWidgetRoute(
      context: context, page: const AllChannelsPage());
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: ZulipAppBar(
        title: Text(zulipLocalizations.allChannelsPageTitle)),
      body: AllChannelsPageBody());
  }
}


class AllChannelsPageBody extends StatelessWidget {
  const AllChannelsPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final channels = PerAccountStoreWidget.of(context).streams;

    if (channels.isEmpty) {
      return PageBodyEmptyContentPlaceholder(
        message: zulipLocalizations.allChannelsEmptyPlaceholder);
    }

    final items = channels.values.toList();
    items.sort(ChannelStore.compareChannelsByName);

    final sliverList = SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 8),
      sliver: MediaQuery.removePadding(
        context: context,
        // the bottom inset will be consumed by a different sliver after this one
        removeBottom: true,
        child: SliverSafeArea(
          minimum: EdgeInsetsDirectional.only(start: 8).resolve(Directionality.of(context)),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) =>
              AllChannelsListEntry(channel: items[i])))));

    return CustomScrollView(slivers: [
      sliverList,
      SliverSafeArea(
        // TODO(#1572) "New channel" button
        sliver: SliverPadding(padding: EdgeInsets.zero)),
    ]);
  }
}

@visibleForTesting
class AllChannelsListEntry extends StatelessWidget {
  const AllChannelsListEntry({super.key, required this.channel});

  final ZulipStream channel;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final designVariables = DesignVariables.of(context);
    final channel = this.channel;
    final Subscription? subscription = channel is Subscription ? channel : null;
    final hasContentAccess = store.selfHasContentAccess(channel);

    return ConstrainedBox(constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: 8, end: 4),
        child: Row(spacing: 6, children: [
          Icon(
            size: 20,
            color: colorSwatchFor(context, subscription).iconOnPlainBackground,
            iconDataForStream(channel)),
          Expanded(
            child: Text(
              style: TextStyle(
                color: designVariables.textMessage,
                fontSize: 17,
                height: 20 / 17,
              ).merge(weightVariableTextStyle(context, wght: 600)),
              channel.name)),
          if (hasContentAccess) _SubscribeToggle(channel: channel),
          ZulipIconButton(
            icon: ZulipIcons.more_horizontal,
            onPressed: () {
              showChannelActionSheet(context, channelId: channel.streamId);
            }),
        ])));
  }
}

class _SubscribeToggle extends StatelessWidget {
  const _SubscribeToggle({required this.channel});

  final ZulipStream channel;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);

    return RemoteSettingBuilder<bool>(
      findValueInStore: (store) => store.subscriptions.containsKey(channel.streamId),
      sendValueToServer: (value) async {
        if (value) {
          await subscribeToChannel(store.connection,
            subscriptions: [channel.name]);
        } else {
          await ZulipAction.unsubscribeFromChannel(context,
            channelId: channel.streamId,
            alwaysAsk: false);
        }
      },
      // TODO(#741) interpret API errors for user
      onError: (e, requestedValue) => reportErrorToUserBriefly(
        requestedValue
          ? zulipLocalizations.subscribeFailedTitle
          : zulipLocalizations.unsubscribeFailedTitle),
      builder: (value, handleRequestNewValue) => Toggle(
        value: value,
        onChanged: handleRequestNewValue));
  }
}
