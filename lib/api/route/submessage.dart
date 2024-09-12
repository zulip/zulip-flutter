import '../core.dart';
import '../model/submessage.dart';

/// https://zulip.readthedocs.io/en/latest/subsystems/widgets.html#polls-todo-lists-and-games
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
