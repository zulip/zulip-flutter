
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/message.dart';
import 'package:zulip/model/narrow.dart';

import '../example_data.dart' as eg;
import 'narrow_checks.dart';

void main() {
  int nextLocalMessageId = 1;

  StreamOutboxMessage streamOutboxMessage({
    required ZulipStream stream,
    required String topic,
  }) {
    return OutboxMessage.fromConversation(
      StreamConversation(
        stream.streamId, TopicName(topic), displayRecipient: null),
      localMessageId: nextLocalMessageId++,
      selfUserId: eg.selfUser.userId,
      timestamp: 123456789,
      contentMarkdown: 'content') as StreamOutboxMessage;
  }

  DmOutboxMessage dmOutboxMessage({required List<int> allRecipientIds}) {
    return OutboxMessage.fromConversation(
      DmConversation(allRecipientIds: allRecipientIds),
      localMessageId: nextLocalMessageId++,
      selfUserId: allRecipientIds[0],
      timestamp: 123456789,
      contentMarkdown: 'content') as DmOutboxMessage;
  }

  group('SendableNarrow', () {
    test('ofMessage: stream message', () {
      final message = eg.streamMessage();
      final actual = SendableNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      check(actual).equals(TopicNarrow.ofMessage(message));
    });

    test('ofMessage: DM message', () {
      final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      final actual = SendableNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      check(actual).equals(DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
    });
  });

  group('ChannelNarrow', () {
    test('containsMessage', () {
      final stream = eg.stream();
      final otherStream = eg.stream();
      final narrow = ChannelNarrow(stream.streamId);
      check(narrow.containsMessage(
        eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(stream: otherStream, topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(stream: stream,      topic: 'topic'))).isTrue();

      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [1]))).isFalse();
      check(narrow.containsMessage(
        streamOutboxMessage(stream: otherStream, topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        streamOutboxMessage(stream: stream,      topic: 'topic'))).isTrue();
    });
  });

  group('TopicNarrow', () {
    test('ofMessage', () {
      final stream = eg.stream();
      final message = eg.streamMessage(stream: stream);
      final actual = TopicNarrow.ofMessage(message);
      check(actual).equals(TopicNarrow(stream.streamId, message.topic));
    });

    test('containsMessage', () {
      final stream = eg.stream();
      final otherStream = eg.stream();
      final narrow = eg.topicNarrow(stream.streamId, 'topic');
      check(narrow.containsMessage(
        eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(stream: otherStream, topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(stream: stream,      topic: 'topic2'))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(stream: stream,      topic: 'topic'))).isTrue();

      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [1]))).isFalse();
      check(narrow.containsMessage(
        streamOutboxMessage(stream: otherStream, topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        streamOutboxMessage(stream: stream,      topic: 'topic2'))).isFalse();
      check(narrow.containsMessage(
        streamOutboxMessage(stream: stream,      topic: 'topic'))).isTrue();
    });
  });

  group('DmNarrow', () {
    test('constructor assertions', () {
      check(() => DmNarrow(allRecipientIds: [2, 12], selfUserId: 2)).returnsNormally();
      check(() => DmNarrow(allRecipientIds: [2],     selfUserId: 2)).returnsNormally();

      check(() => DmNarrow(allRecipientIds: [12, 2], selfUserId: 2)).throws<void>();
      check(() => DmNarrow(allRecipientIds: [2, 2],  selfUserId: 2)).throws<void>();
      check(() => DmNarrow(allRecipientIds: [2, 12], selfUserId: 1)).throws<void>();
      check(() => DmNarrow(allRecipientIds: [],      selfUserId: 2)).throws<void>();
    });

    test('ofMessage: self-dm', () {
      final message = eg.dmMessage(from: eg.selfUser, to: []);
      final actual = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      check(actual).equals(DmNarrow(
        allRecipientIds: [eg.selfUser.userId],
        selfUserId: eg.selfUser.userId));
      check(() => {
        actual.allRecipientIds[0] = eg.otherUser.userId
      }).throws<UnsupportedError>(); // "Cannot modify an unmodifiable list"
    });

    test('ofMessage: 1:1', () {
      final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      final actual = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      check(actual).equals(DmNarrow(
        allRecipientIds: [eg.selfUser.userId, eg.otherUser.userId]..sort(),
        selfUserId: eg.selfUser.userId));
    });

    test('ofMessage: group', () {
      final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser, eg.thirdUser]);
      final actual = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      check(actual).equals(DmNarrow(
        allRecipientIds: [eg.selfUser.userId, eg.otherUser.userId, eg.thirdUser.userId]..sort(),
        selfUserId: eg.selfUser.userId));
    });

    test('withUser: same user', () {
      final actual = DmNarrow.withUser(5, selfUserId: 5);
      check(actual).equals(DmNarrow(
        allRecipientIds: [5],
        selfUserId: 5));
    });

    test('withUser: user ID less than selfUserId', () {
      final actual = DmNarrow.withUser(3, selfUserId: 5);
      check(actual).equals(DmNarrow(
          allRecipientIds: [3, 5],
          selfUserId: 5));
    });

    test('withUser: user ID greater than selfUserId', () {
      final actual = DmNarrow.withUser(7, selfUserId: 5);
      check(actual).equals(DmNarrow(
          allRecipientIds: [5, 7],
          selfUserId: 5));
    });

    test('withUsers: without selfUserId', () {
      final actual = DmNarrow.withUsers([1, 2], selfUserId: 3);
      check(actual).equals(DmNarrow(
          allRecipientIds: [1, 2, 3],
          selfUserId: 3));
    });

    test('withUsers: with selfUserId', () {
      final actual = DmNarrow.withUsers([1, 2, 3], selfUserId: 3);
      check(actual).equals(DmNarrow(
          allRecipientIds: [1, 2, 3],
          selfUserId: 3));
    });

    test('otherRecipientIds', () {
      check(DmNarrow(allRecipientIds: [1, 2, 3], selfUserId: 2))
        .otherRecipientIds.deepEquals([1, 3]);
      check(DmNarrow(allRecipientIds: [1, 2], selfUserId: 2))
        .otherRecipientIds.deepEquals([1]);
      check(DmNarrow(allRecipientIds: [2], selfUserId: 2))
        .otherRecipientIds.deepEquals([]);
    });

    test('containsMessage', () {
      final user1 = eg.user(userId: 1);
      final user2 = eg.user(userId: 2);
      final user3 = eg.user(userId: 3);
      final narrow2   = DmNarrow(allRecipientIds: [2],       selfUserId: 2);
      final narrow12  = DmNarrow(allRecipientIds: [1, 2],    selfUserId: 2);
      final narrow123 = DmNarrow(allRecipientIds: [1, 2, 3], selfUserId: 2);

      Message dm(User from, List<User> to) => eg.dmMessage(from: from, to: to);
      final streamMessage = eg.streamMessage(sender: user2);

      check(narrow2.containsMessage(streamMessage)).isFalse();
      check(narrow2.containsMessage(dm(user2, []))).isTrue();
      check(narrow2.containsMessage(dm(user1, [user2]))).isFalse();
      check(narrow2.containsMessage(dm(user2, [user1]))).isFalse();
      check(narrow2.containsMessage(dm(user1, [user2, user3]))).isFalse();
      check(narrow2.containsMessage(dm(user2, [user1, user3]))).isFalse();
      check(narrow2.containsMessage(dm(user3, [user1, user2]))).isFalse();

      check(narrow12.containsMessage(streamMessage)).isFalse();
      check(narrow12.containsMessage(dm(user2, []))).isFalse();
      check(narrow12.containsMessage(dm(user1, [user2]))).isTrue();
      check(narrow12.containsMessage(dm(user2, [user1]))).isTrue();
      check(narrow12.containsMessage(dm(user1, [user2, user3]))).isFalse();
      check(narrow12.containsMessage(dm(user2, [user1, user3]))).isFalse();
      check(narrow12.containsMessage(dm(user3, [user1, user2]))).isFalse();

      check(narrow123.containsMessage(streamMessage)).isFalse();
      check(narrow123.containsMessage(dm(user2, []))).isFalse();
      check(narrow123.containsMessage(dm(user1, [user2]))).isFalse();
      check(narrow123.containsMessage(dm(user2, [user1]))).isFalse();
      check(narrow123.containsMessage(dm(user1, [user2, user3]))).isTrue();
      check(narrow123.containsMessage(dm(user2, [user1, user3]))).isTrue();
      check(narrow123.containsMessage(dm(user3, [user1, user2]))).isTrue();
    });

    test('containsMessage with non-Message', () {
      final narrow = DmNarrow(allRecipientIds: [1, 2], selfUserId: 2);

      check(narrow.containsMessage(
        streamOutboxMessage(stream: eg.stream(), topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [2]))).isFalse();
      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [2, 3]))).isFalse();
      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [1, 2]))).isTrue();
    });
  });

  group('MentionsNarrow', () {
    test('containsMessage', () {
      const narrow = MentionsNarrow();

      check(narrow.containsMessage(
        eg.streamMessage(flags: []))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(flags:[MessageFlag.mentioned]))).isTrue();
      check(narrow.containsMessage(
        eg.streamMessage(flags: [MessageFlag.wildcardMentioned]))).isTrue();

      check(narrow.containsMessage(
        streamOutboxMessage(stream: eg.stream(), topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [eg.selfUser.userId]))).isFalse();
    });
  });

  group('StarredMessagesNarrow', () {
    test('containsMessage', () {
      const narrow = StarredMessagesNarrow();

      check(narrow.containsMessage(
        eg.streamMessage(flags: []))).isFalse();
      check(narrow.containsMessage(
        eg.streamMessage(flags:[MessageFlag.starred]))).isTrue();

      check(narrow.containsMessage(
        streamOutboxMessage(stream: eg.stream(), topic: 'topic'))).isFalse();
      check(narrow.containsMessage(
        dmOutboxMessage(allRecipientIds: [eg.selfUser.userId]))).isFalse();
    });
  });
}
