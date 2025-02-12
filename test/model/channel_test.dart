
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/channel.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';

void main() {
  group('Unified stream/sub data', () {
    /// Check that `streams`, `streamsByName`, and `subscriptions` all agree
    /// and point to the same objects where applicable.
    void checkUnified(ChannelStore store) {
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
      final stream1 = eg.stream();
      final stream2 = eg.stream();
      checkUnified(eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream1, stream2],
        subscriptions: [eg.subscription(stream1)],
      )));
    });

    test('added/updated by events', () async {
      final stream1 = eg.stream();
      final stream2 = eg.stream();
      final store = eg.store();
      checkUnified(store);

      await store.addStream(stream1);
      checkUnified(store);

      await store.addStream(stream2);
      checkUnified(store);

      await store.addSubscription(eg.subscription(stream1));
      checkUnified(store);

      await store.handleEvent(eg.channelUpdateEvent(store.streams[stream1.streamId]!,
        property: ChannelPropertyName.name, value: 'new stream',
      ));
      checkUnified(store);

      await store.handleEvent(eg.channelUpdateEvent(store.streams[stream1.streamId]!,
        property: ChannelPropertyName.channelPostPolicy,
        value: ChannelPostPolicy.administrators,
      ));
      checkUnified(store);
    });
  });

  group('SubscriptionEvent', () {
    final stream = eg.stream();

    test('SubscriptionProperty.color updates with an int value', () async {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, color: 0xFFFF0000)],
      ));
      check(store.subscriptions[stream.streamId]!.color).equals(0xFFFF0000);

      await store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.color,
        value: 0xFFFF00FF));
      check(store.subscriptions[stream.streamId]!.color).equals(0xFFFF00FF);
    });

    test('SubscriptionProperty.isMuted updates with a boolean value', () async {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, isMuted: false)],
      ));
      check(store.subscriptions[stream.streamId]!.isMuted).isFalse();

      await store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.isMuted,
        value: true));
      check(store.subscriptions[stream.streamId]!.isMuted).isTrue();
    });

    test('SubscriptionProperty.inHomeView updates isMuted instead', () async {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        subscriptions: [eg.subscription(stream, isMuted: false)],
      ));
      check(store.subscriptions[stream.streamId]!.isMuted).isFalse();

      await store.handleEvent(SubscriptionUpdateEvent(id: 1,
        streamId: stream.streamId,
        property: SubscriptionProperty.inHomeView,
        value: false));
      check(store.subscriptions[stream.streamId]!.isMuted).isTrue();
    });
  });

  group('topic visibility', () {
    final stream1 = eg.stream();
    final stream2 = eg.stream();

    group('getter topicVisibilityPolicy', () {
      test('with nothing for stream', () {
        final store = eg.store();
        check(store.topicVisibilityPolicy(stream1.streamId, eg.t('topic')))
          .equals(UserTopicVisibilityPolicy.none);
      });

      test('with nothing for topic', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.muted);
        check(store.topicVisibilityPolicy(stream1.streamId, eg.t('topic')))
          .equals(UserTopicVisibilityPolicy.none);
      });

      test('with topic present', () async {
        final store = eg.store();
        for (final policy in [
          UserTopicVisibilityPolicy.muted,
          UserTopicVisibilityPolicy.unmuted,
          UserTopicVisibilityPolicy.followed,
        ]) {
          await store.addUserTopic(stream1, 'topic', policy);
          check(store.topicVisibilityPolicy(stream1.streamId, eg.t('topic')))
            .equals(policy);
        }
      });
    });

    group('isTopicVisible/InStream', () {
      test('with policy none, stream not muted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1));
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isTrue();
      });

      test('with policy none, stream muted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isFalse();
      });

      test('with policy none, stream unsubscribed', () async {
        final store = eg.store();
        await store.addStream(stream1);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isFalse();
      });

      test('with policy muted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1));
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isFalse();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isFalse();
      });

      test('with policy unmuted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unmuted);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isTrue();
      });

      test('with policy followed', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.followed);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isTrue();
      });
    });

    group('willChangeIfTopicVisible/InStream', () {
      UserTopicEvent mkEvent(UserTopicVisibilityPolicy policy) =>
        eg.userTopicEvent(stream1.streamId, 'topic', policy);

      void checkChanges(PerAccountStore store,
          UserTopicVisibilityPolicy newPolicy,
          VisibilityEffect expectedInStream, VisibilityEffect expectedOverall) {
        final event = mkEvent(newPolicy);
        check(store.willChangeIfTopicVisibleInStream(event)).equals(expectedInStream);
        check(store.willChangeIfTopicVisible        (event)).equals(expectedOverall);
      }

      test('stream not muted, policy none -> followed, no change', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1));
        checkChanges(store, UserTopicVisibilityPolicy.followed,
          VisibilityEffect.none, VisibilityEffect.none);
      });

      test('stream not muted, policy none -> muted, means muted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1));
        checkChanges(store, UserTopicVisibilityPolicy.muted,
          VisibilityEffect.muted, VisibilityEffect.muted);
      });

      test('stream muted, policy none -> followed, means none/unmuted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        checkChanges(store, UserTopicVisibilityPolicy.followed,
          VisibilityEffect.none, VisibilityEffect.unmuted);
      });

      test('stream muted, policy none -> muted, means muted/none', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        checkChanges(store, UserTopicVisibilityPolicy.muted,
          VisibilityEffect.muted, VisibilityEffect.none);
      });

      final policies = [
        UserTopicVisibilityPolicy.muted,
        UserTopicVisibilityPolicy.none,
        UserTopicVisibilityPolicy.unmuted,
      ];
      for (final streamMuted in [null, false, true]) {
        for (final oldPolicy in policies) {
          for (final newPolicy in policies) {
            final streamDesc = switch (streamMuted) {
              false => "stream not muted",
              true => "stream muted",
              null => "stream unsubscribed",
            };
            test('$streamDesc, topic ${oldPolicy.name} -> ${newPolicy.name}', () async {
              final store = eg.store();
              await store.addStream(stream1);
              if (streamMuted != null) {
                await store.addSubscription(
                  eg.subscription(stream1, isMuted: streamMuted));
              }
              await store.handleEvent(mkEvent(oldPolicy));
              final oldVisibleInStream = store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'));
              final oldVisible         = store.isTopicVisible(stream1.streamId, eg.t('topic'));

              final event = mkEvent(newPolicy);
              final willChangeInStream = store.willChangeIfTopicVisibleInStream(event);
              final willChange         = store.willChangeIfTopicVisible(event);

              await store.handleEvent(event);
              final newVisibleInStream = store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'));
              final newVisible         = store.isTopicVisible(stream1.streamId, eg.t('topic'));

              VisibilityEffect fromOldNew(bool oldVisible, bool newVisible) {
                if (newVisible == oldVisible) return VisibilityEffect.none;
                if (newVisible) return VisibilityEffect.unmuted;
                return VisibilityEffect.muted;
              }
              check(willChangeInStream)
                .equals(fromOldNew(oldVisibleInStream, newVisibleInStream));
              check(willChange)
                .equals(fromOldNew(oldVisible,         newVisible));
            });
          }
        }
      }
    });

    void compareTopicVisibility(PerAccountStore store, List<UserTopicItem> expected) {
      final expectedStore = eg.store(initialSnapshot: eg.initialSnapshot(
        userTopics: expected,
      ));
      check(store.debugTopicVisibility)
        .deepEquals(expectedStore.debugTopicVisibility);
    }

    test('data structure', () {
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream1, stream2],
        userTopics: [
          eg.userTopicItem(stream1, 'topic 1', UserTopicVisibilityPolicy.muted),
          eg.userTopicItem(stream1, 'topic 2', UserTopicVisibilityPolicy.unmuted),
          eg.userTopicItem(stream2, 'topic 3', UserTopicVisibilityPolicy.unknown),
          eg.userTopicItem(stream2, 'topic 4', UserTopicVisibilityPolicy.followed),
        ]));
      check(store.debugTopicVisibility).deepEquals({
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
      test('add with new stream', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.muted),
        ]);
      });

      test('add in existing stream', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.addUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.muted),
          eg.userTopicItem(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('update existing policy', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unmuted);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('remove, with others in stream', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.addUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted);
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.none);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('remove, as last in stream', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.none);
        compareTopicVisibility(store, [
        ]);
      });

      test('treat unknown enum value as removing', () async {
        final store = eg.store();
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.addUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unknown);
        compareTopicVisibility(store, [
        ]);
      });
    });

    test('smoke', () {
      final stream = eg.stream();
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        streams: [stream],
        userTopics: [
          eg.userTopicItem(stream, 'topic 1', UserTopicVisibilityPolicy.muted),
          eg.userTopicItem(stream, 'topic 2', UserTopicVisibilityPolicy.unmuted),
          eg.userTopicItem(stream, 'topic 3', UserTopicVisibilityPolicy.followed),
        ]));
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('topic 1')))
        .equals(UserTopicVisibilityPolicy.muted);
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('topic 2')))
        .equals(UserTopicVisibilityPolicy.unmuted);
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('topic 3')))
        .equals(UserTopicVisibilityPolicy.followed);
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('topic 4')))
        .equals(UserTopicVisibilityPolicy.none);
    });
  });
}
