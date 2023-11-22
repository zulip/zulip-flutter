
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/stream.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';

void main() {
  group('Unified stream/sub data', () {
    /// Check that `streams`, `streamsByName`, and `subscriptions` all agree
    /// and point to the same objects where applicable.
    void checkUnified(StreamStore store) {
      check(store.streamsByName).length.equals(store.streams.length);
      for (final MapEntry(key: streamId, value: stream)
           in store.streams.entries) {
        check(streamId).equals(stream.streamId);
        check(store.streamsByName[stream.name]).identicalTo(stream);
        if (stream is Subscription) {
          check(store.subscriptions[streamId]).identicalTo(stream);
        } else {
          check(store.subscriptions[streamId]).isNull();
        }
      }
      for (final MapEntry(key: streamId, value: subscription)
           in store.subscriptions.entries) {
        check(streamId).equals(subscription.streamId);
        check(store.streams[streamId]).identicalTo(subscription);
      }
    }

    test('initial', () {
      final stream1 = eg.stream(streamId: 1, name: 'stream 1');
      final stream2 = eg.stream(streamId: 2, name: 'stream 2');
      checkUnified(eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream1, stream2],
        subscriptions: [eg.subscription(stream1)],
      )));
    });

    test('added by events', () {
      final stream1 = eg.stream(streamId: 1, name: 'stream 1');
      final stream2 = eg.stream(streamId: 2, name: 'stream 2');
      final store = eg.store();
      checkUnified(store);
      checkUnified(store..addStream(stream1));
      checkUnified(store..addStream(stream2));
      checkUnified(store..addSubscription(eg.subscription(stream1)));
    });
  });

  group('SubscriptionEvent', () {
    final stream = eg.stream();

    test('SubscriptionProperty.color updates with an int value', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, color: 0xFFFF0000)],
      ));
      check(store.subscriptions[stream.streamId]!.color).equals(0xFFFF0000);

      store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.color,
        value: 0xFFFF00FF));
      check(store.subscriptions[stream.streamId]!.color).equals(0xFFFF00FF);
    });

    test('SubscriptionProperty.isMuted updates with a boolean value', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, isMuted: false)],
      ));
      check(store.subscriptions[stream.streamId]!.isMuted).isFalse();

      store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.isMuted,
        value: true));
      check(store.subscriptions[stream.streamId]!.isMuted).isTrue();
    });

    test('SubscriptionProperty.inHomeView updates isMuted instead', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, isMuted: false)],
      ));
      check(store.subscriptions[stream.streamId]!.isMuted).isFalse();

      store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.inHomeView,
        value: false));
      check(store.subscriptions[stream.streamId]!.isMuted).isTrue();
    });
  });

  group('topic visibility', () {
    final stream1 = eg.stream(streamId: 1, name: 'stream 1');
    final stream2 = eg.stream(streamId: 2, name: 'stream 2');

    group('getter topicVisibilityPolicy', () {
      test('with nothing for stream', () {
        final store = eg.store();
        check(store.topicVisibilityPolicy(stream1.streamId, 'topic'))
          .equals(UserTopicVisibilityPolicy.none);
      });

      test('with nothing for topic', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.muted);
        check(store.topicVisibilityPolicy(stream1.streamId, 'topic'))
          .equals(UserTopicVisibilityPolicy.none);
      });

      test('with topic present', () {
        final store = eg.store();
        for (final policy in [
          UserTopicVisibilityPolicy.muted,
          UserTopicVisibilityPolicy.unmuted,
          UserTopicVisibilityPolicy.followed,
        ]) {
          store.addUserTopic(stream1, 'topic', policy);
          check(store.topicVisibilityPolicy(stream1.streamId, 'topic'))
            .equals(policy);
        }
      });
    });

    group('isTopicVisible/InStream', () {
      test('with policy none, stream not muted', () {
        final store = eg.store()..addStream(stream1)
          ..addSubscription(eg.subscription(stream1));
        check(store.isTopicVisibleInStream(stream1.streamId, 'topic')).isTrue();
        check(store.isTopicVisible        (stream1.streamId, 'topic')).isTrue();
      });

      test('with policy none, stream muted', () {
        final store = eg.store()..addStream(stream1)
          ..addSubscription(eg.subscription(stream1, isMuted: true));
        check(store.isTopicVisibleInStream(stream1.streamId, 'topic')).isTrue();
        check(store.isTopicVisible        (stream1.streamId, 'topic')).isFalse();
      });

      test('with policy none, stream unsubscribed', () {
        final store = eg.store()..addStream(stream1);
        check(store.isTopicVisibleInStream(stream1.streamId, 'topic')).isTrue();
        check(store.isTopicVisible        (stream1.streamId, 'topic')).isFalse();
      });

      test('with policy muted', () {
        final store = eg.store()..addStream(stream1)
          ..addSubscription(eg.subscription(stream1))
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        check(store.isTopicVisibleInStream(stream1.streamId, 'topic')).isFalse();
        check(store.isTopicVisible        (stream1.streamId, 'topic')).isFalse();
      });

      test('with policy unmuted', () {
        final store = eg.store()..addStream(stream1)
          ..addSubscription(eg.subscription(stream1, isMuted: true))
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unmuted);
        check(store.isTopicVisibleInStream(stream1.streamId, 'topic')).isTrue();
        check(store.isTopicVisible        (stream1.streamId, 'topic')).isTrue();
      });

      test('with policy followed', () {
        final store = eg.store()..addStream(stream1)
          ..addSubscription(eg.subscription(stream1, isMuted: true))
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.followed);
        check(store.isTopicVisibleInStream(stream1.streamId, 'topic')).isTrue();
        check(store.isTopicVisible        (stream1.streamId, 'topic')).isTrue();
      });
    });

    UserTopicItem makeUserTopicItem(
        ZulipStream stream, String topic, UserTopicVisibilityPolicy policy) {
      return UserTopicItem(
        streamId: stream.streamId,
        topicName: topic,
        lastUpdated: 1234567890,
        visibilityPolicy: policy,
      );
    }

    void compareTopicVisibility(PerAccountStore store, List<UserTopicItem> expected) {
      final expectedStore = eg.store(initialSnapshot: eg.initialSnapshot(
        userTopics: expected,
      ));
      check(store.debugStreamStore.topicVisibility)
        .deepEquals(expectedStore.debugStreamStore.topicVisibility);
    }

    test('data structure', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream1, stream2],
        userTopics: [
          makeUserTopicItem(stream1, 'topic 1', UserTopicVisibilityPolicy.muted),
          makeUserTopicItem(stream1, 'topic 2', UserTopicVisibilityPolicy.unmuted),
          makeUserTopicItem(stream2, 'topic 3', UserTopicVisibilityPolicy.unknown),
          makeUserTopicItem(stream2, 'topic 4', UserTopicVisibilityPolicy.followed),
        ]));
      check(store.debugStreamStore.topicVisibility).deepEquals({
        stream1.streamId: {
          'topic 1': UserTopicVisibilityPolicy.muted,
          'topic 2': UserTopicVisibilityPolicy.unmuted,
        },
        stream2.streamId: {
          // 'topic 3' -> unknown treated as no policy
          'topic 4': UserTopicVisibilityPolicy.followed,
        }
      });
    });

    group('events', () {
      test('add with new stream', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        compareTopicVisibility(store, [
          makeUserTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.muted),
        ]);
      });

      test('add in existing stream', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted)
          ..addUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted);
        compareTopicVisibility(store, [
          makeUserTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.muted),
          makeUserTopicItem(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('update existing policy', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted)
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unmuted);
        compareTopicVisibility(store, [
          makeUserTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('remove, with others in stream', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted)
          ..addUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted)
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.none);
        compareTopicVisibility(store, [
          makeUserTopicItem(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('remove, as last in stream', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted)
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.none);
        compareTopicVisibility(store, [
        ]);
      });

      test('treat unknown enum value as removing', () {
        final store = eg.store()
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted)
          ..addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unknown);
        compareTopicVisibility(store, [
        ]);
      });
    });

    test('smoke', () {
      final stream = eg.stream();
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        userTopics: [
          makeUserTopicItem(stream, 'topic 1', UserTopicVisibilityPolicy.muted),
          makeUserTopicItem(stream, 'topic 2', UserTopicVisibilityPolicy.unmuted),
          makeUserTopicItem(stream, 'topic 3', UserTopicVisibilityPolicy.followed),
        ]));
      check(store.topicVisibilityPolicy(stream.streamId, 'topic 1'))
        .equals(UserTopicVisibilityPolicy.muted);
      check(store.topicVisibilityPolicy(stream.streamId, 'topic 2'))
        .equals(UserTopicVisibilityPolicy.unmuted);
      check(store.topicVisibilityPolicy(stream.streamId, 'topic 3'))
        .equals(UserTopicVisibilityPolicy.followed);
      check(store.topicVisibilityPolicy(stream.streamId, 'topic 4'))
        .equals(UserTopicVisibilityPolicy.none);
    });
  });
}
