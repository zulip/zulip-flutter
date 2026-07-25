import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';
part 'channels.g.dart';

/// https://zulip.com/api/subscribe
///
/// [subscriptions] is a list of channel names.
/// (This is one of the few remaining areas where the Zulip API hasn't migrated
/// to using IDs.)
Future<void> subscribeToChannel(ApiConnection connection, {
  // TODO(server-future): This should use a stream ID, not stream name.
  //   (Keep dartdoc up to date.)
  //   Server issue: https://github.com/zulip/zulip/issues/10744
  required List<String> subscriptions,
  List<int>? principals,
}) {
  return connection.post('subscribeToChannel', (_) {}, 'users/me/subscriptions', {
    'subscriptions': subscriptions.map((name) => {'name': name}).toList(),
    'principals': ?principals,
  });
}

/// https://zulip.com/api/unsubscribe
///
/// [subscriptions] is a list of channel names.
/// (This is one of the few remaining areas where the Zulip API hasn't migrated
/// to using IDs.)
Future<void> unsubscribeFromChannel(ApiConnection connection, {
  // TODO(server-future): This should use a stream ID, not stream name.
  //   (Keep dartdoc up to date.)
  //   Server issue: https://github.com/zulip/zulip/issues/10744
  required List<String> subscriptions,
  List<int>? principals,
}) {
  return connection.delete('unsubscribeFromChannel', (_) {}, 'users/me/subscriptions', {
    'subscriptions': subscriptions,
    'principals': ?principals,
  });
}

/// https://zulip.com/api/update-subscription-settings
Future<void> updateSubscriptionSettings(ApiConnection connection, {
  required int streamId,
  required SubscriptionProperty property,
  required Object value,
}) {
  return connection.post('updateSubscriptionSettings', (_) {}, 'users/me/subscriptions/properties', {
    'subscription_data': [{
      'stream_id': streamId,
      'property': property,
      'value': value,
    }],
  });
}

/// https://zulip.com/api/get-stream-topics
Future<GetChannelTopicsResult> getChannelTopics(ApiConnection connection, {
  required int channelId,
  required bool allowEmptyTopicName,
}) {
  assert(allowEmptyTopicName, '`allowEmptyTopicName` should only be true');
  return connection.get('getChannelTopics', GetChannelTopicsResult.fromJson, 'users/me/$channelId/topics', {
    'allow_empty_topic_name': allowEmptyTopicName,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetChannelTopicsResult {
  final List<GetChannelTopicsEntry> topics;

  GetChannelTopicsResult({
    required this.topics,
  });

  factory GetChannelTopicsResult.fromJson(Map<String, dynamic> json) =>
    _$GetChannelTopicsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetChannelTopicsResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetChannelTopicsEntry {
  final int maxId;
  final TopicName name;

  GetChannelTopicsEntry({
    required this.maxId,
    required this.name,
  });

  factory GetChannelTopicsEntry.fromJson(Map<String, dynamic> json) => _$GetChannelTopicsEntryFromJson(json);

  Map<String, dynamic> toJson() => _$GetChannelTopicsEntryToJson(this);
}

/// https://zulip.com/api/update-user-topic
Future<void> updateUserTopic(ApiConnection connection, {
  required int channelId,
  required TopicName topic,
  required UserTopicVisibilityPolicy visibilityPolicy,
}) {
  assert(visibilityPolicy != UserTopicVisibilityPolicy.unknown);
  return connection.post('updateUserTopic', (_) {}, 'user_topics', {
    'stream_id': channelId,
    'topic': RawParameter(topic.apiName),
    'visibility_policy': visibilityPolicy,
  });
}
