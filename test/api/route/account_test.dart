import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/route/account.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('devFetchApiKey', () {
    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        final fakeResult = FetchApiKeyResult(
          apiKey: 'xyz', email: 'iago@zulip.com', userId: 11);
        connection.prepare(json: fakeResult.toJson());
        final result = await devFetchApiKey(connection,
          username: 'iago@zulip.com');
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/dev_fetch_api_key')
          ..bodyFields.deepEquals({
            'username': 'iago@zulip.com',
          });
        check(result).jsonEquals(fakeResult);
      });
    });
  });

  group('devListUsers', () {
    test('smoke', () {
      return FakeApiConnection.with_((connection) async {
        final fakeResult = DevListUsersResult(
          directAdmins: [
            DevListUsersEntry(email: 'iago@zulip.com',
              realmUrl: Uri.parse('http://localhost:9991')),
          ],
          directUsers: [
            DevListUsersEntry(email: 'hamlet@zulip.com',
              realmUrl: Uri.parse('http://localhost:9991')),
            DevListUsersEntry(email: 'king@lear.org',
              realmUrl: Uri.parse('http://lear.localhost:9991')),
          ]);
        connection.prepare(json: fakeResult.toJson());
        final result = await devListUsers(connection);
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/dev_list_users');
        check(result).jsonEquals(fakeResult);
      });
    });
  });
}
