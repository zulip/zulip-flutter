import 'package:json_annotation/json_annotation.dart';
import '../core.dart';

part 'video_call.g.dart';

/// Creates a Zoom video/audio call
///
/// POST /api/v1/calls/zoom/create
Future<VideoCallResponse> createZoomCall(ApiConnection connection, {
  required bool isVideoCall,
}) async {
  return connection.post('createZoomCall', VideoCallResponse.fromJson,
    '/calls/zoom/create', {'is_video_call': isVideoCall});
}

/// https://zulip.com/api/create-big-blue-button-video-call
Future<VideoCallResponse> createBigBlueButtonCall(ApiConnection connection, {
  required String meetingName,
  bool? voiceOnly
}) async {
  return connection.get(
    'createBigBlueButtonCall', VideoCallResponse.fromJson, '/calls/bigbluebutton/create', {
      'meeting_name': RawParameter(meetingName),
      if (voiceOnly != null) 'voice_only': voiceOnly,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class VideoCallResponse {
  final String msg;
  final String result;
  final String url;

  VideoCallResponse({
    required this.msg,
    required this.result,
    required this.url,
  });

  factory VideoCallResponse.fromJson(Map<String, dynamic> json)  =>
    _$VideoCallResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoCallResponseToJson(this);
}

