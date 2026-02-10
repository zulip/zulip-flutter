import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/events.dart';
import '../model/initial_snapshot.dart';

part 'events.g.dart';

/// https://zulip.com/api/register-queue
Future<InitialSnapshot> registerQueue(ApiConnection connection) {
  return connection.post('registerQueue', InitialSnapshot.fromJson, 'register', {
    'apply_markdown': true,
    'slim_presence': true,
    'client_gravatar': false, // TODO(#255): turn on
    'client_capabilities': {
      'notification_settings_null': true,
      'bulk_message_deletion': true,
      'user_avatar_url_field_optional': false, // TODO(#254): turn on
      'stream_typing_notifications': true,
      'user_settings_object': true,
      'include_deactivated_groups': true,
      'empty_topic_name': true,
    },
  });
}

/// https://zulip.com/api/get-events
Future<GetEventsResult> getEvents(ApiConnection connection, {
  required String queueId, int? lastEventId, bool? dontBlock,
}) {
  return connection.get('getEvents', GetEventsResult.fromJson, 'events', {
    'queue_id': RawParameter(queueId),
    'last_event_id': ?lastEventId,
    'dont_block': ?dontBlock,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetEventsResult {
  final List<Event> events;
  // TODO(server): Docs say queueId required; empirically sometimes missing.
  final String? queueId;

  GetEventsResult({
    required this.events,
    required this.queueId,
  });

  factory GetEventsResult.fromJson(Map<String, dynamic> json) =>
    _$GetEventsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetEventsResultToJson(this);
}
