import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../model/channel.dart';
import '../../widgets/app_bar.dart';
import '../../utils/page.dart';
import '../../utils/store.dart';
import 'widgets/all_channels_list_entry.dart';

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
      context: context,
      page: const AllChannelsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: ZulipAppBar(title: Text(zulipLocalizations.allChannelsPageTitle)),
      body: AllChannelsPageBody(),
    );
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
        header: zulipLocalizations.allChannelsEmptyPlaceholderHeader,
      );
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
          minimum: EdgeInsetsDirectional.only(
            start: 8,
          ).resolve(Directionality.of(context)),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) =>
                AllChannelsListEntry(channel: items[i]),
          ),
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        sliverList,
        SliverSafeArea(
          // TODO(#1572) "New channel" button
          sliver: SliverPadding(padding: EdgeInsets.zero),
        ),
      ],
    );
  }
}
