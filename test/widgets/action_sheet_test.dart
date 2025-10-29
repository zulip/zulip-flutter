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
import 'package:zulip/api/model/narrow.dart';
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
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/emoji_reaction.dart';
import 'package:zulip/widgets/home.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/inbox.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import 'package:zulip/widgets/read_receipts.dart';
import 'package:zulip/widgets/subscription_list.dart';
import 'package:zulip/widgets/topic_list.dart';
import 'package:zulip/widgets/user.dart';
import '../api/fake_api.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/autocomplete_checks.dart';
import '../model/binding.dart';
import '../model/content_test.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_clipboard.dart';
import '../test_images.dart';
import '../test_share_plus.dart';
import 'checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

late PerAccountStore store;
late FakeApiConnection connection;
late TransitionDurationObserver transitionDurationObserver;

/// Simulates loading a [MessageListPage] and long-pressing on [message].
Future<void> setupToMessageActionSheet(WidgetTester tester, {
  required Message message,
  required Narrow narrow,
  User? selfUser,
  User? sender,
  List<int>? mutedUserIds,
  bool? realmAllowMessageEditing,
  int? realmMessageContentEditLimitSeconds,
  bool hasDeletePermission = true,
  bool? realmEnableReadReceipts,
  bool shouldSetServerEmojiData = true,
  bool useLegacyServerEmojiData = false,
  Future<void> Function()? beforeLongPress,
}) async {
  addTearDown(testBinding.reset);
  // TODO(#1667) will be null in a search narrow; remove `!`.
  assert(narrow.containsMessage(message)!);

  selfUser ??= eg.selfUser;
  assert(!(hasDeletePermission && selfUser.role == UserRole.guest));
  final selfAccount = eg.account(user: selfUser);
  await testBinding.globalStore.add(
    selfAccount,
    eg.initialSnapshot(
      realmUsers: [selfUser],
      realmAllowMessageEditing: realmAllowMessageEditing,
      realmMessageContentEditLimitSeconds: realmMessageContentEditLimitSeconds,
      realmEnableReadReceipts: realmEnableReadReceipts,
      realmCanDeleteAnyMessageGroup: hasDeletePermission
        ? eg.groupSetting(members: [selfUser.userId])
        : eg.groupSetting(members: []),
      realmCanDeleteOwnMessageGroup: eg.groupSetting(members: []),
    ));
  store = await testBinding.globalStore.perAccount(selfAccount.id);
  await store.addUsers([
    selfUser,
    sender ?? eg.user(userId: message.senderId),
    if (narrow is DmNarrow)
      ...narrow.otherRecipientIds.map((id) => eg.user(userId: id)),
  ]);
  if (mutedUserIds != null) {
    await store.setMutedUsers(mutedUserIds);
  }
  if (message is StreamMessage) {
    final stream = eg.stream(streamId: message.streamId);
    await store.addStream(stream);
    await store.addSubscription(eg.subscription(stream));
  }
  connection = store.connection as FakeApiConnection;
  if (shouldSetServerEmojiData) {
    store.setServerEmojiData(useLegacyServerEmojiData
      ? eg.serverEmojiDataPopularLegacy
      : eg.serverEmojiDataPopular);
  }

  transitionDurationObserver = TransitionDurationObserver();

  connection.prepare(json: eg.newestGetMessagesResult(
    foundOldest: true, messages: [message]).toJson());
  await tester.pumpWidget(TestZulipApp(
    accountId: selfAccount.id,
    navigatorObservers: [transitionDurationObserver],
    child: MessageListPage(initNarrow: narrow)));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();

  check(store.selfCanDeleteMessage(message.id, atDate: testBinding.utcNow()))
    .equals(hasDeletePermission);

  await beforeLongPress?.call();

  // Request the message action sheet.
  //
  // We use `warnIfMissed: false` to suppress warnings in cases where
  // MessageContent itself didn't hit-test as true but the action sheet still
  // opened. The action sheet still opens because the gesture handler is an
  // ancestor of MessageContent, but MessageContent might not hit-test as true
  // because its render box effectively has HitTestBehavior.deferToChild, and
  // the long-press might land where no child hit-tests as true,
  // like if it's in padding around a Paragraph.
  await tester.longPress(find.byType(MessageContent), warnIfMissed: false);
  // sheet appears onscreen; default duration of bottom-sheet enter animation
  await tester.pump(const Duration(milliseconds: 250));
  // Check the action sheet did in fact open, so we don't defeat any tests that
  // use simple `find.byIcon`-style checks to test presence/absence of a button.
  check(find.byType(BottomSheet)).findsOne();
}

