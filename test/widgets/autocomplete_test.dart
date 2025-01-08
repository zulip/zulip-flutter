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
import '../flutter_checks.dart';
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
      // Add an extra pump to account for any potential frame delays introduced
      // by the post frame callback in RawAutocomplete's implementation.
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
      check(find.text(topic.name.displayName).evaluate().length).equals(expected ? 1 : 0);
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
        .equals(topic3.name.displayName);
      checkTopicShown(topic1, store, expected: false);
      checkTopicShown(topic2, store, expected: false);
      checkTopicShown(topic3, store, expected: true); // shown in `_TopicInput` once

      // Then a new autocomplete intent brings up options again
      await tester.enterText(topicInputFinder, 'Topic');
      await tester.enterText(topicInputFinder, 'Topic T');
      await tester.pumpAndSettle();
      checkTopicShown(topic2, store, expected: true);
    });

    testWidgets('text selection is reset on choosing an option', (tester) async {
      // TODO test also that composing region gets reset.
      //   (Just adding it to the updateEditingValue call below doesn't seem
      //   to suffice to set it up; the controller value after the pump still
      //   has empty composing region, so there's nothing to check after tap.)

      final topic = eg.getStreamTopicsEntry(name: 'some topic');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic]);
      final controller = tester.widget<TextField>(topicInputFinder).controller!;

      await tester.enterText(topicInputFinder, 'so');
      await tester.enterText(topicInputFinder, 'some');
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'some',
        selection: TextSelection(baseOffset: 1, extentOffset: 3)));
      await tester.pump();
      check(controller.value)
        ..text.equals('some')
        ..selection.equals(
            const TextSelection(baseOffset: 1, extentOffset: 3));

      await tester.tap(find.text('some topic'));
      await tester.pump();
      check(controller.value)
        ..text.equals('some topic')
        ..selection.equals(
            const TextSelection.collapsed(offset: 'some topic'.length));

      await tester.pump(Duration.zero);
    });
  });
}
