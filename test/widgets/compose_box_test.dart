import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../stdlib_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<GlobalKey<ComposeBoxController>> prepareComposeBox(WidgetTester tester, Narrow narrow) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
    connection = store.connection as FakeApiConnection;

    final controllerKey = GlobalKey<ComposeBoxController>();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        home: GlobalStoreWidget(
          child: PerAccountStoreWidget(
            accountId: eg.selfAccount.id,
            child: ComposeBox(controllerKey: controllerKey, narrow: narrow)))));
    await tester.pumpAndSettle();

    return controllerKey;
  }

  group('ComposeContentController', () {
    group('insertPadded', () {
      // Like `parseMarkedText` in test/model/autocomplete_test.dart,
      //   but a bit different -- could maybe deduplicate some.
      parseMarkedText(String markedText) {
        final textBuffer = StringBuffer();
        int? insertionPoint;
        int i = 0;
        for (final char in markedText.codeUnits) {
          if (char == 94 /* ^ */) {
            if (insertionPoint != null) {
              throw Exception('Test error: too many ^ in input');
            }
            insertionPoint = i;
            continue;
          }
          textBuffer.writeCharCode(char);
          i++;
        }
        if (insertionPoint == null) {
          throw Exception('Test error: expected ^ in input');
        }
        return TextEditingValue(text: textBuffer.toString(), selection: TextSelection.collapsed(offset: insertionPoint));
      }

      /// Test the given `insertPadded` call, in a convenient format.
      ///
      /// In valueBefore, represent the insertion point as "^".
      /// In expectedValue, represent the collapsed selection as "^".
      testInsertPadded(String description, String valueBefore, String textToInsert, String expectedValue) {
        test(description, () {
          final controller = ComposeContentController();
          controller.value = parseMarkedText(valueBefore);
          controller.insertPadded(textToInsert);
          check(controller.value).equals(parseMarkedText(expectedValue));
        });
      }

      // TODO(?) exercise the part of insertPadded that chooses the insertion
      //   point based on [TextEditingValue.selection], which may be collapsed,
      //   expanded, or null (what they call !TextSelection.isValid).

      testInsertPadded('empty; insert one line',
        '^', 'a\n',    'a\n\n^');
      testInsertPadded('empty; insert two lines',
        '^', 'a\nb\n', 'a\nb\n\n^');

      group('insert at end', () {
        testInsertPadded('one empty line; insert one line',
          '\n^',     'a\n',    '\na\n\n^');
        testInsertPadded('two empty lines; insert one line',
          '\n\n^',   'a\n',    '\n\na\n\n^');
        testInsertPadded('one line, incomplete; insert one line',
          'a^',      'b\n',    'a\n\nb\n\n^');
        testInsertPadded('one line, complete; insert one line',
          'a\n^',    'b\n',    'a\n\nb\n\n^');
        testInsertPadded('multiple lines, last is incomplete; insert one line',
          'a\nb^',   'c\n',    'a\nb\n\nc\n\n^');
        testInsertPadded('multiple lines, last is complete; insert one line',
          'a\nb\n^', 'c\n',    'a\nb\n\nc\n\n^');
        testInsertPadded('multiple lines, last is complete; insert two lines',
          'a\nb\n^', 'c\nd\n', 'a\nb\n\nc\nd\n\n^');
      });

      group('insert at start', () {
        testInsertPadded('one empty line; insert one line',
          '^\n',     'a\n',    'a\n\n^');
        testInsertPadded('two empty lines; insert one line',
          '^\n\n',   'a\n',    'a\n\n^\n');
        testInsertPadded('one line, incomplete; insert one line',
          '^a',      'b\n',    'b\n\n^a');
        testInsertPadded('one line, complete; insert one line',
          '^a\n',    'b\n',    'b\n\n^a\n');
        testInsertPadded('multiple lines, last is incomplete; insert one line',
          '^a\nb',   'c\n',    'c\n\n^a\nb');
        testInsertPadded('multiple lines, last is complete; insert one line',
          '^a\nb\n', 'c\n',    'c\n\n^a\nb\n');
        testInsertPadded('multiple lines, last is complete; insert two lines',
          '^a\nb\n', 'c\nd\n', 'c\nd\n\n^a\nb\n');
      });

      group('insert in middle', () {
        testInsertPadded('middle of line',
          'a^a\n',       'b\n', 'a\n\nb\n\n^a\n');
        testInsertPadded('start of non-empty line, after empty line',
          'b\n\n^a\n',   'c\n', 'b\n\nc\n\n^a\n');
        testInsertPadded('end of non-empty line, before non-empty line',
          'a^\nb\n',     'c\n', 'a\n\nc\n\n^b\n');
        testInsertPadded('start of non-empty line, after non-empty line',
          'a\n^b\n',     'c\n', 'a\n\nc\n\n^b\n');
        testInsertPadded('text start; one empty line; insertion point; one empty line',
          '\n^\n',       'a\n', '\na\n\n^');
        testInsertPadded('text start; one empty line; insertion point; two empty lines',
          '\n^\n\n',     'a\n', '\na\n\n^\n');
        testInsertPadded('text start; two empty lines; insertion point; one empty line',
          '\n\n^\n',     'a\n', '\n\na\n\n^');
        testInsertPadded('text start; two empty lines; insertion point; two empty lines',
          '\n\n^\n\n',   'a\n', '\n\na\n\n^\n');
      });
    });
  });

  group('ComposeBox textCapitalization', () {
    void checkComposeBoxTextFields(WidgetTester tester, {
      required GlobalKey<ComposeBoxController> controllerKey,
      required bool expectTopicTextField,
    }) {
      final composeBoxController = controllerKey.currentState!;

      final topicTextField = tester.widgetList<TextField>(find.byWidgetPredicate(
        (widget) => widget is TextField
          && widget.controller == composeBoxController.topicController)).singleOrNull;
      if (expectTopicTextField) {
        check(topicTextField).isNotNull()
          .textCapitalization.equals(TextCapitalization.none);
      } else {
        check(topicTextField).isNull();
      }

      final contentTextField = tester.widget<TextField>(find.byWidgetPredicate(
        (widget) => widget is TextField
          && widget.controller == composeBoxController.contentController));
      check(contentTextField)
        .textCapitalization.equals(TextCapitalization.sentences);
    }

    testWidgets('_StreamComposeBox', (tester) async {
      final key = await prepareComposeBox(tester,
        StreamNarrow(eg.stream().streamId));
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: true);
    });

    testWidgets('_FixedDestinationComposeBox', (tester) async {
      final key = await prepareComposeBox(tester,
        TopicNarrow.ofMessage(eg.streamMessage()));
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: false);
    });
  });

  group('message-send request response', () {
    Future<void> setupAndTapSend(WidgetTester tester, {
      required void Function(int messageId) prepareResponse,
    }) async {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepareComposeBox(tester, const TopicNarrow(123, 'some topic'));

      final contentInputFinder = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller is ComposeContentController);
      await tester.enterText(contentInputFinder, 'hello world');

      prepareResponse(456);
      await tester.tap(find.byTooltip(zulipLocalizations.composeBoxSendTooltip));
      await tester.pump(Duration.zero);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
            'type': 'stream',
            'to': '123',
            'topic': 'some topic',
            'content': 'hello world',
            'read_by_sender': 'true',
          });
    }

    testWidgets('success', (tester) async {
      await setupAndTapSend(tester, prepareResponse: (int messageId) {
        connection.prepare(json: SendMessageResult(id: messageId).toJson());
      });
      final errorDialogs = tester.widgetList(find.byType(AlertDialog));
      check(errorDialogs).isEmpty();
    });
  });
}