void main() {
  TestZulipBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();
  MessageListPage.debugEnableMarkReadOnScroll = false;

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
    connection.prepare(apiException: eg.apiBadRequest(message: 'Invalid message(s)'));
  }

  group('channel action sheet', () {
    late ZulipStream someChannel;
    const someTopic = 'my topic';
    late StreamMessage someMessage;

    Future<void> prepare({bool hasUnreadMessages = true}) async {
      someChannel = eg.stream();
      someMessage = eg.streamMessage(
        stream: someChannel, topic: someTopic, sender: eg.otherUser,
        flags: hasUnreadMessages ? [] : [MessageFlag.read]);
      addTearDown(testBinding.reset);

      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;

      await store.addUser(eg.selfUser);
      await store.addUser(eg.otherUser);
      await store.addStream(someChannel);
      await store.addSubscription(eg.subscription(someChannel));
      await store.addMessage(someMessage);
    }

    Future<void> showFromInbox(WidgetTester tester) async {
      transitionDurationObserver = TransitionDurationObserver();
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        navigatorObservers: [transitionDurationObserver],
        child: const HomePage()));
      await tester.pump();
      check(find.byType(InboxPageBody)).findsOne();

      await tester.longPress(find.text(someChannel.name).hitTestable());
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> showFromSubscriptionList(WidgetTester tester) async {
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: const HomePage()));
      await tester.pump();
      await tester.tap(find.byIcon(ZulipIcons.hash_italic));
      await tester.pump();
      check(find.byType(SubscriptionListPageBody)).findsOne();

      await tester.longPress(find.text(someChannel.name).hitTestable());
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> showFromMsglistAppBar(WidgetTester tester, {
      ZulipStream? channel,
      required Narrow narrow,
    }) async {
      channel ??= someChannel;

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: []).toJson());
      if (narrow case ChannelNarrow()) {
        // We auto-focus the topic input when there are no messages;
        // this is for topic autocomplete.
        connection.prepare(json: GetStreamTopicsResult(topics: []).toJson());
      }
      await tester.pumpWidget(TestZulipApp(
        accountId: eg.selfAccount.id,
        child: MessageListPage(
          initNarrow: narrow)));
      await tester.pumpAndSettle();

      await tester.longPress(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text(channel.name)));
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> showFromRecipientHeader(WidgetTester tester, {
      StreamMessage? message,
    }) async {
      message ??= someMessage;

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [message]).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: const MessageListPage(initNarrow: CombinedFeedNarrow())));
      await tester.pumpAndSettle();

      await tester.longPress(find.descendant(
        of: find.byType(RecipientHeader),
        matching: find.text(message.displayRecipient ?? '')));
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> showFromTopicListAppBar(WidgetTester tester, {int? streamId}) async {
      streamId ??= someChannel.streamId;
      final transitionDurationObserver = TransitionDurationObserver();

      connection.prepare(json: GetStreamTopicsResult(topics: []).toJson());
      await tester.pumpWidget(TestZulipApp(
        navigatorObservers: [transitionDurationObserver],
        accountId: eg.selfAccount.id,
        child: TopicListPage(streamId: streamId)));
      await tester.pump();

      final titleText = store.streams[streamId]?.name ?? '(unknown channel)';
      await tester.longPress(find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text(titleText)));
      await transitionDurationObserver.pumpPastTransition(tester);
    }

    final actionSheetFinder = find.byType(BottomSheet);
    Finder findButtonForLabel(String label) =>
      find.descendant(of: actionSheetFinder, matching: find.text(label));

    void checkButton(String label) {
      check(findButtonForLabel(label)).findsOne();
    }

    void checkNoButton(String label) {
      check(findButtonForLabel(label)).findsNothing();
    }

    group('showChannelActionSheet', () {
      void checkButtons() {
        check(actionSheetFinder).findsOne();
        checkButton('Mark channel as read');
        checkButton('Copy link to channel');
      }

      group('header', () {
        final findHeader = find.descendant(
          of: actionSheetFinder,
          matching: find.byType(BottomSheetHeader));

        Finder findInHeader(Finder finder) =>
          find.descendant(of: findHeader, matching: finder);

        testWidgets('public channel', (tester) async {
          await prepare();
          check(store.streams[someChannel.streamId]).isNotNull()
            ..inviteOnly.isFalse()..isWebPublic.isFalse();
          await showFromInbox(tester);
          check(findInHeader(find.byIcon(ZulipIcons.hash_sign))).findsOne();
          check(findInHeader(find.textContaining(someChannel.name))).findsOne();
        });

        testWidgets('web-public channel', (tester) async {
          await prepare();
          await store.handleEvent(ChannelUpdateEvent(id: 1,
            streamId: someChannel.streamId,
            name: someChannel.name,
            property: null, value: null,
            // (Ideally we'd use `property` and `value` but I'm not sure if
            // modern servers actually do that or if they still use this
            // separate field.)
            isWebPublic: true));
          check(store.streams[someChannel.streamId]).isNotNull()
            ..inviteOnly.isFalse()..isWebPublic.isTrue();
          await showFromInbox(tester);
          check(findInHeader(find.byIcon(ZulipIcons.globe))).findsOne();
          check(findInHeader(find.textContaining(someChannel.name))).findsOne();
        });

        testWidgets('private channel', (tester) async {
          await prepare();
          await store.handleEvent(eg.channelUpdateEvent(someChannel,
            property: ChannelPropertyName.inviteOnly, value: true));
          check(store.streams[someChannel.streamId]).isNotNull()
            ..inviteOnly.isTrue()..isWebPublic.isFalse();
          await showFromInbox(tester);
          check(findInHeader(find.byIcon(ZulipIcons.lock))).findsOne();
          check(findInHeader(find.textContaining(someChannel.name))).findsOne();
        });

        testWidgets('unknown channel', (tester) async {
          await prepare();
          await store.handleEvent(ChannelDeleteEvent(id: 1,
            channelIds: [someChannel.streamId]));
          check(store.streams[someChannel.streamId]).isNull();
          await showFromTopicListAppBar(tester);
          check(findInHeader(find.byType(Icon))).findsNothing();
          check(findInHeader(find.textContaining('(unknown channel)'))).findsOne();
        });
      });

      testWidgets('show from inbox', (tester) async {
        await prepare();
        await showFromInbox(tester);
        checkButtons();
      });

      testWidgets('show from subscription list', (tester) async {
        await prepare();
        await showFromSubscriptionList(tester);
        checkButtons();
      });

      testWidgets('show with no unread messages', (tester) async {
        await prepare(hasUnreadMessages: false);
        await showFromSubscriptionList(tester);
        check(findButtonForLabel('Mark channel as read')).findsNothing();
      });

      testWidgets('show from message-list app bar in channel narrow', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        await showFromMsglistAppBar(tester, narrow: narrow);
        checkButtons();
      });

      testWidgets('show from message-list app bar in topic narrow', (tester) async {
        await prepare();
        final narrow = eg.topicNarrow(someChannel.streamId, someTopic);
        await showFromMsglistAppBar(tester, narrow: narrow);
        checkButtons();
      });

      testWidgets('show from recipient header', (tester) async {
        await prepare();
        await showFromRecipientHeader(tester, message: someMessage);
        checkButtons();
      });

      testWidgets('show from topic-list app bar', (tester) async {
        await prepare();
        await showFromTopicListAppBar(tester);
        checkButtons();
      });
    });

    group('SubscribeButton', () {
      Future<void> tapButton(WidgetTester tester) async {
        await tester.tap(findButtonForLabel('Subscribe'));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('channel not subscribed, with content access', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        await store.removeSubscription(narrow.streamId);
        check(store.selfHasContentAccess(someChannel)).isTrue();
        await showFromMsglistAppBar(tester, narrow: narrow);
        checkButton('Subscribe');
      });

      testWidgets('channel not subscribed, without content access', (tester) async {
        final privateChannel = eg.stream(inviteOnly: true);
        await prepare();
        await store.addStream(privateChannel);
        await store.updateChannel(privateChannel.streamId,
          ChannelPropertyName.canSubscribeGroup, eg.groupSetting(members: []));
        await store.updateChannel(privateChannel.streamId,
          ChannelPropertyName.canAddSubscribersGroup, eg.groupSetting(members: []));
        final narrow = ChannelNarrow(privateChannel.streamId);
        check(store.selfHasContentAccess(privateChannel)).isFalse();
        await showFromMsglistAppBar(tester,
          channel: privateChannel, narrow: narrow);
        checkNoButton('Subscribe');
      });

      testWidgets('channel subscribed', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        check(store.subscriptions[narrow.streamId]).isNotNull();
        await showFromMsglistAppBar(tester, narrow: narrow);
        checkNoButton('Subscribe');
      });

      testWidgets('smoke', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        await store.removeSubscription(narrow.streamId);
        await showFromMsglistAppBar(tester, narrow: narrow);

        connection.prepare(json: {});
        await tapButton(tester);
        await tester.pump(Duration.zero);

        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/users/me/subscriptions')
          ..bodyFields.deepEquals({
            'subscriptions': jsonEncode([{'name': someChannel.name}]),
          });
      });
    });

    group('MarkChannelAsReadButton', () {
      void checkRequest(int channelId) {
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode([
              {'operator': 'channel', 'operand': channelId},
              {'operator': 'is', 'operand': 'unread'},
            ]),
            'op': 'add',
            'flag': 'read',
          });
      }

      testWidgets('happy path from inbox', (tester) async {
        await prepare();
        final message = eg.streamMessage(stream: someChannel, topic: someTopic);
        await store.addMessage(message);
        await showFromInbox(tester);
        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 1, updatedCount: 1,
          firstProcessedId: message.id, lastProcessedId: message.id,
          foundOldest: true, foundNewest: true).toJson());
        await tester.tap(findButtonForLabel('Mark channel as read'));
        await tester.pumpAndSettle();
        checkRequest(someChannel.streamId);
        checkNoDialog(tester);
      });

      testWidgets('request fails', (tester) async {
        await prepare();
        await showFromInbox(tester);
        connection.prepare(httpException: http.ClientException('Oops'));
        await tester.tap(findButtonForLabel('Mark channel as read'));
        await tester.pumpAndSettle();
        checkRequest(someChannel.streamId);
        checkErrorDialog(tester,
          expectedTitle: "Mark as read failed");
      });
    });

    group('TopicListButton', () {
      testWidgets('not visible from app bar on topic list', (tester) async {
        await prepare();
        await showFromTopicListAppBar(tester);
        checkNoButton('List of topics');
      });

      testWidgets('happy path from msglist app bar', (tester) async {
        await prepare();
        await showFromMsglistAppBar(tester,
          narrow: ChannelNarrow(someChannel.streamId));

        connection.prepare(json: GetStreamTopicsResult(topics: [
          eg.getStreamTopicsEntry(name: 'some topic foo'),
        ]).toJson());
        await tester.tap(findButtonForLabel('List of topics'));
        await tester.pumpAndSettle();
        check(find.text('some topic foo')).findsOne();
      });
    });

    group('ChannelFeedButton', () {
      Future<void> tapButtonAndPump(WidgetTester tester) async {
        await tester.tap(findButtonForLabel('Channel feed'));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('from inbox: visible', (tester) async {
        await prepare();
        await showFromInbox(tester);
        checkButton('Channel feed');
      });

      testWidgets('from subscription list: visible', (tester) async {
        await prepare();
        await showFromSubscriptionList(tester);
        checkButton('Channel feed');
      });

      testWidgets('from recipient header in combined feed: visible', (tester) async {
        await prepare();
        await showFromRecipientHeader(tester);
        checkButton('Channel feed');
      });

      testWidgets('from app bar on topic list: visible', (tester) async {
        await prepare();
        await showFromTopicListAppBar(tester);
        checkButton('Channel feed');
      });

      testWidgets('from msglist app bar on channel feed: not visible', (tester) async {
        await prepare();
        await showFromMsglistAppBar(tester, narrow: ChannelNarrow(someChannel.streamId));
        checkNoButton('Channel feed');
      });

      // (The channel action sheet isn't reached from a recipient header
      // in the channel feed.)

      testWidgets('navigates to channel feed', (tester) async {
        await prepare();
        await showFromInbox(tester);

        connection.prepare(json: eg.newestGetMessagesResult(
          foundOldest: true, messages: []).toJson());
        // for topic autocomplete
        connection.prepare(json: GetStreamTopicsResult(topics: []).toJson());
        await tapButtonAndPump(tester);
        await transitionDurationObserver.pumpPastTransition(tester);

        final appBar = tester.widget(find.byType(MessageListAppBarTitle)) as MessageListAppBarTitle;
        check(appBar.narrow).equals(ChannelNarrow(someChannel.streamId));
      });
    });

    group('CopyChannelLinkButton', () {
      setUp(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          MockClipboard().handleMethodCall,
        );
      });

      Future<void> tapCopyChannelLinkButton(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(ZulipIcons.link, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.link));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('copies channel link to clipboard', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        await showFromMsglistAppBar(tester, narrow: narrow);

        await tapCopyChannelLinkButton(tester);
        await tester.pump(Duration.zero);
        final expectedLink = narrowLink(store, narrow).toString();
        check(await Clipboard.getData('text/plain')).isNotNull().text.equals(expectedLink);
      });
    });

    group('UnsubscribeButton', () {
      Future<void> tapButton(WidgetTester tester) async {
        await tester.ensureVisible(findButtonForLabel('Unsubscribe'));
        await tester.tap(findButtonForLabel('Unsubscribe'));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('channel subscribed', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        check(store.subscriptions[narrow.streamId]).isNotNull();
        await showFromMsglistAppBar(tester, narrow: narrow);
        checkButton('Unsubscribe');
      });

      testWidgets('channel not subscribed', (tester) async {
        await prepare();
        final narrow = ChannelNarrow(someChannel.streamId);
        await store.removeSubscription(narrow.streamId);
        await showFromMsglistAppBar(tester, narrow: narrow);
        checkNoButton('Unsubscribe');
      });

      testWidgets('smoke, public channel', (tester) async {
        final channel = eg.stream(inviteOnly: false);
        await prepare();
        await store.addStream(channel);
        await store.addSubscription(eg.subscription(channel));
        final narrow = ChannelNarrow(channel.streamId);
        await showFromMsglistAppBar(tester, channel: channel, narrow: narrow);

        connection.prepare(json: {});
        await tapButton(tester);
        await tester.pump();

        final (unsubscribeButton, cancelButton) = checkSuggestedActionDialog(tester,
          expectedTitle: 'Unsubscribe from #${channel.name}?',
          expectDestructiveActionButton: false,
          expectedActionButtonText: 'Unsubscribe');
        await tester.tap(find.byWidget(unsubscribeButton));
        await tester.pump();
        await tester.pump(Duration.zero);

        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('DELETE')
          ..url.path.equals('/api/v1/users/me/subscriptions')
          ..bodyFields.deepEquals({
            'subscriptions': jsonEncode([channel.name]),
          });
      });

      testWidgets('smoke, private channel', (tester) async {
        final channel = eg.stream(inviteOnly: true);
        await prepare();
        await store.addStream(channel);
        await store.addSubscription(eg.subscription(channel));
        final narrow = ChannelNarrow(channel.streamId);
        await showFromMsglistAppBar(tester, channel: channel, narrow: narrow);
        connection.takeRequests();

        connection.prepare(json: {});
        await tapButton(tester);
        await tester.pump();

        final (unsubscribeButton, cancelButton) = checkSuggestedActionDialog(tester,
          expectedTitle: 'Unsubscribe from #${channel.name}?',
          expectedMessage: 'Once you leave this channel, you will not be able to rejoin.',
          expectDestructiveActionButton: true,
          expectedActionButtonText: 'Unsubscribe');
        await tester.tap(find.byWidget(unsubscribeButton));
        await tester.pump(Duration.zero);

        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('DELETE')
          ..url.path.equals('/api/v1/users/me/subscriptions')
          ..bodyFields.deepEquals({
            'subscriptions': jsonEncode([channel.name]),
          });
      });
    });
  });

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
      TopicName? topic,
      List<StreamMessage>? messages,
    }) async {
      final effectiveChannel = channel ?? someChannel;
      final effectiveTopic = topic ?? TopicName(someTopic);
      final effectiveMessages = messages ?? [someMessage];
      assert(effectiveMessages.every((m) => m.topic.apiName == effectiveTopic.apiName));

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: effectiveMessages).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: MessageListPage(
          initNarrow: TopicNarrow(effectiveChannel.streamId, effectiveTopic))));
      // global store, per-account store, and message list get loaded
      await tester.pumpAndSettle();

      final topicRow = find.descendant(
        of: find.byType(ZulipAppBar),
        matching: find.text(
          effectiveTopic.displayName ?? eg.defaultRealmEmptyTopicDisplayName));
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
        matching: find.text(effectiveMessage.topic.displayName!)));
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
        checkButton('Copy link to topic');
      }

      group('header', () {
        final findHeader = find.descendant(
          of: actionSheetFinder,
          matching: find.byType(BottomSheetHeader));

        Finder findInHeader(Finder finder) =>
          find.descendant(of: findHeader, matching: finder);

        testWidgets('with topic', (tester) async {
          await prepare();
          check(store.streams[someChannel.streamId]).isNotNull()
            ..inviteOnly.isFalse()..isWebPublic.isFalse();
          await showFromAppBar(tester);
          check(findInHeader(find.byIcon(ZulipIcons.hash_sign))).findsOne();
          check(findInHeader(find.textContaining(someChannel.name))).findsOne();
          check(findInHeader(find.textContaining(someTopic))).findsOne();
        });

        testWidgets('without topic (general chat)', (tester) async {
          await prepare(topic: '');
          check(store.streams[someChannel.streamId]).isNotNull()
            ..inviteOnly.isFalse()..isWebPublic.isFalse();
          final message = eg.streamMessage(
            stream: someChannel, topic: '', sender: eg.otherUser);
          await showFromAppBar(tester, messages: [message], topic: eg.t(''));
          check(findInHeader(find.byIcon(ZulipIcons.hash_sign))).findsOne();
          check(findInHeader(find.textContaining(someChannel.name))).findsOne();
          check(findInHeader(find.textContaining(store.realmEmptyTopicDisplayName)))
            .findsOne();
        });
      });

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

      testWidgets('show from app bar: resolve/unresolve not offered when topic is empty', (tester) async {
        await prepare();
        final message = eg.streamMessage(stream: someChannel, topic: '');
        await showFromAppBar(tester,
          topic: TopicName(''),
          messages: [message]);
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
          channel: someChannel, topic: TopicName(topic), messages: [message]);
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

        connection.prepare(apiException: eg.apiBadRequest());
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

        checkNoDialog(tester);
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

        checkNoDialog(tester);
        checkRequest(message.id, '✔ zulip');
      });

      testWidgets('unresolve: happy path', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: '✔ zulip');
        await prepare(topic: '✔ zulip');
        await showFromAppBar(tester,
          topic: TopicName('✔ zulip'), messages: [message]);
        connection.takeRequests();
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(findButtonForLabel('Mark as unresolved'));
        await tester.pumpAndSettle();

        checkNoDialog(tester);
        checkRequest(message.id, 'zulip');
      });

      testWidgets('unresolve: weird prefix', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: '✔ ✔ zulip');
        await prepare(topic: '✔ ✔ zulip');
        await showFromAppBar(tester,
          topic: TopicName('✔ ✔ zulip'), messages: [message]);
        connection.takeRequests();
        connection.prepare(json: UpdateMessageResult().toJson());
        await tester.tap(findButtonForLabel('Mark as unresolved'));
        await tester.pumpAndSettle();

        checkNoDialog(tester);
        checkRequest(message.id, 'zulip');
      });

      testWidgets('resolve: request fails', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: 'zulip');
        await prepare(topic: 'zulip');
        await showFromRecipientHeader(tester, message: message);
        connection.takeRequests();
        connection.prepare(httpException: http.ClientException('Oops'));
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
        connection.prepare(httpException: http.ClientException('Oops'));
        await tester.tap(findButtonForLabel('Mark as unresolved'));
        await tester.pumpAndSettle();
        checkRequest(message.id, 'zulip');

        checkErrorDialog(tester,
          expectedTitle: 'Failed to mark topic as unresolved');
      });
    });

    group('MarkTopicAsReadButton', () {
      testWidgets('visible if topic has unread messages', (tester) async {
        await prepare();
        final message = eg.streamMessage(stream: someChannel, topic: someTopic,
          flags: []);
        await store.addMessage(message);
        await showFromAppBar(tester, messages: [message]);
        check(find.text('Mark topic as read')).findsOne();
      });

      testWidgets('not visible if topic has no unread messages', (tester) async {
        await prepare();
        final message = eg.streamMessage(stream: someChannel, topic: someTopic,
          flags: [MessageFlag.read]);
        await store.addMessage(message);
        await showFromAppBar(tester, messages: [message]);
        check(find.text('Mark topic as read')).findsNothing();
      });

      testWidgets('marks topic as read when pressed', (tester) async {
        await prepare();
        final message = eg.streamMessage(stream: someChannel, topic: someTopic,
          flags: []);
        await store.addMessage(message);
        await showFromAppBar(tester, messages: [message]);

        connection.prepare(json: UpdateMessageFlagsForNarrowResult(
          processedCount: 1, updatedCount: 1,
          firstProcessedId: message.id, lastProcessedId: message.id,
          foundOldest: true, foundNewest: true).toJson());
        await tester.tap(find.text('Mark topic as read'));
        await tester.pumpAndSettle();

        check(connection.lastRequest).isA<http.Request>()
          ..url.path.equals('/api/v1/messages/flags/narrow')
          ..bodyFields['narrow'].equals(jsonEncode([
              ...resolveApiNarrowForServer(
                eg.topicNarrow(someChannel.streamId, someTopic).apiEncode(),
                connection.zulipFeatureLevel!),
              ApiNarrowIs(IsOperand.unread),
            ]))
          ..bodyFields['op'].equals('add')
          ..bodyFields['flag'].equals('read');
      });
    });

    group('CopyTopicLinkButton', () {
      setUp(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          MockClipboard().handleMethodCall,
        );
      });

      Future<void> tapCopyTopicLinkButton(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(ZulipIcons.link, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.link));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('copies topic link to clipboard', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: someTopic);
        await prepare(channel: someChannel, topic: someTopic,
          zulipFeatureLevel: eg.recentZulipFeatureLevel);
        await showFromAppBar(tester, channel: someChannel,
          topic: TopicName(someTopic), messages: [message]);

        await tapCopyTopicLinkButton(tester);
        await tester.pump(Duration.zero);
        final expectedLink = narrowLink(store,
          TopicNarrow(someChannel.streamId, TopicName(someTopic), with_: message.id));
        check(expectedLink.toString().contains('/with/')).isTrue();
        check((await Clipboard.getData('text/plain'))!)
          .text.equals(expectedLink.toString());
      });

      testWidgets('FL < 271 -> link doesn\'t contain "with" operator', (tester) async {
        final message = eg.streamMessage(stream: someChannel, topic: someTopic);
        await prepare(channel: someChannel, topic: someTopic,
          zulipFeatureLevel: 270);
        await showFromAppBar(tester, channel: someChannel,
          topic: TopicName(someTopic), messages: [message]);

        await tapCopyTopicLinkButton(tester);
        await tester.pump(Duration.zero);
        final expectedLink = narrowLink(store,
          TopicNarrow(someChannel.streamId, TopicName(someTopic)));
        check(expectedLink.toString().contains('/with/')).isFalse();
        check((await Clipboard.getData('text/plain'))!)
          .text.equals(expectedLink.toString());
      });
    });
  });

  group('message action sheet', () {
    final actionSheetFinder = find.byType(BottomSheet);
    Finder findButtonForLabel(String label) =>
      find.descendant(of: actionSheetFinder, matching: find.text(label));

    group('header', () {
      void checkSenderAndTimestampShown(WidgetTester tester, {required int senderId}) {
        check(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate(
            (widget) => widget is Avatar && widget.userId == senderId))
        ).findsOne();
        final expectedTimestampColor = MessageListTheme.of(
          tester.element(find.byType(BottomSheet))).labelTime;
        // TODO check the timestamp text itself, when it's convenient to do so:
        //   https://github.com/zulip/zulip-flutter/pull/1624#discussion_r2181383754
        check(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate((widget) =>
            widget is Text
            && widget.style?.color == expectedTimestampColor
            && (widget.style?.fontFeatures?.contains(FontFeature.enable('c2sc')) ?? false)))
        ).findsOne();
      }

      testWidgets('message sender and content shown', (tester) async {
        final message = eg.streamMessage(
          timestamp: 1671409088,
          content: ContentExample.userMentionPlain.html);
        await setupToMessageActionSheet(tester,
          message: message,
          narrow: TopicNarrow.ofMessage(message));
        checkSenderAndTimestampShown(tester, senderId: message.senderId);
        check(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(UserMention))
        ).findsOne();
      });

      testWidgets('muted sender also shown', (tester) async {
        final message = eg.streamMessage(
          timestamp: 1671409088,
          content: ContentExample.userMentionPlain.html);
        await setupToMessageActionSheet(tester,
          message: message,
          narrow: TopicNarrow.ofMessage(message),
          mutedUserIds: [message.senderId],
          beforeLongPress: () async {
            check(find.byType(MessageContent)).findsNothing();
            await tester.tap(
              find.widgetWithText(ZulipWebUiKitButton, 'Reveal message'));
            await tester.pump();
            check(find.byType(MessageContent)).findsOne();
          },
        );
        checkSenderAndTimestampShown(tester, senderId: message.senderId);
        check(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(UserMention))
        ).findsOne();
      });

      testWidgets('poll is rendered', (tester) async {
        final submessageContent = eg.pollWidgetData(
          question: 'poll', options: ['First option', 'Second option']);
        final message = eg.streamMessage(
          timestamp: 1671409088,
          sender: eg.selfUser,
          submessages: [eg.submessage(content: submessageContent)]);
        await setupToMessageActionSheet(tester,
          message: message,
          narrow: TopicNarrow.ofMessage(message));
        checkSenderAndTimestampShown(tester, senderId: message.senderId);
        check(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('First option'))
        ).findsOne();
      });
    });

    group('ReactionButtons', () {
      testWidgets('absent if ServerEmojiData not loaded', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester,
          message: message,
          narrow: TopicNarrow.ofMessage(message),
          shouldSetServerEmojiData: false);
        check(find.byType(ReactionButtons)).findsNothing();
      });

      for (final useLegacy in [false, true]) {
        final popularCandidates =
          (eg.store()..setServerEmojiData(
            useLegacy
              ? eg.serverEmojiDataPopularLegacy
              : eg.serverEmojiDataPopular))
            .popularEmojiCandidates();
        for (final emoji in popularCandidates) {
          final emojiDisplay = emoji.emojiDisplay as UnicodeEmojiDisplay;

          Future<void> tapButton(WidgetTester tester) async {
            await tester.tap(find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text(emojiDisplay.emojiUnicode)));
          }

          testWidgets('${emoji.emojiName} adding success; useLegacy: $useLegacy', (tester) async {
            final message = eg.streamMessage();
            await setupToMessageActionSheet(tester,
              message: message,
              narrow: TopicNarrow.ofMessage(message),
              useLegacyServerEmojiData: useLegacy);

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

          testWidgets('${emoji.emojiName} removing success; useLegacy: $useLegacy', (tester) async {
            final message = eg.streamMessage(
              reactions: [Reaction(
                emojiName: emoji.emojiName,
                emojiCode: emoji.emojiCode,
                reactionType: ReactionType.unicodeEmoji,
                userId: eg.selfAccount.userId)]
            );
            await setupToMessageActionSheet(tester,
              message: message,
              narrow: TopicNarrow.ofMessage(message),
              useLegacyServerEmojiData: useLegacy);

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

          testWidgets('${emoji.emojiName} request has an error; useLegacy: $useLegacy', (tester) async {
            final message = eg.streamMessage();
            await setupToMessageActionSheet(tester,
              message: message,
              narrow: TopicNarrow.ofMessage(message),
              useLegacyServerEmojiData: useLegacy);

            connection.prepare(
              apiException: eg.apiBadRequest(message: 'Invalid message(s)'));
            await tapButton(tester);
            await tester.pump(Duration.zero); // error arrives; error dialog shows

            await tester.tap(find.byWidget(checkErrorDialog(tester,
              expectedTitle: 'Adding reaction failed',
              expectedMessage: 'Invalid message(s)')));
          });
        }
      }
    });

    group('ViewReactionsButton', () {
      final findButtonInSheet = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(ZulipIcons.see_who_reacted));

      testWidgets('not visible if message has no reactions', (tester) async {
        final message = eg.streamMessage(reactions: []);
        await setupToMessageActionSheet(tester,
          message: message, narrow: CombinedFeedNarrow());

        check(findButtonInSheet).findsNothing();
      });

      Future<void> tapButton(WidgetTester tester) async {
        await tester.ensureVisible(findButtonInSheet);
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
        await tester.tap(findButtonInSheet);
      }

      testWidgets('smoke', (tester) async {
        final message = eg.streamMessage(reactions: [eg.unicodeEmojiReaction]);
        await setupToMessageActionSheet(tester,
          message: message, narrow: CombinedFeedNarrow());

        await tapButton(tester);

        // The message action sheet exits and the view-reactions sheet enters.
        //
        // This just pumps through twice the duration of the latest transition.
        // Ideally we'd check that the two expected transitions were triggered
        // and that they started at the same time, and pump through the
        // longer of the two durations.
        // TODO(upstream) support this in TransitionDurationObserver
        await transitionDurationObserver.pumpPastTransition(tester);
        await transitionDurationObserver.pumpPastTransition(tester);

        check(findButtonInSheet).findsNothing(); // the message action sheet exited
        check(find.byType(ViewReactions)).findsOne();
      });
    });

    group('ViewReadReceiptsButton', () {
      final findButtonInSheet = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(ZulipIcons.check_check));

      Future<void> tapButton(WidgetTester tester) async {
        await tester.ensureVisible(findButtonInSheet);
        await tester.tap(findButtonInSheet);
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      testWidgets('smoke', (tester) async {
        await setupToMessageActionSheet(tester,
          message: eg.streamMessage(), narrow: CombinedFeedNarrow());

        await tapButton(tester);

        // The message action sheet exits and the view-reactions sheet enters.
        //
        // This just pumps through twice the duration of the latest transition.
        // Ideally we'd check that the two expected transitions were triggered
        // and that they started at the same time, and pump through the
        // longer of the two durations.
        // TODO(upstream) support this in TransitionDurationObserver
        await transitionDurationObserver.pumpPastTransition(tester);
        await transitionDurationObserver.pumpPastTransition(tester);

        // message action sheet exited
        check(find.ancestor(of: find.byIcon(ZulipIcons.check_check),
          matching: find.byType(BottomSheet))).findsNothing();

        // receipts sheet opened
        check(find.ancestor(of: find.byType(ReadReceipts),
          matching: find.byType(BottomSheet))).findsOne();
      });

      testWidgets('realm-level read receipts disabled -> button is absent', (tester) async {
        await setupToMessageActionSheet(tester,
          message: eg.streamMessage(),
          narrow: CombinedFeedNarrow(),
          realmEnableReadReceipts: false);

        check(findButtonInSheet).findsNothing();
      });
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

        connection.prepare(
          apiException: eg.apiBadRequest(message: 'Invalid message(s)'));
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

        connection.prepare(
          apiException: eg.apiBadRequest(message: 'Invalid message(s)'));
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
        check(contentController).value.equals((ComposeContentController(store: store)
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
        final builder = ComposeContentController(store: store)
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

      testWidgets('in channel narrow with different, non-vacuous topic', (tester) async {
        final message = eg.streamMessage(topic: 'some topic');
        await setupToMessageActionSheet(tester, message: message, narrow: ChannelNarrow(message.streamId));

        final composeBoxController = findComposeBoxController(tester) as StreamComposeBoxController;
        final contentController = composeBoxController.content;

        // Ensure channel-topics are loaded before testing quote & reply behavior
        connection.prepare(body:
          jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
        final topicController = composeBoxController.topic;
        topicController.value = TextEditingValue(text: 'other topic');

        final valueBefore = contentController.value;
        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        await tapQuoteAndReplyButton(tester);
        checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
        await tester.pump(Duration.zero); // message is fetched; compose box updates
        check(composeBoxController.contentFocusNode.hasFocus).isTrue();
        checkSuccessState(store, contentController,
          valueBefore: valueBefore, message: message, rawContent: 'Hello world');
        check(topicController).textNormalized.equals('other topic');
      });

      testWidgets('in channel narrow with empty topic', (tester) async {
        // Regression test for https://github.com/zulip/zulip-flutter/issues/1469
        final message = eg.streamMessage(topic: 'some topic');
        await setupToMessageActionSheet(tester, message: message, narrow: ChannelNarrow(message.streamId));

        final composeBoxController = findComposeBoxController(tester) as StreamComposeBoxController;
        final contentController = composeBoxController.content;

        // Ensure channel-topics are loaded before testing quote & reply behavior
        connection.prepare(body:
          jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
        final topicController = composeBoxController.topic;
        topicController.value = const TextEditingValue(text: '');

        final valueBefore = contentController.value;
        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        await tapQuoteAndReplyButton(tester);
        checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
        await tester.pump(Duration.zero); // message is fetched; compose box updates
        check(composeBoxController.contentFocusNode.hasFocus).isTrue();
        checkSuccessState(store, contentController,
          valueBefore: valueBefore, message: message, rawContent: 'Hello world');
        check(topicController).textNormalized.equals('some topic');
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
          final selfUser = eg.user(role: UserRole.member);
          final stream = eg.stream();
          final message = eg.streamMessage(stream: stream);
          await setupToMessageActionSheet(tester, selfUser: selfUser,
            message: message, narrow: TopicNarrow.ofMessage(message));

          await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: selfUser.userId,
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
          final otherUser = eg.user();
          final message = eg.dmMessage(from: eg.selfUser, to: [otherUser]);
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

          await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: otherUser.userId,
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

      testWidgets('handle empty topic', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester,
          message: message, narrow: TopicNarrow.ofMessage(message));

        prepareRawContentResponseSuccess(message: message, rawContent: 'Hello world');
        await tapQuoteAndReplyButton(tester);
        check(connection.lastRequest).isA<http.Request>()
          .url.queryParameters['allow_empty_topic_name'].equals('true');
        await tester.pump(Duration.zero);
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
                'narrow': jsonEncode(resolveApiNarrowForServer(
                  TopicNarrow.ofMessage(message).apiEncode(),
                  connection.zulipFeatureLevel!)),
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
                jsonEncode(resolveApiNarrowForServer(
                  eg.topicNarrow(newStream.streamId, newTopic).apiEncode(),
                  connection.zulipFeatureLevel!)));
        });

        testWidgets('shows error when fails', (tester) async {
          final message = eg.streamMessage(flags: [MessageFlag.read]);
          await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

          connection.prepare(httpException: http.ClientException('Oops'));
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

    group('UnrevealMutedMessageButton', () {
      final user = eg.user(userId: 1, fullName: 'User', avatarUrl: '/foo.png');
      final message = eg.streamMessage(sender: user,
        content: '<p>A message</p>', reactions: [eg.unicodeEmojiReaction]);

      final revealButtonFinder = find.widgetWithText(ZulipWebUiKitButton,
        'Reveal message');

      final contentFinder = find.descendant(
        of: find.byType(MessageContent),
        matching: find.text('A message', findRichText: true));

      testWidgets('not visible if message is from normal sender (not muted)', (tester) async {
        prepareBoringImageHttpClient();

        await setupToMessageActionSheet(tester,
          message: message,
          narrow: const CombinedFeedNarrow(),
          sender: user);
        check(store.isUserMuted(user.userId)).isFalse();

        check(find.byIcon(ZulipIcons.eye_off, skipOffstage: false)).findsNothing();

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('visible if message is from muted sender and revealed', (tester) async {
        prepareBoringImageHttpClient();

        await setupToMessageActionSheet(tester,
          message: message,
          narrow: const CombinedFeedNarrow(),
          sender: user,
          mutedUserIds: [user.userId],
          beforeLongPress: () async {
            check(contentFinder).findsNothing();
            await tester.tap(revealButtonFinder);
            await tester.pump();
            check(contentFinder).findsOne();
          },
        );

        check(find.byIcon(ZulipIcons.eye_off, skipOffstage: false)).findsOne();

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('when pressed, unreveals the message', (tester) async {
        prepareBoringImageHttpClient();

        await setupToMessageActionSheet(tester,
          message: message,
          narrow: const CombinedFeedNarrow(),
          sender: user,
          mutedUserIds: [user.userId],
          beforeLongPress: () async {
            check(contentFinder).findsNothing();
            await tester.tap(revealButtonFinder);
            await tester.pump();
            check(contentFinder).findsOne();
          });

        await tester.ensureVisible(find.byIcon(ZulipIcons.eye_off, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.eye_off));
        await tester.pumpAndSettle();

        check(contentFinder).findsNothing();
        check(revealButtonFinder).findsOne();

        debugNetworkImageHttpClientProvider = null;
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
        await tester.ensureVisible(find.byIcon(ZulipIcons.link, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.link));
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

    group('EditButton', () {
      Future<void> tapEdit(WidgetTester tester) async {
        await tester.ensureVisible(find.byIcon(ZulipIcons.edit, skipOffstage: false));
        await tester.tap(find.byIcon(ZulipIcons.edit));
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      Future<void> takeErrorDialogAndPump(WidgetTester tester) async {
        final errorDialog = checkErrorDialog(tester, expectedTitle: 'Message not saved');
        await tester.tap(find.byWidget(errorDialog));
        await tester.pump();
      }

      group('present/absent appropriately', () {
        /// Test whether the edit-message button is visible, given params.
        ///
        /// The message timestamp is 60s before the current time
        /// ([TestZulipBinding.utcNow]) as of the start of the test run.
        ///
        /// The message has streamId: 1 and topic: 'topic'.
        /// The message list is for that [TopicNarrow] unless [narrow] is passed.
        void testVisibility(bool expected, {
          bool self = true,
          Narrow? narrow,
          bool allowed = true,
          int? limit,
          bool boxInEditMode = false,
          bool? errorStatus,
          bool poll = false,
        }) {
          // It's inconvenient here to set up a state where the compose box
          // is in edit mode and the action sheet is opened for a message
          // with an edit request that's in progress or in the error state.
          // In the setup, we'd need to either use two messages or (via an edge
          // case) two MessageListPages. It should suffice to test the
          // boxInEditMode and errorStatus states separately.
          assert(!boxInEditMode || errorStatus == null);

          final description = [
            'from self: $self',
            'narrow: $narrow',
            'realm allows: $allowed',
            'edit limit: $limit',
            'compose box is in editing mode: $boxInEditMode',
            'edit-message error status: $errorStatus',
            'has poll: $poll',
          ].join(', ');

          void checkButtonIsPresent(bool expected) {
            if (expected) {
              check(find.byIcon(ZulipIcons.edit, skipOffstage: false)).findsOne();
            } else {
              check(find.byIcon(ZulipIcons.edit, skipOffstage: false)).findsNothing();
            }
          }

          testWidgets(description, (tester) async {
            TypingNotifier.debugEnable = false;
            addTearDown(TypingNotifier.debugReset);

            final message = eg.streamMessage(
              stream: eg.stream(streamId: 1),
              topic: 'topic',
              sender: self ? eg.selfUser : eg.otherUser,
              timestamp: eg.utcTimestamp(testBinding.utcNow()) - 60,
              submessages: poll
                ? [eg.submessage(content: eg.pollWidgetData(question: 'poll', options: ['A']))]
                : null,
            );

            await setupToMessageActionSheet(tester,
              message: message,
              narrow: narrow ?? TopicNarrow.ofMessage(message),
              realmAllowMessageEditing: allowed,
              realmMessageContentEditLimitSeconds: limit,
            );

            if (!boxInEditMode && errorStatus == null) {
              // The state we're testing is present on the original action sheet.
              checkButtonIsPresent(expected);
              return;
            }
            // The state we're testing requires a previous "edit message" action
            // in order to set up. Use the first action sheet for that setup step.

            connection.prepare(json: GetMessageResult(
              message: eg.streamMessage(content: 'foo')).toJson());
            await tapEdit(tester);
            await tester.pump();
            // Default duration of bottom-sheet exit animation,
            // plus 1ms fudge factor (why needed?)
            // TODO(#1668) get this dynamically instead of hard-coding
            await tester.pump(Duration(milliseconds: 200 + 1));
            await tester.enterText(find.byWidgetPredicate(
                (widget) => widget is TextField && widget.controller?.text == 'foo'),
              'bar');

            if (errorStatus == true) {
              // We're testing the request-failed state. Prepare a failure
              // and tap Save.
              connection.prepare(apiException: eg.apiBadRequest());
              await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
              await tester.pump(Duration.zero);
              await takeErrorDialogAndPump(tester);
            } else if (errorStatus == false) {
              // We're testing the request-in-progress state. Prepare a delay,
              // tap Save, and wait through only part of the delay.
              connection.prepare(
                json: UpdateMessageResult().toJson(), delay: Duration(seconds: 1));
              await tester.tap(find.widgetWithText(ZulipWebUiKitButton, 'Save'));
              await tester.pump(Duration(milliseconds: 500));
            } else {
              // We're testing the state where the compose box is in
              // edit-message mode. Keep it that way by not tapping Save.
            }

            // See comment in setupToMessageActionSheet about warnIfMissed: false
            await tester.longPress(find.byType(MessageContent), warnIfMissed: false);
            // sheet appears onscreen; default duration of bottom-sheet enter animation
            await tester.pump(const Duration(milliseconds: 250));
            check(find.byType(BottomSheet)).findsOne();
            checkButtonIsPresent(expected);

            await tester.pump(Duration(milliseconds: 500)); // flush timers
          });
        }

        testVisibility(true);
        testVisibility(true, limit: 600);
        testVisibility(true, narrow: ChannelNarrow(1));

        testVisibility(false, self: false);
        testVisibility(false, narrow: CombinedFeedNarrow());
        testVisibility(false, allowed: false);
        testVisibility(false, limit: 10);
        testVisibility(false, boxInEditMode: true);
        testVisibility(false, errorStatus: false);
        testVisibility(false, errorStatus: true);
        testVisibility(false, poll: true);
      });

      group('tap button', () {
        ComposeBoxController? findComposeBoxController(WidgetTester tester) {
          return tester.stateList<ComposeBoxState>(find.byType(ComposeBox))
            .singleOrNull?.controller;
        }

        testWidgets('smoke', (tester) async {
          final message = eg.streamMessage(sender: eg.selfUser);
          await setupToMessageActionSheet(tester,
            message: message,
            narrow: TopicNarrow.ofMessage(message),
            realmAllowMessageEditing: true,
            realmMessageContentEditLimitSeconds: null,
          );

          check(findComposeBoxController(tester))
            .isA<FixedDestinationComposeBoxController>();

          connection.prepare(json: GetMessageResult(
            message: eg.streamMessage(content: 'foo')).toJson());
          await tapEdit(tester);
          await tester.pump(Duration.zero);

          check(findComposeBoxController(tester))
            .isA<EditMessageComposeBoxController>()
              ..messageId.equals(message.id)
              ..originalRawContent.equals('foo');
        });
      });
    });

    group('DeleteMessageButton', () {
      final findButton = findButtonForLabel('Delete message');

      group('visibility', () {
        testWidgets('shown when user has permission', (tester) async {
          final message = eg.streamMessage(flags: []);
          await setupToMessageActionSheet(tester,
            hasDeletePermission: true,
            message: message, narrow: TopicNarrow.ofMessage(message));

          check(findButton).findsOne();
        });

        testWidgets('not shown when user does not have permission', (tester) async {
          final message = eg.streamMessage(flags: []);
          await setupToMessageActionSheet(tester,
            hasDeletePermission: false,
            message: message, narrow: TopicNarrow.ofMessage(message));

          check(findButton).findsNothing();
        });
      });

      Future<void> tapButton(WidgetTester tester, {bool starred = false}) async {
        await tester.ensureVisible(findButton);
        await tester.tap(findButton);
        await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
      }

      (Widget, Widget) checkConfirmation(WidgetTester tester) =>
        checkSuggestedActionDialog(tester,
          expectedTitle: 'Delete message?',
          expectedMessage: 'Deleting a message permanently removes it for everyone.',
          expectDestructiveActionButton: true,
          expectedActionButtonText: 'Delete');

      testWidgets('smoke', (tester) async {
        final message = eg.streamMessage(flags: []);
        await setupToMessageActionSheet(tester,
          message: message, narrow: TopicNarrow.ofMessage(message));

        await tapButton(tester);
        await tester.pump();

        final (deleteButton, cancelButton) = checkConfirmation(tester);
        connection.prepare(json: {});
        await tester.tap(find.byWidget(deleteButton));
        await tester.pump(Duration.zero);

        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('DELETE')
          ..url.path.equals('/api/v1/messages/${message.id}')
          ..bodyFields.deepEquals({});
      });

      testWidgets('cancel confirmation dialog', (tester) async {
        final message = eg.streamMessage(flags: []);
        await setupToMessageActionSheet(tester,
          message: message, narrow: TopicNarrow.ofMessage(message));

        connection.takeRequests();

        await tapButton(tester);
        await tester.pump();

        final (deleteButton, cancelButton) = checkConfirmation(tester);
        await tester.tap(find.byWidget(cancelButton));
        await tester.pumpAndSettle();

        check(connection.lastRequest).isNull();
      });

      testWidgets('request fails', (tester) async {
        final message = eg.streamMessage(flags: []);
        await setupToMessageActionSheet(tester,
          message: message, narrow: TopicNarrow.ofMessage(message));

        await tapButton(tester);
        await tester.pump();

        final (deleteButton, cancelButton) = checkConfirmation(tester);
        connection.prepare(apiException: eg.apiBadRequest());
        await tester.tap(find.byWidget(deleteButton));
        await tester.pump(Duration.zero);

        checkErrorDialog(tester, expectedTitle: 'Failed to delete message');
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
