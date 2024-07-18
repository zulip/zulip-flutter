import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/submessage.dart';

import '../../example_data.dart' as eg;
import 'submessage_checks.dart';

void main() {
  group('Message.submessages', () {
    test('no crash on unrecognized submessage type', () {
      final submessageJson = {
        'content': '[]',
        'message_id': 123,
        'sender_id': eg.selfUser.userId,
        'id': 1,
      };

      check(Submessage.fromJson({
        ...submessageJson,
        'msg_type': 'widget',
      })).msgType.equals(SubmessageType.widget);

      check(Submessage.fromJson({
        ...submessageJson,
        'msg_type': 'unknown_widget',
      })).msgType.equals(SubmessageType.unknown);
    });
  });

  test('no crash on unknown submessage content encoding', () {
    final submessageJson = {
      'msg_type': 'widget',
      'content': 'not json',
      'message_id': 123,
      'sender_id': eg.selfUser.userId,
      'id': 1,
    };

    check(Submessage.fromJson(submessageJson))
      ..msgType.equals(SubmessageType.widget)
      ..content.isNull();
  });

  test('submessage content gets decoded from JSON', () {
    final submessageJson = {
      'msg_type': 'widget',
      'content': jsonEncode(eg.pollWidgetDataFavoriteLetter),
      'message_id': 123,
      'sender_id': eg.selfUser.userId,
      'id': 1,
    };

    check(Submessage.fromJson(submessageJson))
      .content.isA<Map<String, Object?>>().deepEquals(eg.pollWidgetDataFavoriteLetter);
  });
}
