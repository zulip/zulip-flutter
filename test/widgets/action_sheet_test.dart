import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/store.dart';
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import 'package:zulip/widgets/theme.dart';
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

/// Simulates loading a [MessageListPage] and long-pressing on [message].
Future<void> setupToMessageActionSheet(WidgetTester tester, {
  required Message message,
  required Narrow narrow,
}) async {
  addTearDown(testBinding.reset);

  await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  await store.addUser(eg.user(userId: message.senderId));
  if (message is StreamMessage) {
    final stream = eg.stream(streamId: message.streamId);
    await store.addStream(stream);
    await store.addSubscription(eg.subscription(stream));
  }
  final connection = store.connection as FakeApiConnection;

  // prepare message list data
  connection.prepare(json: GetMessagesResult(
    anchor: message.id,
    foundNewest: true,
    foundOldest: true,
    foundAnchor: true,
    historyLimited: false,
    messages: [message],
  ).toJson());

  await tester.pumpWidget(Builder(builder: (context) =>
    MaterialApp(
      theme: zulipThemeData(context),
      localizationsDelegates: ZulipLocalizations.localizationsDelegates,
      supportedLocales: ZulipLocalizations.supportedLocales,
      home: GlobalStoreWidget(
        child: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: MessageListPage(narrow: narrow))))));

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

  void prepareRawContentResponseSuccess(PerAccountStore store, {
    required Message message,
    required String rawContent,
  }) {
    // Prepare fetch-raw-Markdown response
    // TODO: Message should really only differ from `message`
    //   in its content / content_type, not in `id` or anything else.
    (store.connection as FakeApiConnection).prepare(json:
      GetMessageResult(message: eg.streamMessage(contentMarkdown: rawContent)).toJson());
  }

  void prepareRawContentResponseError(PerAccountStore store) {
    final fakeResponseJson = {
      'code': 'BAD_REQUEST',
      'msg': 'Invalid message(s)',
      'result': 'error',
    };
    (store.connection as FakeApiConnection).prepare(httpStatus: 400, json: fakeResponseJson);
  }

  group('AddThumbsUpButton', () {
    Future<void> tapButton(WidgetTester tester) async {
      await tester.ensureVisible(find.byIcon(Icons.add_reaction_outlined, skipOffstage: false));
      await tester.tap(find.byIcon(Icons.add_reaction_outlined));
      await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
    }

    testWidgets('success', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final connection = store.connection as FakeApiConnection;
      connection.prepare(json: {});
      await tapButton(tester);
      await tester.pump(Duration.zero);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/${message.id}/reactions')
        ..bodyFields.deepEquals({
            'reaction_type': 'unicode_emoji',
            'emoji_code': '1f44d',
            'emoji_name': '+1',
          });
    });

    testWidgets('request has an error', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final connection = store.connection as FakeApiConnection;

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
  });

  group('StarButton', () {
    Future<void> tapButton(WidgetTester tester) async {
      // Starred messages include the same icon so we need to
      // match only by descendants of [BottomSheet].
      await tester.ensureVisible(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(ZulipIcons.star_filled, skipOffstage: false)));
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(ZulipIcons.star_filled)));
      await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
    }

    testWidgets('star success', (WidgetTester tester) async {
      final message = eg.streamMessage(flags: []);
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final connection = store.connection as FakeApiConnection;
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

    testWidgets('unstar success', (WidgetTester tester) async {
      final message = eg.streamMessage(flags: [MessageFlag.starred]);
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final connection = store.connection as FakeApiConnection;
      connection.prepare(json: {});
      await tapButton(tester);
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

    testWidgets('star request has an error', (WidgetTester tester) async {
      final message = eg.streamMessage(flags: []);
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

      final connection = store.connection as FakeApiConnection;

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

    testWidgets('unstar request has an error', (WidgetTester tester) async {
      final message = eg.streamMessage(flags: [MessageFlag.starred]);
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

      final connection = store.connection as FakeApiConnection;

      connection.prepare(httpStatus: 400, json: {
        'code': 'BAD_REQUEST',
        'msg': 'Invalid message(s)',
        'result': 'error',
      });
      await tapButton(tester);
      await tester.pump(Duration.zero); // error arrives; error dialog shows

      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorUnstarMessageFailedTitle,
        expectedMessage: 'Invalid message(s)')));
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
      await tester.ensureVisible(find.byIcon(Icons.adaptive.share, skipOffstage: false));
      await tester.tap(find.byIcon(Icons.adaptive.share));
      await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
    }

    testWidgets('request succeeds; sharing succeeds', (WidgetTester tester) async {
      final mockSharePlus = setupMockSharePlus();
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      prepareRawContentResponseSuccess(store, message: message, rawContent: 'Hello world');
      await tapShareButton(tester);
      await tester.pump(Duration.zero);
      check(mockSharePlus.sharedString).equals('Hello world');
    });

    testWidgets('request succeeds; sharing fails', (WidgetTester tester) async {
      final mockSharePlus = setupMockSharePlus();
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      prepareRawContentResponseSuccess(store, message: message, rawContent: 'Hello world');
      mockSharePlus.resultString = 'dev.fluttercommunity.plus/share/unavailable';
      await tapShareButton(tester);
      await tester.pump(Duration.zero);
      check(mockSharePlus.sharedString).equals('Hello world');
      await tester.pump();
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: 'Sharing failed')));
    });

    testWidgets('request has an error', (WidgetTester tester) async {
      final mockSharePlus = setupMockSharePlus();
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      prepareRawContentResponseError(store);
      await tapShareButton(tester);
      await tester.pump(Duration.zero); // error arrives; error dialog shows

      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: 'Sharing failed',
        expectedMessage: 'That message does not seem to exist.',
      )));

      check(mockSharePlus.sharedString).isNull();
    });
  });

  group('QuoteAndReplyButton', () {
    ComposeBoxController? findComposeBoxController(WidgetTester tester) {
      return tester.widget<ComposeBox>(find.byType(ComposeBox))
        .controllerKey?.currentState;
    }

    Widget? findQuoteAndReplyButton(WidgetTester tester) {
      return tester.widgetList(find.byIcon(Icons.format_quote_outlined)).singleOrNull;
    }

    /// Simulates tapping the quote-and-reply button in the message action sheet.
    ///
    /// Checks that there is a quote-and-reply button.
    Future<void> tapQuoteAndReplyButton(WidgetTester tester) async {
      await tester.ensureVisible(find.byIcon(Icons.format_quote_outlined, skipOffstage: false));
      final quoteAndReplyButton = findQuoteAndReplyButton(tester);
      check(quoteAndReplyButton).isNotNull();
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

    testWidgets('in stream narrow', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: StreamNarrow(message.streamId));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final composeBoxController = findComposeBoxController(tester)!;
      final contentController = composeBoxController.contentController;

      final valueBefore = contentController.value;
      prepareRawContentResponseSuccess(store, message: message, rawContent: 'Hello world');
      await tapQuoteAndReplyButton(tester);
      checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
      await tester.pump(Duration.zero); // message is fetched; compose box updates
      check(composeBoxController.contentFocusNode.hasFocus).isTrue();
      checkSuccessState(store, contentController,
        valueBefore: valueBefore, message: message, rawContent: 'Hello world');
    });

    testWidgets('in topic narrow', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final composeBoxController = findComposeBoxController(tester)!;
      final contentController = composeBoxController.contentController;

      final valueBefore = contentController.value;
      prepareRawContentResponseSuccess(store, message: message, rawContent: 'Hello world');
      await tapQuoteAndReplyButton(tester);
      checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
      await tester.pump(Duration.zero); // message is fetched; compose box updates
      check(composeBoxController.contentFocusNode.hasFocus).isTrue();
      checkSuccessState(store, contentController,
        valueBefore: valueBefore, message: message, rawContent: 'Hello world');
    });

    testWidgets('in DM narrow', (WidgetTester tester) async {
      final message = eg.dmMessage(from: eg.selfUser, to: [eg.otherUser]);
      await setupToMessageActionSheet(tester,
        message: message, narrow: DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final composeBoxController = findComposeBoxController(tester)!;
      final contentController = composeBoxController.contentController;

      final valueBefore = contentController.value;
      prepareRawContentResponseSuccess(store, message: message, rawContent: 'Hello world');
      await tapQuoteAndReplyButton(tester);
      checkLoadingState(store, contentController, valueBefore: valueBefore, message: message);
      await tester.pump(Duration.zero); // message is fetched; compose box updates
      check(composeBoxController.contentFocusNode.hasFocus).isTrue();
      checkSuccessState(store, contentController,
        valueBefore: valueBefore, message: message, rawContent: 'Hello world');
    });

    testWidgets('request has an error', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final composeBoxController = findComposeBoxController(tester)!;
      final contentController = composeBoxController.contentController;

      final valueBefore = contentController.value = TextEditingValue.empty;
      prepareRawContentResponseError(store);
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

    testWidgets('not offered in CombinedFeedNarrow (composing to reply is not yet supported)', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: const CombinedFeedNarrow());
      check(findQuoteAndReplyButton(tester)).isNull();
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
      await tester.ensureVisible(find.byIcon(Icons.copy, skipOffstage: false));
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback: flutter/flutter@e4a39fa2e
    }

    testWidgets('success', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      prepareRawContentResponseSuccess(store, message: message, rawContent: 'Hello world');
      await tapCopyMessageTextButton(tester);
      await tester.pump(Duration.zero);
      check(await Clipboard.getData('text/plain')).isNotNull().text.equals('Hello world');
    });

    testWidgets('request has an error', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: TopicNarrow.ofMessage(message));
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      prepareRawContentResponseError(store);
      await tapCopyMessageTextButton(tester);
      await tester.pump(Duration.zero); // error arrives; error dialog shows

      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: 'Copying failed',
        expectedMessage: 'That message does not seem to exist.',
      )));
      check(await Clipboard.getData('text/plain')).isNull();
    });
  });
}
