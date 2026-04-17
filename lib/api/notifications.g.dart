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

MessageFcmMessage _$MessageFcmMessageFromJson(Map<String, dynamic> json) =>
    MessageFcmMessage(
      realmUrl: Uri.parse(
        FcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
      ),
      realmName: json['realm_name'] as String?,
      userId: (_readIntOrString(json, 'user_id') as num).toInt(),
      senderId: (_readIntOrString(json, 'sender_id') as num).toInt(),
      senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
      senderFullName: json['sender_full_name'] as String,
      recipient: FcmMessageRecipient.fromJson(
        MessageFcmMessage._readWhole(json, 'recipient') as Map<String, dynamic>,
      ),
      messageId: (MessageFcmMessage._readMessageId(json, 'message_id') as num)
          .toInt(),
      content: json['content'] as String,
      time: (_readIntOrString(json, 'time') as num).toInt(),
    );

Map<String, dynamic> _$MessageFcmMessageToJson(MessageFcmMessage instance) =>
    <String, dynamic>{
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

FcmMessageChannelRecipient _$FcmMessageChannelRecipientFromJson(
  Map<String, dynamic> json,
) => FcmMessageChannelRecipient(
  channelId:
      (FcmMessageChannelRecipient._readChannelId(json, 'channel_id') as num)
          .toInt(),
  channelName:
      FcmMessageChannelRecipient._readChannelName(json, 'channel_name')
          as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

RemoveFcmMessage _$RemoveFcmMessageFromJson(Map<String, dynamic> json) =>
    RemoveFcmMessage(
      realmUrl: Uri.parse(
        FcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
      ),
      realmName: json['realm_name'] as String?,
      userId: (_readIntOrString(json, 'user_id') as num).toInt(),
      messageIds:
          (RemoveFcmMessage._readMessageIds(json, 'message_ids')
                  as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList(),
    );

Map<String, dynamic> _$RemoveFcmMessageToJson(RemoveFcmMessage instance) =>
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
