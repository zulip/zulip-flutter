// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'video_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoCallResponse _$VideoCallResponseFromJson(Map<String, dynamic> json) =>
    VideoCallResponse(
      msg: json['msg'] as String,
      result: json['result'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$VideoCallResponseToJson(VideoCallResponse instance) =>
    <String, dynamic>{
      'msg': instance.msg,
      'result': instance.result,
      'url': instance.url,
    };
