import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../actions.dart';
import '../../../button.dart';
import '../../../message_list.dart';
import '../../../page.dart';

class UnsubscribedChannelBannerTrailing extends StatelessWidget {
  const UnsubscribedChannelBannerTrailing({super.key, required this.channelId});

  final int channelId;

  @override
  Widget build(BuildContext context) {
    // (A BuildContext that's expected to remain mounted until the whole page
    // disappears, which may be long after the banner disappears.)
    final pageContext = PageRoot.contextOf(context);

    final zulipLocalizations = ZulipLocalizations.of(pageContext);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ZulipWebUiKitButton(
          label: zulipLocalizations.composeBoxBannerButtonRefresh,
          size: .small,
          intent: ZulipWebUiKitButtonIntent.warning,
          onPressed: () {
            MessageListPage.ancestorOf(pageContext).refresh();
          },
        ),
        ZulipWebUiKitButton(
          label: zulipLocalizations.composeBoxBannerButtonSubscribe,
          size: .small,
          intent: ZulipWebUiKitButtonIntent.warning,
          attention: ZulipWebUiKitButtonAttention.high,
          onPressed: () async {
            await ZulipAction.subscribeToChannel(
              pageContext,
              channelId: channelId,
            );
            if (!pageContext.mounted) return;
            MessageListPage.ancestorOf(pageContext).refresh();
          },
        ),
      ],
    );
  }
}
