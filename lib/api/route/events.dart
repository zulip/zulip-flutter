import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/events.dart';
import '../model/initial_snapshot.dart';

part 'events.g.dart';

/// https://zulip.com/api/register-queue
///
/// Unlike in most of our API bindings, this function hard-codes
/// the values of many parameters rather than expose them to the caller.
/// That's because those parameters control the shape of the data
/// that the server returns, mostly in enabling modern rather than legacy APIs.
/// The types in [InitialSnapshot] and the [Event] subclasses, and their
/// deserialization logic, are written for the settings chosen here.
Future<InitialSnapshot> registerQueue(ApiConnection connection, {
  IdleQueueTimeout? idleQueueTimeout,
}) {
  return connection.post('registerQueue', InitialSnapshot.fromJson, 'register', {
    'idle_queue_timeout': ?idleQueueTimeout,

    // Parameters that change the scope of the data we get,
    // and in principle could be exposed to the caller:
    //   event_types and fetch_event_types omitted; get all events and all data
    //   all_public_streams
    //   narrow

    // Parameters that don't make sense to expose to the caller,
    // for the reasons in the dartdoc above.
    // (We might change these; we'll just need to update types to match.)
    'apply_markdown': true,
    'client_gravatar': false, // TODO(#255): turn on
    // 'include_subscribers': false, // the default
    'slim_presence': true,
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

/// A value for `idleQueueTimeout` on [registerQueue].
///
/// https://zulip.com/api/register-queue#parameter-idle_queue_timeout
class IdleQueueTimeout {
  const IdleQueueTimeout.numeric(this._numeric) : _enum = null;

  static const IdleQueueTimeout mobile = IdleQueueTimeout._(.mobile);

  const IdleQueueTimeout._(this._enum) : _numeric = null;

  final int? _numeric;
  final _IdleQueueTimeout? _enum;

  Object toJson() {
    assert((_numeric != null) ^ (_enum != null));
    return _numeric ?? _enum!.name;
  }
}

enum _IdleQueueTimeout {
  mobile;
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
