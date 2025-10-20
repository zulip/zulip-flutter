import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/route/channels.dart';
import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  group('getSubscribers', () {
    test('smoke test', () {
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: {
          'subscribers': <int>[1, 2, 3],
        });
        final result = await getSubscribers(connection, streamId: 123);
        check(result.subscribers).deepEquals([1, 2, 3]);
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('GET')
          ..url.path.equals('/api/v1/streams/123/members');
      });
    });

    // test('with empty subscribers list', () {
    //   return FakeApiConnection.with_((connection) async {
    //     connection.prepare(json: {
    //       'subscribers': [],
    //     });
    //     final result = await getSubscribers(connection, streamId: 456);
    //     check(result.subscribers).isEmpty();
    //     check(connection.takeRequests()).single.isA<http.Request>()
    //       ..method.equals('GET')
    //       ..url.path.equals('/api/v1/streams/456/members');
    //   });
    // });

    test('handles large subscriber list', () {
      final largeList = List<int>.generate(1000, (i) => i + 1);
      return FakeApiConnection.with_((connection) async {
        connection.prepare(json: {
          'subscribers': largeList,
        });
        final result = await getSubscribers(connection, streamId: 789);
        check(result.subscribers).deepEquals(largeList);
      });
    });
  });

  group('GetSubscribersResult', () {
    test('fromJson smoke test', () {
      final json = {
        'subscribers': <int>[1, 2, 3, 4, 5],
      };
      final result = GetSubscribersResult.fromJson(json);
      check(result.subscribers).deepEquals([1, 2, 3, 4, 5]);
    });

    // test('fromJson with empty list', () {
    //   final json = {'subscribers': []};
    //   final result = GetSubscribersResult.fromJson(json);
    //   check(result.subscribers).isEmpty();
    // });

    test('fromJson preserves order', () {
      final json = {
        'subscribers': [5, 3, 1, 4, 2],
      };
      final result = GetSubscribersResult.fromJson(json);
      check(result.subscribers).deepEquals([5, 3, 1, 4, 2]);
    });

    test('toJson round trip', () {
      final original = GetSubscribersResult(subscribers: [1, 2, 3]);
      final json = original.toJson();
      final restored = GetSubscribersResult.fromJson(json);
      check(restored.subscribers).deepEquals(original.subscribers);
    });
  });
}
