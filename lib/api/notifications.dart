
import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'model/model.dart';

part 'notifications.g.dart';

/// An FCM message whose contents are encrypted end-to-end from the Zulip server.
///
/// Firebase Cloud Messaging (FCM) is the service run by Google that we use
/// for delivering notifications to Android devices.  A decrypted FCM message
/// may be to tell us we should show a notification, or something else like
/// to remove one (because the user read the underlying Zulip message).
///
/// Once decrypted, the contents will become a [NotifPayload].
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

/// An APNs payload whose contents are encrypted end-to-end from the Zulip server.
///
/// Once decrypted, the contents will become a [NotifPayload].
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#data-sent-to-apns
@JsonSerializable(fieldRename: FieldRename.snake)
class EncryptedApnsPayload {
  final int pushKeyId;

  @JsonKey(fromJson: base64Decode, toJson: base64Encode)
  final Uint8List encryptedData;

  // final Map<String, dynamic> aps; // ignore; never used

  EncryptedApnsPayload({required this.pushKeyId, required this.encryptedData});

  factory EncryptedApnsPayload.fromJson(Map<String, dynamic> json) =>
    _$EncryptedApnsPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptedApnsPayloadToJson(this);
}

//|//////////////////////////////////////////////////////////////
// Types for parsing E2EE notification payloads.
//

/// Parsed version of a notification payload, of any plaintext type.
///
/// For partial API docs, see:
///   https://zulip.com/api/mobile-notifications
sealed class NotifPayload {
  NotifPayload();

  factory NotifPayload.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'message': return NotifPayloadNewMessage.fromJson(json);
      case 'remove': return NotifPayloadRemove.fromJson(json);
      default: return UnexpectedNotifPayload.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

/// A [NotifPayload] of a 'type' we didn't know about.
class UnexpectedNotifPayload extends NotifPayload {
  final Map<String, dynamic> json;

  UnexpectedNotifPayload.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// Base class for [NotifPayload]s that identify what Zulip account they're for.
///
/// This includes all known types of notification payloads from Zulip
/// (all [NotifPayload] subclasses other than [UnexpectedNotifPayload]),
/// and it seems likely that it always will.
sealed class NotifPayloadWithIdentity extends NotifPayload {
  /// The realm's own URL.
  ///
  /// This is a real, absolute URL which is the base for all URLs a client uses
  /// with this realm.  It corresponds to [GetServerSettingsResult.realmUri].
  final Uri realmUrl;

  /// The realm's name.
  final String? realmName;

  /// This user's ID within the server.
  ///
  /// Useful mainly in the case where the user has multiple accounts in the
  /// same realm.
  final int userId;

  NotifPayloadWithIdentity({
    required this.realmUrl,
    required this.realmName,
    required this.userId,
  });
}

/// Parsed version of a notification payload of type `message`.
///
/// This corresponds to a Zulip message for which the user wants to
/// see a notification.
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#new-direct-message
@JsonSerializable(fieldRename: FieldRename.snake)
class NotifPayloadNewMessage extends NotifPayloadWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'message';

  final int senderId;
  final Uri senderAvatarUrl;
  final String senderFullName;

  @JsonKey(includeToJson: false, readValue: _readWhole)
  final NotifPayloadRecipient recipient;

  final int messageId;
  final int time; // in Unix seconds UTC, like [Message.timestamp]

  /// The content of the Zulip message, rendered as plain text.
  ///
  /// This is based on the HTML content, but reduced to plain text specifically
  /// for use in notifications.  For details, see `get_mobile_push_content` in
  /// zulip/zulip:zerver/lib/push_notifications.py .
  final String content;

  NotifPayloadNewMessage({
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

  static Object? _readWhole(Map<dynamic, dynamic> json, String key) => json;

  factory NotifPayloadNewMessage.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'message');
    return _$NotifPayloadNewMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$NotifPayloadNewMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case NotifPayloadDmRecipient(:var allRecipientIds):
        result['recipient_user_ids'] = allRecipientIds;
      case NotifPayloadChannelRecipient():
        result['channel_id'] = recipient.channelId;
        if (recipient.channelName != null) result['channel_name'] = recipient.channelName;
        result['topic'] = recipient.topic;
    }
    return result;
  }
}

/// Data identifying where a Zulip message was sent, as part of a [NotifPayload].
sealed class NotifPayloadRecipient {
  NotifPayloadRecipient();

  factory NotifPayloadRecipient.fromJson(Map<String, dynamic> json) {
    // There's also a `recipient_type` field, but we don't really need it.
    // The presence or absence of `channel_id` is just as informative.
    return (json.containsKey('channel_id'))
      ? NotifPayloadChannelRecipient.fromJson(json)
      : NotifPayloadDmRecipient.fromJson(json);
  }
}

