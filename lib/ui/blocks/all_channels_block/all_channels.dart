import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../generated/l10n/zulip_localizations.dart';
import '../../../get/services/store_service.dart';
import '../../widgets/app_bar.dart';
import '../../utils/page.dart';
import 'widgets/all_channels_list_entry.dart';

class AllChannelsController extends GetxController {
  // Minimal controller for AllChannelsPage
}

class AllChannelsPage extends GetView<AllChannelsController> {
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
      body: const AllChannelsPageBody(),
    );
  }
}

class AllChannelsPageBody extends StatelessWidget {
  const AllChannelsPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final channels = requirePerAccountStore().streams;

    if (channels.isEmpty) {
      return PageBodyEmptyContentPlaceholder(
        header: zulipLocalizations.allChannelsEmptyPlaceholderHeader,
      );
    }

    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final stream = channels[index];
        if (stream == null) return const SizedBox.shrink();
        return AllChannelsListEntry(channel: stream);
      },
    );
  }
}
