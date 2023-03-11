// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initial_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitialSnapshot _$InitialSnapshotFromJson(Map<String, dynamic> json) =>
    InitialSnapshot(
      queue_id: json['queue_id'] as String?,
      last_event_id: json['last_event_id'] as int,
      zulip_feature_level: json['zulip_feature_level'] as int,
      zulip_version: json['zulip_version'] as String,
      zulip_merge_base: json['zulip_merge_base'] as String?,
      user_id: json['user_id'] as int,
      alert_words: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      custom_profile_fields: (json['custom_profile_fields'] as List<dynamic>)
          .map((e) => CustomProfileField.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>)
          .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InitialSnapshotToJson(InitialSnapshot instance) =>
    <String, dynamic>{
      'queue_id': instance.queue_id,
      'last_event_id': instance.last_event_id,
      'zulip_feature_level': instance.zulip_feature_level,
      'zulip_version': instance.zulip_version,
      'zulip_merge_base': instance.zulip_merge_base,
      'user_id': instance.user_id,
      'alert_words': instance.alert_words,
      'custom_profile_fields': instance.custom_profile_fields,
      'subscriptions': instance.subscriptions,
    };
