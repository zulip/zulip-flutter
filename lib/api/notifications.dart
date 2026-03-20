
import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'model/model.dart';

part 'notifications.g.dart';

/// An FCM message whose contents are encrypted end-to-end from the Zulip server.
///
/// Once decrypted, the contents will become a [NotifMessage].
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
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#data-sent-to-fcm
@JsonSerializable(fieldRename: FieldRename.snake)
class EncryptedFcmMessage {
  @_IntConverter()
  final int pushKeyId;

  @JsonKey(fromJson: base64Decode, toJson: base64Encode)
  final Uint8List encryptedData;

  EncryptedFcmMessage({required this.pushKeyId, required this.encryptedData});

  factory EncryptedFcmMessage.fromJson(Map<String, dynamic> json) =>
    _$EncryptedFcmMessageFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptedFcmMessageToJson(this);
}

/// Parsed version of a notification message, of any plaintext type.
///
/// This represents the data either decrypted from an [EncryptedFcmMessage],
/// or (TODO(server-12)) delivered in plaintext directly as an FCM payload.
///
/// For partial API docs, see:
///   https://zulip.com/api/mobile-notifications
sealed class NotifMessage {
  NotifMessage();

  factory NotifMessage.fromJson(Map<String, dynamic> json) {
    final notifType = json['type'] ?? json['event']; // TODO(server-12)
    switch (notifType) {
      case 'message': return MessageNotifMessage.fromJson(json);
      case 'remove': return RemoveNotifMessage.fromJson(json);
      default: return UnexpectedNotifMessage.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

/// An [NotifMessage] of a type (a value of `event`) we didn't know about.
class UnexpectedNotifMessage extends NotifMessage {
  final Map<String, dynamic> json;

  UnexpectedNotifMessage.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// Base class for [NotifMessage]s that identify what Zulip account they're for.
///
/// This includes all known types of notification messages from Zulip
/// (all [NotifMessage] subclasses other than [UnexpectedNotifMessage]),
/// and it seems likely that it always will.
sealed class NotifMessageWithIdentity extends NotifMessage {
  // final String server; // ignore; never used, gone with E2EE notifs
  // final int realmId; // ignore; never used, gone with E2EE notifs

  /// The realm's own URL.
  ///
  /// This is a real, absolute URL which is the base for all URLs a client uses
  /// with this realm.  It corresponds to [GetServerSettingsResult.realmUri].
  @JsonKey(readValue: _readRealmUrl) // TODO(server-9)
  final Uri realmUrl;

  /// The realm's name.
  final String? realmName; // TODO(server-8)

  /// This user's ID within the server.
  ///
  /// Useful mainly in the case where the user has multiple accounts in the
  /// same realm.
  @JsonKey(readValue: _readIntOrString) // TODO(server-12)
  final int userId;

  NotifMessageWithIdentity({
    required this.realmUrl,
    required this.realmName,
    required this.userId,
  });

  // TODO(server-9): FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
  static String _readRealmUrl(Map<dynamic, dynamic> json, String key) {
    return (json['realm_url'] ?? json['realm_uri']) as String;
  }
}

/// Parsed version of a notification message of type `message`.
///
/// This corresponds to a Zulip message for which the user wants to
/// see a notification.
///
/// The word "message" can be confusing in this context.
/// See [NotifMessage] for discussion.
@JsonSerializable(fieldRename: FieldRename.snake)
class MessageNotifMessage extends NotifMessageWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'message';

  @JsonKey(readValue: _readIntOrString) // TODO(server-12)
  final int senderId;
  // final String senderEmail; // obsolete; ignore
  final Uri senderAvatarUrl;
  final String senderFullName;

  @JsonKey(includeToJson: false, readValue: _readWhole)
  final NotifMessageRecipient recipient;

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

  MessageNotifMessage({
    required super.realmUrl,
    required super.realmName,
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

  factory MessageNotifMessage.fromJson(Map<String, dynamic> json) {
    assert((json['type'] ?? json['event']) == 'message'); // TODO(server-12)
    return _$MessageNotifMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$MessageNotifMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case NotifMessageDmRecipient(:var allRecipientIds):
        result['recipient_user_ids'] = allRecipientIds;
      case NotifMessageChannelRecipient():
        result['channel_id'] = recipient.channelId;
        if (recipient.channelName != null) result['channel_name'] = recipient.channelName;
        result['topic'] = recipient.topic;
    }
    return result;
  }
}

/// Data identifying where a Zulip message was sent, as part of an [NotifMessage].
sealed class NotifMessageRecipient {
  NotifMessageRecipient();

  factory NotifMessageRecipient.fromJson(Map<String, dynamic> json) {
    // There's also a `recipient_type` field, but we don't really need it.
    // The presence or absence of `channel_id`/`stream_id` is just as informative.
    return (json.containsKey('channel_id') || json.containsKey('stream_id')) // TODO(server-12)
      ? NotifMessageChannelRecipient.fromJson(json)
      : NotifMessageDmRecipient.fromJson(json);
  }
}

/// An [NotifMessageRecipient] for a Zulip message to a stream.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NotifMessageChannelRecipient extends NotifMessageRecipient {
  @JsonKey(readValue: _readChannelId)
  final int channelId;

  // Current servers (as of 2025) always send the channel name.  But
  // future servers might not, once clients get the name from local data.
  // So might as well be ready.
  @JsonKey(readValue: _readChannelName)
  final String? channelName;

  final TopicName topic;

  NotifMessageChannelRecipient({required this.channelId, required this.channelName, required this.topic});

  static Object? _readChannelId(Map<dynamic, dynamic> json, String key) {
    return json['channel_id']
      ?? const _IntConverter().fromJson(json['stream_id'] as String); // TODO(server-12)
  }

  static Object? _readChannelName(Map<dynamic, dynamic> json, String key) {
    return json['channel_name'] ?? json['stream']; // TODO(server-12)
  }

  factory NotifMessageChannelRecipient.fromJson(Map<String, dynamic> json) =>
    _$NotifMessageChannelRecipientFromJson(json);
}

/// An [NotifMessageRecipient] for a Zulip message that was a DM.
class NotifMessageDmRecipient extends NotifMessageRecipient {
  final List<int> allRecipientIds;

  NotifMessageDmRecipient({required this.allRecipientIds});

  factory NotifMessageDmRecipient.fromJson(Map<String, dynamic> json) {
    return NotifMessageDmRecipient(allRecipientIds: switch (json) {
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
class RemoveNotifMessage extends NotifMessageWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'remove';

  // Servers have sent zulip_message_ids, obsoleting the singular zulip_message_id
  // and just sending the first ID there redundantly, since 2019.
  // See zulip-mobile@4acd07376.

  @JsonKey(readValue: _readMessageIds)
  final List<int> messageIds;
  // final String? zulipMessageId; // obsolete; ignore

  RemoveNotifMessage({
    required super.realmUrl,
    required super.realmName,
    required super.userId,
    required this.messageIds,
  });

  static Object? _readMessageIds(Map<dynamic, dynamic> json, String key) {
    return json['message_ids']
      ?? const _IntListConverter().fromJson(json['zulip_message_ids'] as String); // TODO(server-12)
  }

  factory RemoveNotifMessage.fromJson(Map<String, dynamic> json) {
    assert((json['type'] ?? json['event']) == 'remove'); // TODO(server-12)
    return _$RemoveNotifMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$RemoveNotifMessageToJson(this);
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
