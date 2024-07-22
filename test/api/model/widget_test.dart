import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/api/model/widget.dart';

import '../../example_data.dart' as eg;
import '../../stdlib_checks.dart';
import 'model_checks.dart';
import 'widget_checks.dart';

void main() {
  group('Message.poll', () {
    final defaultOptions = [
      Option(text: 'A'),
      Option(text: 'B'),
      Option(text: 'C'),
    ];

    Message messageWithSubmessageContents(
      Map<String, Object?> content,
      {List<(int senderId, PollEvent event)>? events}
    ) {
      return eg.streamMessage(
        id: 123,
        sender: eg.otherUser,
        submessages: [
          eg.submessage(
            messageId: 123,
            content: content,
            senderId: eg.otherUser.userId,
          ),
          if (events != null)
            for (final (senderId, event) in events)
              eg.submessage(
                messageId: 123,
                content: event,
                senderId: senderId,
              )
        ]);
    }

    test('parse poll from message', () {
      check(messageWithSubmessageContents(eg.pollWidgetDataFavoriteLetter))
        .poll.isNotNull()
          ..question.equals('favorite letter')
          ..options.deepEquals(defaultOptions);
    });

    test('parse poll with new question event', () {
      check(messageWithSubmessageContents(
        eg.pollWidgetDataFavoriteLetter,
        events: [
          (eg.otherUser.userId, PollQuestionEvent(question: 'new question')),
        ],
      ))
        .poll.isNotNull()
          ..question.equals('new question')
          ..options.deepEquals(defaultOptions);
    });

    test('parse poll with new option event', () {
      check(messageWithSubmessageContents(
        eg.pollWidgetDataFavoriteLetter,
        events: [
          (eg.otherUser.userId, PollOptionEvent(latestOptionIndex: 3, option: 'D')),
          (eg.selfUser.userId, PollOptionEvent(latestOptionIndex: 0, option: 'E')),
        ],
      ))
        .poll.isNotNull()
          ..question.equals('favorite letter')
          ..options.deepEquals([
            ...defaultOptions,
            Option(text: 'D'),
            Option(text: 'E'),
          ]);
    });

    test('parse poll with vote events on initial canned options', () {
      check(messageWithSubmessageContents(
        eg.pollWidgetDataFavoriteLetter,
        events: [
          (eg.otherUser.userId, PollVoteEvent(key: 'canned,1', op: VoteOp.add)),
          (eg.otherUser.userId, PollVoteEvent(key: 'canned,2', op: VoteOp.add)),
          (eg.otherUser.userId, PollVoteEvent(key: 'canned,2', op: VoteOp.remove)),
          (eg.selfUser.userId, PollVoteEvent(key: 'canned,1', op: VoteOp.add)),
        ],
      ))
        .poll.isNotNull()
          ..question.equals('favorite letter')
          ..options.deepEquals([
            Option(text: 'A'),
            Option.withVoters('B', [eg.otherUser.userId, eg.selfUser.userId]),
            Option(text: 'C'),
          ]);
    });

    test('parse poll with vote events on post-creation options', () {
      check(messageWithSubmessageContents(
        eg.pollWidgetDataFavoriteLetter,
        events: [
          (eg.otherUser.userId, PollOptionEvent(latestOptionIndex: 0, option: 'D')),
          (eg.otherUser.userId, PollVoteEvent(key: '${eg.otherUser.userId},0', op: VoteOp.add)),
          (eg.otherUser.userId, PollVoteEvent(key: '${eg.selfUser.userId},0', op: VoteOp.add)),
          (eg.otherUser.userId, PollVoteEvent(key: '${eg.selfUser.userId},0', op: VoteOp.remove)),
        ],
      ))
        .poll.isNotNull()
          ..question.equals('favorite letter')
          ..options.deepEquals([
            ...defaultOptions,
            Option.withVoters('D', [eg.otherUser.userId]),
          ]);
    });

    test('applyEvent: adding repeated option', () {
      final poll = messageWithSubmessageContents(eg.pollWidgetDataFavoriteLetter).poll!;
      check(poll.options).deepEquals(defaultOptions);
      poll.applyEvent(eg.otherUser.userId, PollOptionEvent(
        option: defaultOptions[0].text, latestOptionIndex: 0));
      check(poll.options).deepEquals(defaultOptions);
    });

    test('applyEvent: option index limit exceeded', () {
      final poll = messageWithSubmessageContents({
        'widget_type': 'poll',
        'extra_data': {
          'question': 'favorite letter',
          'options': List.generate(1001, (i) => '$i')
        }}).poll!;
      check(poll).options.length.equals(1001);
      poll.applyEvent(eg.otherUser.userId, PollOptionEvent(
        option: 'new option', latestOptionIndex: 1001));
      check(poll.options).length.equals(1001);
    });

    test('applyEvent: vote for non-existent option', () {
      final poll = messageWithSubmessageContents(eg.pollWidgetDataFavoriteLetter).poll!;
      check(poll.options).deepEquals(defaultOptions);
      poll.applyEvent(eg.otherUser.userId, PollVoteEvent(
        key: 'non-existent', op: VoteOp.add));
      check(poll.options).deepEquals(defaultOptions);
    });

    test('applyEvent: invalid vote op', () {
      final poll = messageWithSubmessageContents(eg.pollWidgetDataFavoriteLetter).poll!;
      check(poll.options).deepEquals(defaultOptions);
      poll.applyEvent(eg.otherUser.userId, PollVoteEvent(
        key: PollEvent.optionKey(senderId: eg.otherUser.userId, optionIndex: 0),
        op: VoteOp.unknown));
      check(poll.options).deepEquals(defaultOptions);
    });

    test('applyEvent: unauthorized question edits', () {
      final poll = messageWithSubmessageContents(eg.pollWidgetDataFavoriteLetter).poll!;
      check(poll).question.equals('favorite letter');
      poll.applyEvent(eg.selfUser.userId, PollQuestionEvent(question: 'edit'));
      check(poll).question.equals('favorite letter');
    });

    test('content with invalid widget_type', () {
      check(messageWithSubmessageContents({'widget_type': 'other'}))
        .poll.isNull();
    });

    test('handle malformed poll events', () {
      check(Message.fromJson(
        (deepToJson(eg.streamMessage(
          id: 123,
          sender: eg.selfUser,
        )) as Map<String, Object?>)..['submessages'] = deepToJson([
          eg.submessage(messageId: 123, content: eg.pollWidgetDataFavoriteLetter),
          eg.submessage(messageId: 123, content: {
            // Required field 'key' is missing
            'type': 'vote',
            'op': 1,
          }),
        ])
      )).poll.isNull();
    });

    test('no poll if submessages is empty', () {
      check(Message.fromJson(
        (deepToJson(eg.streamMessage()) as Map<String, Object?>)
          ..['submessages'] = [],
      )).poll.isNull();
    });
  });
}
