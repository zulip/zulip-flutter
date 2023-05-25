import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/messages.dart';

import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  test('sendMessage accepts fixture realm', () async {
    final connection = FakeApiConnection(
      realmUrl: Uri.parse('https://chat.zulip.org/'));
    connection.prepare(json: SendMessageResult(id: 42).toJson());
    check(sendMessage(connection, content: 'hello', topic: 'world'))
      .completes(it()..id.equals(42));
  });

  test('sendMessage rejects unexpected realm', () async {
    final connection = FakeApiConnection(
      realmUrl: Uri.parse('https://chat.example/'));
    connection.prepare(json: SendMessageResult(id: 42).toJson());
    check(() => sendMessage(connection, content: 'hello', topic: 'world'))
      .throws();
  });
}
