import 'dart:convert';

import '../core.dart';
import '../model/submessage.dart';

/// https://zulip.readthedocs.io/en/latest/subsystems/widgets.html#polls-todo-lists-and-games
Future<void> sendSubmessage(ApiConnection connection, {
  required int messageId,
  required SubmessageData content,
}) {
  return connection.post('sendSubmessage', (_) {}, 'submessage', {
    'message_id': messageId,
    // 'widget' applies to submessages for polls and todos.
    // There is also 'zform' for trivia quiz bot,
    // but we currently do not plan to support that.
    'msg_type': RawParameter('widget'),
    // We cannot pass `content` directly because the server
    // expects a plain string of a JSON-encoded value, instead of an object.
    'content': RawParameter(jsonEncode(content)),
  });
}
