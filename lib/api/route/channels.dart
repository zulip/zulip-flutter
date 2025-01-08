import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';
part 'channels.g.dart';

/// https://zulip.com/api/get-stream-topics
Future<GetStreamTopicsResult> getStreamTopics(ApiConnection connection, {
  required int streamId,
}) {
  return connection.get('getStreamTopics', GetStreamTopicsResult.fromJson, 'users/me/$streamId/topics', {});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetStreamTopicsResult {
  final List<GetStreamTopicsEntry> topics;

  GetStreamTopicsResult({
    required this.topics,
  });

  factory GetStreamTopicsResult.fromJson(Map<String, dynamic> json) =>
    _$GetStreamTopicsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetStreamTopicsResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetStreamTopicsEntry {
  final int maxId;
  final TopicName name;

  GetStreamTopicsEntry({
    required this.maxId,
    required this.name,
  });

  factory GetStreamTopicsEntry.fromJson(Map<String, dynamic> json) => _$GetStreamTopicsEntryFromJson(json);

  Map<String, dynamic> toJson() => _$GetStreamTopicsEntryToJson(this);
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
