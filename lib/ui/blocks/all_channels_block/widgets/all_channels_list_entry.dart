import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../get/app_pages.dart';
import '../../../../api/model/model.dart';
import '../../../../api/route/channels.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../log.dart';
import '../../../../model/narrow.dart';
import '../../../utils/actions.dart';
import '../../../utils/remote_settings.dart';
import '../../../utils/store.dart';
import '../../../values/icons.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/action_sheet.dart';
import '../../../widgets/button.dart';

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

    return InkWell(
      onTap: !hasContentAccess
          ? null
          : () => Get.toNamed<dynamic>(
              AppRoutes.topicList,
              arguments: {'narrow': ChannelNarrow(channel.streamId)},
            ),
      onLongPress: () =>
          showChannelActionSheet(context, channelId: channel.streamId),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
          child: Row(
            spacing: 6,
            children: [
              Icon(
                size: 20,
                color: colorSwatchFor(
                  context,
                  subscription,
                ).iconOnPlainBackground,
                iconDataForStream(channel),
              ),
              Expanded(
                child: Text(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: designVariables.textMessage,
                    fontSize: 17,
                    height: 20 / 17,
                  ).merge(weightVariableTextStyle(context, wght: 600)),
                  channel.name,
                ),
              ),
              if (hasContentAccess) _SubscribeToggle(channel: channel),
            ],
          ),
        ),
      ),
    );
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
      findValueInStore: (store) =>
          store.subscriptions.containsKey(channel.streamId),
      sendValueToServer: (value) async {
        if (value) {
          await subscribeToChannel(
            store.connection,
            subscriptions: [channel.name],
          );
        } else {
          await ZulipAction.unsubscribeFromChannel(
            context,
            channelId: channel.streamId,
            alwaysAsk: false,
          );
        }
      },
      // TODO(#741) interpret API errors for user
      onError: (e, requestedValue) => reportErrorToUserBriefly(
        requestedValue
            ? zulipLocalizations.subscribeFailedTitle
            : zulipLocalizations.unsubscribeFailedTitle,
      ),
      builder: (value, handleRequestNewValue) =>
          Toggle(value: value, onChanged: handleRequestNewValue),
    );
  }
}
