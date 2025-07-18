import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/users.dart';
import 'package:zulip/basic.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke updateStatus', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await updateStatus(connection, change: UserStatusChange(
        text: OptionSome('Busy'),
        emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
          emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/users/me/status')
        ..bodyFields.deepEquals({
          'status_text': 'Busy',
          'emoji_name': 'working_on_it',
          'emoji_code': '1f6e0',
          'reaction_type': 'unicode_emoji',
        });
    });
  });

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
