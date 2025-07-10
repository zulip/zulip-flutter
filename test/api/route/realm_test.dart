import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/route/realm.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('fetchServerEmojiData', () {
    Future<ServerEmojiData> checkFetchServerEmojiData(FakeApiConnection connection, {
      required Uri emojiDataUrl,
    }) async {
      final result = await fetchServerEmojiData(connection,
        emojiDataUrl: emojiDataUrl);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('GET')
        ..url.equals(emojiDataUrl)
        ..headers.deepEquals(kFallbackUserAgentHeader);
      return result;
    }

    final fakeResult = ServerEmojiData(codeToNames: {
      '1f642': ['slight_smile'],
      '1f34a': ['orange', 'tangerine', 'mandarin'],
    });

    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: fakeResult.toJson());
        check(await checkFetchServerEmojiData(connection,
          emojiDataUrl: connection.realmUrl.resolve('/static/emoji.json')
        )).jsonEquals(fakeResult);
      });
    });

    test('off-realm is OK', () {
      return FakeApiConnection.with_(
          realmUrl: Uri.parse('https://chat.example'), (connection) async {
        connection.prepare(json: fakeResult.toJson());
        check(await checkFetchServerEmojiData(connection,
          emojiDataUrl: Uri.parse('https://elsewhere.example/static/emoji.json')
        )).jsonEquals(fakeResult);
      });
    });
  });
}
