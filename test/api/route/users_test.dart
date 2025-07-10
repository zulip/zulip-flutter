import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/users.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke updatePresence', () {
    return FakeApiConnection.with_((connection) async {
      final response = UpdatePresenceResult(
        presenceLastUpdateId: -1,
        serverTimestamp: 1656958539.6287155,
        presences: {},
      );
      connection.prepare(json: response.toJson());
      await updatePresence(connection,
        lastUpdateId: -1,
        historyLimitDays: 21,
        newUserInput: false,
        pingOnly: false,
        status: PresenceStatus.active,
      );
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/presence')
        ..bodyFields.deepEquals({
          'last_update_id': '-1',
          'history_limit_days': '21',
          'new_user_input': 'false',
          'ping_only': 'false',
          'status': 'active',
          'slim_presence': 'true',
        });
    });
  });
}