/// A [NotifPayloadRecipient] for a Zulip message to a channel.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NotifPayloadChannelRecipient extends NotifPayloadRecipient {
  final int channelId;

  // Current servers (as of 2025) always send the channel name.  But
  // future servers might not, once clients get the name from local data.
  // So might as well be ready.
  final String? channelName;

  final TopicName topic;

  NotifPayloadChannelRecipient({required this.channelId, required this.channelName, required this.topic});

  factory NotifPayloadChannelRecipient.fromJson(Map<String, dynamic> json) =>
    _$NotifPayloadChannelRecipientFromJson(json);
}

/// A [NotifPayloadRecipient] for a Zulip message that was a DM.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NotifPayloadDmRecipient extends NotifPayloadRecipient {
  @JsonKey(name: 'recipient_user_ids')
  final List<int> allRecipientIds;

  NotifPayloadDmRecipient({required this.allRecipientIds});

  factory NotifPayloadDmRecipient.fromJson(Map<String, dynamic> json) =>
    _$NotifPayloadDmRecipientFromJson(json);
}

/// Parsed version of a notification payload of type `remove`.
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#remove-notifications
@JsonSerializable(fieldRename: FieldRename.snake)
class NotifPayloadRemove extends NotifPayloadWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'remove';

  final List<int> messageIds;

  NotifPayloadRemove({
    required super.realmUrl,
    required super.realmName,
    required super.userId,
    required this.messageIds,
  });

  factory NotifPayloadRemove.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'remove');
    return _$NotifPayloadRemoveFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$NotifPayloadRemoveToJson(this);
}

//|//////////////////////////////////////////////////////////////
// Types for parsing legacy plaintext notification payloads.
//

// TODO(server-12) remove handling of legacy plaintext notifications

/// Parsed version of a legacy plaintext FCM message.
///
/// See pre-E2EE server implementation for reference:
///   https://github.com/zulip/zulip/blob/10.x/zerver/lib/push_notifications.py#L963
sealed class LegacyFcmMessage implements NotifPayload {
  LegacyFcmMessage();

  static NotifPayload fromJson(Map<String, dynamic> json) {
    switch (json['event']) {
      case 'message': return MessageLegacyFcmMessage.fromJson(json);
      case 'remove': return RemoveLegacyFcmMessage.fromJson(json);
      default: return UnexpectedFcmMessage.fromJson(json);
    }
  }

  @override
  Map<String, dynamic> toJson();
}

/// An FCM message of a type (a value of `event`) we didn't know about,
/// and not recognized as an [EncryptedFcmMessage] either.
///
/// The FCM message could have been intended as an E2EE notification
/// or a legacy notification; hard to say, since we didn't understand it.
class UnexpectedFcmMessage implements UnexpectedNotifPayload {
  @override
  final Map<String, dynamic> json;

  UnexpectedFcmMessage.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// Base class for [LegacyFcmMessage]s that identify what Zulip account they're for.
sealed class LegacyFcmMessageWithIdentity extends LegacyFcmMessage implements NotifPayloadWithIdentity {
  // final String server; // ignore; never used, gone with E2EE notifs
  // final int realmId; // ignore; never used, gone with E2EE notifs

  /// The realm's own URL.
  ///
  /// This is a real, absolute URL which is the base for all URLs a client uses
  /// with this realm.  It corresponds to [GetServerSettingsResult.realmUri].
  @override
  @JsonKey(readValue: _readRealmUrl) // TODO(server-9)
  final Uri realmUrl;

  /// The realm's name.
  @override
  final String? realmName; // TODO(server-8)

  /// This user's ID within the server.
  ///
  /// Useful mainly in the case where the user has multiple accounts in the
  /// same realm.
  @override
  @_IntConverter()
  final int userId;

  LegacyFcmMessageWithIdentity({
    required this.realmUrl,
    required this.realmName,
    required this.userId,
  });

  // TODO(server-9): FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
  static String _readRealmUrl(Map<dynamic, dynamic> json, String key) {
    return (json['realm_url'] ?? json['realm_uri']) as String;
  }
}

/// Parsed version of a legacy plaintext FCM message of type `message`.
///
/// This corresponds to a Zulip message for which the user wants to
/// see a notification.
@JsonSerializable(fieldRename: FieldRename.snake)
class MessageLegacyFcmMessage extends LegacyFcmMessageWithIdentity implements NotifPayloadNewMessage {
  @override
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'message';

