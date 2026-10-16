import '../api/notifications.dart';
import '../generated/l10n/zulip_localizations.dart';

String titleForNotifPayload(NotifPayloadNewMessage data, ZulipLocalizations zulipLocalizations) {
  return switch (data.recipient) {
    NotifPayloadChannelRecipient(:var channelName?, :var topic) =>
      '#$channelName > ${topic.displayName}',
    NotifPayloadChannelRecipient(:var topic) =>
      '#${zulipLocalizations.unknownChannelName} > ${topic.displayName}', // TODO get stream name from data
    NotifPayloadDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 =>
      zulipLocalizations.notifGroupDmConversationLabel(
        data.senderFullName, allRecipientIds.length - 2), // TODO use others' names, from data
    NotifPayloadDmRecipient() =>
      data.senderFullName,
  };
}

String subtitleForNotifPayloadOnIos(NotifPayloadNewMessage data) {
  // Adapted from server implementation:
  //   https://github.com/zulip/zulip/blob/11bf985d1/zerver/lib/push_notifications.py#L1087-L1124
  // TODO handle subtitle for user/group/wildcard mentions
  return switch (data.recipient) {
    NotifPayloadChannelRecipient() => '${data.senderFullName}:',

    // The title indicates the sender's name in both 1-1 and group DMs.
    NotifPayloadDmRecipient() => '',
  };
}
