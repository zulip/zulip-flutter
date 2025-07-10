import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/submessage.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'submessage_checks.dart';

void main() {
  group('Message.submessages', () {
    test('no crash on unrecognized submessage type', () {
      final baseJson = {
        'id': 1,
        'sender_id': eg.selfUser.userId,
        'message_id': 123,
        'content': '[]',
      };

      check(Submessage.fromJson({
        ...baseJson,
        'msg_type': 'widget',
      })).msgType.equals(SubmessageType.widget);

      check(Submessage.fromJson({
        ...baseJson,
        'msg_type': 'unknown_widget',
      })).msgType.equals(SubmessageType.unknown);
    });
  });

  test('invalid widget_type -> UnsupportedWidgetData/throw', () {
    final pollWidgetData = deepToJson(eg.pollWidgetData(
      question: 'example question',
      options: ['A', 'B', 'C'],
    )) as Map<String, Object?>;

    check(WidgetData.fromJson(pollWidgetData)).isA<PollWidgetData>()
      ..widgetType.equals(WidgetType.poll)
      ..extraData.which((x) => x
          ..question.equals('example question')
          ..options.deepEquals(['A', 'B', 'C'])
        );
    check(WidgetData.fromJson({
      ...pollWidgetData,
      'widget_type': 'unknown_foo',
    })).isA<UnsupportedWidgetData>();

    check(() => WidgetData.fromJson({
      ...pollWidgetData,
      'widget_type': 123,
    })).throws<TypeError>();
  });

  test('smoke PollEventSubmessage',  () {
    check(PollEventSubmessage.fromJson({
      'type': 'new_option',
      'option': 'new option',
      'idx': 0,
    })).isA<PollNewOptionEventSubmessage>()
      ..type.equals(PollEventSubmessageType.newOption)
      ..option.equals('new option');

    check(PollEventSubmessage.fromJson({
      'type': 'question',
      'question': 'new question',
    })).isA<PollQuestionEventSubmessage>()
      ..type.equals(PollEventSubmessageType.question)
      ..question.equals('new question');

    check(PollEventSubmessage.fromJson({
      'type': 'vote',
      'vote': 1,
      'key': PollEventSubmessage.optionKey(senderId: null, idx: 0),
    })).isA<PollVoteEventSubmessage>()
      ..type.equals(PollEventSubmessageType.vote)
      ..op.equals(PollVoteOp.add)
      ..key.equals('canned,0');
  });

  test('handle unknown poll event', () {
    check(() => PollEventSubmessage.fromJson({
      'type': 'foo',
    })).throws<TypeError>();
  });

  test('crash on poll vote key', () {
    final voteData = {'type': 'vote', 'vote': 1};

    check(() => PollEventSubmessage.fromJson({...voteData,
      'key': PollEventSubmessage.optionKey(senderId: null, idx: 0)
    })).returnsNormally();
    check(() => PollEventSubmessage.fromJson({ ...voteData,
      'key': PollEventSubmessage.optionKey(senderId: 5, idx: 0)
    })).returnsNormally();

    check(() => PollEventSubmessage.fromJson({ ...voteData,
      'key': 'foo,0',
    })).throws<FormatException>();
    check(() => PollEventSubmessage.fromJson({ ...voteData,
      'key': 'canned,bar',
    })).throws<FormatException>();
    check(() => PollEventSubmessage.fromJson({ ...voteData,
      'key': 'canned,0xdeadbeef',
    })).throws<FormatException>();
    check(() => PollEventSubmessage.fromJson({ ...voteData,
      'key': '0xdeadbeef,0',
    })).throws<FormatException>();
  });

  test('handle unknown poll vote op', () {
    check(PollEventSubmessage.fromJson({
      'type': 'vote',
      'vote': 'invalid',
      'key': PollEventSubmessage.optionKey(senderId: null, idx: 0)
    })).isA<PollVoteEventSubmessage>().op.equals(PollVoteOp.unknown);
  });

  // Parsing polls with PollEventSubmessages are tested in
  // `test/model/message_test.dart` in the "handleSubmessageEvent" test.
}
