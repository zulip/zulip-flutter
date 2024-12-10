import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/internal_link.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/action_sheet.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/emoji.dart';
import 'package:zulip/widgets/emoji_reaction.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import '../api/fake_api.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/emoji_test.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_clipboard.dart';
import '../test_images.dart';
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

  group('ReactionButtons', () {
    final popularCandidates = EmojiStore.popularEmojiCandidates;

    group('popular emoji reactions;', () {
      testWidgets('ensure all are shown', (tester) async {
        final message = eg.streamMessage();
        await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        // Ensure all popular emoji buttons are shown.
        final emojis = tester.widgetList<UnicodeEmojiWidget>(find.descendant(
          of: find.descendant(
            of: find.byType(ReactionButtons),
            matching: find.byType(InkWell)),
          matching: find.byType(UnicodeEmojiWidget)));
        check(emojis).deepEquals(popularCandidates.map<Condition<Object?>>((emoji) {
          final emojiDisplay = emoji.emojiDisplay as UnicodeEmojiDisplay;
          return (it) => it.isA<UnicodeEmojiWidget>()
            ..emojiDisplay.which((it) => it
              ..emojiName.equals(emojiDisplay.emojiName)
              ..emojiUnicode.equals(emojiDisplay.emojiUnicode));
        }));
      });

      for (final emoji in popularCandidates) {
        final emojiDisplay = emoji.emojiDisplay as UnicodeEmojiDisplay;

        Future<void> tapButton(WidgetTester tester) async {
          await tester.tap(find.descendant(
            of: find.descendant(
              of: find.descendant(
                of: find.byType(ReactionButtons),
                matching: find.byType(InkWell)),
              matching: find.byType(UnicodeEmojiWidget)),
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

    group('emoji picker;', () {
      Future<void> setupEmojiPicker(WidgetTester tester, {
        required Message message,
        required Narrow narrow,
      }) async {
        final httpClient = FakeImageHttpClient();
        debugNetworkImageHttpClientProvider = () => httpClient;
        httpClient.request.response
          ..statusCode = HttpStatus.ok
          ..content = kSolidBlueAvatar;

        await setupToMessageActionSheet(tester, message: message, narrow: narrow);
        store.setServerEmojiData(ServerEmojiData(codeToNames: {
          '1f4a4': ['zzz', 'sleepy'], // (just 'zzz' in real data)
        }));
        await store.handleEvent(RealmEmojiUpdateEvent(id: 1, realmEmoji: {
          '1': eg.realmEmojiItem(emojiCode: '1', emojiName: 'buzzing'),
        }));

        await tester.tap(find.ancestor(
          of: find.byIcon(ZulipIcons.chevron_right),
          matching: find.byType(InkWell)));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(EmojiPicker));
      }

      final searchFieldFinder = find.widgetWithText(TextField, 'Search emoji');

      Condition<Object?> conditionEmojiListEntry({
        required ReactionType emojiType,
        required String emojiCode,
        required String emojiName,
      }) {
        return (Subject<Object?> it) => it.isA<EmojiPickerListEntry>()
          ..emoji.which((it) => it
            ..emojiType.equals(emojiType)
            ..emojiCode.equals(emojiCode)
            ..emojiName.equals(emojiName));
      }

      List<Condition<Object?>> arePopularCandidates = popularCandidates.map((c) =>
        conditionEmojiListEntry(
          emojiType: c.emojiType,
          emojiCode: c.emojiCode,
          emojiName: c.emojiName)).toList();

      testWidgets('show, search', (tester) async {
        final message = eg.streamMessage();
        await setupEmojiPicker(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        check(tester.widgetList<EmojiPickerListEntry>(find.byType(EmojiPickerListEntry))).deepEquals([
          ...arePopularCandidates,
          conditionEmojiListEntry(
            emojiType: ReactionType.realmEmoji,
            emojiCode: '1',
            emojiName: 'buzzing'),
          conditionEmojiListEntry(
            emojiType: ReactionType.zulipExtraEmoji,
            emojiCode: 'zulip',
            emojiName: 'zulip'),
          conditionEmojiListEntry(
            emojiType: ReactionType.unicodeEmoji,
            emojiCode: '1f4a4',
            emojiName: 'zzz'),
        ]);

        tester.widget(searchFieldFinder);
        await tester.enterText(searchFieldFinder, 'z');
        await tester.pump();

        check(tester.widgetList<EmojiPickerListEntry>(find.byType(EmojiPickerListEntry))).deepEquals([
          conditionEmojiListEntry(
            emojiType: ReactionType.zulipExtraEmoji,
            emojiCode: 'zulip',
            emojiName: 'zulip'),
          conditionEmojiListEntry(
            emojiType: ReactionType.unicodeEmoji,
            emojiCode: '1f4a4',
            emojiName: 'zzz'),
          conditionEmojiListEntry(
            emojiType: ReactionType.realmEmoji,
            emojiCode: '1',
            emojiName: 'buzzing'),
        ]);

        tester.widget(searchFieldFinder);
        await tester.enterText(searchFieldFinder, 'zz');
        await tester.pump();

        check(tester.widgetList<EmojiPickerListEntry>(find.byType(EmojiPickerListEntry))).deepEquals([
          conditionEmojiListEntry(
            emojiType: ReactionType.unicodeEmoji,
            emojiCode: '1f4a4',
            emojiName: 'zzz'),
          conditionEmojiListEntry(
            emojiType: ReactionType.realmEmoji,
            emojiCode: '1',
            emojiName: 'buzzing'),
        ]);

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('adding success', (tester) async {
        final message = eg.streamMessage();
        await setupEmojiPicker(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        connection.prepare(json: {});
        await tester.tap(find.text('\u{1f4a4}')); // 'zzz' emoji
        await tester.pump(Duration.zero);

        check(connection.lastRequest).isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/messages/${message.id}/reactions')
          ..bodyFields.deepEquals({
              'reaction_type': 'unicode_emoji',
              'emoji_code': '1f4a4',
              'emoji_name': 'zzz',
            });

        debugNetworkImageHttpClientProvider = null;
      });

      testWidgets('request has an error', (tester) async {
        final message = eg.streamMessage();
        await setupEmojiPicker(tester, message: message, narrow: TopicNarrow.ofMessage(message));

        connection.prepare(httpStatus: 400, json: {
          'code': 'BAD_REQUEST',
          'msg': 'Invalid message(s)',
          'result': 'error',
        });
        await tester.tap(find.text('\u{1f4a4}')); // 'zzz' emoji
        await tester.pump(Duration.zero); // error arrives; error dialog shows

        await tester.tap(find.byWidget(checkErrorDialog(tester,
          expectedTitle: 'Adding reaction failed',
          expectedMessage: 'Invalid message(s)')));

        debugNetworkImageHttpClientProvider = null;
      });
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
        ..insertPadded(quoteAndReplyPlaceholder(store, message: message))
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
          newStreamId: newStream.streamId, newTopic: newTopic,
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
              jsonEncode(TopicNarrow(newStream.streamId, newTopic).apiEncode()));
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
}

extension UnicodeEmojiWidgetChecks on Subject<UnicodeEmojiWidget> {
  Subject<UnicodeEmojiDisplay> get emojiDisplay => has((x) => x.emojiDisplay, 'emojiDisplay');
}

extension EmojiPickerListItemChecks on Subject<EmojiPickerListEntry> {
  Subject<EmojiCandidate> get emoji => has((x) => x.emoji, 'emoji');
}
