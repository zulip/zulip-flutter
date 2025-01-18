// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomProfileField _$CustomProfileFieldFromJson(Map<String, dynamic> json) =>
    CustomProfileField(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(_$CustomProfileFieldTypeEnumMap, json['type'],
          unknownValue: CustomProfileFieldType.unknown),
      order: (json['order'] as num).toInt(),
      name: json['name'] as String,
      hint: json['hint'] as String,
      fieldData: json['field_data'] as String,
      displayInProfileSummary: json['display_in_profile_summary'] as bool?,
    );

Map<String, dynamic> _$CustomProfileFieldToJson(CustomProfileField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'order': instance.order,
      'name': instance.name,
      'hint': instance.hint,
      'field_data': instance.fieldData,
      'display_in_profile_summary': instance.displayInProfileSummary,
    };

const _$CustomProfileFieldTypeEnumMap = {
  CustomProfileFieldType.shortText: 1,
  CustomProfileFieldType.longText: 2,
  CustomProfileFieldType.choice: 3,
  CustomProfileFieldType.date: 4,
  CustomProfileFieldType.link: 5,
  CustomProfileFieldType.user: 6,
  CustomProfileFieldType.externalAccount: 7,
  CustomProfileFieldType.pronouns: 8,
  CustomProfileFieldType.unknown: null,
};

CustomProfileFieldChoiceDataItem _$CustomProfileFieldChoiceDataItemFromJson(
        Map<String, dynamic> json) =>
    CustomProfileFieldChoiceDataItem(
      text: json['text'] as String,
    );

Map<String, dynamic> _$CustomProfileFieldChoiceDataItemToJson(
        CustomProfileFieldChoiceDataItem instance) =>
    <String, dynamic>{
      'text': instance.text,
    };

CustomProfileFieldExternalAccountData
    _$CustomProfileFieldExternalAccountDataFromJson(
            Map<String, dynamic> json) =>
        CustomProfileFieldExternalAccountData(
          subtype: json['subtype'] as String,
          urlPattern: json['url_pattern'] as String?,
        );

Map<String, dynamic> _$CustomProfileFieldExternalAccountDataToJson(
        CustomProfileFieldExternalAccountData instance) =>
    <String, dynamic>{
      'subtype': instance.subtype,
      'url_pattern': instance.urlPattern,
    };

