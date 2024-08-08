import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/model.dart';
import '../model/narrow.dart';
import 'icons.dart';
import 'message_list.dart';
import 'page.dart';
import 'store.dart';

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
    final streams = store.streams.values.toList();
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.channelListPageTitle)),
      body: SafeArea(
        child: streams.isEmpty ? const _NoStreamsItem() : ListView.builder(
          itemCount: streams.length,
          itemBuilder: (context, index) => ChannelItem(stream: streams[index]))));
  }
}

class _NoStreamsItem extends StatelessWidget {
  const _NoStreamsItem();

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(zulipLocalizations.noChannelsFound,
          textAlign: TextAlign.center,
          style: TextStyle(
            // TODO(#95) need dark-theme color
            color: const HSLColor.fromAHSL(1.0, 240, 0.1, 0.5).toColor(),
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
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(context, MessageListPage.buildRoute(context: context,
          narrow: ChannelNarrow(stream.streamId))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(children: [
            Icon(size: 16, iconDataForStream(stream)),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(stream.name,
                style: const TextStyle(
                  fontSize: 18,
                  height: (20 / 18),
                  // TODO(#95) need dark-theme color
                  color: Color(0xFF262626)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
                if (stream.description.isNotEmpty) Text(
                  stream.description,
                  style: const TextStyle(
                    fontSize: 12,
                    // TODO(#95) need dark-theme color
                    color: Color(0xCC262626)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ])),
            ]))));
  }
}
