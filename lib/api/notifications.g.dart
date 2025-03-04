// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageFcmMessage _$MessageFcmMessageFromJson(Map<String, dynamic> json) =>
    MessageFcmMessage(
      server: json['server'] as String,
      realmId: const _IntConverter().fromJson(json['realm_id'] as String),
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
      zulipMessageId: const _IntConverter().fromJson(
        json['zulip_message_id'] as String,
      ),
      content: json['content'] as String,
      time: const _IntConverter().fromJson(json['time'] as String),
    );

Map<String, dynamic> _$MessageFcmMessageToJson(MessageFcmMessage instance) =>
    <String, dynamic>{
      'server': instance.server,
      'realm_id': const _IntConverter().toJson(instance.realmId),
      'realm_url': instance.realmUrl.toString(),
      'user_id': const _IntConverter().toJson(instance.userId),
      'event': instance.type,
      'sender_id': const _IntConverter().toJson(instance.senderId),
      'sender_avatar_url': instance.senderAvatarUrl.toString(),
      'sender_full_name': instance.senderFullName,
      'zulip_message_id': const _IntConverter().toJson(instance.zulipMessageId),
      'time': const _IntConverter().toJson(instance.time),
      'content': instance.content,
    };

FcmMessageChannelRecipient _$FcmMessageChannelRecipientFromJson(
  Map<String, dynamic> json,
) => FcmMessageChannelRecipient(
  streamId: const _IntConverter().fromJson(json['stream_id'] as String),
  streamName: json['stream'] as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

RemoveFcmMessage _$RemoveFcmMessageFromJson(Map<String, dynamic> json) =>
    RemoveFcmMessage(
      server: json['server'] as String,
      realmId: const _IntConverter().fromJson(json['realm_id'] as String),
      realmUrl: Uri.parse(
        FcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
      ),
      userId: const _IntConverter().fromJson(json['user_id'] as String),
      zulipMessageIds: const _IntListConverter().fromJson(
        json['zulip_message_ids'] as String,
      ),
    );

Map<String, dynamic> _$RemoveFcmMessageToJson(RemoveFcmMessage instance) =>
    <String, dynamic>{
      'server': instance.server,
      'realm_id': const _IntConverter().toJson(instance.realmId),
      'realm_url': instance.realmUrl.toString(),
      'user_id': const _IntConverter().toJson(instance.userId),
      'event': instance.type,
      'zulip_message_ids': const _IntListConverter().toJson(
        instance.zulipMessageIds,
      ),
    };