RealmEmojiItem _$RealmEmojiItemFromJson(Map<String, dynamic> json) =>
    RealmEmojiItem(
      emojiCode: json['id'] as String,
      name: json['name'] as String,
      sourceUrl: json['source_url'] as String,
      stillUrl: json['still_url'] as String?,
      deactivated: json['deactivated'] as bool,
      authorId: (json['author_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RealmEmojiItemToJson(RealmEmojiItem instance) =>
    <String, dynamic>{
      'id': instance.emojiCode,
      'name': instance.name,
      'source_url': instance.sourceUrl,
      'still_url': instance.stillUrl,
      'deactivated': instance.deactivated,
      'author_id': instance.authorId,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
      userId: (json['user_id'] as num).toInt(),
      deliveryEmail: json['delivery_email'] as String?,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      dateJoined: json['date_joined'] as String,
      isActive: json['is_active'] as bool,
      isBillingAdmin: json['is_billing_admin'] as bool?,
      isBot: json['is_bot'] as bool,
      botType: (json['bot_type'] as num?)?.toInt(),
      botOwnerId: (json['bot_owner_id'] as num?)?.toInt(),
      role: $enumDecode(_$UserRoleEnumMap, json['role'],
          unknownValue: UserRole.unknown),
      timezone: json['timezone'] as String,
      avatarUrl: json['avatar_url'] as String?,
      avatarVersion: (json['avatar_version'] as num).toInt(),
      profileData:
          (User._readProfileData(json, 'profile_data') as Map<String, dynamic>?)
              ?.map(
        (k, e) => MapEntry(int.parse(k),
            ProfileFieldUserData.fromJson(e as Map<String, dynamic>)),
      ),
      isSystemBot: User._readIsSystemBot(json, 'is_system_bot') as bool,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'user_id': instance.userId,
      'delivery_email': instance.deliveryEmail,
      'email': instance.email,
      'full_name': instance.fullName,
      'date_joined': instance.dateJoined,
      'is_active': instance.isActive,
      'is_billing_admin': instance.isBillingAdmin,
      'is_bot': instance.isBot,
      'bot_type': instance.botType,
      'bot_owner_id': instance.botOwnerId,
      'role': instance.role,
      'timezone': instance.timezone,
      'avatar_url': instance.avatarUrl,
      'avatar_version': instance.avatarVersion,
      'profile_data':
          instance.profileData?.map((k, e) => MapEntry(k.toString(), e)),
      'is_system_bot': instance.isSystemBot,
    };

const _$UserRoleEnumMap = {
  UserRole.owner: 100,
  UserRole.administrator: 200,
  UserRole.moderator: 300,
  UserRole.member: 400,
  UserRole.guest: 600,
  UserRole.unknown: null,
};

ProfileFieldUserData _$ProfileFieldUserDataFromJson(
        Map<String, dynamic> json) =>
    ProfileFieldUserData(
      value: json['value'] as String,
      renderedValue: json['rendered_value'] as String?,
    );

Map<String, dynamic> _$ProfileFieldUserDataToJson(
        ProfileFieldUserData instance) =>
    <String, dynamic>{
      'value': instance.value,
      'rendered_value': instance.renderedValue,
    };

ZulipStream _$ZulipStreamFromJson(Map<String, dynamic> json) => ZulipStream(
      streamId: (json['stream_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      renderedDescription: json['rendered_description'] as String,
      dateCreated: (json['date_created'] as num).toInt(),
      firstMessageId: (json['first_message_id'] as num?)?.toInt(),
      inviteOnly: json['invite_only'] as bool,
      isWebPublic: json['is_web_public'] as bool,
      historyPublicToSubscribers: json['history_public_to_subscribers'] as bool,
      messageRetentionDays: (json['message_retention_days'] as num?)?.toInt(),
      channelPostPolicy:
          $enumDecode(_$ChannelPostPolicyEnumMap, json['stream_post_policy']),
      streamWeeklyTraffic: (json['stream_weekly_traffic'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ZulipStreamToJson(ZulipStream instance) =>
    <String, dynamic>{
      'stream_id': instance.streamId,
      'name': instance.name,
      'description': instance.description,
      'rendered_description': instance.renderedDescription,
      'date_created': instance.dateCreated,
      'first_message_id': instance.firstMessageId,
      'invite_only': instance.inviteOnly,
      'is_web_public': instance.isWebPublic,
      'history_public_to_subscribers': instance.historyPublicToSubscribers,
      'message_retention_days': instance.messageRetentionDays,
      'stream_post_policy': instance.channelPostPolicy,
      'stream_weekly_traffic': instance.streamWeeklyTraffic,
    };

const _$ChannelPostPolicyEnumMap = {
  ChannelPostPolicy.any: 1,
  ChannelPostPolicy.administrators: 2,
  ChannelPostPolicy.fullMembers: 3,
  ChannelPostPolicy.moderators: 4,
  ChannelPostPolicy.unknown: null,
};

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      streamId: (json['stream_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      renderedDescription: json['rendered_description'] as String,
      dateCreated: (json['date_created'] as num).toInt(),
      firstMessageId: (json['first_message_id'] as num?)?.toInt(),
      inviteOnly: json['invite_only'] as bool,
      isWebPublic: json['is_web_public'] as bool,
      historyPublicToSubscribers: json['history_public_to_subscribers'] as bool,
      messageRetentionDays: (json['message_retention_days'] as num?)?.toInt(),
      channelPostPolicy:
          $enumDecode(_$ChannelPostPolicyEnumMap, json['stream_post_policy']),
      streamWeeklyTraffic: (json['stream_weekly_traffic'] as num?)?.toInt(),
      desktopNotifications: json['desktop_notifications'] as bool?,
      emailNotifications: json['email_notifications'] as bool?,
      wildcardMentionsNotify: json['wildcard_mentions_notify'] as bool?,
      pushNotifications: json['push_notifications'] as bool?,
      audibleNotifications: json['audible_notifications'] as bool?,
      pinToTop: json['pin_to_top'] as bool,
      isMuted: json['is_muted'] as bool,
      color: (Subscription._readColor(json, 'color') as num).toInt(),
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'stream_id': instance.streamId,
      'name': instance.name,
      'description': instance.description,
      'rendered_description': instance.renderedDescription,
      'date_created': instance.dateCreated,
      'first_message_id': instance.firstMessageId,
      'invite_only': instance.inviteOnly,
      'is_web_public': instance.isWebPublic,
      'history_public_to_subscribers': instance.historyPublicToSubscribers,
      'message_retention_days': instance.messageRetentionDays,
      'stream_post_policy': instance.channelPostPolicy,
      'stream_weekly_traffic': instance.streamWeeklyTraffic,
      'desktop_notifications': instance.desktopNotifications,
      'email_notifications': instance.emailNotifications,
      'wildcard_mentions_notify': instance.wildcardMentionsNotify,
      'push_notifications': instance.pushNotifications,
      'audible_notifications': instance.audibleNotifications,
      'pin_to_top': instance.pinToTop,
      'is_muted': instance.isMuted,
      'color': instance.color,
    };

StreamMessage _$StreamMessageFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['display_recipient'],
    disallowNullValues: const ['display_recipient'],
  );
  return StreamMessage(
    client: json['client'] as String,
    content: json['content'] as String,
    contentType: json['content_type'] as String,
    editState: Message._messageEditStateFromJson(
        MessageEditState._readFromMessage(json, 'edit_state')),
    id: (json['id'] as num).toInt(),
    isMeMessage: json['is_me_message'] as bool,
    lastEditTimestamp: (json['last_edit_timestamp'] as num?)?.toInt(),
    reactions: Message._reactionsFromJson(json['reactions']),
    recipientId: (json['recipient_id'] as num).toInt(),
    senderEmail: json['sender_email'] as String,
    senderFullName: json['sender_full_name'] as String,
    senderId: (json['sender_id'] as num).toInt(),
    senderRealmStr: json['sender_realm_str'] as String,
    timestamp: (json['timestamp'] as num).toInt(),
    flags: Message._flagsFromJson(json['flags']),
    matchContent: json['match_content'] as String?,
    matchTopic: json['match_subject'] as String?,
    displayRecipient: json['display_recipient'] as String?,
    streamId: (json['stream_id'] as num).toInt(),
    topic: TopicName.fromJson(json['subject'] as String),
  )..poll = Poll.fromJson(Message._readPoll(json, 'submessages'));
}

Map<String, dynamic> _$StreamMessageToJson(StreamMessage instance) =>
    <String, dynamic>{
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.contentType,
      'edit_state': _$MessageEditStateEnumMap[instance.editState]!,
      'id': instance.id,
      'is_me_message': instance.isMeMessage,
      'last_edit_timestamp': instance.lastEditTimestamp,
      'reactions': Message._reactionsToJson(instance.reactions),
      'recipient_id': instance.recipientId,
      'sender_email': instance.senderEmail,
      'sender_full_name': instance.senderFullName,
      'sender_id': instance.senderId,
      'sender_realm_str': instance.senderRealmStr,
      'submessages': Poll.toJson(instance.poll),
      'timestamp': instance.timestamp,
      'flags': instance.flags,
      'match_content': instance.matchContent,
      'match_subject': instance.matchTopic,
      'type': instance.type,
      if (instance.displayRecipient case final value?)
        'display_recipient': value,
      'stream_id': instance.streamId,
      'subject': instance.topic,
    };

const _$MessageEditStateEnumMap = {
  MessageEditState.none: 'none',
  MessageEditState.edited: 'edited',
  MessageEditState.moved: 'moved',
};

DmRecipient _$DmRecipientFromJson(Map<String, dynamic> json) => DmRecipient(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['full_name'] as String,
    );

Map<String, dynamic> _$DmRecipientToJson(DmRecipient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
    };

DmMessage _$DmMessageFromJson(Map<String, dynamic> json) => DmMessage(
      client: json['client'] as String,
      content: json['content'] as String,
      contentType: json['content_type'] as String,
      editState: Message._messageEditStateFromJson(
          MessageEditState._readFromMessage(json, 'edit_state')),
      id: (json['id'] as num).toInt(),
      isMeMessage: json['is_me_message'] as bool,
      lastEditTimestamp: (json['last_edit_timestamp'] as num?)?.toInt(),
      reactions: Message._reactionsFromJson(json['reactions']),
      recipientId: (json['recipient_id'] as num).toInt(),
      senderEmail: json['sender_email'] as String,
      senderFullName: json['sender_full_name'] as String,
      senderId: (json['sender_id'] as num).toInt(),
      senderRealmStr: json['sender_realm_str'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      flags: Message._flagsFromJson(json['flags']),
      matchContent: json['match_content'] as String?,
      matchTopic: json['match_subject'] as String?,
      displayRecipient: const DmRecipientListConverter()
          .fromJson(json['display_recipient'] as List),
    )..poll = Poll.fromJson(Message._readPoll(json, 'submessages'));

Map<String, dynamic> _$DmMessageToJson(DmMessage instance) => <String, dynamic>{
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.contentType,
      'edit_state': _$MessageEditStateEnumMap[instance.editState]!,
      'id': instance.id,
      'is_me_message': instance.isMeMessage,
      'last_edit_timestamp': instance.lastEditTimestamp,
      'reactions': Message._reactionsToJson(instance.reactions),
      'recipient_id': instance.recipientId,
      'sender_email': instance.senderEmail,
      'sender_full_name': instance.senderFullName,
      'sender_id': instance.senderId,
      'sender_realm_str': instance.senderRealmStr,
      'submessages': Poll.toJson(instance.poll),
      'timestamp': instance.timestamp,
      'flags': instance.flags,
      'match_content': instance.matchContent,
      'match_subject': instance.matchTopic,
      'type': instance.type,
      'display_recipient':
          const DmRecipientListConverter().toJson(instance.displayRecipient),
    };

const _$UserSettingNameEnumMap = {
  UserSettingName.twentyFourHourTime: 'twenty_four_hour_time',
  UserSettingName.displayEmojiReactionUsers: 'display_emoji_reaction_users',
  UserSettingName.emojiset: 'emojiset',
};

const _$EmojisetEnumMap = {
  Emojiset.google: 'google',
  Emojiset.googleBlob: 'google-blob',
  Emojiset.twitter: 'twitter',
  Emojiset.text: 'text',
};

const _$ChannelPropertyNameEnumMap = {
  ChannelPropertyName.name: 'name',
  ChannelPropertyName.description: 'description',
  ChannelPropertyName.firstMessageId: 'first_message_id',
  ChannelPropertyName.inviteOnly: 'invite_only',
  ChannelPropertyName.messageRetentionDays: 'message_retention_days',
  ChannelPropertyName.channelPostPolicy: 'stream_post_policy',
  ChannelPropertyName.streamWeeklyTraffic: 'stream_weekly_traffic',
};

const _$MessageFlagEnumMap = {
  MessageFlag.read: 'read',
  MessageFlag.starred: 'starred',
  MessageFlag.collapsed: 'collapsed',
  MessageFlag.mentioned: 'mentioned',
  MessageFlag.wildcardMentioned: 'wildcard_mentioned',
  MessageFlag.hasAlertWord: 'has_alert_word',
  MessageFlag.historical: 'historical',
  MessageFlag.unknown: 'unknown',
};
