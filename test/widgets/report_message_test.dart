import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/message_list.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();
  MessageListPage.debugEnableMarkReadOnScroll = false;

  late PerAccountStore store;
  late FakeApiConnection connection;

  group('ReportMessageDialog', () {
    Future<void> showFromMessageList(WidgetTester tester, {
      required StreamMessage message,
      _ReportTypeSource reportTypeSource = .boring,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
        realmModerationRequestChannelId: 1,
        serverReportMessageTypes: switch (reportTypeSource) {
          .boring => [
            ReportMessageType(key: 'spam', name: 'Spam'),
            ReportMessageType(key: 'harassment', name: 'Harassment'),
            ReportMessageType(key: 'other', name: 'Other'),
          ],
          .spanish => [
            ReportMessageType(key: 'spam', name: 'Correo no deseado'),
            ReportMessageType(key: 'other', name: 'Otro'),
          ],
          .legacy => null,
        },
      ));
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;
      await store.addUser(eg.user(userId: message.senderId));
      final channel = eg.stream(streamId: message.streamId);
      await store.addStream(channel);
      await store.addSubscription(eg.subscription(channel));

      connection.prepare(json: eg.newestGetMessagesResult(
        foundOldest: true, messages: [message]).toJson());
      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
        child: MessageListPage(initNarrow: TopicNarrow.ofMessage(message))));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(MessageContent));
      await tester.pump(const Duration(milliseconds: 250));
      check(find.byType(BottomSheet)).findsOne();

      final reportButton = find.descendant(
        of: find.byType(BottomSheet), matching: find.text('Report message'));
      await tester.ensureVisible(reportButton);
      await tester.tap(reportButton);
      await tester.pump(); // [MenuItemButton.onPressed] called in a post-frame callback
      await tester.pump(); // showDialog
    }

    Future<void> selectType(WidgetTester tester, String label) async {
      await tester.tap(find.byType(DropdownMenuFormField<String>));
      await tester.pump();
      await tester.tap(find.text(label).last);
      await tester.pump();
    }

    Future<void> tapSubmit(WidgetTester tester, {
      bool prepareSuccess = false,
      bool prepareError = false,
    }) async {
      assert(!prepareSuccess || !prepareError);
      if (prepareSuccess) {
        connection.prepare(json: {});
      } else if (prepareError) {
        connection.prepare(apiException: eg.apiBadRequest());
      }
      await tester.tap(find.text('Submit'));
      await tester.pump(Duration.zero);
    }

    void checkRequest(Message message, {
      required Map<String, String> bodyFields,
    }) {
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/${message.id}/report')
        ..bodyFields.deepEquals(bodyFields);
    }

    testWidgets('smoke', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);
      await selectType(tester, 'Spam');
      await tapSubmit(tester, prepareSuccess: true);
      checkRequest(message, bodyFields: {'report_type': 'spam'});
    });

    testWidgets('server-provided report types in Spanish', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message,
        reportTypeSource: .spanish);
      await selectType(tester, 'Correo no deseado');
      await tapSubmit(tester, prepareSuccess: true);
      checkRequest(message, bodyFields: {'report_type': 'spam'});
    });

    testWidgets('legacy: no server_report_message_types', (tester) async {
      // TODO(server-12) remove this test
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message,
        reportTypeSource: .legacy);
      await selectType(tester, 'Spam');
      await tapSubmit(tester, prepareSuccess: true);
      checkRequest(message, bodyFields: {'report_type': 'spam'});
    });

    testWidgets('submit with description', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);
      await selectType(tester, 'Other');
      await tester.enterText(find.byType(TextFormField), 'some context');
      await tester.pump();
      await tapSubmit(tester, prepareSuccess: true);
      checkRequest(message, bodyFields: {
        'report_type': 'other',
        'description': 'some context',
      });
    });

    testWidgets('submit with no type selected shows error on dropdown', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);

      check(find.text('Please select a reason.')).findsNothing();

      // Tap submit without selecting a type.
      await tapSubmit(tester);
      check(find.text('Please select a reason.')).findsOne();

      // Select a type; error clears, and submit succeeds.
      await selectType(tester, 'Spam');
      await tester.pump();
      check(find.text('Please select a reason.')).findsNothing();
      await tapSubmit(tester, prepareSuccess: true);
      checkRequest(message, bodyFields: {'report_type': 'spam'});
    });

    testWidgets('"Other" type with no description shows error on text field', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);
      await selectType(tester, 'Other');

      final errorText = 'Please provide details.';
      check(find.text(errorText)).findsNothing();

      // Tap submit without entering a description.
      await tapSubmit(tester);
      check(find.text(errorText)).findsOne();

      // Enter description; error clears, and submit succeeds.
      await tester.enterText(find.byType(TextFormField), 'some context');
      await tester.pump();
      check(find.text(errorText)).findsNothing();
      await tapSubmit(tester, prepareSuccess: true);
      checkRequest(message, bodyFields: {
        'report_type': 'other',
        'description': 'some context',
      });
    });

    testWidgets('request fails: shows error dialog', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);
      await selectType(tester, 'Spam');
      await tapSubmit(tester, prepareError: true);
      checkErrorDialog(tester, allowOtherAlertDialogs: true,
        expectedTitle: 'Failed to report message');
    });

    testWidgets('success: shows snackbar', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);
      await selectType(tester, 'Spam');
      await tapSubmit(tester, prepareSuccess: true);
      check(find.text('Message reported')).findsOne();
    });

    testWidgets('message deleted while dialog open', (tester) async {
      final message = eg.streamMessage(flags: []);
      await showFromMessageList(tester, message: message);

      // Delete the message while the dialog is open.
      await store.handleEvent(eg.deleteMessageEvent([message]));
      await tester.pump();

      // The dialog is still showing and functional.
      // We expect an error from the server, and we show that instead of failing
      // silently (e.g. as a consequence of some message-related BuildContext
      // being unmounted.)
      await selectType(tester, 'Spam');
      await tapSubmit(tester, prepareError: true);
      checkErrorDialog(tester, allowOtherAlertDialogs: true,
        expectedTitle: 'Failed to report message');
    });
  });
}

enum _ReportTypeSource {
  /// Server-provided report types with boring English names.
  boring,

  /// Server-provided report types with Spanish names.
  spanish,

  /// No server-provided report types; uses [LegacyReportMessageType].
  legacy,
}
