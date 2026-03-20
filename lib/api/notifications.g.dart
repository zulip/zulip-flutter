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

MessageNotifMessage _$MessageNotifMessageFromJson(Map<String, dynamic> json) =>
    MessageNotifMessage(
      realmUrl: Uri.parse(
        NotifMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
      ),
      realmName: json['realm_name'] as String?,
      userId: (_readIntOrString(json, 'user_id') as num).toInt(),
      senderId: (_readIntOrString(json, 'sender_id') as num).toInt(),
      senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
      senderFullName: json['sender_full_name'] as String,
      recipient: NotifMessageRecipient.fromJson(
        MessageNotifMessage._readWhole(json, 'recipient')
            as Map<String, dynamic>,
      ),
      messageId: (MessageNotifMessage._readMessageId(json, 'message_id') as num)
          .toInt(),
      content: json['content'] as String,
      time: (_readIntOrString(json, 'time') as num).toInt(),
    );

Map<String, dynamic> _$MessageNotifMessageToJson(
  MessageNotifMessage instance,
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

NotifMessageChannelRecipient _$NotifMessageChannelRecipientFromJson(
  Map<String, dynamic> json,
) => NotifMessageChannelRecipient(
  channelId:
      (NotifMessageChannelRecipient._readChannelId(json, 'channel_id') as num)
          .toInt(),
  channelName:
      NotifMessageChannelRecipient._readChannelName(json, 'channel_name')
          as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

RemoveNotifMessage _$RemoveNotifMessageFromJson(Map<String, dynamic> json) =>
    RemoveNotifMessage(
      realmUrl: Uri.parse(
        NotifMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
      ),
      realmName: json['realm_name'] as String?,
      userId: (_readIntOrString(json, 'user_id') as num).toInt(),
      messageIds:
          (RemoveNotifMessage._readMessageIds(json, 'message_ids')
                  as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList(),
    );

Map<String, dynamic> _$RemoveNotifMessageToJson(RemoveNotifMessage instance) =>
    <String, dynamic>{
      'realm_url': instance.realmUrl.toString(),
      'realm_name': instance.realmName,
      'user_id': instance.userId,
      'type': instance.type,
      'message_ids': instance.messageIds,
    };
