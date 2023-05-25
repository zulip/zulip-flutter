import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';

import '../../example_data.dart' as eg;
import 'events_checks.dart';
import 'model_checks.dart';

void main() {
  test('message: move flags into message object', () {
    final message = eg.streamMessage();
    MessageEvent mkEvent(List<String> flags) => Event.fromJson({
      'type': 'message',
      'id': 1,
      'message': message.toJson()..remove('flags'),
      'flags': flags,
    }) as MessageEvent;
    check(mkEvent(message.flags)).message.jsonEquals(message);
    check(mkEvent([])).message.flags.deepEquals([]);
    check(mkEvent(['read'])).message.flags.deepEquals(['read']);
  });
}
