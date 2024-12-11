import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/message_list.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import 'test_app.dart';

/// Simulates loading a [MessageListPage] and tapping to focus the compose input.
///
/// Also adds [users] to the [PerAccountStore],
/// so they can show up in autocomplete.
///
/// Also sets [debugNetworkImageHttpClientProvider] to return a constant image.
///
/// The caller must set [debugNetworkImageHttpClientProvider] back to null
/// before the end of the test.
Future<Finder> setupToComposeInput(WidgetTester tester, {
  List<User> users = const [],
}) async {
  TypingNotifier.debugEnable = false;
  addTearDown(TypingNotifier.debugReset);

  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUsers([eg.selfUser, eg.otherUser]);
  await store.addUsers(users);
  final connection = store.connection as FakeApiConnection;

  // prepare message list data
  final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
  connection.prepare(json: GetMessagesResult(
    anchor: message.id,
    foundNewest: true,
    foundOldest: true,
    foundAnchor: true,
    historyLimited: false,
    messages: [message],
  ).toJson());

  prepareBoringImageHttpClient();

  await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
    child: MessageListPage(initNarrow: DmNarrow(
      allRecipientIds: [eg.selfUser.userId, eg.otherUser.userId],
      selfUserId: eg.selfUser.userId))));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();

  // (hint text of compose input in a 1:1 DM)
  final finder = find.widgetWithText(TextField, 'Message @${eg.otherUser.fullName}');
  check(finder.evaluate()).isNotEmpty();
  return finder;
}

/// Simulates loading a [MessageListPage] with a stream narrow
/// and tapping to focus the topic input.
///
/// Also prepares test-topics to be sent to topics api request,
/// so they can show up in autocomplete.
///
/// Returns a [Finder] for the topic input's [TextField].
Future<Finder> setupToTopicInput(WidgetTester tester, {
  required List<GetStreamTopicsEntry> topics,
}) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUser(eg.selfUser);
  final connection = store.connection as FakeApiConnection;

  // prepare message list data
  final stream = eg.stream();
  await store.addStream(stream);
  final message = eg.streamMessage(stream: stream, sender: eg.selfUser);
  connection.prepare(json: GetMessagesResult(
    anchor: message.id,
    foundNewest: true,
    foundOldest: true,
    foundAnchor: true,
    historyLimited: false,
    messages: [message],
  ).toJson());

  await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
    child: MessageListPage(initNarrow: ChannelNarrow(stream.streamId))));
  await tester.pumpAndSettle();

  connection.prepare(json: GetStreamTopicsResult(topics: topics).toJson());
  final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
  final finder = find.byWidgetPredicate((widget) => widget is TextField
    && widget.decoration?.hintText == zulipLocalizations.composeBoxTopicHintText);
  check(finder.evaluate()).isNotEmpty();
  return finder;
}

Finder findNetworkImage(String url) {
  return find.byWidgetPredicate((widget) => switch(widget) {
    Image(image: NetworkImage(url: var imageUrl)) when imageUrl == url
      => true,
    _ => false,
  });
}

typedef ExpectedEmoji = (String label, EmojiDisplay display);

