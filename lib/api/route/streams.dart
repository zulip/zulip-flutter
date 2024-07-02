import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
part 'streams.g.dart';

/// https://zulip.com/api/get-stream-topics
Future<GetTopicsResult> getStreamTopics(
  ApiConnection connection, {
  required int streamId,
}) {
  return connection.get('getStreamTopics', GetTopicsResult.fromJson,
    'users/me/$streamId/topics', {});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetTopicsResult {
  final List<Topic>? topics;

  GetTopicsResult({
    required this.topics,
  });

  factory GetTopicsResult.fromJson(Map<String, dynamic> json) =>
    _$GetTopicsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetTopicsResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Topic {
  final int maxId;
  final String name;

  Topic({
    required this.maxId,
    required this.name,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);

  Map<String, dynamic> toJson() => _$TopicToJson(this);
}
