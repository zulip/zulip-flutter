import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/compose_box.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  Future<GlobalKey<ComposeBoxController>> prepareComposeBox(WidgetTester tester,
      {required Narrow narrow, List<User> users = const []}) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    await store.addUsers([eg.selfUser, ...users]);
    connection = store.connection as FakeApiConnection;

    if (narrow is ChannelNarrow) {
      // Ensure topics are loaded before testing actual logic.
      connection.prepare(body:
        jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
    }
    final controllerKey = GlobalKey<ComposeBoxController>();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: ComposeBox(controllerKey: controllerKey, narrow: narrow)));
    await tester.pumpAndSettle();

    return controllerKey;
  }

  group('ComposeContentController', () {
    group('insertPadded', () {
      // Like `parseMarkedText` in test/model/autocomplete_test.dart,
      //   but a bit different -- could maybe deduplicate some.
      TextEditingValue parseMarkedText(String markedText) {
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
      void testInsertPadded(String description, String valueBefore, String textToInsert, String expectedValue) {
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
        narrow: ChannelNarrow(eg.stream().streamId));
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: true);
    });

    testWidgets('_FixedDestinationComposeBox', (tester) async {
      final key = await prepareComposeBox(tester,
        narrow: TopicNarrow.ofMessage(eg.streamMessage()));
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: false);
    });
  });

  group('message-send request response', () {
    Future<void> setupAndTapSend(WidgetTester tester, {
      required void Function(int messageId) prepareResponse,
    }) async {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepareComposeBox(tester, narrow: const TopicNarrow(123, 'some topic'));

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

    testWidgets('ZulipApiException', (tester) async {
      await setupAndTapSend(tester, prepareResponse: (message) {
        connection.prepare(
          httpStatus: 400,
          json: {
            'result': 'error',
            'code': 'BAD_REQUEST',
            'msg': 'You do not have permission to initiate direct message conversations.',
          });
      });
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorMessageNotSent,
        expectedMessage: zulipLocalizations.errorServerMessage(
          'You do not have permission to initiate direct message conversations.'),
      )));
    });
  });

  group('uploads', () {
    void checkAppearsLoading(WidgetTester tester, bool expected) {
      final sendButtonElement = tester.element(find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton)));
      final sendButtonWidget = sendButtonElement.widget as IconButton;
      final colorScheme = Theme.of(sendButtonElement).colorScheme;
      final expectedForegroundColor = expected
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onPrimary;
      check(sendButtonWidget.color).isNotNull().isSameColorAs(expectedForegroundColor);
    }

    group('attach from media library', () {
      testWidgets('success', (tester) async {
        final controllerKey = await prepareComposeBox(tester, narrow: ChannelNarrow(eg.stream().streamId));
        final composeBoxController = controllerKey.currentState!;

        // (When we check that the send button looks disabled, it should be because
        // the file is uploading, not a pre-existing reason.)
        composeBoxController.topicController!.value = const TextEditingValue(text: 'some topic');
        composeBoxController.contentController.value = const TextEditingValue(text: 'see image: ');
        await tester.pump();
        checkAppearsLoading(tester, false);

        testBinding.pickFilesResult = FilePickerResult([PlatformFile(
          readStream: Stream.fromIterable(['asdf'.codeUnits]),
          // TODO test inference of MIME type from initial bytes, when
          //   it can't be inferred from path
          path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
          name: 'image.jpg',
          size: 12345,
        )]);
        connection.prepare(delay: const Duration(seconds: 1), json:
          UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());

        await tester.tap(find.byIcon(Icons.image));
        await tester.pump();
        final call = testBinding.takePickFilesCalls().single;
        check(call.allowMultiple).equals(true);
        check(call.type).equals(FileType.media);

        final errorDialogs = tester.widgetList(find.byType(AlertDialog));
        check(errorDialogs).isEmpty();

        check(composeBoxController.contentController.text)
          .equals('see image: [Uploading image.jpg…]()\n\n');
        // (the request is checked more thoroughly in API tests)
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..files.single.which((it) => it
            ..field.equals('file')
            ..length.equals(12345)
            ..filename.equals('image.jpg')
            ..contentType.asString.equals('image/jpeg')
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes((it) => it.deepEquals(['asdf'.codeUnits].expand((l) => l)))
          );
        checkAppearsLoading(tester, true);

        await tester.pump(const Duration(seconds: 1));
        check(composeBoxController.contentController.text)
          .equals('see image: [image.jpg](/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg)\n\n');
        checkAppearsLoading(tester, false);
      });

      // TODO test what happens when selecting/uploading fails
    });

    group('attach from camera', () {
      testWidgets('success', (tester) async {
        final controllerKey = await prepareComposeBox(tester, narrow: ChannelNarrow(eg.stream().streamId));
        final composeBoxController = controllerKey.currentState!;

        // (When we check that the send button looks disabled, it should be because
        // the file is uploading, not a pre-existing reason.)
        composeBoxController.topicController!.value = const TextEditingValue(text: 'some topic');
        composeBoxController.contentController.value = const TextEditingValue(text: 'see image: ');
        await tester.pump();
        checkAppearsLoading(tester, false);

        testBinding.pickImageResult = XFile.fromData(
          // TODO test inference of MIME type when it's missing here
          mimeType: 'image/jpeg',
          utf8.encode('asdf'),
          name: 'image.jpg',
          length: 12345,
          path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
        );
        connection.prepare(delay: const Duration(seconds: 1), json:
          UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());

        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pump();
        final call = testBinding.takePickImageCalls().single;
        check(call.source).equals(ImageSource.camera);
        check(call.requestFullMetadata).equals(false);

        final errorDialogs = tester.widgetList(find.byType(AlertDialog));
        check(errorDialogs).isEmpty();

        check(composeBoxController.contentController.text)
          .equals('see image: [Uploading image.jpg…]()\n\n');
        // (the request is checked more thoroughly in API tests)
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..files.single.which((it) => it
            ..field.equals('file')
            ..length.equals(12345)
            ..filename.equals('image.jpg')
            ..contentType.asString.equals('image/jpeg')
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes((it) => it.deepEquals(['asdf'.codeUnits].expand((l) => l)))
          );
        checkAppearsLoading(tester, true);

        await tester.pump(const Duration(seconds: 1));
        check(composeBoxController.contentController.text)
          .equals('see image: [image.jpg](/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg)\n\n');
        checkAppearsLoading(tester, false);
      });

      // TODO test what happens when capturing/uploading fails
    });
  });

  group('compose box in DMs with deactivated users', () {
    Finder contentFieldFinder() => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.byType(TextField));

    Finder attachButtonFinder(IconData icon) => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.widgetWithIcon(IconButton, icon));

    void checkComposeBoxParts({required bool areShown}) {
      check(contentFieldFinder().evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.attach_file).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.image).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.camera_alt).evaluate().length).equals(areShown ? 1 : 0);
    }

    void checkBanner({required bool isShown}) {
      final bannerTextFinder = find.text(GlobalLocalizations.zulipLocalizations
        .errorBannerDeactivatedDmLabel);
      check(bannerTextFinder.evaluate().length).equals(isShown ? 1 : 0);
    }

    void checkComposeBox({required bool isShown}) {
      checkComposeBoxParts(areShown: isShown);
      checkBanner(isShown: !isShown);
    }

    Future<void> changeUserStatus(WidgetTester tester,
        {required User user, required bool isActive}) async {
      await store.handleEvent(RealmUserUpdateEvent(id: 1,
        userId: user.userId, isActive: isActive));
      await tester.pump();
    }

    DmNarrow dmNarrowWith(User otherUser) => DmNarrow.withUser(otherUser.userId,
      selfUserId: eg.selfUser.userId);

    DmNarrow groupDmNarrowWith(List<User> otherUsers) => DmNarrow.withOtherUsers(
      otherUsers.map((u) => u.userId), selfUserId: eg.selfUser.userId);

    group('1:1 DMs', () {
      testWidgets('compose box replaced with a banner', (tester) async {
        final deactivatedUser = eg.user(isActive: false);
        await prepareComposeBox(tester, narrow: dmNarrowWith(deactivatedUser),
          users: [deactivatedUser]);
        checkComposeBox(isShown: false);
      });

      testWidgets('active user becomes deactivated -> '
          'compose box is replaced with a banner', (tester) async {
        final activeUser = eg.user(isActive: true);
        await prepareComposeBox(tester, narrow: dmNarrowWith(activeUser),
          users: [activeUser]);
        checkComposeBox(isShown: true);

        await changeUserStatus(tester, user: activeUser, isActive: false);
        checkComposeBox(isShown: false);
      });

      testWidgets('deactivated user becomes active -> '
          'banner is replaced with the compose box', (tester) async {
        final deactivatedUser = eg.user(isActive: false);
        await prepareComposeBox(tester, narrow: dmNarrowWith(deactivatedUser),
          users: [deactivatedUser]);
        checkComposeBox(isShown: false);

        await changeUserStatus(tester, user: deactivatedUser, isActive: true);
        checkComposeBox(isShown: true);
      });
    });

    group('group DMs', () {
      testWidgets('compose box replaced with a banner', (tester) async {
        final deactivatedUsers = [eg.user(isActive: false), eg.user(isActive: false)];
        await prepareComposeBox(tester, narrow: groupDmNarrowWith(deactivatedUsers),
          users: deactivatedUsers);
        checkComposeBox(isShown: false);
      });

      testWidgets('at least one user becomes deactivated -> '
          'compose box is replaced with a banner', (tester) async {
        final activeUsers = [eg.user(isActive: true), eg.user(isActive: true)];
        await prepareComposeBox(tester, narrow: groupDmNarrowWith(activeUsers),
          users: activeUsers);
        checkComposeBox(isShown: true);

        await changeUserStatus(tester, user: activeUsers[0], isActive: false);
        checkComposeBox(isShown: false);
      });

      testWidgets('all deactivated users become active -> '
          'banner is replaced with the compose box', (tester) async {
        final deactivatedUsers = [eg.user(isActive: false), eg.user(isActive: false)];
        await prepareComposeBox(tester, narrow: groupDmNarrowWith(deactivatedUsers),
          users: deactivatedUsers);
        checkComposeBox(isShown: false);

        await changeUserStatus(tester, user: deactivatedUsers[0], isActive: true);
        checkComposeBox(isShown: false);

        await changeUserStatus(tester, user: deactivatedUsers[1], isActive: true);
        checkComposeBox(isShown: true);
      });
    });
  });
}
