import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/store.dart';
import '../api/fake_api.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import 'compose_box_checks.dart';
import 'dialog_checks.dart';

/// Simulates loading a [MessageListPage] and long-pressing on [message].
Future<void> setupToMessageActionSheet(WidgetTester tester, {
  required Message message,
  required Narrow narrow,
}) async {
  addTearDown(TestDataBinding.instance.reset);

  await TestDataBinding.instance.globalStore.add(eg.selfAccount, eg.initialSnapshot());
  final store = await TestDataBinding.instance.globalStore.perAccount(eg.selfAccount.id);
  store.addUser(eg.user(userId: message.senderId));
  if (message is StreamMessage) {
    store.addStream(eg.stream(streamId: message.streamId));
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

  await tester.pumpWidget(
    MaterialApp(
      home: GlobalStoreWidget(
        child: PerAccountStoreWidget(
          accountId: eg.selfAccount.id,
          child: MessageListPage(narrow: narrow)))));

  // global store, per-account store, and message list get loaded
  await tester.pumpAndSettle();

  // request the message action sheet
  await tester.longPress(find.byType(MessageContent));
  // sheet appears onscreen; default duration of bottom-sheet enter animation
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  TestDataBinding.ensureInitialized();

  group('QuoteAndReplyButton', () {
    ComposeBoxController? findComposeBoxController(WidgetTester tester) {
      return tester.widget<ComposeBox>(find.byType(ComposeBox))
        .controllerKey?.currentState;
    }

    Widget? findQuoteAndReplyButton(WidgetTester tester) {
      return tester.widgetList(find.byIcon(Icons.format_quote_outlined)).singleOrNull;
    }

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

    /// Simulates tapping the quote-and-reply button in the message action sheet.
    ///
    /// Checks that there is a quote-and-reply button.
    Future<void> tapQuoteAndReplyButton(WidgetTester tester) async {
      final quoteAndReplyButton = findQuoteAndReplyButton(tester);
      check(quoteAndReplyButton).isNotNull();
      await tester.tap(find.byWidget(quoteAndReplyButton!));
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
      check(contentController).not(it()..validationErrors.contains(ContentValidationError.quoteAndReplyInProgress));
    }

    testWidgets('in stream narrow', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: StreamNarrow(message.streamId));
      final store = await TestDataBinding.instance.globalStore.perAccount(eg.selfAccount.id);

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
      final store = await TestDataBinding.instance.globalStore.perAccount(eg.selfAccount.id);

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
      final store = await TestDataBinding.instance.globalStore.perAccount(eg.selfAccount.id);

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
      final store = await TestDataBinding.instance.globalStore.perAccount(eg.selfAccount.id);

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

    testWidgets('not offered in AllMessagesNarrow (composing to reply is not yet supported)', (WidgetTester tester) async {
      final message = eg.streamMessage();
      await setupToMessageActionSheet(tester, message: message, narrow: const AllMessagesNarrow());
      check(findQuoteAndReplyButton(tester)).isNull();
    });
  });
}
