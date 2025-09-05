import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../log.dart';
import 'action_sheet.dart';
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
      body: AllChannels());
  }
}

class AllChannels extends StatelessWidget {
  const AllChannels({super.key});

  // TODO(linter): The linter incorrectly flags the following regexp string
  //    as invalid. See: https://github.com/dart-lang/sdk/issues/61246
  // ignore: valid_regexps
  static final _startsWithEmojiRegex = RegExp(r'^\p{Emoji}', unicode: true);

  void _sort(List<ZulipStream> list) {
    list.sort((a, b) {
      // A user gave feedback wanting zulip-flutter to match web in putting
      // emoji-prefixed channels first; see #1202.
      // TODO(#1165) for matching web's ordering completely, which
      //   (for the all-channels view) I think just means locale-aware sorting.
      final aStartsWithEmoji = _startsWithEmojiRegex.hasMatch(a.name);
      final bStartsWithEmoji = _startsWithEmojiRegex.hasMatch(b.name);
      if (aStartsWithEmoji && !bStartsWithEmoji) return -1;
      if (!aStartsWithEmoji && bStartsWithEmoji) return 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final channels = PerAccountStoreWidget.of(context).streams;

    if (channels.isEmpty) {
      return PageBodyEmptyContentPlaceholder(
        message: zulipLocalizations.allChannelsEmptyPlaceholder);
    }

    final items = channels.values.toList();
    _sort(items);

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
        minimum: EdgeInsets.only(bottom: 8),
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

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 40),
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
        switch (value) {
          case true:
            await subscribeToChannel(store.connection,
              subscriptions: [channel.name]);
          case false:
            await unsubscribeFromChannel(store.connection,
              subscriptions: [channel.name]);
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
