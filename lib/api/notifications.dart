
import 'package:json_annotation/json_annotation.dart';

import 'model/model.dart';

part 'notifications.g.dart';

/// Parsed version of an FCM message, of any type.
///
/// For partial API docs, see:
///   https://zulip.com/api/mobile-notifications
///
/// Firebase Cloud Messaging (FCM) is the service run by Google that we use
/// for delivering notifications to Android devices.  An FCM message may
/// be to tell us we should show a notification, or something else like
/// to remove one (because the user read the underlying Zulip message).
///
/// The word "message" can be confusing in this context,
/// and in our notification code we usually stick to more specific phrases:
///
///  * An "FCM message" is one of the blobs we receive over FCM; what FCM docs
///    call a "message", and is also known as a "data notification".
///
///    One of these might correspond to zero, one, or more actual notifications
///    we show in the UI.
///
///  * A "Zulip message" is the thing that in other Zulip contexts we call
///    simply a "message": a [Message], the central item in the Zulip app model.
sealed class FcmMessage {
  FcmMessage();

  factory FcmMessage.fromJson(Map<String, dynamic> json) {
    final notifType = json['type'] ?? json['event']; // TODO(server-12)
    switch (notifType) {
      case 'message': return MessageFcmMessage.fromJson(json);
      case 'remove': return RemoveFcmMessage.fromJson(json);
      default: return UnexpectedFcmMessage.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

/// An [FcmMessage] of a type (a value of `event`) we didn't know about.
class UnexpectedFcmMessage extends FcmMessage {
  final Map<String, dynamic> json;

  UnexpectedFcmMessage.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// Base class for [FcmMessage]s that identify what Zulip account they're for.
///
/// This includes all known types of FCM messages from Zulip
/// (all [FcmMessage] subclasses other than [UnexpectedFcmMessage]),
/// and it seems likely that it always will.
sealed class FcmMessageWithIdentity extends FcmMessage {
  // final String server; // ignore; never used, gone with E2EE notifs
  // final int realmId; // ignore; never used, gone with E2EE notifs

  /// The realm's own URL.
  ///
  /// This is a real, absolute URL which is the base for all URLs a client uses
  /// with this realm.  It corresponds to [GetServerSettingsResult.realmUri].
  @JsonKey(readValue: _readRealmUrl) // TODO(server-9)
  final Uri realmUrl;

  /// This user's ID within the server.
  ///
  /// Useful mainly in the case where the user has multiple accounts in the
  /// same realm.
  @JsonKey(readValue: _readIntOrString) // TODO(server-12)
  final int userId;

  FcmMessageWithIdentity({
    required this.realmUrl,
    required this.userId,
  });

  // TODO(server-9): FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
  static String _readRealmUrl(Map<dynamic, dynamic> json, String key) {
    return (json['realm_url'] ?? json['realm_uri']) as String;
  }
}

/// Parsed version of an FCM message of type `message`.
///
/// This corresponds to a Zulip message for which the user wants to
/// see a notification.
///
/// The word "message" can be confusing in this context.
/// See [FcmMessage] for discussion.
@JsonSerializable(fieldRename: FieldRename.snake)
class MessageFcmMessage extends FcmMessageWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'message';

  @JsonKey(readValue: _readIntOrString) // TODO(server-12)
  final int senderId;
  // final String senderEmail; // obsolete; ignore
  final Uri senderAvatarUrl;
  final String senderFullName;

  @JsonKey(includeToJson: false, readValue: _readWhole)
  final FcmMessageRecipient recipient;

  @JsonKey(readValue: _readMessageId)
  final int messageId;
  @JsonKey(readValue: _readIntOrString) // TODO(server-12)
  final int time; // in Unix seconds UTC, like [Message.timestamp]

  /// The content of the Zulip message, rendered as plain text.
  ///
  /// This is based on the HTML content, but reduced to plain text specifically
  /// for use in notifications.  For details, see `get_mobile_push_content` in
  /// zulip/zulip:zerver/lib/push_notifications.py .
  final String content;

  MessageFcmMessage({
    required super.realmUrl,
    required super.userId,
    required this.senderId,
    required this.senderAvatarUrl,
    required this.senderFullName,
    required this.recipient,
    required this.messageId,
    required this.content,
    required this.time,
  });

  static Object? _readMessageId(Map<dynamic, dynamic> json, String key) {
    return json['message_id']
      ?? const _IntConverter().fromJson(json['zulip_message_id'] as String); // TODO(server-12)
  }

  static Object? _readWhole(Map<dynamic, dynamic> json, String key) => json;

  factory MessageFcmMessage.fromJson(Map<String, dynamic> json) {
    assert((json['type'] ?? json['event']) == 'message'); // TODO(server-12)
    return _$MessageFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$MessageFcmMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case FcmMessageDmRecipient(:var allRecipientIds):
        result['recipient_user_ids'] = allRecipientIds;
      case FcmMessageChannelRecipient():
        result['channel_id'] = recipient.channelId;
        if (recipient.channelName != null) result['channel_name'] = recipient.channelName;
        result['topic'] = recipient.topic;
    }
    return result;
  }
}

/// Data identifying where a Zulip message was sent, as part of an [FcmMessage].
sealed class FcmMessageRecipient {
  FcmMessageRecipient();

  factory FcmMessageRecipient.fromJson(Map<String, dynamic> json) {
    // There's also a `recipient_type` field, but we don't really need it.
    // The presence or absence of `channel_id`/`stream_id` is just as informative.
    return (json.containsKey('channel_id') || json.containsKey('stream_id')) // TODO(server-12)
      ? FcmMessageChannelRecipient.fromJson(json)
      : FcmMessageDmRecipient.fromJson(json);
  }
}

/// An [FcmMessageRecipient] for a Zulip message to a stream.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class FcmMessageChannelRecipient extends FcmMessageRecipient {
  @JsonKey(readValue: _readChannelId)
  final int channelId;

  // Current servers (as of 2025) always send the channel name.  But
  // future servers might not, once clients get the name from local data.
  // So might as well be ready.
  @JsonKey(readValue: _readChannelName)
  final String? channelName;

  final TopicName topic;

  FcmMessageChannelRecipient({required this.channelId, required this.channelName, required this.topic});

  static Object? _readChannelId(Map<dynamic, dynamic> json, String key) {
    return json['channel_id']
      ?? const _IntConverter().fromJson(json['stream_id'] as String); // TODO(server-12)
  }

  static Object? _readChannelName(Map<dynamic, dynamic> json, String key) {
    return json['channel_name'] ?? json['stream']; // TODO(server-12)
  }

  factory FcmMessageChannelRecipient.fromJson(Map<String, dynamic> json) =>
    _$FcmMessageChannelRecipientFromJson(json);
}

/// An [FcmMessageRecipient] for a Zulip message that was a DM.
class FcmMessageDmRecipient extends FcmMessageRecipient {
  final List<int> allRecipientIds;

