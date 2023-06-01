// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomProfileField _$CustomProfileFieldFromJson(Map<String, dynamic> json) =>
    CustomProfileField(
      id: json['id'] as int,
      type: json['type'] as int,
      order: json['order'] as int,
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

User _$UserFromJson(Map<String, dynamic> json) => User(
      userId: json['user_id'] as int,
      deliveryEmailStaleDoNotUse: json['delivery_email'] as String?,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      dateJoined: json['date_joined'] as String,
      isActive: json['is_active'] as bool,
      isOwner: json['is_owner'] as bool,
      isAdmin: json['is_admin'] as bool,
      isGuest: json['is_guest'] as bool,
      isBillingAdmin: json['is_billing_admin'] as bool?,
      isBot: json['is_bot'] as bool,
      botType: json['bot_type'] as int?,
      botOwnerId: json['bot_owner_id'] as int?,
      role: json['role'] as int,
      timezone: json['timezone'] as String,
      avatarUrl: json['avatar_url'] as String?,
      avatarVersion: json['avatar_version'] as int,
      profileData:
          (User._readProfileData(json, 'profile_data') as Map<String, dynamic>?)
              ?.map(
        (k, e) => MapEntry(int.parse(k),
            ProfileFieldUserData.fromJson(e as Map<String, dynamic>)),
      ),
      isSystemBot: User._readIsSystemBot(json, 'is_system_bot') as bool?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'user_id': instance.userId,
      'delivery_email': instance.deliveryEmailStaleDoNotUse,
      'email': instance.email,
      'full_name': instance.fullName,
      'date_joined': instance.dateJoined,
      'is_active': instance.isActive,
      'is_owner': instance.isOwner,
      'is_admin': instance.isAdmin,
      'is_guest': instance.isGuest,
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

ZulipStream _$ZulipStreamFromJson(Map<String, dynamic> json) => ZulipStream(
      streamId: json['stream_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      renderedDescription: json['rendered_description'] as String,
      dateCreated: json['date_created'] as int,
      firstMessageId: json['first_message_id'] as int?,
      inviteOnly: json['invite_only'] as bool,
      isWebPublic: json['is_web_public'] as bool,
      historyPublicToSubscribers: json['history_public_to_subscribers'] as bool,
      messageRetentionDays: json['message_retention_days'] as int?,
      streamPostPolicy: json['stream_post_policy'] as int,
      canRemoveSubscribersGroupId:
          json['can_remove_subscribers_group_id'] as int?,
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
      'stream_post_policy': instance.streamPostPolicy,
      'can_remove_subscribers_group_id': instance.canRemoveSubscribersGroupId,
    };

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      streamId: json['stream_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      renderedDescription: json['rendered_description'] as String,
      dateCreated: json['date_created'] as int,
      inviteOnly: json['invite_only'] as bool,
      desktopNotifications: json['desktop_notifications'] as bool?,
      emailNotifications: json['email_notifications'] as bool?,
      wildcardMentionsNotify: json['wildcard_mentions_notify'] as bool?,
      pushNotifications: json['push_notifications'] as bool?,
      audibleNotifications: json['audible_notifications'] as bool?,
      pinToTop: json['pin_to_top'] as bool,
      emailAddress: json['email_address'] as String,
      isMuted: json['is_muted'] as bool,
      isWebPublic: json['is_web_public'] as bool?,
      color: json['color'] as String,
      streamPostPolicy: json['stream_post_policy'] as int,
      messageRetentionDays: json['message_retention_days'] as int?,
      historyPublicToSubscribers: json['history_public_to_subscribers'] as bool,
      firstMessageId: json['first_message_id'] as int?,
      streamWeeklyTraffic: json['stream_weekly_traffic'] as int?,
      canRemoveSubscribersGroupId:
          json['can_remove_subscribers_group_id'] as int?,
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'stream_id': instance.streamId,
      'name': instance.name,
      'description': instance.description,
      'rendered_description': instance.renderedDescription,
      'date_created': instance.dateCreated,
      'invite_only': instance.inviteOnly,
      'desktop_notifications': instance.desktopNotifications,
      'email_notifications': instance.emailNotifications,
      'wildcard_mentions_notify': instance.wildcardMentionsNotify,
      'push_notifications': instance.pushNotifications,
      'audible_notifications': instance.audibleNotifications,
      'pin_to_top': instance.pinToTop,
      'email_address': instance.emailAddress,
      'is_muted': instance.isMuted,
      'is_web_public': instance.isWebPublic,
      'color': instance.color,
      'stream_post_policy': instance.streamPostPolicy,
      'message_retention_days': instance.messageRetentionDays,
      'history_public_to_subscribers': instance.historyPublicToSubscribers,
      'first_message_id': instance.firstMessageId,
      'stream_weekly_traffic': instance.streamWeeklyTraffic,
      'can_remove_subscribers_group_id': instance.canRemoveSubscribersGroupId,
    };

StreamMessage _$StreamMessageFromJson(Map<String, dynamic> json) =>
    StreamMessage(
      avatarUrl: json['avatar_url'] as String?,
      client: json['client'] as String,
      content: json['content'] as String,
      contentType: json['content_type'] as String,
      id: json['id'] as int,
      isMeMessage: json['is_me_message'] as bool,
      lastEditTimestamp: json['last_edit_timestamp'] as int?,
      recipientId: json['recipient_id'] as int,
      senderEmail: json['sender_email'] as String,
      senderFullName: json['sender_full_name'] as String,
      senderId: json['sender_id'] as int,
      senderRealmStr: json['sender_realm_str'] as String,
      subject: json['subject'] as String,
      timestamp: json['timestamp'] as int,
      flags: (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
      matchContent: json['match_content'] as String?,
      matchSubject: json['match_subject'] as String?,
      displayRecipient: json['display_recipient'] as String,
      streamId: json['stream_id'] as int,
    );

Map<String, dynamic> _$StreamMessageToJson(StreamMessage instance) =>
    <String, dynamic>{
      'avatar_url': instance.avatarUrl,
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.contentType,
      'id': instance.id,
      'is_me_message': instance.isMeMessage,
      'last_edit_timestamp': instance.lastEditTimestamp,
      'recipient_id': instance.recipientId,
      'sender_email': instance.senderEmail,
      'sender_full_name': instance.senderFullName,
      'sender_id': instance.senderId,
      'sender_realm_str': instance.senderRealmStr,
      'subject': instance.subject,
      'timestamp': instance.timestamp,
      'flags': instance.flags,
      'match_content': instance.matchContent,
      'match_subject': instance.matchSubject,
      'type': instance.type,
      'display_recipient': instance.displayRecipient,
      'stream_id': instance.streamId,
    };

PmRecipient _$PmRecipientFromJson(Map<String, dynamic> json) => PmRecipient(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
    );

Map<String, dynamic> _$PmRecipientToJson(PmRecipient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
    };

PmMessage _$PmMessageFromJson(Map<String, dynamic> json) => PmMessage(
      avatarUrl: json['avatar_url'] as String?,
      client: json['client'] as String,
      content: json['content'] as String,
      contentType: json['content_type'] as String,
      id: json['id'] as int,
      isMeMessage: json['is_me_message'] as bool,
      lastEditTimestamp: json['last_edit_timestamp'] as int?,
      recipientId: json['recipient_id'] as int,
      senderEmail: json['sender_email'] as String,
      senderFullName: json['sender_full_name'] as String,
      senderId: json['sender_id'] as int,
      senderRealmStr: json['sender_realm_str'] as String,
      subject: json['subject'] as String,
      timestamp: json['timestamp'] as int,
      flags: (json['flags'] as List<dynamic>).map((e) => e as String).toList(),
      matchContent: json['match_content'] as String?,
      matchSubject: json['match_subject'] as String?,
      displayRecipient: (json['display_recipient'] as List<dynamic>)
          .map((e) => PmRecipient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PmMessageToJson(PmMessage instance) => <String, dynamic>{
      'avatar_url': instance.avatarUrl,
      'client': instance.client,
      'content': instance.content,
      'content_type': instance.contentType,
      'id': instance.id,
      'is_me_message': instance.isMeMessage,
      'last_edit_timestamp': instance.lastEditTimestamp,
      'recipient_id': instance.recipientId,
      'sender_email': instance.senderEmail,
      'sender_full_name': instance.senderFullName,
      'sender_id': instance.senderId,
      'sender_realm_str': instance.senderRealmStr,
      'subject': instance.subject,
      'timestamp': instance.timestamp,
      'flags': instance.flags,
      'match_content': instance.matchContent,
      'match_subject': instance.matchSubject,
      'type': instance.type,
      'display_recipient': instance.displayRecipient,
    };