  @override
  @_IntConverter()
  final int senderId;
  // final String senderEmail; // obsolete; ignore
  @override
  final Uri senderAvatarUrl;
  @override
  final String senderFullName;

  @override
  @JsonKey(includeToJson: false, readValue: _readWhole)
  final LegacyFcmMessageRecipient recipient;

  @override
  @JsonKey(name: 'zulip_message_id')
  @_IntConverter()
  final int messageId;
  @override
  @_IntConverter()
  final int time; // in Unix seconds UTC, like [Message.timestamp]

  /// The content of the Zulip message, rendered as plain text.
  ///
  /// This is based on the HTML content, but reduced to plain text specifically
  /// for use in notifications.  For details, see `get_mobile_push_content` in
  /// zulip/zulip:zerver/lib/push_notifications.py .
  @override
  final String content;

  MessageLegacyFcmMessage({
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

  static Object? _readWhole(Map<dynamic, dynamic> json, String key) => json;

  factory MessageLegacyFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'message');
    return _$MessageLegacyFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$MessageLegacyFcmMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case LegacyFcmMessageDmRecipient(allRecipientIds: [_] || [_, _]):
        break;
      case LegacyFcmMessageDmRecipient(:var allRecipientIds):
        result['pm_users'] = const _IntListConverter().toJson(allRecipientIds);
      case LegacyFcmMessageChannelRecipient():
        result['stream_id'] = const _IntConverter().toJson(recipient.channelId);
        if (recipient.channelName != null) result['stream'] = recipient.channelName;
        result['topic'] = recipient.topic;
    }
    result['realm_uri'] = realmUrl.toString(); // TODO(server-9): deprecated in FL 257
    return result;
  }
}

/// Data identifying where a Zulip message was sent, as part of a [LegacyFcmMessage].
sealed class LegacyFcmMessageRecipient implements NotifPayloadRecipient {
  LegacyFcmMessageRecipient();

  factory LegacyFcmMessageRecipient.fromJson(Map<String, dynamic> json) {
    // There's also a `recipient_type` field, but we don't really need it.
    // The presence or absence of `stream_id` is just as informative.
    return json.containsKey('stream_id')
      ? LegacyFcmMessageChannelRecipient.fromJson(json)
      : LegacyFcmMessageDmRecipient.fromJson(json);
  }
}

/// A [LegacyFcmMessageRecipient] for a Zulip message to a stream.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class LegacyFcmMessageChannelRecipient extends LegacyFcmMessageRecipient implements NotifPayloadChannelRecipient {
  @override
  @JsonKey(name: 'stream_id')
  @_IntConverter()
  final int channelId;

  // Current servers (as of 2025) always send the channel name.  But
  // future servers might not, once clients get the name from local data.
  // So might as well be ready.
  @override
  @JsonKey(name: 'stream')
  final String? channelName;

  @override
  final TopicName topic;

  LegacyFcmMessageChannelRecipient({required this.channelId, required this.channelName, required this.topic});

  factory LegacyFcmMessageChannelRecipient.fromJson(Map<String, dynamic> json) =>
    _$LegacyFcmMessageChannelRecipientFromJson(json);
}

/// A [LegacyFcmMessageRecipient] for a Zulip message that was a DM.
class LegacyFcmMessageDmRecipient extends LegacyFcmMessageRecipient implements NotifPayloadDmRecipient {
  @override
  final List<int> allRecipientIds;

  LegacyFcmMessageDmRecipient({required this.allRecipientIds});

  factory LegacyFcmMessageDmRecipient.fromJson(Map<String, dynamic> json) {
    return LegacyFcmMessageDmRecipient(allRecipientIds: switch (json) {
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
class RemoveLegacyFcmMessage extends LegacyFcmMessageWithIdentity implements NotifPayloadRemove {
  @override
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'remove';

  // Servers have sent zulip_message_ids, obsoleting the singular zulip_message_id
  // and just sending the first ID there redundantly, since 2019.
  // See zulip-mobile@4acd07376.

  @override
  @JsonKey(name: 'zulip_message_ids')
  @_IntListConverter()
  final List<int> messageIds;
  // final String? zulipMessageId; // obsolete; ignore

  RemoveLegacyFcmMessage({
    required super.realmUrl,
    required super.realmName,
    required super.userId,
    required this.messageIds,
  });

  factory RemoveLegacyFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'remove');
    return _$RemoveLegacyFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$RemoveLegacyFcmMessageToJson(this);
    result['realm_uri'] = realmUrl.toString(); // TODO(server-9): deprecated in FL 257
    return result;
  }
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

int _parseInt(String string) => int.parse(string, radix: 10);
