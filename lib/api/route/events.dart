// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/events.dart';
import '../model/initial_snapshot.dart';

part 'events.g.dart';

/// https://zulip.com/api/register-queue
Future<InitialSnapshot> registerQueue(ApiConnection connection) async {
  final data = await connection.post('register', {
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
  final json = jsonDecode(data);
  return InitialSnapshot.fromJson(json);
}

/// https://zulip.com/api/get-events
Future<GetEventsResult> getEvents(ApiConnection connection, {
  required String queue_id, int? last_event_id, bool? dont_block,
}) async {
  final data = await connection.get('events', {
    'queue_id': RawParameter(queue_id),
    if (last_event_id != null) 'last_event_id': last_event_id,
    if (dont_block != null) 'dont_block': dont_block,
  });
  return GetEventsResult.fromJson(jsonDecode(data));
}

@JsonSerializable()
class GetEventsResult {
  final List<Event> events;
  // TODO(server): Docs say queue_id required; empirically sometimes missing.
  final String? queue_id;

  GetEventsResult({
    required this.events,
    this.queue_id,
  });

  factory GetEventsResult.fromJson(Map<String, dynamic> json) =>
      _$GetEventsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetEventsResultToJson(this);
}
