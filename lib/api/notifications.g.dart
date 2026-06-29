// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptedFcmMessage _$EncryptedFcmMessageFromJson(Map<String, dynamic> json) =>
    EncryptedFcmMessage(
      pushKeyId: const _IntConverter().fromJson(json['push_key_id'] as String),
      encryptedData: base64Decode(json['encrypted_data'] as String),
    );

Map<String, dynamic> _$EncryptedFcmMessageToJson(
  EncryptedFcmMessage instance,
) => <String, dynamic>{
  'push_key_id': const _IntConverter().toJson(instance.pushKeyId),
  'encrypted_data': base64Encode(instance.encryptedData),
};

EncryptedApnsPayload _$EncryptedApnsPayloadFromJson(
  Map<String, dynamic> json,
) => EncryptedApnsPayload(
  pushKeyId: (json['push_key_id'] as num).toInt(),
  encryptedData: base64Decode(json['encrypted_data'] as String),
);

Map<String, dynamic> _$EncryptedApnsPayloadToJson(
  EncryptedApnsPayload instance,
) => <String, dynamic>{
  'push_key_id': instance.pushKeyId,
  'encrypted_data': base64Encode(instance.encryptedData),
};

NotifPayloadNewMessage _$NotifPayloadNewMessageFromJson(
  Map<String, dynamic> json,
) => NotifPayloadNewMessage(
  realmUrl: Uri.parse(json['realm_url'] as String),
  realmName: json['realm_name'] as String?,
  userId: (json['user_id'] as num).toInt(),
  senderId: (json['sender_id'] as num).toInt(),
  senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
  senderFullName: json['sender_full_name'] as String,
  recipient: NotifPayloadRecipient.fromJson(
    NotifPayloadNewMessage._readWhole(json, 'recipient')
        as Map<String, dynamic>,
  ),
  messageId: (json['message_id'] as num).toInt(),
  content: json['content'] as String,
  time: (json['time'] as num).toInt(),
);

Map<String, dynamic> _$NotifPayloadNewMessageToJson(
  NotifPayloadNewMessage instance,
) => <String, dynamic>{
  'realm_url': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'user_id': instance.userId,
  'type': instance.type,
  'sender_id': instance.senderId,
  'sender_avatar_url': instance.senderAvatarUrl.toString(),
  'sender_full_name': instance.senderFullName,
  'message_id': instance.messageId,
  'time': instance.time,
  'content': instance.content,
};

NotifPayloadChannelRecipient _$NotifPayloadChannelRecipientFromJson(
  Map<String, dynamic> json,
) => NotifPayloadChannelRecipient(
  channelId: (json['channel_id'] as num).toInt(),
  channelName: json['channel_name'] as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

NotifPayloadDmRecipient _$NotifPayloadDmRecipientFromJson(
  Map<String, dynamic> json,
) => NotifPayloadDmRecipient(
  allRecipientIds: (json['recipient_user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

NotifPayloadRemove _$NotifPayloadRemoveFromJson(Map<String, dynamic> json) =>
    NotifPayloadRemove(
      realmUrl: Uri.parse(json['realm_url'] as String),
      realmName: json['realm_name'] as String?,
      userId: (json['user_id'] as num).toInt(),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$NotifPayloadRemoveToJson(NotifPayloadRemove instance) =>
    <String, dynamic>{
      'realm_url': instance.realmUrl.toString(),
      'realm_name': instance.realmName,
      'user_id': instance.userId,
      'type': instance.type,
      'message_ids': instance.messageIds,
    };

MessageLegacyFcmMessage _$MessageLegacyFcmMessageFromJson(
  Map<String, dynamic> json,
) => MessageLegacyFcmMessage(
  realmUrl: Uri.parse(
    LegacyFcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
  ),
  realmName: json['realm_name'] as String?,
  userId: const _IntConverter().fromJson(json['user_id'] as String),
  senderId: const _IntConverter().fromJson(json['sender_id'] as String),
  senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
  senderFullName: json['sender_full_name'] as String,
  recipient: LegacyFcmMessageRecipient.fromJson(
    MessageLegacyFcmMessage._readWhole(json, 'recipient')
        as Map<String, dynamic>,
  ),
  messageId: const _IntConverter().fromJson(json['zulip_message_id'] as String),
  content: json['content'] as String,
  time: const _IntConverter().fromJson(json['time'] as String),
);

Map<String, dynamic> _$MessageLegacyFcmMessageToJson(
  MessageLegacyFcmMessage instance,
) => <String, dynamic>{
  'realm_url': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'user_id': const _IntConverter().toJson(instance.userId),
  'event': instance.type,
  'sender_id': const _IntConverter().toJson(instance.senderId),
  'sender_avatar_url': instance.senderAvatarUrl.toString(),
  'sender_full_name': instance.senderFullName,
  'zulip_message_id': const _IntConverter().toJson(instance.messageId),
  'time': const _IntConverter().toJson(instance.time),
  'content': instance.content,
};

LegacyFcmMessageChannelRecipient _$LegacyFcmMessageChannelRecipientFromJson(
  Map<String, dynamic> json,
) => LegacyFcmMessageChannelRecipient(
  channelId: const _IntConverter().fromJson(json['stream_id'] as String),
  channelName: json['stream'] as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

RemoveLegacyFcmMessage _$RemoveLegacyFcmMessageFromJson(
  Map<String, dynamic> json,
) => RemoveLegacyFcmMessage(
  realmUrl: Uri.parse(
    LegacyFcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
  ),
  realmName: json['realm_name'] as String?,
  userId: const _IntConverter().fromJson(json['user_id'] as String),
  messageIds: const _IntListConverter().fromJson(
    json['zulip_message_ids'] as String,
  ),
);

Map<String, dynamic> _$RemoveLegacyFcmMessageToJson(
  RemoveLegacyFcmMessage instance,
) => <String, dynamic>{
  'realm_url': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'user_id': const _IntConverter().toJson(instance.userId),
  'event': instance.type,
  'zulip_message_ids': const _IntListConverter().toJson(instance.messageIds),
};