void main() {
  TestZulipBinding.ensureInitialized();

  group('@-mentions', () {
    void checkUserShown(User user, PerAccountStore store, {required bool expected}) {
      check(find.text(user.fullName).evaluate().length).equals(expected ? 1 : 0);
      final avatarFinder =
        findNetworkImage(store.tryResolveUrl(user.avatarUrl!).toString());
      check(avatarFinder.evaluate().length).equals(expected ? 1 : 0);
    }

    testWidgets('options appear, disappear, and change correctly', (tester) async {
      final user1 = eg.user(userId: 1, fullName: 'User One', avatarUrl: 'user1.png');
      final user2 = eg.user(userId: 2, fullName: 'User Two', avatarUrl: 'user2.png');
      final user3 = eg.user(userId: 3, fullName: 'User Three', avatarUrl: 'user3.png');
      final composeInputFinder = await setupToComposeInput(tester, users: [user1, user2, user3]);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      // Options are filtered correctly for query
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @user ');
      await tester.enterText(composeInputFinder, 'hello @user t');
      await tester.pumpAndSettle(); // async computation; options appear

      // "User Two" and "User Three" appear, but not "User One"
      checkUserShown(user1, store, expected: false);
      checkUserShown(user2, store, expected: true);
      checkUserShown(user3, store, expected: true);

      // Finishing autocomplete updates compose box; causes options to disappear
      await tester.tap(find.text('User Three'));
      await tester.pump();
      check(tester.widget<TextField>(composeInputFinder).controller!.text)
        .contains(mention(user3, users: store.users));
      checkUserShown(user1, store, expected: false);
      checkUserShown(user2, store, expected: false);
      checkUserShown(user3, store, expected: false);

      // Then a new autocomplete intent brings up options again
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @user tw');
      await tester.enterText(composeInputFinder, 'hello @user two');
      await tester.pumpAndSettle(); // async computation; options appear
      checkUserShown(user2, store, expected: true);

      // Removing autocomplete intent causes options to disappear
      // TODO(#226): Remove one of these edits when this bug is fixed.
      await tester.enterText(composeInputFinder, '');
      await tester.enterText(composeInputFinder, ' ');
      checkUserShown(user1, store, expected: false);
      checkUserShown(user2, store, expected: false);
      checkUserShown(user3, store, expected: false);

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('user options appear in the correct rendering order and do not scroll down', (tester) async {
      final List<User> users = [
        eg.user(userId: 1, fullName: 'Aaditya', avatarUrl: 'user1.png'),
        eg.user(userId: 2, fullName: 'Alya', avatarUrl: 'user2.png'),
        eg.user(userId: 3, fullName: 'Aman', avatarUrl: 'user3.png'),
        eg.user(userId: 4, fullName: 'Anders', avatarUrl: 'user4.png'),
        eg.user(userId: 5, fullName: 'Anthony', avatarUrl: 'user5.png'),
        eg.user(userId: 6, fullName: 'Apoorva', avatarUrl: 'user6.png'),
        eg.user(userId: 7, fullName: 'Asif', avatarUrl: 'user7.png'),
        eg.user(userId: 8, fullName: 'Asim', avatarUrl: 'user8.png')
      ];

      final composeInputFinder = await setupToComposeInput(tester, users:users);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final expectedUserSequence = users;
      // Options are filtered correctly for query
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @');
      await tester.pumpAndSettle();
      await tester.enterText(composeInputFinder, 'hello @A');
      await tester.pumpAndSettle();
      // Only first seven users render initially, 8th user has to be accessed by scrolling up
      final List<double> positions = [];
      for(int i = 0 ;i < 7 ;i++){
        final user = expectedUserSequence[i];
        checkUserShown(user, store, expected: true);
        final finder = find.text(user.fullName);
        check(because:'Each user option should be rendered (index: $i)',finder).findsOne();
        positions.add(tester.getTopLeft(finder).dy);
      }
      for(int i = 7; i < expectedUserSequence.length;i++){
        final user = expectedUserSequence[i];
        checkUserShown(user, store, expected: false);
      }
      final listViewFinder = find.byType(ListView);
      check(because: "reason: 'ListView should be rendered'",listViewFinder,).findsOne();

      final initialScrollOffset = tester.getTopLeft(listViewFinder).dy;
      await tester.drag(listViewFinder, const Offset(0, -50));
      await tester.pumpAndSettle();
      final scrollOffsetAfterDragDown = tester.getTopLeft(listViewFinder).dy;

      check(because:'ListView should not scroll down because it is already at the bottom',scrollOffsetAfterDragDown).equals(initialScrollOffset);

      for(int i = 0 ;i < 6;i++){
         check(because: '${expectedUserSequence[i + 1]} should appear above ${expectedUserSequence[i]} because of reverse order', positions[i]).isGreaterThan(positions[i+1]);
      }

      await tester.drag(listViewFinder, const Offset(0, 200)); // Should be capped at prev position
      await tester.pumpAndSettle();

      checkUserShown(users.last, store, expected: true);
      checkUserShown(users.first, store, expected: false);

      // 8th user should be above 7th user
      check(because: "8th user should be above 7th user",
      tester.getTopLeft(find.text(users.last.fullName)).dy ).isLessThan(tester.getTopLeft(find.text(users[users.length - 2].fullName)).dy);
      debugNetworkImageHttpClientProvider = null;
    });
  });

  group('emoji', () {
    void checkEmojiShown(ExpectedEmoji option, {required bool expected}) {
      final (label, display) = option;
      final labelSubject = check(find.text(label));
      expected ? labelSubject.findsOne() : labelSubject.findsNothing();

      final Subject<Finder> displaySubject;
      switch (display) {
        case UnicodeEmojiDisplay():
          displaySubject = check(find.text(display.emojiUnicode));
        case ImageEmojiDisplay():
          displaySubject = check(findNetworkImage(display.resolvedUrl.toString()));
        case TextEmojiDisplay():
          // We test this case in the "text emoji" test below,
          // but that doesn't use this helper method.
          throw UnimplementedError();
      }
      expected ? displaySubject.findsOne(): displaySubject.findsNothing();
    }

    testWidgets('show, update, choose', (tester) async {
      final composeInputFinder = await setupToComposeInput(tester);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      store.setServerEmojiData(ServerEmojiData(codeToNames: {
        '1f4a4': ['zzz', 'sleepy'], // (just 'zzz' in real data)
      }));
      await store.handleEvent(RealmEmojiUpdateEvent(id: 1, realmEmoji: {
        '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'buzzing'),
      }));

      final zulipOption = ('zulip', store.emojiDisplayFor(
        emojiType: ReactionType.zulipExtraEmoji,
        emojiCode: 'zulip', emojiName: 'zulip'));
      final buzzingOption = ('buzzing', store.emojiDisplayFor(
        emojiType: ReactionType.realmEmoji,
        emojiCode: '1', emojiName: 'buzzing'));
      final zzzOption = ('zzz, sleepy', store.emojiDisplayFor(
        emojiType: ReactionType.unicodeEmoji,
        emojiCode: '1f4a4', emojiName: 'zzz'));

      // Enter a query; options appear, of all three emoji types.
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hi :');
      await tester.enterText(composeInputFinder, 'hi :z');
      await tester.pump();
      checkEmojiShown(expected: true, zzzOption);
      checkEmojiShown(expected: true, buzzingOption);
      checkEmojiShown(expected: true, zulipOption);

      // Edit query; options change.
      await tester.enterText(composeInputFinder, 'hi :zz');
      await tester.pump();
      checkEmojiShown(expected: true, zzzOption);
      checkEmojiShown(expected: true, buzzingOption);
      checkEmojiShown(expected: false, zulipOption);

      // Choosing an option enters result and closes autocomplete.
      await tester.tap(find.text('buzzing'));
      await tester.pump();
      check(tester.widget<TextField>(composeInputFinder).controller!.text)
        .equals('hi :buzzing:');
      checkEmojiShown(expected: false, zzzOption);
      checkEmojiShown(expected: false, buzzingOption);
      checkEmojiShown(expected: false, zulipOption);

      debugNetworkImageHttpClientProvider = null;
    });

 testWidgets('emoji options appear in the correct rendering order and do not scroll down', (tester) async {
    final composeInputFinder = await setupToComposeInput(tester);
    final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    store.setServerEmojiData(
      ServerEmojiData(
        codeToNames: {
          '1f4a4': ['zzz', 'sleepy'], // Unicode emoji for "zzz"
          '1f52a': ['biohazard'],
          '1f92a': ['zany_face'],
          '1f993': ['zebra'],
          '0030-fe0f-20e3': ['zero'],
          '1f9d0': ['zombie'],
        },
      ),
    );
    await store.handleEvent(
      RealmEmojiUpdateEvent(
        id: 1,
        realmEmoji: {
          '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'buzzing'),
        },
      ),
    );

    const zulipOptionLabel = 'zulip';
    const zanyFaceOptionLabel = 'zany_face';
    const zebraOptionLabel = 'zebra';
    const zzzOptionLabel = 'zzz, sleepy';
    const unicodeGlyph = '💤';
    const zombieOptionLabel = 'zombie';
    const zeroOptionLabel = 'zero';
    const buzzingOptionLabel = 'buzzing';
    const biohazardOptionLabel = 'biohazard';

    // Adjust the order so the best match appears last
    final emojiSequence = [
      zulipOptionLabel,
      zzzOptionLabel,
      unicodeGlyph,
      zanyFaceOptionLabel,
      zebraOptionLabel,
      zeroOptionLabel,
      zombieOptionLabel,
      buzzingOptionLabel,
      // biohazardOptionLabel, this won't be rendered in the list initally since it is the 7th option.
    ];

    // Enter a query; options appear, of all three emoji types.
    // TODO(#226): Remove this extra edit when this bug is fixed.
    await tester.enterText(composeInputFinder, 'hi :');
    await tester.enterText(composeInputFinder, 'hi :z');
    await tester.pumpAndSettle();

    final listViewFinder = find.byType(ListView);
    check(because: "reason: 'ListView should be rendered'",listViewFinder,).findsOne();

    final positions = emojiSequence.map((icon) {
      final finder = find.text(icon);
      check(because:"Each emoji option should be rendered", finder).findsOne();
      return tester.getTopLeft(finder).dy;
    }).toList();

    for (int i = 0; i < positions.length - 1; i++) {
      check(because: "${emojiSequence[i + 1]} should appear above ${emojiSequence[i]} because of reverse order",
      positions[i]).isGreaterThan(positions[i + 1]);
    }

    final initialScrollOffset = tester.getTopLeft(listViewFinder).dy;
    await tester.drag(listViewFinder, const Offset(0, -50));
    await tester.pumpAndSettle();
    final scrollOffsetAfterDragDown = tester.getTopLeft(listViewFinder).dy;

    check(because:"ListView should not scroll down because it is already at the bottom",
    scrollOffsetAfterDragDown).equals(initialScrollOffset);

    final biohazardFinder = find.text(biohazardOptionLabel);
    check(because: "The biohazard emoji should not be visible before scrolling up",biohazardFinder).findsNothing();

    // Scroll up
    await tester.drag(listViewFinder, const Offset(0, 50));
    await tester.pumpAndSettle();

    check(because:"The biohazard emoji should be visible after scrolling up",biohazardFinder).findsOne();

    final firstEmojiPositionAfterScrollUp = tester.getTopLeft(find.text(emojiSequence[0])).dy;
    check(because: "Scrolling up should reveal other emoji matches",firstEmojiPositionAfterScrollUp).isGreaterOrEqual(positions[0]);

    debugNetworkImageHttpClientProvider = null;

  });

    testWidgets('text emoji means just show text', (tester) async {
      final composeInputFinder = await setupToComposeInput(tester);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.handleEvent(UserSettingsUpdateEvent(id: 1,
        property: UserSettingName.emojiset, value: Emojiset.text));

      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hi :');
      await tester.enterText(composeInputFinder, 'hi :z');
      await tester.pump();

      // The emoji's name appears.  (And only once.)
      check(find.text('zulip')).findsOne();

      // But no emoji image appears.
      check(find.byWidgetPredicate((widget) => switch(widget) {
        Image(image: NetworkImage()) => true,
        _ => false,
      })).findsNothing();

      debugNetworkImageHttpClientProvider = null;
    });
  });

  group('TopicAutocomplete', () {
    void checkTopicShown(GetStreamTopicsEntry topic, PerAccountStore store, {required bool expected}) {
      check(find.text(topic.name).evaluate().length).equals(expected ? 1 : 0);
    }

    testWidgets('options appear, disappear, and change correctly', (WidgetTester tester) async {
      final topic1 = eg.getStreamTopicsEntry(maxId: 1, name: 'Topic one');
      final topic2 = eg.getStreamTopicsEntry(maxId: 2, name: 'Topic two');
      final topic3 = eg.getStreamTopicsEntry(maxId: 3, name: 'Topic three');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic1, topic2, topic3]);
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      // Options are filtered correctly for query
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(topicInputFinder, 'Topic');
      await tester.enterText(topicInputFinder, 'Topic T');
      await tester.pumpAndSettle();

      // "topic three" and "topic two" appear, but not "topic one"
      checkTopicShown(topic1, store, expected: false);
      checkTopicShown(topic2, store, expected: true);
      checkTopicShown(topic3, store, expected: true);

      // Finishing autocomplete updates topic box; causes options to disappear
      await tester.tap(find.text('Topic three'));
      await tester.pumpAndSettle();
      check(tester.widget<TextField>(topicInputFinder).controller!.text)
        .equals(topic3.name);
      checkTopicShown(topic1, store, expected: false);
      checkTopicShown(topic2, store, expected: false);
      checkTopicShown(topic3, store, expected: true); // shown in `_TopicInput` once

      // Then a new autocomplete intent brings up options again
      await tester.enterText(topicInputFinder, 'Topic');
      await tester.enterText(topicInputFinder, 'Topic T');
      await tester.pumpAndSettle();
      checkTopicShown(topic2, store, expected: true);
    });
  });
}
