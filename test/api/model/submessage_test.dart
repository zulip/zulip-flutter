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

  test('smoke WidgetData',  () {
    check(WidgetData.fromJson(eg.pollWidgetDataFavoriteLetter)).isA<PollWidgetData>()
      ..widgetType.equals(WidgetType.poll)
      ..extraData.which((x) => x
          ..question.equals('favorite letter')
          ..options.deepEquals(['A', 'B', 'C'])
        );
  });

  test('invalid widget_type -> UnsupportedWidgetData', () {
    check(WidgetData.fromJson({
      ...eg.pollWidgetDataFavoriteLetter,
      'widget_type': 'unknown_foo',
    })).isA<UnsupportedWidgetData>();

    check(WidgetData.fromJson({
      ...eg.pollWidgetDataFavoriteLetter,
      'widget_type': 123,
    })).isA<UnsupportedWidgetData>();
  });

  test('smoke PollEvent',  () {
    check(PollEvent.fromJson({
      'type': 'new_option',
      'option': 'new option',
      'idx': 0,
    })).isA<PollOptionEvent>()
      ..type.equals(PollEventType.newOption)
      ..option.equals('new option');

    check(PollEvent.fromJson({
      'type': 'question',
      'question': 'new question',
    })).isA<PollQuestionEvent>()
      ..type.equals(PollEventType.question)
      ..question.equals('new question');

    check(PollEvent.fromJson({
      'type': 'vote',
      'vote': 1,
      'key': PollEvent.optionKey(senderId: null, optionIndex: 0),
    })).isA<PollVoteEvent>()
      ..type.equals(PollEventType.vote)
      ..op.equals(VoteOp.add)
      ..key.equals('canned,0');
  });

  test('handle unknown poll event', () {
    check(PollEvent.fromJson({
      'type': 'foo',
    })).isA<UnknownPollEvent>().type.equals(PollEventType.unknown);
  });

  test('crash on poll vote key', () {
    final voteData = {'type': 'vote', 'vote': 1};

    check(() => PollEvent.fromJson({...voteData,
      'key': PollEvent.optionKey(senderId: null, optionIndex: 0)
    })).returnsNormally();
    check(() => PollEvent.fromJson({ ...voteData,
      'key': PollEvent.optionKey(senderId: 5, optionIndex: 0)
    })).returnsNormally();

    check(() => PollEvent.fromJson({ ...voteData,
      'key': 'foo,0',
    })).throws<FormatException>();
    check(() => PollEvent.fromJson({ ...voteData,
      'key': 'canned,bar',
    })).throws<FormatException>();
    check(() => PollEvent.fromJson({ ...voteData,
      'key': 'canned,0xdeadbeef',
    })).throws<FormatException>();
    check(() => PollEvent.fromJson({ ...voteData,
      'key': '0xdeadbeef,0',
    })).throws<FormatException>();
  });

  test('handle unknown poll vote op', () {
    check(PollEvent.fromJson({
      'type': 'vote',
      'vote': 'invalid',
      'key': PollEvent.optionKey(senderId: null, optionIndex: 0)
    })).isA<PollVoteEvent>().op.equals(VoteOp.unknown);
  });
}
