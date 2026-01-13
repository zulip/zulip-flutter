// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageFcmMessage _$MessageFcmMessageFromJson(Map<String, dynamic> json) =>
    MessageFcmMessage(
      realmUrl: Uri.parse(
        FcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
      ),
      userId: const _IntConverter().fromJson(json['user_id'] as String),
      senderId: const _IntConverter().fromJson(json['sender_id'] as String),
      senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
      senderFullName: json['sender_full_name'] as String,
      recipient: FcmMessageRecipient.fromJson(
        MessageFcmMessage._readWhole(json, 'recipient') as Map<String, dynamic>,
      ),
      messageId: (MessageFcmMessage._readMessageId(json, 'message_id') as num)
          .toInt(),
      content: json['content'] as String,
      time: const _IntConverter().fromJson(json['time'] as String),
    );

Map<String, dynamic> _$MessageFcmMessageToJson(MessageFcmMessage instance) =>
    <String, dynamic>{
      'realm_url': instance.realmUrl.toString(),
      'user_id': const _IntConverter().toJson(instance.userId),
      'type': instance.type,
      'sender_id': const _IntConverter().toJson(instance.senderId),
      'sender_avatar_url': instance.senderAvatarUrl.toString(),
      'sender_full_name': instance.senderFullName,
      'message_id': instance.messageId,
      'time': const _IntConverter().toJson(instance.time),
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
      userId: const _IntConverter().fromJson(json['user_id'] as String),
      messageIds:
          (RemoveFcmMessage._readMessageIds(json, 'message_ids')
                  as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList(),
    );

Map<String, dynamic> _$RemoveFcmMessageToJson(RemoveFcmMessage instance) =>
    <String, dynamic>{
      'realm_url': instance.realmUrl.toString(),
      'user_id': const _IntConverter().toJson(instance.userId),
      'type': instance.type,
      'message_ids': instance.messageIds,
    };
