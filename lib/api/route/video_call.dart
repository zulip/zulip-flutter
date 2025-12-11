import '../core.dart';
import '../model/model.dart';

/// Creates a Zoom video/audio call
///
/// POST /api/v1/calls/zoom/create
Future<VideoCallResponse> createZoomCall(ApiConnection connection, {
  required bool isVideoCall,
}) async {
  return connection.post('createZoomCall', VideoCallResponse.fromJson,
    '/calls/zoom/create', {'is_video_call': isVideoCall});
}

/// Creates a BigBlueButton meeting
///
/// GET /api/v1/calls/bigbluebutton/create
Future<VideoCallResponse> createBigBlueButtonCall(ApiConnection connection, {
  required String meetingName,
  required bool voiceOnly,
}) async {
  return connection.get('createBigBlueButtonCall', VideoCallResponse.fromJson,
  '/calls/bigbluebutton/create', {'meeting_name': meetingName, 'voice_only': voiceOnly});
}
