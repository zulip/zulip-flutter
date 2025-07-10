// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reaction _$ReactionFromJson(Map<String, dynamic> json) => Reaction(
  emojiName: json['emoji_name'] as String,
  emojiCode: json['emoji_code'] as String,
  reactionType: $enumDecode(_$ReactionTypeEnumMap, json['reaction_type']),
  userId: (json['user_id'] as num).toInt(),
);

Map<String, dynamic> _$ReactionToJson(Reaction instance) => <String, dynamic>{
  'emoji_name': instance.emojiName,
  'emoji_code': instance.emojiCode,
  'reaction_type': instance.reactionType,
  'user_id': instance.userId,
};

const _$ReactionTypeEnumMap = {
  ReactionType.unicodeEmoji: 'unicode_emoji',
  ReactionType.realmEmoji: 'realm_emoji',
  ReactionType.zulipExtraEmoji: 'zulip_extra_emoji',
};
