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
  final String name;

  GetStreamTopicsEntry({
    required this.maxId,
    required this.name,
  });

  factory GetStreamTopicsEntry.fromJson(Map<String, dynamic> json) => _$GetStreamTopicsEntryFromJson(json);

  Map<String, dynamic> toJson() => _$GetStreamTopicsEntryToJson(this);
}

/// https://zulip.com/api/subscribe
Future<SubscribeToChannelsResult> subscribeToChannels(ApiConnection connection, List<ZulipStream> streams) {
  return connection.post('subscribe', SubscribeToChannelsResult.fromJson,
    'users/me/subscriptions', {'subscriptions': streams.map((e) => {'name': e.name}).toList()});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SubscribeToChannelsResult {
  final Map<String, List<String>> subscribed;
  final Map<String, List<String>> alreadySubscribed;
  final List<String>? unauthorized;

  SubscribeToChannelsResult({
    required this.subscribed,
    required this.alreadySubscribed,
    this.unauthorized,
  });

  factory SubscribeToChannelsResult.fromJson(Map<String, dynamic> json) =>
    _$SubscribeToChannelsResultFromJson(json);

  Map<String, dynamic> toJson() => _$SubscribeToChannelsResultToJson(this);
}