  FcmMessageDmRecipient({required this.allRecipientIds});

  factory FcmMessageDmRecipient.fromJson(Map<String, dynamic> json) {
    return FcmMessageDmRecipient(allRecipientIds: switch (json) {
      // TODO(server-12) accept only the recipient_user_ids form
      {'recipient_user_ids': List<dynamic> userIds} =>
        userIds.map((id) => id as int).toList(),

      // Group DM conversations ("huddles") are represented with `pm_users`,
      // which lists all the user IDs in the conversation.
      // TODO check they're sorted.
      {'pm_users': String pmUsers} => const _IntListConverter().fromJson(pmUsers),

      // 1:1 DM conversations have no `pm_users`.  Knowing that it's a
      // 1:1 DM, `sender_id` is enough to identify the conversation.
      {'sender_id': String senderId, 'user_id': String userId} =>
        _pairSet(_parseInt(senderId), _parseInt(userId)),

      _ => throw Exception("bad recipient"),
    });
  }

  /// The set {id1, id2}, represented as a sorted list.
  // (In set theory this is called the "pair" of id1 and id2: https://en.wikipedia.org/wiki/Axiom_of_pairing .)
  static List<int> _pairSet(int id1, int id2) {
    if (id1 == id2) return [id1];
    if (id1 < id2) return [id1, id2];
    return [id2, id1];
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoveFcmMessage extends FcmMessageWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'remove';

  // Servers have sent zulip_message_ids, obsoleting the singular zulip_message_id
  // and just sending the first ID there redundantly, since 2019.
  // See zulip-mobile@4acd07376.

  @JsonKey(readValue: _readMessageIds)
  final List<int> messageIds;
  // final String? zulipMessageId; // obsolete; ignore

  RemoveFcmMessage({
    required super.realmUrl,
    required super.userId,
    required this.messageIds,
  });

  static Object? _readMessageIds(Map<dynamic, dynamic> json, String key) {
    return json['message_ids']
      ?? const _IntListConverter().fromJson(json['zulip_message_ids'] as String); // TODO(server-12)
  }

  factory RemoveFcmMessage.fromJson(Map<String, dynamic> json) {
    assert((json['type'] ?? json['event']) == 'remove'); // TODO(server-12)
    return _$RemoveFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$RemoveFcmMessageToJson(this);
}

class _IntListConverter extends JsonConverter<List<int>, String> {
  const _IntListConverter();

  @override
  List<int> fromJson(String json) => json.split(',').map(_parseInt).toList();

  @override
  String toJson(List<int> value) => value.join(',');
}

class _IntConverter extends JsonConverter<int, String> {
  const _IntConverter();

  @override
  int fromJson(String json) => _parseInt(json);

  @override
  String toJson(int value) => value.toString();
}

Object? _readIntOrString(Map<dynamic, dynamic> json, String key) {
  final jsonValue = json[key];
  if (jsonValue is String) return _parseInt(jsonValue);
  return jsonValue;
}

int _parseInt(String string) => int.parse(string, radix: 10);
