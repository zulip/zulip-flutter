import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/internal_link.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/action_sheet.dart';
import 'package:zulip/widgets/app_bar.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/emoji.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import '../api/fake_api.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_clipboard.dart';
import '../test_share_plus.dart';
import 'compose_box_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

late PerAccountStore store;
late FakeApiConnection connection;

/// Simulates loading a [MessageListPage] and long-pressing on [message].
Future<void> setupToMessageActionSheet(WidgetTester tester, {
  required Message message,
  required Narrow narrow,
}) async {
  addTearDown(testBinding.reset);
  assert(narrow.containsMessage(message));

  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUsers([
    eg.selfUser,
    eg.user(userId: message.senderId),
    if (narrow is DmNarrow)
      ...narrow.otherRecipientIds.map((id) => eg.user(userId: id)),
  ]);
  if (message is StreamMessage) {
    final stream = eg.stream(streamId: message.streamId);
    await store.addStream(stream);
    await store.addSubscription(eg.subscription(stream));
  }
  connection = store.connection as FakeApiConnection;

  connection.prepare(json: eg.newestGetMessagesResult(
    foundOldest: true, messages: [message]).toJson());
  await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
    child: MessageListPage(initNarrow: narrow)));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();

  // request the message action sheet
  await tester.longPress(find.byType(MessageContent));
  // sheet appears onscreen; default duration of bottom-sheet enter animation
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  TestZulipBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  void prepareRawContentResponseSuccess({
    required Message message,
    required String rawContent,
    Duration delay = Duration.zero,
  }) {
    // Prepare fetch-raw-Markdown response
    // TODO: Message should really only differ from `message`
    //   in its content / content_type, not in `id` or anything else.
    connection.prepare(delay: delay, json:
      GetMessageResult(message: eg.streamMessage(contentMarkdown: rawContent)).toJson());
  }

  void prepareRawContentResponseError() {
    final fakeResponseJson = {
      'code': 'BAD_REQUEST',
      'msg': 'Invalid message(s)',
      'result': 'error',
    };
    connection.prepare(httpStatus: 400, json: fakeResponseJson);
  }

  group('topic action sheet', () {
    final someChannel = eg.stream();
    const someTopic = 'my topic';
    final someMessage = eg.streamMessage(
      stream: someChannel, topic: someTopic, sender: eg.otherUser);

    Future<void> prepare({
      ZulipStream? channel,
      String topic = someTopic,
      bool isChannelSubscribed = true,
      bool? isChannelMuted,
      UserTopicVisibilityPolicy? visibilityPolicy,
      UnreadMessagesSnapshot? unreadMsgs,
      int? zulipFeatureLevel,
    }) async {
      final effectiveChannel = channel ?? someChannel;
      assert(isChannelSubscribed || isChannelMuted == null);

      addTearDown(testBinding.reset);

      final account = eg.selfAccount.copyWith(zulipFeatureLevel: zulipFeatureLevel);
      await testBinding.globalStore.add(account, eg.initialSnapshot(
        realmUsers: [eg.selfUser, eg.otherUser],
        streams: [effectiveChannel],
        subscriptions: isChannelSubscribed
          ? [eg.subscription(effectiveChannel, isMuted: isChannelMuted ?? false)]
          : null,
        userTopics: visibilityPolicy != null
          ? [eg.userTopicItem(effectiveChannel, topic, visibilityPolicy)]
          : null,
        unreadMsgs: unreadMsgs,
        zulipFeatureLevel: zulipFeatureLevel));
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;
    }

    Future<void> showFromInbox(WidgetTester tester, {
      String topic = someTopic,
    }) async {
      final channelIdsWithUnreads = store.unreads.streams.keys;
      final hasTopicWithUnreads = channelIdsWithUnreads.any((streamId) =>
        store.unreads.countInTopicNarrow(streamId, TopicName(topic)) > 0);
      if (!hasTopicWithUnreads) {
        throw FlutterError.fromParts([
          ErrorSummary('showFromInbox called without an unread message'),
          ErrorHint(
            'Before calling showFromInbox, ensure that [Unreads] '
            'has an unread message in the relevant topic. ',
          ),
        ]);
      }

      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: const HomePage()));
      await tester.pump();
      check(find.byType(InboxPageBody)).findsOne();

      await tester.longPress(find.text(topic));
      // sheet appears onscreen; default duration of bottom-sheet enter animation
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> showFromAppBar(WidgetTester tester, {
      ZulipStream? channel,
      String topic = someTopic,
      List<StreamMessage>? messages,
    }) async {
      final effectiveChannel = channel ?? someChannel;
      final effectiveMessages = messages ?? [someMessage];
      assert(effectiveMessages.every((m) => m.topic.apiName == topic));

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: effectiveMessages).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: MessageListPage(
          initNarrow: eg.topicNarrow(effectiveChannel.streamId, topic))));
      // global store, per-account store, and message list get loaded
      await tester.pumpAndSettle();

      final topicRow = find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text(topic));
      await tester.longPress(topicRow);
      // sheet appears onscreen; default duration of bottom-sheet enter animation
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> showFromRecipientHeader(WidgetTester tester, {
      StreamMessage? message,
    }) async {
      final effectiveMessage = message ?? someMessage;

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [effectiveMessage]).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: const MessageListPage(initNarrow: CombinedFeedNarrow())));
      // global store, per-account store, and message list get loaded
      await tester.pumpAndSettle();

      await tester.longPress(find.descendant(
        of: find.byType(RecipientHeader),
        matching: find.text(effectiveMessage.topic.displayName)));
      // sheet appears onscreen; default duration of bottom-sheet enter animation
      await tester.pump(const Duration(milliseconds: 250));
    }

    final actionSheetFinder = find.byType(BottomSheet);
    Finder findButtonForLabel(String label) =>
      find.descendant(of: actionSheetFinder, matching: find.text(label));

    group('showTopicActionSheet', () {
      void checkButtons() {
        check(actionSheetFinder).findsOne();

        void checkButton(String label) {
          check(findButtonForLabel(label)).findsOne();
        }

        checkButton('Follow topic');
        checkButton('Mark as resolved');
      }

      testWidgets('show from inbox; message in Unreads but not in MessageStore', (tester) async {
        await prepare(unreadMsgs: eg.unreadMsgs(count: 1,
          channels: [eg.unreadChannelMsgs(
            streamId: someChannel.streamId,
            topic: someTopic,
            unreadMessageIds: [someMessage.id],
          )]));
        await showFromInbox(tester);
        check(store.unreads.isUnread(someMessage.id)).isNotNull().isTrue();
        check(store.messages).not((it) => it.containsKey(someMessage.id));
        checkButtons();
      });

      testWidgets('show from inbox; message in Unreads and in MessageStore', (tester) async {
        await prepare();
        await store.addMessage(someMessage);
        await showFromInbox(tester);
        check(store.unreads.isUnread(someMessage.id)).isNotNull().isTrue();
        check(store.messages)[someMessage.id].isNotNull();
        checkButtons();
      });

      testWidgets('show from app bar', (tester) async {
        await prepare();
        await showFromAppBar(tester);
        checkButtons();
      });

      testWidgets('show from app bar: resolve/unresolve not offered when msglist empty', (tester) async {
        await prepare();
        await showFromAppBar(tester, messages: []);
        check(findButtonForLabel('Mark as resolved')).findsNothing();
        check(findButtonForLabel('Mark as unresolved')).findsNothing();
      });

      testWidgets('show from recipient header', (tester) async {
        await prepare();
        await showFromRecipientHeader(tester);
        checkButtons();
      });
    });

    group('UserTopicUpdateButton', () {
      late String topic;

      final mute =     findButtonForLabel('Mute topic');
      final unmute =   findButtonForLabel('Unmute topic');
      final follow =   findButtonForLabel('Follow topic');
      final unfollow = findButtonForLabel('Unfollow topic');

      /// Prepare store and bring up a topic action sheet.
      ///
      /// If `isChannelMuted` is `null`, the user is not subscribed to the
      /// channel.
      Future<void> setupToTopicActionSheet(WidgetTester tester, {
        required bool? isChannelMuted,
        required UserTopicVisibilityPolicy visibilityPolicy,
        int? zulipFeatureLevel,
      }) async {
        addTearDown(testBinding.reset);

        topic = 'isChannelMuted: $isChannelMuted, policy: $visibilityPolicy';
        await prepare(
          channel: someChannel,
          topic: topic,
          isChannelSubscribed: isChannelMuted != null, // shorthand; see dartdoc
          isChannelMuted: isChannelMuted,
          visibilityPolicy: visibilityPolicy,
          zulipFeatureLevel: zulipFeatureLevel,
        );

        final message = eg.streamMessage(
          stream: someChannel, topic: topic, sender: eg.otherUser);
        await showFromAppBar(tester,
          channel: someChannel, topic: topic, messages: [message]);
      }

      void checkButtons(List<Finder> expectedButtonFinders) {
        check(actionSheetFinder).findsOne();

        for (final buttonFinder in expectedButtonFinders) {
          check(buttonFinder).findsOne();
        }
        check(find.bySubtype<UserTopicUpdateButton>())
          .findsExactly(expectedButtonFinders.length);
      }

      void checkUpdateUserTopicRequest(UserTopicVisibilityPolicy expectedPolicy) async {
        check(connection.lastRequest).isA<http.Request>()
          ..url.path.equals('/api/v1/user_topics')
          ..bodyFields.deepEquals({
            'stream_id': '${someChannel.streamId}',
            'topic': topic,
            'visibility_policy': jsonEncode(expectedPolicy),
          });
      }

      testWidgets('unmuteInMutedChannel', (tester) async {
        await setupToTopicActionSheet(tester,
          isChannelMuted: true,
          visibilityPolicy: UserTopicVisibilityPolicy.none);
        await tester.tap(unmute);
        await tester.pump();
        checkUpdateUserTopicRequest(UserTopicVisibilityPolicy.unmuted);
      });

      testWidgets('unmute', (tester) async {
        await setupToTopicActionSheet(tester,
          isChannelMuted: false,
          visibilityPolicy: UserTopicVisibilityPolicy.muted);
        await tester.tap(unmute);
        await tester.pump();
        checkUpdateUserTopicRequest(UserTopicVisibilityPolicy.none);
      });

      testWidgets('mute', (tester) async {
        await setupToTopicActionSheet(tester,
          isChannelMuted: false,
          visibilityPolicy: UserTopicVisibilityPolicy.none);
        await tester.tap(mute);
        await tester.pump();
        checkUpdateUserTopicRequest(UserTopicVisibilityPolicy.muted);
      });

      testWidgets('follow', (tester) async {
        await setupToTopicActionSheet(tester,
          isChannelMuted: false,
          visibilityPolicy: UserTopicVisibilityPolicy.none);
        await tester.tap(follow);
        await tester.pump();
        checkUpdateUserTopicRequest(UserTopicVisibilityPolicy.followed);
      });

      testWidgets('unfollow', (tester) async {
        await setupToTopicActionSheet(tester,
          isChannelMuted: false,
          visibilityPolicy: UserTopicVisibilityPolicy.followed);
        await tester.tap(unfollow);
        await tester.pump();
        checkUpdateUserTopicRequest(UserTopicVisibilityPolicy.none);
      });

      testWidgets('request fails with an error dialog', (tester) async {
        await setupToTopicActionSheet(tester,
          isChannelMuted: false,
          visibilityPolicy: UserTopicVisibilityPolicy.followed);

        connection.prepare(httpStatus: 400, json: {
          'result': 'error', 'code': 'BAD_REQUEST', 'msg': ''});
        await tester.tap(unfollow);
        await tester.pumpAndSettle();

        checkErrorDialog(tester, expectedTitle: 'Failed to unfollow topic');
      });

      group('check expected buttons', () {
        final testCases = [
          (false, UserTopicVisibilityPolicy.muted,    [unmute, follow]),
          (false, UserTopicVisibilityPolicy.none,     [mute, follow]),
          (false, UserTopicVisibilityPolicy.unmuted,  [mute, follow]),
          (false, UserTopicVisibilityPolicy.followed, [mute, unfollow]),

          (true,  UserTopicVisibilityPolicy.muted,    [unmute, follow]),
          (true,  UserTopicVisibilityPolicy.none,     [unmute, follow]),
          (true,  UserTopicVisibilityPolicy.unmuted,  [mute, follow]),
          (true,  UserTopicVisibilityPolicy.followed, [mute, unfollow]),

          (null,  UserTopicVisibilityPolicy.none,     <Finder>[]),
        ];

        for (final (isChannelMuted, visibilityPolicy, buttons) in testCases) {
          final description = 'isChannelMuted: ${isChannelMuted ?? "(not subscribed)"}, $visibilityPolicy';
          testWidgets(description, (tester) async {
            await setupToTopicActionSheet(tester,
              isChannelMuted: isChannelMuted,
              visibilityPolicy: visibilityPolicy);
            checkButtons(buttons);
          });
        }
      });

      group('legacy: follow is unsupported when FL < 219', () {
        final testCases = [
          (false, UserTopicVisibilityPolicy.muted,    [unmute]),
          (false, UserTopicVisibilityPolicy.none,     [mute]),
          (false, UserTopicVisibilityPolicy.unmuted,  [mute]),
          (false, UserTopicVisibilityPolicy.followed, [mute]),

          (true,  UserTopicVisibilityPolicy.muted,    [unmute]),
          (true,  UserTopicVisibilityPolicy.none,     [unmute]),
          (true,  UserTopicVisibilityPolicy.unmuted,  [mute]),
          (true,  UserTopicVisibilityPolicy.followed, [mute]),

          (null,  UserTopicVisibilityPolicy.none,     <Finder>[]),
        ];

        for (final (isChannelMuted, visibilityPolicy, buttons) in testCases) {
          final description = 'isChannelMuted: ${isChannelMuted ?? "(not subscribed)"}, $visibilityPolicy';
          testWidgets(description, (tester) async {
            await setupToTopicActionSheet(tester,
              isChannelMuted: isChannelMuted,
              visibilityPolicy: visibilityPolicy,
              zulipFeatureLevel: 218);
            checkButtons(buttons);
          });
        }
      });

      group('legacy: unmute is unsupported when FL < 170', () {
        final testCases = [
          (false, UserTopicVisibilityPolicy.muted,    [unmute]),
          (false, UserTopicVisibilityPolicy.none,     [mute]),
          (false, UserTopicVisibilityPolicy.unmuted,  [mute]),
          (false, UserTopicVisibilityPolicy.followed, [mute]),

          (true,  UserTopicVisibilityPolicy.muted,    <Finder>[]),
          (true,  UserTopicVisibilityPolicy.none,     <Finder>[]),
          (true,  UserTopicVisibilityPolicy.unmuted,  <Finder>[]),
          (true,  UserTopicVisibilityPolicy.followed, <Finder>[]),

          (null,  UserTopicVisibilityPolicy.none,     <Finder>[]),
        ];

        for (final (isChannelMuted, visibilityPolicy, buttons) in testCases) {
          final description = 'isChannelMuted: ${isChannelMuted ?? "(not subscribed)"}, $visibilityPolicy';
          testWidgets(description, (tester) async {
            await setupToTopicActionSheet(tester,
              isChannelMuted: isChannelMuted,
              visibilityPolicy: visibilityPolicy,
              zulipFeatureLevel: 169);
            checkButtons(buttons);
          });
        }
      });
    });

    group('ResolveUnresolveButton', () {
      void checkRequest(int messageId, String topic) {
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('PATCH')
          ..url.path.equals('/api/v1/messages/$messageId')
          ..bodyFields.deepEquals({
            'topic': topic,
            'propagate_mode': 'change_all',
            'send_notification_to_old_thread': 'false',
            'send_notification_to_new_thread': 'true',
          });
      }

      testWidgets('resolve: happy path from inbox; message in Unreads but not MessageStore', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: 'zulip');
        await prepare(
          topic: 'zulip',
          unreadMsgs: eg.unreadMsgs(count: 1,
            channels: [eg.unreadChannelMsgs(
              streamId: someChannel.streamId,
              topic: 'zulip',
              unreadMessageIds: [message.id],
            )]));
        await showFromInbox(tester, topic: 'zulip');
        check(store.messages).not((it) => it.containsKey(message.id));
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(findButtonForLabel('Mark as resolved'));
        await tester.pumpAndSettle();

        checkNoErrorDialog(tester);
        checkRequest(message.id, '✔ zulip');
      });

      testWidgets('resolve: happy path from inbox; message in Unreads and MessageStore', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: 'zulip');
        await prepare(topic: 'zulip');
        await store.addMessage(message);
        await showFromInbox(tester, topic: 'zulip');
        check(store.unreads.isUnread(message.id)).isNotNull().isTrue();
        check(store.messages)[message.id].isNotNull();
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(findButtonForLabel('Mark as resolved'));
        await tester.pumpAndSettle();

        checkNoErrorDialog(tester);
        checkRequest(message.id, '✔ zulip');
      });

      testWidgets('unresolve: happy path', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: '✔ zulip');
        await prepare(topic: '✔ zulip');
        await showFromAppBar(tester, topic: '✔ zulip', messages: [message]);
        connection.takeRequests();
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(findButtonForLabel('Mark as unresolved'));
        await tester.pumpAndSettle();

        checkNoErrorDialog(tester);
        checkRequest(message.id, 'zulip');
      });

      testWidgets('unresolve: weird prefix', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: '✔ ✔ zulip');
        await prepare(topic: '✔ ✔ zulip');
        await showFromAppBar(tester, topic: '✔ ✔ zulip', messages: [message]);
        connection.takeRequests();
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(findButtonForLabel('Mark as unresolved'));
        await tester.pumpAndSettle();

        checkNoErrorDialog(tester);
        checkRequest(message.id, 'zulip');
      });

      testWidgets('resolve: request fails', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: 'zulip');
        await prepare(topic: 'zulip');
        await showFromRecipientHeader(tester, message: message);
        connection.takeRequests();
        connection.prepare(exception: http.ClientException('Oops'));
        await tester.tap(findButtonForLabel('Mark as resolved'));
        await tester.pumpAndSettle();
        checkRequest(message.id, '✔ zulip');

        checkErrorDialog(tester,
          expectedTitle: 'Failed to mark topic as resolved');
      });

      testWidgets('unresolve: request fails', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: '✔ zulip');
        await prepare(topic: '✔ zulip');
        await showFromRecipientHeader(tester, message: message);
        connection.takeRequests();
        connection.prepare(exception: http.ClientException('Oops'));
        await tester.tap(findButtonForLabel('Mark as unresolved'));
        await tester.pumpAndSettle();
        checkRequest(message.id, 'zulip');

        checkErrorDialog(tester,
          expectedTitle: 'Failed to mark topic as unresolved');
      });
    });
  });

  group('message action sheet', () {
    group('ReactionButtons', () {
      final popularCandidates = EmojiStore.popularEmojiCandidates;

      for (final emoji in popularCandidates) {
        final emojiDisplay = emoji.emojiDisplay as UnicodeEmojiDisplay;

        Future<void> tapButton(WidgetTester tester) async {
          await tester.tap(find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(emojiDisplay.emojiUnicode)));
        }

        testWidgets('${emoji.emojiName} adding success', (tester) async {
          final message = eg.streamMessage();
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          connection.prepare(json: {});
          await tapButton(tester);
          await tester.pump(Duration.zero);

          check(connection.lastRequest).isA<http.Request>()
            ..method.equals('POST')
            ..url.path.equals('/api/v1/messages/${message.id}/reactions')
            ..bodyFields.deepEquals({
                'reaction_type': 'unicode_emoji',
                'emoji_code': emoji.emojiCode,
                'emoji_name': emoji.emojiName,
              });
        });

        testWidgets('${emoji.emojiName} removing success', (tester) async {
          final message = eg.streamMessage(
            reactions: [Reaction(
              emojiName: emoji.emojiName,
              emojiCode: emoji.emojiCode,
              reactionType: ReactionType.unicodeEmoji,
              userId: eg.selfAccount.userId)]
          );
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          connection.prepare(json: {});
          await tapButton(tester);
          await tester.pump(Duration.zero);

          check(connection.lastRequest).isA<http.Request>()
            ..method.equals('DELETE')
            ..url.path.equals('/api/v1/messages/${message.id}/reactions')
            ..bodyFields.deepEquals({
                'reaction_type': 'unicode_emoji',
                'emoji_code': emoji.emojiCode,
                'emoji_name': emoji.emojiName,
              });
        });

        testWidgets('${emoji.emojiName} request has an error', (tester) async {
          final message = eg.streamMessage();
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          connection.prepare(httpStatus: 400, json: {
            'code': 'BAD_REQUEST',
            'msg': 'Invalid message(s)',
            'result': 'error',
          });
          await tapButton(tester);
          await tester.pump(Duration.zero); // error arrives; error dialog shows

          await tester.tap(find.byWidget(checkErrorDialog(tester,
            expectedTitle: 'Adding reaction failed',
            expectedMessage: 'Invalid message(s)')));
        });
      }
    });

    group('StarButton', () {
      Future<void> tapButton(WidgetTester tester, {bool starred = false}) async {
        // Starred messages include the same icon so we need to
        // match only by descendants of [BottomSheet].
        await tester.ensureVisible(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(starred ? ZulipIcons.star_filled : ZulipIcons.star, skipOffstage: false)));
        await tester.tap(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(starred ? ZulipIcons.star_filled : ZulipIcons.star)));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('star success', (tester) async {
        final message = eg.streamMessage(flags: []);
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        connection.prepare(json: {});
        await tapButton(tester);
        await tester.pump(Duration.zero);

        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags')
          ..bodyFields.deepEquals({
            'messages': jsonEncode([message.id]),
            'op': 'add',
            'flag': 'starred',
          });
      });

      testWidgets('unstar success', (tester) async {
        final message = eg.streamMessage(flags: [MessageFlag.starred]);
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        connection.prepare(json: {});
        await tapButton(tester, starred: true);
        await tester.pump(Duration.zero);

        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags')
          ..bodyFields.deepEquals({
            'messages': jsonEncode([message.id]),
            'op': 'remove',
            'flag': 'starred',
          });
      });

      testWidgets('star request has an error', (tester) async {
        final message = eg.streamMessage(flags: []);
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

        connection.prepare(httpStatus: 400, json: {
          'code': 'BAD_REQUEST',
          'msg': 'Invalid message(s)',
          'result': 'error',
        });
        await tapButton(tester);
        await tester.pump(Duration.zero); // error arrives; error dialog shows

        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: zulipLocalizations.errorStarMessageFailedTitle,
          expectedMessage: 'Invalid message(s)')));
      });

      testWidgets('unstar request has an error', (tester) async {
        final message = eg.streamMessage(flags: [MessageFlag.starred]);
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

        connection.prepare(httpStatus: 400, json: {
          'code': 'BAD_REQUEST',
          'msg': 'Invalid message(s)',
          'result': 'error',
        });
        await tapButton(tester, starred: true);
        await tester.pump(Duration.zero); // error arrives; error dialog shows

        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: zulipLocalizations.errorUnstarMessageFailedTitle,
          expectedMessage: 'Invalid message(s)')));
      });
    });

    group('QuoteAndReplyButton', () {
      ComposeBoxController? findComposeBoxController(WidgetTester tester) {
        return tester.stateList<ComposeBoxState>(find.byType(ComposeBox))
          .singleOrNull?.controller;
      }

      Widget? findQuoteAndReplyButton(WidgetTester tester) {
        return tester.widgetList(find.byIcon(ZulipIcons.format_quote)).singleOrNull;
      }

      /// Simulates tapping the quote-and-reply button in the message action sheet.
      ///
      /// Checks that there is a quote-and-reply button.
      Future<void> tapQuoteAndReplyButton(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(ZulipIcons.format_quote, skipOffstage: false));
        final quoteAndReplyButton = findQuoteAndReplyButton(tester);
        check(quoteAndReplyButton).isNotNull();
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);
        await tester.tap(find.byWidget(quoteAndReplyButton!));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      void checkLoadingState(PerAccountStore store, ComposeContentController contentController, {
        required TextEditingValue valueBefore,
        required Message message,
      }) {
        check(contentController).value.equals((ComposeContentController()
          ..value = valueBefore
          ..insertPadded(quoteAndReplyPlaceholder(
              GlobalLocalizations.zulipLocalizations, store, message: message))
        ).value);
        check(contentController).validationErrors.contains(ContentValidationError.quoteAndReplyInProgress);
      }

      void checkSuccessState(PerAccountStore store, ComposeContentController contentController, {
        required TextEditingValue valueBefore,
        required Message message,
        required String rawContent,
      }) {
        final builder = ComposeContentController()
          ..value = valueBefore
          ..insertPadded(quoteAndReply(store, message: message, rawContent: rawContent));
        if (!valueBefore.selection.isValid) {
          // (At the end of the process, we focus the input, which puts a cursor
          // at text's end, if there was no cursor at the time.)
          builder.selection = TextSelection.collapsed(offset: builder.text.length);
        }
        check(contentController).value.equals(builder.value);
        check(contentController).not((it) => it.validationErrors.contains(ContentValidationError.quoteAndReplyInProgress));
      }

      testWidgets('in channel narrow', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: ChannelNarrow(message.streamId));

        final composeBoxController = findComposeBoxController(tester) as StreamComposeBoxController;
        final contentController = composeBoxController.content;

        // Ensure channel-topics are loaded before testing quote & reply behavior
        connection.prepare(body:
          jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
        final topicController = composeBoxController.topic;
        topicController.value = const TextEditingValue(text: kNoTopicTopic);

        final valueBefore = contentController.value;
        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        await tapQuoteAndReplyButton(tester);
        checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
        await tester.pump(Duration.zero); // message is fetched; compose box updates
        check(composeBoxController.contentFocusNode.hasFocus).isTrue();
        checkSuccessState(store, contentController,
          valueBefore: valueBefore, message: message, rawContent: 'Hello world');
      });

      group('in topic narrow', () {
        testWidgets('smoke', (tester) async {
          final message = eg.streamMessage();
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          final composeBoxController = findComposeBoxController(tester)!;
          final contentController = composeBoxController.content;

          final valueBefore = contentController.value;
          prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
          await tapQuoteAndReplyButton(tester);
          checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
          await tester.pump(Duration.zero); // message is fetched; compose box updates
          check(composeBoxController.contentFocusNode.hasFocus).isTrue();
          checkSuccessState(store, contentController,
            valueBefore: valueBefore, message: message, rawContent: 'Hello world');
        });

        testWidgets('no error if user lost posting permission after action sheet opened', (tester) async {
          final stream = eg.stream();
          final message = eg.streamMessage(stream: stream);
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: eg.selfUser.userId,
            role: UserRole.guest));
          await store.handleEvent(eg.channelUpdateEvent(stream,
            property: ChannelPropertyName.channelPostPolicy,
            value: ChannelPostPolicy.administrators));
          await tester.pump();

          await tapQuoteAndReplyButton(tester);
          // no error
        });
      });

      group('in DM narrow', () {
        testWidgets('smoke', (tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
          await setupToMessageActionSheet(tester,
            message: message, narrow: DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));

          final composeBoxController = findComposeBoxController(tester)!;
          final contentController = composeBoxController.content;

          final valueBefore = contentController.value;
          prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
          await tapQuoteAndReplyButton(tester);
          checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
          await tester.pump(Duration.zero); // message is fetched; compose box updates
          check(composeBoxController.contentFocusNode.hasFocus).isTrue();
          checkSuccessState(store, contentController,
            valueBefore: valueBefore, message: message, rawContent: 'Hello world');
        });

        testWidgets('no error if recipient was deactivated while raw-content request in progress', (tester) async {
          final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
          await setupToMessageActionSheet(tester,
            message: message,
            narrow: DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));

          prepareRawContentResponseSuccess(
            message: message,
            rawContent: 'Hello world',
            delay: const Duration(seconds: 5),
          );
          await tapQuoteAndReplyButton(tester);
          await tester.pump(const Duration(seconds: 1)); // message not yet fetched

          await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: eg.otherUser.userId,
            isActive: false));
          await tester.pump();
          // no error
          await tester.pump(const Duration(seconds: 4));
        });
      });

      testWidgets('request has an error', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        final composeBoxController = findComposeBoxController(tester)!;
        final contentController = composeBoxController.content;

        final valueBefore = contentController.value = TextEditingValue.empty;
        prepareRawContentResponseError();
        await tapQuoteAndReplyButton(tester);
        checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
        await tester.pump(Duration.zero); // error arrives; error dialog shows

        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Quotation failed',
          expectedMessage: 'That message does not seem to exist.',
        )));

        check(contentController.value).equals(const TextEditingValue(
          // The placeholder was removed. (A newline from the placeholder's
          // insertPadded remains; I guess ideally we'd try to prevent that.)
          text: '\n',

          // (At the end of the process, we focus the input.)
          selection: TextSelection.collapsed(offset: 1), //
        ));
      });

      testWidgets('not offered in CombinedFeedNarrow (composing to reply is not yet supported)', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: const CombinedFeedNarrow());
        check(findQuoteAndReplyButton(tester)).isNull();
      });

      testWidgets('not offered in MentionsNarrow (composing to reply is not yet supported)', (tester) async {
        final message = eg.streamMessage(flags: [MessageFlag.mentioned]);
        await setupToMessageActionSheet(tester, message: message, narrow: const MentionsNarrow());
        check(findQuoteAndReplyButton(tester)).isNull();
      });

      testWidgets('not offered in StarredMessagesNarrow (composing to reply is not yet supported)', (tester) async {
        final message = eg.streamMessage(flags: [MessageFlag.starred]);
        await setupToMessageActionSheet(tester, message: message, narrow: const StarredMessagesNarrow());
        check(findQuoteAndReplyButton(tester)).isNull();
      });
    });

    group('MarkAsUnread', () {
      testWidgets('not visible if message is not read', (tester) async {
        final unreadMessage = eg.streamMessage(flags: []);
        await setupToMessageActionSheet(tester, message: unreadMessage, narrow: TopicNarrow.ofMessage(unreadMessage));

        check(find.byIcon(Icons.mark_chat_unread_outlined).evaluate()).isEmpty();
      });

      testWidgets('visible if message is read', (tester) async {
        final readMessage = eg.streamMessage(flags: [MessageFlag.read]);
        await setupToMessageActionSheet(tester, message: readMessage, narrow: TopicNarrow.ofMessage(readMessage));

        check(find.byIcon(Icons.mark_chat_unread_outlined).evaluate()).single;
      });

      group('onPressed', () {
        testWidgets('smoke test', (tester) async {
          final message = eg.streamMessage(flags: [MessageFlag.read]);
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          connection.prepare(json: UpdateMessageFlagsForNarrowResult(
            processedCount: 11, updatedCount: 3,
            firstProcessedId: 1, lastProcessedId: 1980,
            foundOldest: true, foundNewest: true).toJson());

          await tester.ensureVisible(find.byIcon(Icons.mark_chat_unread_outlined, skipOffstage: false));
          await tester.tap(find.byIcon(Icons.mark_chat_unread_outlined, skipOffstage: false));
          await tester.pumpAndSettle();
          check(connection.lastRequest).isA<http.Request>()
            ..method.equals('POST')
            ..url.path.equals('/api/v1/messages/flags/narrow')
            ..bodyFields.deepEquals({
                'anchor': '${message.id}',
                'include_anchor': 'true',
                'num_before': '0',
                'num_after': '1000',
                'narrow': jsonEncode(TopicNarrow.ofMessage(message).apiEncode()),
                'op': 'remove',
                'flag': 'read',
              });
        });

        testWidgets('on topic move, acts on new topic', (tester) async {
          final stream = eg.stream();
          const topic = 'old topic';
          final message = eg.streamMessage(flags: [MessageFlag.read],
            stream: stream, topic: topic);
          await setupToMessageActionSheet(tester, message: message,
            narrow: TopicNarrow.ofMessage(message));

          // Get the action sheet fully deployed while the old narrow applies.
          // (This way we maximize the range of potential bugs this test can catch,
          // by giving the code maximum opportunity to latch onto the old topic.)
          await tester.pumpAndSettle();

          final newStream = eg.stream();
          const newTopic = 'other topic';
          // This result isn't quite realistic for this request: it should get
          // the updated channel/stream ID and topic, because we don't even
          // start the request until after we get the move event.
          // But constructing the right result is annoying at the moment, and
          // it doesn't matter anyway: [MessageStoreImpl.reconcileMessages] will
          // keep the version updated by the event.  If that somehow changes in
          // some future refactor, it'll cause this test to fail.
          connection.prepare(json: eg.newestGetMessagesResult(
            foundOldest: true, messages: [message]).toJson());
          await store.handleEvent(eg.updateMessageEventMoveFrom(
            newStreamId: newStream.streamId, newTopicStr: newTopic,
            propagateMode: PropagateMode.changeAll,
            origMessages: [message]));

          connection.prepare(json: UpdateMessageFlagsForNarrowResult(
            processedCount: 11, updatedCount: 3,
            firstProcessedId: 1, lastProcessedId: 1980,
            foundOldest: true, foundNewest: true).toJson());
          await tester.tap(find.byIcon(Icons.mark_chat_unread_outlined, skipOffstage: false));
          await tester.pumpAndSettle();
          check(connection.lastRequest).isA<http.Request>()
            ..method.equals('POST')
            ..url.path.equals('/api/v1/messages/flags/narrow')
            ..bodyFields['narrow'].equals(
                jsonEncode(eg.topicNarrow(newStream.streamId, newTopic).apiEncode()));
        });

        testWidgets('shows error when fails', (tester) async {
          final message = eg.streamMessage(flags: [MessageFlag.read]);
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          connection.prepare(exception: http.ClientException('Oops'));
          final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

          await tester.ensureVisible(find.byIcon(Icons.mark_chat_unread_outlined, skipOffstage: false));
          await tester.tap(find.byIcon(Icons.mark_chat_unread_outlined, skipOffstage: false));
          await tester.pumpAndSettle();
          checkErrorDialog(tester,
            expectedTitle: zulipLocalizations.errorMarkAsUnreadFailedTitle,
            expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
        });
      });
    });

    group('CopyMessageTextButton', () {
      setUp(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          MockClipboard().handleMethodCall,
        );
      });

      Future<void> tapCopyMessageTextButton(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(ZulipIcons.copy, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.copy));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('success', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        await tapCopyMessageTextButton(tester);
        await tester.pump(Duration.zero);
        check(await Clipboard.getData('text/plain')).isNotNull().text.equals('Hello world');
      });

      testWidgets('can show snackbar on success', (tester) async {
        // Regression test for: https://github.com/zulip/zulip-flutter/issues/732
        testBinding.deviceInfoResult = const IosDeviceInfo(systemVersion: '16.0');

        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        // Make the request take a bit of time to complete…
        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world',
          delay: const Duration(milliseconds: 500));
        await tapCopyMessageTextButton(tester);
        // … and pump a frame to finish the NavigationState.pop animation…
        await tester.pump(const Duration(milliseconds: 250));
        // … before the request finishes.  This is the repro condition for #732.
        await tester.pump(const Duration(milliseconds: 250));

        final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
        check(snackbar.behavior).equals(SnackBarBehavior.floating);
        final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
        tester.widget(find.descendant(matchRoot: true,
          of: find.byWidget(snackbar.content),
          matching: find.text(zulipLocalizations.successMessageTextCopied)));
      });

      testWidgets('request has an error', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        prepareRawContentResponseError();
        await tapCopyMessageTextButton(tester);
        await tester.pump(Duration.zero); // error arrives; error dialog shows

        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Copying failed',
          expectedMessage: 'That message does not seem to exist.',
        )));
        check(await Clipboard.getData('text/plain')).isNull();
      });
    });

    group('CopyMessageLinkButton', () {
      setUp(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          MockClipboard().handleMethodCall,
        );
      });

      Future<void> tapCopyMessageLinkButton(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(Icons.link, skipOffstage: false));
        await tester.tap(find.byIcon(Icons.link));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('copies message link to clipboard', (tester) async {
        final message = eg.streamMessage();
        final narrow = TopicNarrow.ofMessage(message);
        await setupToMessageActionSheet(tester, message: message, narrow: narrow);

        await tapCopyMessageLinkButton(tester);
        await tester.pump(Duration.zero);
        final expectedLink = narrowLink(store, narrow, nearMessageId: message.id).toString();
        check(await Clipboard.getData('text/plain')).isNotNull().text.equals(expectedLink);
      });
    });

    group('ShareButton', () {
      // Tests should call this.
      MockSharePlus setupMockSharePlus() {
        final mock = MockSharePlus();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannelShare.channel,
          mock.handleMethodCall,
        );
        return mock;
      }

      Future<void> tapShareButton(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(ZulipIcons.share, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.share));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('request succeeds; sharing succeeds', (tester) async {
        final mockSharePlus = setupMockSharePlus();
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        await tapShareButton(tester);
        await tester.pump(Duration.zero);
        check(mockSharePlus.sharedString).equals('Hello world');
      });

      testWidgets('request succeeds; sharing fails', (tester) async {
        final mockSharePlus = setupMockSharePlus();
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        mockSharePlus.resultString = 'dev.fluttercommunity.plus/share/unavailable';
        await tapShareButton(tester);
        await tester.pump(Duration.zero);
        check(mockSharePlus.sharedString).equals('Hello world');
        await tester.pump();
        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Sharing failed')));
      });

      testWidgets('request has an error', (tester) async {
        final mockSharePlus = setupMockSharePlus();
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        prepareRawContentResponseError();
        await tapShareButton(tester);
        await tester.pump(Duration.zero); // error arrives; error dialog shows

        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Sharing failed',
          expectedMessage: 'That message does not seem to exist.',
        )));

        check(mockSharePlus.sharedString).isNull();
      });
    });

    group('MessageActionSheetCancelButton', () {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

      void checkActionSheet(WidgetTester tester, {required bool isShown}) {
        check(find.text(zulipLocalizations.actionSheetOptionStarMessage)
          .evaluate().length).equals(isShown ? 1 : 0);

        final findCancelButton = find.text(zulipLocalizations.dialogCancel);
        check(findCancelButton.evaluate().length).equals(isShown ? 1 : 0);
      }

      testWidgets('pressing the button dismisses the action sheet', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
        checkActionSheet(tester, isShown: true);

        final findCancelButton = find.text(zulipLocalizations.dialogCancel);
        await tester.tap(findCancelButton);
        await tester.pumpAndSettle();
        checkActionSheet(tester, isShown: false);
      });
    });
  });
}

extension UnicodeEmojiWidgetChecks on Subject<UnicodeEmojiWidget> {
  Subject<UnicodeEmojiDisplay> get emojiDisplay => has((x) => x.emojiDisplay, 'emojiDisplay');
}
