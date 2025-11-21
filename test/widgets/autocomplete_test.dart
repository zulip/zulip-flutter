import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/basic.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/autocomplete.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/user.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import 'test_app.dart';

late PerAccountStore store;

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
  Narrow? narrow,
}) async {
  assert(narrow is ChannelNarrow? || narrow is SendableNarrow?);
  TypingNotifier.debugEnable = false;
  addTearDown(TypingNotifier.debugReset);

  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUsers([eg.selfUser, eg.otherUser]);
  await store.addUsers(users);
  final connection = store.connection as FakeApiConnection;

  narrow ??= DmNarrow(
    allRecipientIds: [eg.selfUser.userId, eg.otherUser.userId],
    selfUserId: eg.selfUser.userId);
  // prepare message list data
  final Message message;
  switch(narrow) {
    case DmNarrow():
      message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
    case ChannelNarrow(:final streamId):
      final stream = eg.stream(streamId: streamId);
      message = eg.streamMessage(stream: stream);
      await store.addStream(stream);
    case TopicNarrow(:final streamId, :final topic):
      final stream = eg.stream(streamId: streamId);
      message = eg.streamMessage(stream: stream, topic: topic.apiName);
      await store.addStream(stream);
    default: throw StateError('unexpected narrow type');
  }
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
    child: MessageListPage(initNarrow: narrow)));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();

  final finder = find.byWidgetPredicate((widget) => widget is TextField
    && widget.controller is ComposeContentController);
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
  required List<GetChannelTopicsEntry> topics,
  String? realmEmptyTopicDisplayName,
}) async {
  addTearDown(testBinding.reset);
  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
    realmEmptyTopicDisplayName: realmEmptyTopicDisplayName));
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
  MessageListPage.debugEnableMarkReadOnScroll = false;

  group('@-mentions', () {

    Finder findAvatarImage(int userId) =>
      find.byWidgetPredicate((widget) => widget is AvatarImage && widget.userId == userId);

    void checkUserShown(User user, {required bool expected}) {
      check(find.text(user.fullName)).findsExactly(expected ? 1 : 0);
      check(findAvatarImage(user.userId)).findsExactly(expected ? 1 : 0);
    }

    testWidgets('user options appear, disappear, and change correctly', (tester) async {
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
      checkUserShown(user1, expected: false);
      checkUserShown(user2, expected: true);
      checkUserShown(user3, expected: true);

      // Finishing autocomplete updates compose box; causes options to disappear
      await tester.tap(find.text('User Three'));
      await tester.pump();
      check(tester.widget<TextField>(composeInputFinder).controller!.text)
        .contains(userMention(user3, users: store));
      checkUserShown(user1, expected: false);
      checkUserShown(user2, expected: false);
      checkUserShown(user3, expected: false);

      // Then a new autocomplete intent brings up options again
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @user tw');
      await tester.enterText(composeInputFinder, 'hello @user two');
      await tester.pumpAndSettle(); // async computation; options appear
      checkUserShown(user2, expected: true);

      // Removing autocomplete intent causes options to disappear
      // TODO(#226): Remove one of these edits when this bug is fixed.
      await tester.enterText(composeInputFinder, '');
      await tester.enterText(composeInputFinder, ' ');
      checkUserShown(user1, expected: false);
      checkUserShown(user2, expected: false);
      checkUserShown(user3, expected: false);

      debugNetworkImageHttpClientProvider = null;
    });

    group('User status', () {
      void checkFindsStatusEmoji(WidgetTester tester, Finder emojiFinder) {
        final statusEmojiFinder = find.ancestor(of: emojiFinder,
          matching: find.byType(UserStatusEmoji));
        check(statusEmojiFinder).findsOne();
        check(tester.widget<UserStatusEmoji>(statusEmojiFinder)
          .animationMode).equals(ImageAnimationMode.animateNever);
        check(find.ancestor(of: statusEmojiFinder,
          matching: find.byType(MentionAutocompleteItem))).findsOne();
      }

      testWidgets('emoji & text are set -> emoji is displayed, text is not', (tester) async {
        final user = eg.user(fullName: 'User');
        final composeInputFinder = await setupToComposeInput(tester, users: [user]);
        await store.changeUserStatus(user.userId, UserStatusChange(
          text: OptionSome('Busy'),
          emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
            emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
        await tester.pump();

        // // TODO(#226): Remove this extra edit when this bug is fixed.
        await tester.enterText(composeInputFinder, 'hello @u');
        await tester.enterText(composeInputFinder, 'hello @');
        await tester.pumpAndSettle(); // async computation; options appear

        checkFindsStatusEmoji(tester, find.text('\u{1f6e0}'));
        check(find.textContaining('Busy')).findsNothing();

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('emoji is not set, text is set -> text is not displayed', (tester) async {
        final user = eg.user(fullName: 'User');
        final composeInputFinder = await setupToComposeInput(tester, users: [user]);
        await store.changeUserStatus(user.userId, UserStatusChange(
          text: OptionSome('Busy'), emoji: OptionNone()));
        await tester.pump();

        // // TODO(#226): Remove this extra edit when this bug is fixed.
        await tester.enterText(composeInputFinder, 'hello @u');
        await tester.enterText(composeInputFinder, 'hello @');
        await tester.pumpAndSettle(); // async computation; options appear

        check(find.textContaining('Busy')).findsNothing();

        debugNetworkImageHttpClientProvider = null;
      });
    });

    void checkWildcardShown(WildcardMentionOption wildcard, {required bool expected}) {
      check(find.text(wildcard.canonicalString)).findsExactly(expected ? 1 : 0);
    }

    testWidgets('wildcard options appear, disappear, and change correctly', (tester) async {
      final composeInputFinder = await setupToComposeInput(tester,
        narrow: const ChannelNarrow(1));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      // Options are filtered correctly for query
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(composeInputFinder, 'hello @');
      await tester.enterText(composeInputFinder, 'hello @c');
      await tester.pumpAndSettle(); // async computation; options appear

      checkWildcardShown(WildcardMentionOption.channel, expected: true);
      checkWildcardShown(WildcardMentionOption.topic, expected: true);
      checkWildcardShown(WildcardMentionOption.all, expected: false);
      checkWildcardShown(WildcardMentionOption.everyone, expected: false);
      checkWildcardShown(WildcardMentionOption.stream, expected: false);

      // Finishing autocomplete updates compose box; causes options to disappear
      await tester.tap(find.text(WildcardMentionOption.channel.canonicalString));
      await tester.pump();
      check(tester.widget<TextField>(composeInputFinder).controller!.text)
        .contains(wildcardMention(WildcardMentionOption.channel, store: store));
      checkWildcardShown(WildcardMentionOption.channel, expected: false);
      checkWildcardShown(WildcardMentionOption.topic, expected: false);
      checkWildcardShown(WildcardMentionOption.all, expected: false);
      checkWildcardShown(WildcardMentionOption.everyone, expected: false);
      checkWildcardShown(WildcardMentionOption.stream, expected: false);

      debugNetworkImageHttpClientProvider = null;
    });

    group('sublabel', () {
      Finder findLabelsForItem({required Finder itemFinder}) {
        final itemColumn = find.ancestor(
          of: itemFinder,
          matching: find.byType(Column),
        ).first;
        return find.descendant(of: itemColumn, matching: find.byType(Text));
      }

      testWidgets('no sublabel when delivery email is unavailable', (tester) async {
        final user = eg.user(fullName: 'User One', deliveryEmail: null);
        final composeInputFinder = await setupToComposeInput(tester, users: [user]);

        // TODO(#226): Remove this extra edit when this bug is fixed.
        await tester.enterText(composeInputFinder, 'hello @user ');
        await tester.enterText(composeInputFinder, 'hello @user o');
        await tester.pumpAndSettle(); // async computation; options appear

        checkUserShown(user, expected: true);
        check(find.text(user.email)).findsNothing();
        check(findLabelsForItem(
          itemFinder: find.text(user.fullName))).findsOne();

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('show sublabel when delivery email is available', (tester) async {
        final user = eg.user(fullName: 'User One', deliveryEmail: 'email1@email.com');
        final composeInputFinder = await setupToComposeInput(tester, users: [user]);

        // TODO(#226): Remove this extra edit when this bug is fixed.
        await tester.enterText(composeInputFinder, 'hello @user ');
        await tester.enterText(composeInputFinder, 'hello @user o');
        await tester.pumpAndSettle(); // async computation; options appear

        checkUserShown(user, expected: true);
        check(find.text(user.deliveryEmail!)).findsOne();
        check(findLabelsForItem(
          itemFinder: find.text(user.fullName))).findsExactly(2);

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('show sublabel for wildcard mention items', (tester) async {
        final composeInputFinder = await setupToComposeInput(tester,
          narrow: const ChannelNarrow(1));

        // TODO(#226): Remove this extra edit when this bug is fixed.
        await tester.enterText(composeInputFinder, '@chann');
        await tester.enterText(composeInputFinder, '@channe');
        await tester.pumpAndSettle(); // async computation; options appear

        checkWildcardShown(WildcardMentionOption.channel, expected: true);
        check(find.text('Notify channel')).findsOne();
        check(findLabelsForItem(
          itemFinder: find.text('channel'))).findsExactly(2);

        debugNetworkImageHttpClientProvider = null;
      });
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
    testWidgets('options appear, disappear, and change correctly', (WidgetTester tester) async {
      final topic1 = eg.getChannelTopicsEntry(maxId: 1, name: 'Topic one');
      final topic2 = eg.getChannelTopicsEntry(maxId: 2, name: 'Topic two');
      final topic3 = eg.getChannelTopicsEntry(maxId: 3, name: 'Topic three');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic1, topic2, topic3]);

      // Options are filtered correctly for query
      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(topicInputFinder, 'Topic');
      await tester.enterText(topicInputFinder, 'Topic T');
      await tester.pumpAndSettle();

      // "topic three" and "topic two" appear, but not "topic one"
      check(find.text('Topic one'  )).findsNothing();
      check(find.text('Topic two'  )).findsOne();
      check(find.text('Topic three')).findsOne();

      // Finishing autocomplete updates topic box; causes options to disappear
      await tester.tap(find.text('Topic three'));
      await tester.pumpAndSettle();
      check(tester.widget<TextField>(topicInputFinder).controller!.text)
        .equals(topic3.name.displayName!);
      check(find.text('Topic one'  )).findsNothing();
      check(find.text('Topic two'  )).findsNothing();
      check(find.text('Topic three')).findsOne(); // shown in `_TopicInput` once

      // Then a new autocomplete intent brings up options again
      await tester.enterText(topicInputFinder, 'Topic');
      await tester.enterText(topicInputFinder, 'Topic T');
      await tester.pumpAndSettle();
      check(find.text('Topic two')).findsOne();
    });

    testWidgets('text selection is reset on choosing an option', (tester) async {
      // TODO test also that composing region gets reset.
      //   (Just adding it to the updateEditingValue call below doesn't seem
      //   to suffice to set it up; the controller value after the pump still
      //   has empty composing region, so there's nothing to check after tap.)

      final topic = eg.getChannelTopicsEntry(name: 'some topic');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic]);
      final controller = tester.widget<TextField>(topicInputFinder).controller!;

      await tester.enterText(topicInputFinder, 'so');
      await tester.enterText(topicInputFinder, 'some');
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'some',
        selection: TextSelection(baseOffset: 1, extentOffset: 3)));
      await tester.pump();
      // Add an extra pump to account for any potential frame delays introduced
      // by the post frame callback in RawAutocomplete's implementation.
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

    testWidgets('display realmEmptyTopicDisplayName for empty topic', (tester) async {
      final topic = eg.getChannelTopicsEntry(name: '');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic],
        realmEmptyTopicDisplayName: 'some display name');

      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(topicInputFinder, ' ');
      await tester.enterText(topicInputFinder, '');
      await tester.pumpAndSettle();

      check(find.text('some display name')).findsOne();
    });

    testWidgets('match realmEmptyTopicDisplayName in autocomplete', (tester) async {
      final topic = eg.getChannelTopicsEntry(name: '');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic],
        realmEmptyTopicDisplayName: 'general chat');

      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(topicInputFinder, 'general ch');
      await tester.enterText(topicInputFinder, 'general cha');
      await tester.pumpAndSettle();

      check(find.text('general chat')).findsOne();
    });

    testWidgets('autocomplete to realmEmptyTopicDisplayName sets topic to empty string', (tester) async {
      final topic = eg.getChannelTopicsEntry(name: '');
      final topicInputFinder = await setupToTopicInput(tester, topics: [topic],
        realmEmptyTopicDisplayName: 'general chat');
      final controller = tester.widget<TextField>(topicInputFinder).controller!;

      // TODO(#226): Remove this extra edit when this bug is fixed.
      await tester.enterText(topicInputFinder, 'general ch');
      await tester.enterText(topicInputFinder, 'general cha');
      await tester.pumpAndSettle();

      await tester.tap(find.text('general chat'));
      await tester.pump(Duration.zero);
      check(controller.value).text.equals('');
    });
  });
}
