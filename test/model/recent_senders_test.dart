import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
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
      check(idTracker.idsForTesting).isEmpty();
    });

    test('calling add(id) adds the same id to the tracker just one time', () {
      prepare();
      check(idTracker.idsForTesting).isEmpty();
      idTracker.add(1);
      idTracker.add(1);
      check(idTracker.idsForTesting.singleOrNull).equals(1);
    });

    test('ids are sorted ascendingly, with maxId pointing to the last element', () {
      prepare();
      check(idTracker.idsForTesting).isEmpty();
      idTracker.add(1);
      idTracker.add(9);
      idTracker.add(-1);
      idTracker.add(5);
      check(idTracker.idsForTesting).deepEquals([-1, 1, 5, 9]);
      check(idTracker.maxId).equals(idTracker.idsForTesting.last);
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

      final streamMessage = eg.streamMessage();
      recentSenders.handleMessage(streamMessage);
      check(recentSenders.debugIsNotEmpty).equals(true);
    });

    group('compareByRecency', () {
      final userA = eg.otherUser;
      final userB = eg.thirdUser;
      final stream = eg.stream();
      const topic1 = 'topic1';
      const topic2 = 'topic2';

      void fillWithMessages(List<StreamMessage> messages) {
        for (final message in messages) {
          recentSenders.handleMessage(message);
        }
      }

      /// Determines the priority between [userA] and [userB] based on their activity.
      ///
      /// The activity is first looked for in [topic] then in [stream].
      /// 
      /// Returns a negative number if [userA] has more recent activity,
      /// returns a positive number if [userB] has more recent activity, and
      /// returns `0` if the activity is the same or there is no activity at all.
      int priority({required String? topic}) {
        return recentSenders.compareByRecency(
          userA,
          userB,
          streamId: stream.streamId,
          topic: topic,
        );
      }

      test('prioritizes the user with more recent activity in the topic', () {
        final userAMessage = eg.streamMessage(sender: userA, stream: stream, topic: topic1);
        final userBMessage = eg.streamMessage(sender: userB, stream: stream, topic: topic1);
        prepare();
        fillWithMessages([userAMessage, userBMessage]);
        final priorityInTopic1 = priority(topic: topic1);
        check(priorityInTopic1).isGreaterThan(0); // [userB] is more recent in topic1.
      });

      test('prioritizes the user with more recent activity in the stream '
        'if there is no activity in the topic from both users', () {
        final userAMessage = eg.streamMessage(sender: userA, stream: stream, topic: topic1);
        final userBMessage = eg.streamMessage(sender: userB, stream: stream, topic: topic1);
        prepare();
        fillWithMessages([userAMessage, userBMessage]);
        final priorityInTopic2 = priority(topic: topic2);
        check(priorityInTopic2).isGreaterThan(0); // [userB] is more recent in the stream.
      });

      test('prioritizes the user with more recent activity in the stream '
        'if there is no topic provided', () {
        final userAMessage = eg.streamMessage(sender: userA, stream: stream, topic: topic1);
        final userBMessage = eg.streamMessage(sender: userB, stream: stream, topic: topic2);
        prepare();
        fillWithMessages([userAMessage, userBMessage]);
        final priorityInStream = priority(topic: null);
        check(priorityInStream).isGreaterThan(0); // [userB] is more recent in the stream.
      });

      test('prioritizes none of the users if there is no activity in the stream from both users', () {
        prepare();
        fillWithMessages([]);
        final priorityInStream = priority(topic: null);
        check(priorityInStream).equals(0); // none of the users has activity in the stream.
      });
    });
  });
}
