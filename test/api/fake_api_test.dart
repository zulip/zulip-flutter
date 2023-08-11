import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/exception.dart';

import 'exception_checks.dart';
import 'fake_api.dart';

void main() {
  test('baseline happy case', () async {
    final connection = FakeApiConnection();
    connection.prepare(json: {'a': 3});
    await check(connection.get('aRoute', (json) => json, '/', null))
      .completes((it) => it.deepEquals({'a': 3}));
  });

  test('error message on send without prepare', () async {
    final connection = FakeApiConnection();
    // no connection.prepare
    await check(connection.get('aRoute', (json) => json, '/', null))
      .throws((it) => it.isA<NetworkException>()
        ..asString.contains('no response was prepared')
        ..asString.contains('FakeApiConnection.prepare'));
  });
}
