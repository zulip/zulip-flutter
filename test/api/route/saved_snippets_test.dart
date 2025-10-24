import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/route/saved_snippets.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';
import 'route_checks.dart';

void main() {
  test('smoke', () async {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(
        json: CreateSavedSnippetResult(savedSnippetId: 123).toJson());
      final result = await createSavedSnippet(connection,
        title: 'test saved snippet', content: 'content');
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/saved_snippets')
        ..bodyFields.deepEquals({
          'title': 'test saved snippet',
          'content': 'content',
        });
      check(result).savedSnippetId.equals(123);
    });
  });
}
