import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../model/narrow.dart';
import 'app_bar.dart';
import '../model/store.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';
import 'text.dart';
import 'theme.dart';

class ChannelListPage extends StatelessWidget {
  const ChannelListPage({super.key});

  static Route<void> buildRoute({int? accountId, BuildContext? context}) {
    return MaterialAccountWidgetRoute(accountId: accountId, context: context,
      page: const ChannelListPage());
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);
    final streams = store.streams.values.toList()..sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return Scaffold(
      appBar: ZulipAppBar(title: Text(zulipLocalizations.channelListPageTitle)),
      body: SafeArea(
        // Don't pad the bottom here; we want the list content to do that.
        bottom: false,
        child: streams.isEmpty ? const _NoChannelsItem() : ListView.builder(
          itemCount: streams.length,
          itemBuilder: (context, index) => ChannelItem(stream: streams[index]))));
  }
}

class _NoChannelsItem extends StatelessWidget {
  const _NoChannelsItem();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final designVariables = DesignVariables.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(zulipLocalizations.noChannelsFound,
          textAlign: TextAlign.center,
          style: TextStyle(
            // TODO(design) check if this is the right variable
            color: designVariables.subscriptionListHeaderText,
            fontSize: 18,
            height: (20 / 18),
          ))));
  }
}

@visibleForTesting
class ChannelItem extends StatelessWidget {
  const ChannelItem({super.key, required this.stream});

  final ZulipStream stream;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return Material(
      // TODO(design) check if this is the right variable
      color: designVariables.background,
      child: InkWell(
        onTap: () => Navigator.push(context, MessageListPage.buildRoute(context: context,
          narrow: ChannelNarrow(stream.streamId))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(children: [
            Icon(size: 16, iconDataForStream(stream)),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(stream.name,
                  style: TextStyle(
                    fontSize: 18,
                    height: (20 / 18),
                    // TODO(design) check if this is the right variable
                    color: designVariables.labelMenuButton),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                // TODO(#488) parse and show `stream.renderedDescription` with content widget
                if (stream.description.isNotEmpty) Text(
                  stream.description,
                  style: TextStyle(
                    fontSize: 12,
                    // TODO(design) check if this is the right variable
                    color: designVariables.labelMenuButton.withValues(alpha: 0xBF)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ])),
            const SizedBox(width: 8),
            if (stream is! Subscription) _ChannelItemSubscribeButton(stream: stream, channelItemContext: context),
          ]))));
  }
}

class _ChannelItemSubscribeButton extends StatefulWidget {
  const _ChannelItemSubscribeButton({required this.stream, required this.channelItemContext});

  final ZulipStream stream;
  final BuildContext channelItemContext;

  @override
  State<_ChannelItemSubscribeButton> createState() => _ChannelItemSubscribeButtonState();
}

class _ChannelItemSubscribeButtonState extends State<_ChannelItemSubscribeButton> {
  bool _isLoading = false;

  void _setIsLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: _isLoading ? null : () async {
        _setIsLoading(true);
        await _subscribeToChannel(context, widget.stream);
        _setIsLoading(false);
      });
  }

  Future<void> _subscribeToChannel(BuildContext context, ZulipStream stream) async {
    final store = PerAccountStoreWidget.of(context);
    final connection = store.connection;
    final zulipLocalizations = ZulipLocalizations.of(context);
    try {
      final res = await subscribeToChannels(connection, [stream]);
      if (!context.mounted) return;
      if (_subscriptionResultContains(store, res.subscribed, stream.name)) {
        _showSnackbarWithChannelTitle(context, zulipLocalizations.messageSubscribedToChannel, stream);
      } else if (_subscriptionResultContains(store, res.alreadySubscribed, stream.name)) {
        _showSnackbarWithChannelTitle(context, zulipLocalizations.messageAlreadySubscribedToChannel, stream);
      } else {
        _showSnackbarWithChannelTitle(context, zulipLocalizations.errorFailedToSubscribeToChannel, stream);
      }
    } catch (e) {
      if (!context.mounted) return;
      final zulipLocalizations = ZulipLocalizations.of(context);
      _showSnackbarWithChannelTitle(context, zulipLocalizations.errorFailedToSubscribeToChannel, stream);
    }
  }

  bool _subscriptionResultContains(PerAccountStore store, Map<String, List<String>> emailOrIdSubs, String subscription) {
    // TODO (server-10) Before the user keys were Zulip API email addresses, not user ID.
    final expectedEmail = store.users[store.selfUserId]?.email;
    final foundByEmail = emailOrIdSubs[expectedEmail]?.contains(subscription);
    final foundById = emailOrIdSubs[store.selfUserId.toString()]?.contains(subscription);
    return foundByEmail ?? foundById ?? false;
  }

  void _showSnackbarWithChannelTitle(BuildContext context, String message, ZulipStream stream) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text.rich(TextSpan(text: message, children: [
          WidgetSpan(child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(
              size: 12,
              iconDataForStream(stream),
              color: Theme.of(context).scaffoldBackgroundColor))),
          TextSpan(text: ' ${stream.name}.', style: weightVariableTextStyle(context, wght: 700)),
    ]))));
  }
}
