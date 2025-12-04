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
    if (principals != null) 'principals': principals,
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
    if (principals != null) 'principals': principals,
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

/// Update a topic's visibility policy.
///
/// This encapsulates a server-feature check.
// TODO(server-7): remove this and just use updateUserTopic
Future<void> updateUserTopicCompat(ApiConnection connection, {
  required int streamId,
  required TopicName topic,
  required UserTopicVisibilityPolicy visibilityPolicy,
}) {
  final useLegacyApi = connection.zulipFeatureLevel! < 170;
  if (useLegacyApi) {
    final op = switch (visibilityPolicy) {
      UserTopicVisibilityPolicy.none => 'remove',
      UserTopicVisibilityPolicy.muted => 'add',
      _ => throw UnsupportedError('$visibilityPolicy on old server'),
    };
    // https://zulip.com/api/mute-topic
    return connection.patch('muteTopic', (_) {}, 'users/me/subscriptions/muted_topics', {
      'stream_id': streamId,
      'topic': RawParameter(topic.apiName),
      'op': RawParameter(op),
    });
  } else {
    return updateUserTopic(connection,
      streamId: streamId,
      topic: topic,
      visibilityPolicy: visibilityPolicy);
  }
}

/// https://zulip.com/api/update-user-topic
///
/// This binding only supports feature levels 170+.
// TODO(server-7) remove FL 170+ mention in doc, and the related `assert`
Future<void> updateUserTopic(ApiConnection connection, {
  required int streamId,
  required TopicName topic,
  required UserTopicVisibilityPolicy visibilityPolicy,
}) {
  assert(visibilityPolicy != UserTopicVisibilityPolicy.unknown);
  assert(connection.zulipFeatureLevel! >= 170);
  return connection.post('updateUserTopic', (_) {}, 'user_topics', {
    'stream_id': streamId,
    'topic': RawParameter(topic.apiName),
    'visibility_policy': visibilityPolicy,
  });
}
