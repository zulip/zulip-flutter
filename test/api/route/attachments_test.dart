import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/attachments.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('removeAttachment', () {
    test('success', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: {'result': 'success', 'msg': ''});
        await removeAttachment(connection, attachmentId: 123321);
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('DELETE')
          ..url.path.equals('/api/v1/attachments/123321')
          ..bodyFields.isEmpty();
      });
    });
  });
}
