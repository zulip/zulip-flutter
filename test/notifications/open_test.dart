import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/notifications/open.dart';

import '../example_data.dart' as eg;
import '../model/narrow_checks.dart';
import '../stdlib_checks.dart';

void main() {
  group('NotificationOpenPayload', () {
    test('smoke round-trip', () {
      // DM narrow
      var payload = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: DmNarrow(allRecipientIds: [1001, 1002], selfUserId: 1001),
      );
      var url = payload.buildUrl();
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(payload.realmUrl)
        ..userId.equals(payload.userId)
        ..narrow.equals(payload.narrow);

      // Topic narrow
      payload = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: eg.topicNarrow(1, 'topic A'),
      );
      url = payload.buildUrl();
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(payload.realmUrl)
        ..userId.equals(payload.userId)
        ..narrow.equals(payload.narrow);
    });

    test('buildUrl: smoke DM', () {
      final url = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: DmNarrow(allRecipientIds: [1001, 1002], selfUserId: 1001),
      ).buildUrl();
      check(url)
        ..scheme.equals('zulip')
        ..host.equals('notification')
        ..queryParameters.deepEquals({
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'dm',
          'all_recipient_ids': '1001,1002',
        });
    });

    test('buildUrl: smoke topic', () {
      final url = NotificationOpenPayload(
        realmUrl: Uri.parse('http://chat.example'),
        userId: 1001,
        narrow: eg.topicNarrow(1, 'topic A'),
      ).buildUrl();
      check(url)
        ..scheme.equals('zulip')
        ..host.equals('notification')
        ..queryParameters.deepEquals({
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        });
    });

    test('parse: smoke DM', () {
      final url = Uri(
        scheme: 'zulip',
        host: 'notification',
        queryParameters: <String, String>{
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'dm',
          'all_recipient_ids': '1001,1002',
        });
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(Uri.parse('http://chat.example'))
        ..userId.equals(1001)
        ..narrow.which((it) => it.isA<DmNarrow>()
          ..allRecipientIds.deepEquals([1001, 1002])
          ..otherRecipientIds.deepEquals([1002]));
    });

    test('parse: smoke topic', () {
      final url = Uri(
        scheme: 'zulip',
        host: 'notification',
        queryParameters: <String, String>{
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        });
      check(NotificationOpenPayload.parseUrl(url))
        ..realmUrl.equals(Uri.parse('http://chat.example'))
        ..userId.equals(1001)
        ..narrow.which((it) => it.isA<TopicNarrow>()
          ..streamId.equals(1)
          ..topic.equals(eg.t('topic A')));
    });

    test('parse: fails when missing any expected query parameters', () {
      final testCases = <Map<String, String>>[
        {
          // 'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        },
        {
          'realm_url': 'http://chat.example',
          // 'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        },
        {
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          // 'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        },
        {
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          // 'channel_id': '1',
          'topic': 'topic A',
        },
        {
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          // 'topic': 'topic A',
        },
        {
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          // 'narrow_type': 'dm',
          'all_recipient_ids': '1001,1002',
        },
        {
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'dm',
          // 'all_recipient_ids': '1001,1002',
        },
      ];
      for (final params in testCases) {
        check(() => NotificationOpenPayload.parseUrl(Uri(
          scheme: 'zulip',
          host: 'notification',
          queryParameters: params,
        )))
          // Missing 'realm_url', 'user_id' and 'narrow_type'
          // throws 'FormatException'.
          // Missing 'channel_id', 'topic', when narrow_type == 'topic'
          // throws 'TypeError'.
          // Missing 'all_recipient_ids', when narrow_type == 'dm'
          // throws 'TypeError'.
          .throws<Object>();
      }
    });

    test('parse: fails when scheme is not "zulip"', () {
      final url = Uri(
        scheme: 'http',
        host: 'notification',
        queryParameters: <String, String>{
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        });
      check(() => NotificationOpenPayload.parseUrl(url))
        .throws<FormatException>();
    });

    test('parse: fails when host is not "notification"', () {
      final url = Uri(
        scheme: 'zulip',
        host: 'example',
        queryParameters: <String, String>{
          'realm_url': 'http://chat.example',
          'user_id': '1001',
          'narrow_type': 'topic',
          'channel_id': '1',
          'topic': 'topic A',
        });
      check(() => NotificationOpenPayload.parseUrl(url))
        .throws<FormatException>();
    });
  });
}

extension on Subject<NotificationOpenPayload> {
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<Narrow> get narrow => has((x) => x.narrow, 'narrow');
}
