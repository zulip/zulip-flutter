// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast

part of 'initial_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitialSnapshot _$InitialSnapshotFromJson(Map<String, dynamic> json) =>
    InitialSnapshot(
      queueId: json['queue_id'] as String?,
      lastEventId: json['last_event_id'] as int,
      zulipFeatureLevel: json['zulip_feature_level'] as int,
      zulipVersion: json['zulip_version'] as String,
      zulipMergeBase: json['zulip_merge_base'] as String?,
      alertWords: (json['alert_words'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      customProfileFields: (json['custom_profile_fields'] as List<dynamic>)
          .map((e) => CustomProfileField.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>)
          .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxFileUploadSizeMib: json['max_file_upload_size_mib'] as int,
    );

Map<String, dynamic> _$InitialSnapshotToJson(InitialSnapshot instance) =>
    <String, dynamic>{
      'queue_id': instance.queueId,
      'last_event_id': instance.lastEventId,
      'zulip_feature_level': instance.zulipFeatureLevel,
      'zulip_version': instance.zulipVersion,
      'zulip_merge_base': instance.zulipMergeBase,
      'alert_words': instance.alertWords,
      'custom_profile_fields': instance.customProfileFields,
      'subscriptions': instance.subscriptions,
      'max_file_upload_size_mib': instance.maxFileUploadSizeMib,
    };
