import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/events.dart';
import '../model/initial_snapshot.dart';

part 'events.g.dart';

/// https://zulip.com/api/register-queue
Future<InitialSnapshot> registerQueue(ApiConnection connection) async {
  final data = await connection.post('registerQueue', 'register', {
    'apply_markdown': true,
    'slim_presence': true,
    'client_capabilities': {
      'notification_settings_null': true,
      'bulk_message_deletion': true,
      'user_avatar_url_field_optional': true,
      'stream_typing_notifications': false, // TODO implement
      'user_settings_object': true,
    },
  });
  return InitialSnapshot.fromJson(data);
}

/// https://zulip.com/api/get-events
Future<GetEventsResult> getEvents(ApiConnection connection, {
  required String queueId, int? lastEventId, bool? dontBlock,
}) async {
  final data = await connection.get('getEvents', 'events', {
    'queue_id': RawParameter(queueId),
    if (lastEventId != null) 'last_event_id': lastEventId,
    if (dontBlock != null) 'dont_block': dontBlock,
  });
  return GetEventsResult.fromJson(data);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetEventsResult {
  final List<Event> events;
  // TODO(server): Docs say queueId required; empirically sometimes missing.
  final String? queueId;

  GetEventsResult({
    required this.events,
    this.queueId,
  });

  factory GetEventsResult.fromJson(Map<String, dynamic> json) =>
      _$GetEventsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetEventsResultToJson(this);
}
