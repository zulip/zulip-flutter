import '../api/model/model.dart';
import '../model/narrow.dart';

/// A stable key identifying a Zulip conversation for iOS foreground
/// notification suppression.
///
/// Format:
/// * topic: `{realmOrigin}|{userId}|topic:{channelId}:{topicCanonical}`
/// * DM: `{realmOrigin}|{userId}|dm:{sortedRecipientIds}`
///
/// Topics use [TopicName.canonicalize] (case-insensitive).
/// Returns null for narrow types that never appear in push notifications
/// (e.g. [ChannelNarrow], [CombinedFeedNarrow]).
///
/// Must stay in sync with `AppDelegate.conversationKeyForNotifSuppression(from:)`
/// on iOS.
String? conversationKeyForNotifSuppression({
  required Uri realmUrl,
  required int userId,
  required Narrow narrow,
}) {
  return switch (narrow) {
    TopicNarrow(:var channelId, :var topic) =>
      '${realmUrl.origin}|$userId|topic:$channelId:${topic.canonicalize()}',
    DmNarrow(:var allRecipientIds) =>
      '${realmUrl.origin}|$userId|dm:${allRecipientIds.join(',')}',
    _ => null,
  };
}
