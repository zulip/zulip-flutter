import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test_api/scaffolding.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/route/events.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('registerQueue', () {
    Future<InitialSnapshot> checkRegisterQueue(FakeApiConnection connection, {
      IdleQueueTimeout? idleQueueTimeout,
    }) async {
      final result = await registerQueue(connection,
        idleQueueTimeout: idleQueueTimeout);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/register')
        ..bodyFields.which((it) =>
            idleQueueTimeout == null
              ? it.not((it) => it.containsKey('idle_queue_timeout'))
              : it['idle_queue_timeout'].equals(jsonEncode(idleQueueTimeout)));
      return result;
    }

    test('idleQueueTimeout absent', () => FakeApiConnection.with_((connection) async {
      connection.prepare(json: eg.initialSnapshot().toJson());
      await checkRegisterQueue(connection, idleQueueTimeout: null);
    }));

    test('idleQueueTimeout numeric', () => FakeApiConnection.with_((connection) async {
      connection.prepare(json: eg.initialSnapshot().toJson());
      await checkRegisterQueue(connection, idleQueueTimeout: .numeric(3600));
    }));

    test('idleQueueTimeout mobile', () => FakeApiConnection.with_((connection) async {
      connection.prepare(json: eg.initialSnapshot().toJson());
      await checkRegisterQueue(connection, idleQueueTimeout: .mobile);
    }));
  });
}
