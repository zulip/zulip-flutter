import '../core.dart';
import '../model/submessage.dart';

/// https://zulip.readthedocs.io/en/latest/subsystems/widgets.html#polls-todo-lists-and-games
/// https://github.com/zulip/zulip-mobile/blob/fc23edd67a5ec7f32c7c5f6cd81893b94dc043a2/src/api/submessages/sendSubmessage.js
Future<void> sendSubmessage(ApiConnection connection, {
  required int messageId,
  required SubmessageType submessageType,
  required SubmessageData content,
}) {
  return connection.post('sendSubmessage', (_) {}, 'submessage', {
    'message_id': messageId,
    'msg_type': RawParameter(submessageType.toJson()),
    'content': content,
  });
}
