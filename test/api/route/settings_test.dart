import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/settings.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke updateSettings', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});

      final newSettings = <UserSettingName, Object?>{};
      final expectedBodyFields = <String, String>{};
      for (final name in UserSettingName.values) {
        switch (name) {
          case UserSettingName.twentyFourHourTime:
            newSettings[name] = TwentyFourHourTimeMode.twelveHour;
            expectedBodyFields['twenty_four_hour_time'] = 'false';
          case UserSettingName.starredMessageCounts:
            newSettings[name] = false;
            expectedBodyFields['starred_message_counts'] = 'false';
          case UserSettingName.displayEmojiReactionUsers:
            newSettings[name] = false;
            expectedBodyFields['display_emoji_reaction_users'] = 'false';
          case UserSettingName.emojiset:
            newSettings[name] = Emojiset.googleBlob;
            expectedBodyFields['emojiset'] = 'google-blob';
          case UserSettingName.presenceEnabled:
            newSettings[name] = true;
            expectedBodyFields['presence_enabled'] = 'true';
        }
      }

      await updateSettings(connection, newSettings: newSettings);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('PATCH')
        ..url.path.equals('/api/v1/settings')
        ..bodyFields.deepEquals(expectedBodyFields);
    });
  });

  test('TwentyFourHourTime.localeDefault', () async {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});

      // TODO(server-future) instead, check for twenty_four_hour_time: null
      //   (could be an error-prone part of the JSONification)
      check(() => updateSettings(connection,
        newSettings: {UserSettingName.twentyFourHourTime: TwentyFourHourTimeMode.localeDefault})
      ).throws<AssertionError>();
    });
  });
}
