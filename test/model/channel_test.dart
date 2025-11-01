import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/channel.dart';

import '../api/fake_api.dart';
import '../api/model/model_checks.dart';
import '../api/route/route_checks.dart';
import '../example_data.dart' as eg;
import '../stdlib_checks.dart';
import 'binding.dart';
import 'store_checks.dart';
import 'test_store.dart';

void main() {
  TestZulipBinding.ensureInitialized();

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

    test('unsubscribed then subscribed by events', () async {
      // Regression test for: https://chat.zulip.org/#narrow/channel/48-mobile/topic/Unsubscribe.20then.20resubscribe.20to.20channel/with/2160241
      final stream = eg.stream();
      final store = eg.store();
      await store.addStream(stream);
      await store.addSubscription(eg.subscription(stream));
      checkUnified(store);

      await store.handleEvent(SubscriptionRemoveEvent(id: 1,
        streamIds: [stream.streamId]));
      checkUnified(store);

      await store.handleEvent(SubscriptionAddEvent(id: 1,
        subscriptions: [eg.subscription(stream)]));
      checkUnified(store);
    });
  });

  group('channelFolderComparator', () {
    final folder1 = eg.channelFolder(id: 1, order: null, name: 'M');
    final folder2 = eg.channelFolder(id: 2, order: null, name: 'n');
    final folder3 = eg.channelFolder(id: 3, order: 2, name: 'a');
    final folder4 = eg.channelFolder(id: 4, order: 0, name: 'b');
    final folder5 = eg.channelFolder(id: 5, order: 1, name: 'c');

    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      channelFolders: [folder1, folder2, folder3, folder4, folder5]));

    final sorted = store.channelFolders.values.toList()
      .sorted(ChannelStore.compareChannelFolders);
    check(sorted).deepEquals([folder1, folder2, folder4, folder5, folder3]);
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
  });

  group('ChannelFolderEvent', () {
    group('add', () {
      test('smoke', () async {
        final folder1 = eg.channelFolder(id: 1);
        final folder2 = eg.channelFolder(id: 2);
        final store = eg.store(initialSnapshot: eg.initialSnapshot(
          channelFolders: [folder1]));

        await store.handleEvent(ChannelFolderAddEvent(
          id: 1, channelFolder: folder2));
        check(store.channelFolders).deepEquals({1: folder1, 2: folder2});
      });
    });

    group('update', () {
      void doTest(ChannelFolderChange change) {
        final ChannelFolderChange(
          :name, :description, :renderedDescription, :isArchived) = change;
        final testDescription = [
          if (name != null)                'name: $name',
          if (description != null)         'description: $description',
          if (renderedDescription != null) 'renderedDescription: $renderedDescription',
          if (isArchived != null)          'isArchived: $isArchived',
        ].join(', ');
        test(testDescription, () async {
          final channelFolder = eg.channelFolder();
          assert(name == null || name != channelFolder.name);
          assert(description == null || description != channelFolder.description);
          assert(renderedDescription == null || renderedDescription != channelFolder.renderedDescription);
          assert(isArchived == null || isArchived != channelFolder.isArchived);

          final store = eg.store(initialSnapshot: eg.initialSnapshot(
            channelFolders: [channelFolder]));
          await store.handleEvent(ChannelFolderUpdateEvent(id: 1,
            channelFolderId: channelFolder.id, data: change));
          check(store.channelFolders.values.single)
            ..name.equals(name ?? channelFolder.name)
            ..description.equals(description ?? channelFolder.description)
            ..renderedDescription.equals(renderedDescription ?? channelFolder.renderedDescription)
            ..isArchived.equals(isArchived ?? channelFolder.isArchived);
        });
      }

      doTest(eg.channelFolderChange(name: 'new name'));
      doTest(eg.channelFolderChange(description: 'new description'));
      doTest(eg.channelFolderChange(renderedDescription: '<p>new description</p>'));
      doTest(eg.channelFolderChange(isArchived: true));

      doTest(eg.channelFolderChange(
        name: 'new name',
        description: 'new description',
        renderedDescription: '<p>new description</p>',
        isArchived: true,
      ));
    });

    group('reorder', () {
      List<ChannelFolder> foldersFromStoreInOrder(PerAccountStore store) {
        return store.channelFolders.values.toList()
          ..sort((a, b) => a.order!.compareTo(b.order!));
      }

      test('smoke', () async {
        final folderA = eg.channelFolder(order: 0);
        final folderB = eg.channelFolder(order: 1);
        final folderC = eg.channelFolder(order: 2);

        final store = eg.store(initialSnapshot: eg.initialSnapshot(
          channelFolders: [folderA, folderB, folderC]));
        check(foldersFromStoreInOrder(store)).deepEquals([folderA, folderB, folderC]);

        await store.handleEvent(ChannelFolderReorderEvent(id: 1,
          order: [folderA.id, folderC.id, folderB.id]));
        check(foldersFromStoreInOrder(store)).deepEquals([folderA, folderC, folderB]);

        await store.handleEvent(ChannelFolderReorderEvent(id: 1,
          order: [folderC.id, folderB.id, folderA.id]));
        check(foldersFromStoreInOrder(store)).deepEquals([folderC, folderB, folderA]);
      });
    });
  });

  group('topics data', () {
    final channel = eg.stream();
    final otherChannel = eg.stream();
    late PerAccountStore store;
    late FakeApiConnection connection;
    late int notifiedCount;

    void checkNotified({required int count}) {
      check(notifiedCount).equals(count);
      notifiedCount = 0;
    }
    void checkNotNotified()  => checkNotified(count: 0);
    void checkNotifiedOnce() => checkNotified(count: 1);

    Condition<Object?> isStreamTopicsEntry(String topic, int maxId) {
      return (it) => it.isA<GetStreamTopicsEntry>()
        ..maxId.equals(maxId)
        ..name.equals(eg.t(topic));
    }

    Future<void> prepare({
      List<GetStreamTopicsEntry>? topics,
      List<StreamMessage>? messages,
    }) async {
      notifiedCount = 0;
      store = eg.store();
      await store.addStreams([channel, otherChannel]);
      await store.addSubscriptions([
        eg.subscription(channel),
        eg.subscription(otherChannel),
      ]);
      await store.addMessages(messages ?? []);
      store.addListener(() {
        notifiedCount++;
      });

      connection = store.connection as FakeApiConnection;
      connection.prepare(json: GetStreamTopicsResult(topics: topics ?? []).toJson());
      await store.fetchTopics(channel.streamId);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('GET')
        ..url.path.equals('/api/v1/users/me/${channel.streamId}/topics');
    }

    test('fetch topics -> update data, try fetching again -> no request sent', () async {
      await prepare(topics: [
        eg.getStreamTopicsEntry(name: 'foo', maxId: 100),
        eg.getStreamTopicsEntry(name: 'bar', maxId: 200),
        eg.getStreamTopicsEntry(name: 'baz', maxId: 300),
      ]);
      check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
        isStreamTopicsEntry('baz', 300),
        isStreamTopicsEntry('bar', 200),
        isStreamTopicsEntry('foo', 100),
      ]);

      connection.prepare(json: GetStreamTopicsResult(topics: [
        eg.getStreamTopicsEntry(name: 'foo', maxId: 100),
        eg.getStreamTopicsEntry(name: 'bar', maxId: 200),
        eg.getStreamTopicsEntry(name: 'baz', maxId: 300),
      ]).toJson());
      await store.fetchTopics(channel.streamId);
      check(connection.takeRequests()).isEmpty();
    });

    test('getChannelTopics sorts descending by maxId', () async {
      await prepare(topics: [
        eg.getStreamTopicsEntry(name: 'bar', maxId: 200),
        eg.getStreamTopicsEntry(name: 'foo', maxId: 100),
        eg.getStreamTopicsEntry(name: 'baz', maxId: 300),
      ]);
      check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
        isStreamTopicsEntry('baz', 300),
        isStreamTopicsEntry('bar', 200),
        isStreamTopicsEntry('foo', 100),
      ]);

      await store.addMessage(eg.streamMessage(
        id: 301, stream: channel, topic: 'foo'));
      check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
        isStreamTopicsEntry('foo', 301),
        isStreamTopicsEntry('baz', 300),
        isStreamTopicsEntry('bar', 200),
      ]);
    });

    group('handleMessageEvent', () {
      test('new message in fetched channel', () async {
        await prepare(topics: [
          eg.getStreamTopicsEntry(name: 'old topic', maxId: 1),
        ]);

        await store.addMessage(
          eg.streamMessage(id: 2, stream: channel, topic: 'new topic'));
        check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
          isStreamTopicsEntry('new topic', 2),
          isStreamTopicsEntry('old topic', 1),
        ]);
        checkNotifiedOnce();

        await store.addMessage(
          eg.streamMessage(id: 3, stream: channel, topic: 'old topic'));
        check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
          isStreamTopicsEntry('old topic', 3),
          isStreamTopicsEntry('new topic', 2),
        ]);
        checkNotifiedOnce();
      });

      test('new message in channel not fetched before', () async {
        await prepare();
        check(store).getStreamTopics(otherChannel.streamId).isNull();

        await store.addMessage(
          eg.streamMessage(id: 2, stream: otherChannel, topic: 'new topic'));
        check(store).getStreamTopics(otherChannel.streamId).isNull();
        checkNotNotified();
      });

      test('new message with equal or lower message ID', () async {
        await prepare(topics: [
          eg.getStreamTopicsEntry(name: 'topic', maxId: 2),
        ]);

        await store.addMessage(
          eg.streamMessage(id: 2, stream: channel, topic: 'topic'));
        check(store).getStreamTopics(channel.streamId).isNotNull().single
          ..name.equals(eg.t('topic'))
          ..maxId.equals(2);
        checkNotNotified();

        await store.addMessage(
          eg.streamMessage(id: 1, stream: channel, topic: 'topic'));
        check(store).getStreamTopics(channel.streamId).isNotNull().single
          ..name.equals(eg.t('topic'))
          ..maxId.equals(2);
        checkNotNotified();
      });

      test('ignore DM messages', () async {
        await prepare();
        await store.addUsers([eg.selfUser, eg.otherUser]);
        checkNotified(count: 2);

        await store.addMessage(eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]));
        checkNotNotified();
      });
    });

    group('handleUpdateMessageEvent', () {
      Future<void> prepareWithMessages(List<StreamMessage> messages, {
        required List<Condition<Object?>> expectedTopics,
      }) async {
        await prepare();
        assert(messages.isNotEmpty);
        assert(messages.every((m) => m.streamId == channel.streamId));
        await store.addMessages(messages);
        check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals(expectedTopics);
        checkNotified(count: messages.length);
      }

      test('ignore content only update', () async {
        final message = eg.streamMessage(id: 123, stream: channel, topic: 'foo');
        await prepareWithMessages([message], expectedTopics: [
          isStreamTopicsEntry('foo', 123),
        ]);

        await store.handleEvent(eg.updateMessageEditEvent(message));
        checkNotNotified();
      });

      group('PropagateMode.changedAll', () {
        test('topic moved to another stream with no previously fetched topics', () async {
          final messagesToMove = List.generate(10, (i) =>
            eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
          await prepareWithMessages(messagesToMove, expectedTopics: [
            isStreamTopicsEntry('foo', 109),
          ]);

          await store.handleEvent(eg.updateMessageEventMoveFrom(
            origMessages: messagesToMove,
            newStreamId: otherChannel.streamId,
            propagateMode: PropagateMode.changeAll));
          check(store).getStreamTopics(channel.streamId).isNotNull().isEmpty();
          check(store).getStreamTopics(otherChannel.streamId).isNull();
          checkNotifiedOnce();
        });

        test('topic moved to new topic in another stream', () async {
          final messagesToMove = List.generate(10, (i) =>
            eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
          await prepareWithMessages(messagesToMove, expectedTopics: [
            isStreamTopicsEntry('foo', 109),
          ]);

          // Make sure that topics in otherChannel has been fetched.
          connection.prepare(json: GetStreamTopicsResult(topics: [
            eg.getStreamTopicsEntry(name: 'foo', maxId: 1),
          ]).toJson());
          await store.fetchTopics(otherChannel.streamId);
          check(store).getStreamTopics(otherChannel.streamId).isNotNull().single
            ..name.equals(eg.t('foo'))
            ..maxId.equals(1);
          checkNotNotified();

          await store.handleEvent(eg.updateMessageEventMoveFrom(
            origMessages: messagesToMove,
            newStreamId: otherChannel.streamId,
            newTopicStr: 'bar',
            propagateMode: PropagateMode.changeAll));
          check(store).getStreamTopics(channel.streamId).isNotNull().isEmpty();
          check(store).getStreamTopics(otherChannel.streamId).isNotNull().deepEquals([
            isStreamTopicsEntry('bar', 109),
            isStreamTopicsEntry('foo', 1),
          ]);
          checkNotifiedOnce();
        });

        test('topic moved to known topic in another stream', () async {
          final messagesToMove = List.generate(10, (i) =>
            eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
          await prepareWithMessages(messagesToMove, expectedTopics: [
            isStreamTopicsEntry('foo', 109),
          ]);

          // Make sure that topics in otherChannel has been fetched.
          connection.prepare(json: GetStreamTopicsResult(topics: [
            eg.getStreamTopicsEntry(name: 'foo', maxId: 1),
          ]).toJson());
          await store.fetchTopics(otherChannel.streamId);
          check(store).getStreamTopics(otherChannel.streamId).isNotNull().single
            ..name.equals(eg.t('foo'))
            ..maxId.equals(1);
          checkNotNotified();

          await store.handleEvent(eg.updateMessageEventMoveFrom(
            origMessages: messagesToMove,
            newStreamId: otherChannel.streamId,
            propagateMode: PropagateMode.changeAll));
          check(store).getStreamTopics(channel.streamId).isNotNull().isEmpty();
          check(store).getStreamTopics(otherChannel.streamId).isNotNull().single
            ..name.equals(eg.t('foo'))
            ..maxId.equals(109);
          checkNotifiedOnce();
        });

        test('topic moved to new topic in the same stream', () async {
          final messagesToMove = List.generate(10, (i) =>
            eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
          await prepareWithMessages(messagesToMove, expectedTopics: [
            isStreamTopicsEntry('foo', 109),
          ]);

          await store.handleEvent(eg.updateMessageEventMoveFrom(
            origMessages: messagesToMove,
            newTopicStr: 'bar',
            propagateMode: PropagateMode.changeAll));
          check(store).getStreamTopics(channel.streamId).isNotNull().single
            ..name.equals(eg.t('bar'))
            ..maxId.equals(109);
          checkNotifiedOnce();
        });

        test('topic moved to known topic in the same stream', () async {
          final messagesToMove = List.generate(10, (i) =>
            eg.streamMessage(id: 100 + i, stream: channel, topic: 'foo'));
          await prepareWithMessages([
            ...messagesToMove,
            eg.streamMessage(id: 1, stream: channel, topic: 'bar'),
          ], expectedTopics: [
            isStreamTopicsEntry('foo', 109),
            isStreamTopicsEntry('bar', 1),
          ]);

          await store.handleEvent(eg.updateMessageEventMoveFrom(
            origMessages: messagesToMove,
            newTopicStr: 'bar',
            propagateMode: PropagateMode.changeAll));
          check(store).getStreamTopics(channel.streamId).isNotNull().single
            ..name.equals(eg.t('bar'))
            ..maxId.equals(109);
          checkNotifiedOnce();
        });
      });

      test('message moved to new topic', () async {
        final messageToMove =
          eg.streamMessage(id: 101, stream: channel, topic: 'foo');
        await prepareWithMessages([
          messageToMove,
        ], expectedTopics: [
          isStreamTopicsEntry('foo', 101),
        ]);

        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: [messageToMove],
          newTopicStr: 'bar',
          propagateMode: PropagateMode.changeOne));
        check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
          isStreamTopicsEntry('foo', 101),
          isStreamTopicsEntry('bar', 101),
        ]);
        checkNotifiedOnce();
      });

      test('message moved to known topic; moved message ID < maxId', () async {
        final messageToMove =
          eg.streamMessage(id: 100, stream: channel, topic: 'foo');
        await prepareWithMessages([
          messageToMove,
          eg.streamMessage(id: 999, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isStreamTopicsEntry('bar', 999),
          isStreamTopicsEntry('foo', 100),
        ]);

        // Message with ID 100 moved from "foo" to "bar", whose maxId was 999.
        // We expect no updates to "bar"'s maxId, since the moved message
        // has a lower ID.
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: [messageToMove],
          newTopicStr: 'bar',
          propagateMode: PropagateMode.changeOne));
        check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
          isStreamTopicsEntry('bar', 999),
          isStreamTopicsEntry('foo', 100),
        ]);
        checkNotNotified();
      });

      test('message moved to known topic; moved message ID > maxId', () async {
        final messageToMove =
          eg.streamMessage(id: 999, stream: channel, topic: 'foo');
        await prepareWithMessages([
          messageToMove,
          eg.streamMessage(id: 100, stream: channel, topic: 'bar'),
        ], expectedTopics: [
          isStreamTopicsEntry('foo', 999),
          isStreamTopicsEntry('bar', 100),
        ]);

        // Message with ID 999 moved from "foo" to "bar", whose maxId was 100.
        // We expect an update to "bar"'s maxId, since the moved message has
        // a higher ID.
        await store.handleEvent(eg.updateMessageEventMoveFrom(
          origMessages: [messageToMove],
          newTopicStr: 'bar',
          propagateMode: PropagateMode.changeOne));
        check(store).getStreamTopics(channel.streamId).isNotNull().deepEquals([
          isStreamTopicsEntry('foo', 999),
          isStreamTopicsEntry('bar', 999),
        ]);
        checkNotifiedOnce();
      });
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
        await store.setUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.muted);
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
          await store.setUserTopic(stream1, 'topic', policy);
          check(store.topicVisibilityPolicy(stream1.streamId, eg.t('topic')))
            .equals(policy);

          // Case-insensitive
          check(store.topicVisibilityPolicy(stream1.streamId, eg.t('ToPiC')))
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
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isFalse();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isFalse();

        // Case-insensitive
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('ToPiC'))).isFalse();
        check(store.isTopicVisible        (stream1.streamId, eg.t('ToPiC'))).isFalse();
      });

      test('with policy unmuted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unmuted);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isTrue();

        // Case-insensitive
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('tOpIc'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('tOpIc'))).isTrue();
      });

      test('with policy followed', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.followed);
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('topic'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('topic'))).isTrue();

        // Case-insensitive
        check(store.isTopicVisibleInStream(stream1.streamId, eg.t('TOPIC'))).isTrue();
        check(store.isTopicVisible        (stream1.streamId, eg.t('TOPIC'))).isTrue();
      });
    });

    group('willChangeIfTopicVisible/InStream', () {
      UserTopicEvent mkEvent(UserTopicVisibilityPolicy policy) =>
        eg.userTopicEvent(stream1.streamId, 'topic', policy);

      // For testing case-insensitivity
      UserTopicEvent mkEventDifferentlyCased(UserTopicVisibilityPolicy policy) =>
        eg.userTopicEvent(stream1.streamId, 'ToPiC', policy);

      assert(() {
        // (sanity check on mkEvent and mkEventDifferentlyCased)
        final event1 = mkEvent(UserTopicVisibilityPolicy.followed);
        final event2 = mkEventDifferentlyCased(UserTopicVisibilityPolicy.followed);
        return event1.topicName.isSameAs(event2.topicName)
          && event1.topicName.apiName != event2.topicName.apiName;
      }());

      void checkChanges(PerAccountStore store,
          UserTopicVisibilityPolicy newPolicy,
          UserTopicVisibilityEffect expectedInStream,
          UserTopicVisibilityEffect expectedOverall) {
        final event = mkEvent(newPolicy);
        check(store.willChangeIfTopicVisibleInStream(event)).equals(expectedInStream);
        check(store.willChangeIfTopicVisible        (event)).equals(expectedOverall);

        final event2 = mkEventDifferentlyCased(newPolicy);
        check(store.willChangeIfTopicVisibleInStream(event2)).equals(expectedInStream);
        check(store.willChangeIfTopicVisible        (event2)).equals(expectedOverall);
      }

      test('stream not muted, policy none -> followed, no change', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1));
        checkChanges(store, UserTopicVisibilityPolicy.followed,
          UserTopicVisibilityEffect.none, UserTopicVisibilityEffect.none);
      });

      test('stream not muted, policy none -> muted, means muted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1));
        checkChanges(store, UserTopicVisibilityPolicy.muted,
          UserTopicVisibilityEffect.muted, UserTopicVisibilityEffect.muted);
      });

      test('stream muted, policy none -> followed, means none/unmuted', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        checkChanges(store, UserTopicVisibilityPolicy.followed,
          UserTopicVisibilityEffect.none, UserTopicVisibilityEffect.unmuted);
      });

      test('stream muted, policy none -> muted, means muted/none', () async {
        final store = eg.store();
        await store.addStream(stream1);
        await store.addSubscription(eg.subscription(stream1, isMuted: true));
        checkChanges(store, UserTopicVisibilityPolicy.muted,
          UserTopicVisibilityEffect.muted, UserTopicVisibilityEffect.none);
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

              UserTopicVisibilityEffect fromOldNew(bool oldVisible, bool newVisible) {
                if (newVisible == oldVisible) return UserTopicVisibilityEffect.none;
                if (newVisible) return UserTopicVisibilityEffect.unmuted;
                return UserTopicVisibilityEffect.muted;
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
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.muted),
        ]);
      });

      test('add in existing stream', () async {
        final store = eg.store();
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.setUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.muted),
          eg.userTopicItem(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('update existing policy', () async {
        final store = eg.store();
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.unmuted);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.unmuted),
        ]);

        // case-insensitivity
        await store.setUserTopic(stream1, 'ToPiC', UserTopicVisibilityPolicy.followed);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'topic', UserTopicVisibilityPolicy.followed),
        ]);
      });

      test('remove, with others in stream', () async {
        final store = eg.store();
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        await store.setUserTopic(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted);
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.none);
        compareTopicVisibility(store, [
          eg.userTopicItem(stream1, 'other topic', UserTopicVisibilityPolicy.unmuted),
        ]);
      });

      test('remove, as last in stream', () async {
        final store = eg.store();
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        // case-insensitivity
        await store.setUserTopic(stream1, 'ToPiC', UserTopicVisibilityPolicy.none);
        compareTopicVisibility(store, [
        ]);
      });

      test('treat unknown enum value as removing', () async {
        final store = eg.store();
        await store.setUserTopic(stream1, 'topic', UserTopicVisibilityPolicy.muted);
        // case-insensitivity
        await store.setUserTopic(stream1, 'ToPiC', UserTopicVisibilityPolicy.unknown);
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
      // case-insensitivity
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('ToPiC 2')))
        .equals(UserTopicVisibilityPolicy.unmuted);
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('topic 3')))
        .equals(UserTopicVisibilityPolicy.followed);
      check(store.topicVisibilityPolicy(stream.streamId, eg.t('topic 4')))
        .equals(UserTopicVisibilityPolicy.none);
    });
  });

  group('selfCanSendMessage', () {
    test('in group', () {
      addTearDown(testBinding.reset);
      final now = testBinding.utcNow();

      final canSendMessageGroup = eg.groupSetting(members: [eg.selfUser.userId]);
      final channel = eg.stream(canSendMessageGroup: canSendMessageGroup);
      final store = eg.store(
        initialSnapshot: eg.initialSnapshot(streams: [channel]));
      check(store.selfCanSendMessage(inChannel: channel, byDate: now))
        .isTrue();
    });

    test('not in group', () {
      addTearDown(testBinding.reset);
      final now = testBinding.utcNow();

      final canSendMessageGroup = eg.groupSetting(members: []);
      final channel = eg.stream(canSendMessageGroup: canSendMessageGroup);
      final store = eg.store(
        initialSnapshot: eg.initialSnapshot(streams: [channel]));
      check(store.selfCanSendMessage(inChannel: channel, byDate: now))
        .isFalse();
    });
  });

  group('selfCanSendMessage, legacy', () {
    final testCases = [
      (ChannelPostPolicy.unknown,        UserRole.guest,         true),
      (ChannelPostPolicy.unknown,        UserRole.member,        true),
      (ChannelPostPolicy.unknown,        UserRole.moderator,     true),
      (ChannelPostPolicy.unknown,        UserRole.administrator, true),
      (ChannelPostPolicy.unknown,        UserRole.owner,         true),
      (ChannelPostPolicy.any,            UserRole.guest,         true),
      (ChannelPostPolicy.any,            UserRole.member,        true),
      (ChannelPostPolicy.any,            UserRole.moderator,     true),
      (ChannelPostPolicy.any,            UserRole.administrator, true),
      (ChannelPostPolicy.any,            UserRole.owner,         true),
      (ChannelPostPolicy.fullMembers,    UserRole.guest,         false),
      // The fullMembers/member case gets its own tests further below.
      // (ChannelPostPolicy.fullMembers,    UserRole.member,        /* complicated */),
      (ChannelPostPolicy.fullMembers,    UserRole.moderator,     true),
      (ChannelPostPolicy.fullMembers,    UserRole.administrator, true),
      (ChannelPostPolicy.fullMembers,    UserRole.owner,         true),
      (ChannelPostPolicy.moderators,     UserRole.guest,         false),
      (ChannelPostPolicy.moderators,     UserRole.member,        false),
      (ChannelPostPolicy.moderators,     UserRole.moderator,     true),
      (ChannelPostPolicy.moderators,     UserRole.administrator, true),
      (ChannelPostPolicy.moderators,     UserRole.owner,         true),
      (ChannelPostPolicy.administrators, UserRole.guest,         false),
      (ChannelPostPolicy.administrators, UserRole.member,        false),
      (ChannelPostPolicy.administrators, UserRole.moderator,     false),
      (ChannelPostPolicy.administrators, UserRole.administrator, true),
      (ChannelPostPolicy.administrators, UserRole.owner,         true),
    ];

    for (final (ChannelPostPolicy policy, UserRole role, bool canPost) in testCases) {
      test('"${role.name}" user ${canPost ? 'can' : "can't"} post in channel '
          'with "${policy.name}" policy', () {
        final selfUserWithRole = eg.user(role: role);
        final store = eg.store(
          selfUser: selfUserWithRole,
          initialSnapshot: eg.initialSnapshot(realmUsers: [selfUserWithRole]));
        final actual = store.selfCanSendMessage(
          inChannel: eg.stream(channelPostPolicy: policy),
          // [byDate] is not actually relevant for these test cases; for the
          // ones which it is, they're practiced below.
          byDate: DateTime.now());
        check(actual).equals(canPost);
      });
    }

    group('"member" user posting in a channel with "fullMembers" policy', () {
      PerAccountStore localStore({
        required User selfUser,
        required int realmWaitingPeriodThreshold,
      }) => eg.store(
        selfUser: selfUser,
        initialSnapshot: eg.initialSnapshot(
          realmWaitingPeriodThreshold: realmWaitingPeriodThreshold,
          realmUsers: [selfUser]));

      User memberUser({required String dateJoined}) => eg.user(
        role: UserRole.member, dateJoined: dateJoined);

      test('a "full" member -> can post in the channel', () {
        final store = localStore(
          selfUser: memberUser(dateJoined: '2024-11-25T10:00+00:00'),
          realmWaitingPeriodThreshold: 3);
        final hasPermission = store.selfCanSendMessage(
          inChannel: eg.stream(channelPostPolicy: ChannelPostPolicy.fullMembers),
          byDate: DateTime.utc(2024, 11, 28, 10, 00));
        check(hasPermission).isTrue();
      });

      test('not a "full" member -> cannot post in the channel', () {
        final store = localStore(
          selfUser: memberUser(dateJoined: '2024-11-25T10:00+00:00'),
          realmWaitingPeriodThreshold: 3);
        final actual = store.selfCanSendMessage(
          inChannel: eg.stream(channelPostPolicy: ChannelPostPolicy.fullMembers),
          byDate: DateTime.utc(2024, 11, 28, 09, 59));
        check(actual).isFalse();
      });
    });
  });

  group('makeTopicKeyedMap', () {
    test('"a" equals "A"', () {
      final map = makeTopicKeyedMap<int>()
        ..[eg.t('a')] = 1
        ..[eg.t('A')] = 2;
      check(map)
        ..[eg.t('a')].equals(2)
        ..[eg.t('A')].equals(2)
        ..entries.which((it) => it.single
          ..key.apiName.equals('a')
          ..value.equals(2));
    });

    test('"A" equals "a"', () {
      final map = makeTopicKeyedMap<int>()
        ..[eg.t('A')] = 1
        ..[eg.t('a')] = 2;
      check(map)
        ..[eg.t('A')].equals(2)
        ..[eg.t('a')].equals(2)
        ..entries.which((it) => it.single
          ..key.apiName.equals('A')
          ..value.equals(2));
    });
  });
}
