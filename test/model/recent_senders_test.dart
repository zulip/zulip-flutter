import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/recent_senders.dart';
import '../example_data.dart' as eg;

void main() {
  group('MessageIdTracker', () {
    late MessageIdTracker idTracker;

    void prepare() {
      idTracker = MessageIdTracker();
    }

    test('starts with no ids', () {
      prepare();
      check(idTracker.debugIds).isEmpty();
    });

    test('calling add(id) adds the same id to the tracker just one time', () {
      prepare();
      check(idTracker.debugIds).isEmpty();
      idTracker.add(1);
      idTracker.add(1);
      check(idTracker.debugIds.singleOrNull).equals(1);
    });

    test('ids are sorted ascendingly, with maxId pointing to the last element', () {
      prepare();
      check(idTracker.debugIds).isEmpty();
      idTracker.add(1);
      idTracker.add(9);
      idTracker.add(0);
      idTracker.add(5);
      check(idTracker.debugIds).deepEquals([0, 1, 5, 9]);
      check(idTracker.maxId).equals(idTracker.debugIds.last);
    });
  });

  group('RecentSenders', () {
    late RecentSenders recentSenders;

    void prepare() {
      recentSenders = RecentSenders();
    }

    test('starts with no stream or topic senders', () {
      prepare();
      check(recentSenders.debugIsEmpty).equals(true);
    });

    test('only processes a stream message', () {
      prepare();
      final dmMessage = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      recentSenders.handleMessage(dmMessage);
      check(recentSenders.debugIsEmpty).equals(true);

      final streamMessage = eg.streamMessage(
        id: 100,
        sender: eg.user(userId: 10),
        stream: eg.stream(streamId: 1),
        topic: 'topic',
      );
      recentSenders.handleMessage(streamMessage);

      final expectedStreamSenders = {
        1: {
          10: MessageIdTracker.fromIds([100])
        }
      };
      check(recentSenders.debugStreamSenders).deepEquals(expectedStreamSenders);

      final expectedTopicSenders = {
        1: {
          'topic': {
            10: MessageIdTracker.fromIds([100])
          },
        },
      };
      check(recentSenders.debugTopicSenders).deepEquals(expectedTopicSenders);
    });

    test('adding multiple messages', () {
      prepare();
      final message1 = eg.streamMessage(
        stream: eg.stream(streamId: 1),
        topic: 'topic1',
        sender: eg.user(userId: 10),
        id: 300,
      );
      final message2 = eg.streamMessage(
        stream: eg.stream(streamId: 1),
        topic: 'topic2',
        sender: eg.user(userId: 10),
        id: 100,
      );
      final message3 = eg.streamMessage(
        stream: eg.stream(streamId: 1),
        topic: 'topic1',
        sender: eg.user(userId: 20),
        id: 200,
      );
      final message4 = eg.streamMessage(
        stream: eg.stream(streamId: 1),
        topic: 'topic2',
        sender: eg.user(userId: 20),
        id: 400,
      );
      final message5 = eg.streamMessage(
        id: 500,
        stream: eg.stream(streamId: 2),
        topic: 'topic3',
        sender: eg.user(userId: 20),
      );

      recentSenders.handleMessage(message1);
      recentSenders.handleMessage(message2);
      recentSenders.handleMessage(message3);
      recentSenders.handleMessage(message4);
      recentSenders.handleMessage(message5);

      final expectedStreamSenders = {
        1: {
          10: MessageIdTracker.fromIds([100, 300]),
          20: MessageIdTracker.fromIds([200, 400]),
        },
        2: {
          20: MessageIdTracker.fromIds([500]),
        },
      };

      final expectedTopicSenders = {
        1: {
          'topic1': {
            10: MessageIdTracker.fromIds([300]),
            20: MessageIdTracker.fromIds([200]),
          },
          'topic2': {
            10: MessageIdTracker.fromIds([100]),
            20: MessageIdTracker.fromIds([400]),
          },
        },
        2: {
          'topic3': {
            20: MessageIdTracker.fromIds([500]),
          }
        }
      };

      check(recentSenders.debugStreamSenders).deepEquals(expectedStreamSenders);
      check(recentSenders.debugTopicSenders).deepEquals(expectedTopicSenders);
    });
  });
}
