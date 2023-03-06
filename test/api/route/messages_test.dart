import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/messages.dart';

import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  test('sendMessage accepts fixture realm', () async {
    final connection = FakeApiConnection(
        realmUrl: 'https://chat.zulip.org/', email: 'self@mail.example');
    connection.prepare(jsonEncode(SendMessageResult(id: 42).toJson()));
    check(sendMessage(connection, content: 'hello', topic: 'world'))
        .completes(it()..id.equals(42));
  });

  test('sendMessage rejects unexpected realm', () async {
    final connection = FakeApiConnection(
        realmUrl: 'https://chat.example/', email: 'self@mail.example');
    connection.prepare(jsonEncode(SendMessageResult(id: 42).toJson()));
    check(sendMessage(connection, content: 'hello', topic: 'world'))
        .throws();
  });
}
