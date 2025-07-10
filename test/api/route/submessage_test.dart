import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/api/route/submessage.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke sendSubmessage', () {
    return FakeApiConnection.with_<void>((connection) async {
      connection.prepare(json: {});
      await sendSubmessage(connection, messageId: 1,
        submessageType: SubmessageType.widget,
        content: PollQuestionEventSubmessage(question: 'test question'));
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/submessage')
        ..bodyFields.deepEquals({
          'message_id': '1',
          'msg_type': 'widget',
          'content': '{"type":"question","question":"test question"}',
        });
    });
  });
}
