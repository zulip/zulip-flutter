import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/submessage.dart';

import '../../example_data.dart' as eg;
import 'submessage_checks.dart';

void main() {
  group('Message.submessages', () {
    test('no crash on unrecognized submessage type', () {
      final baseJson = {
        'content': '[]',
        'message_id': 123,
        'sender_id': eg.selfUser.userId,
        'id': 1,
      };

      check(Submessage.fromJson({
        ...baseJson,
        'msg_type': 'widget',
      })).msgType.equals(SubmessageType.widget);

      check(Submessage.fromJson({
        ...baseJson,
        'msg_type': 'unknown_widget',
      })).msgType.equals(SubmessageType.unknown);
    });
  });
}
