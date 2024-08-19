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

  Future<GlobalKey<ComposeBoxController>> prepareComposeBox(WidgetTester tester, {
    required Narrow narrow,
    User? selfUser,
    int realmWaitingPeriodThreshold = 0,
    List<User> users = const [],
    List<ZulipStream> streams = const [],
  }) async {
    if (narrow is ChannelNarrow || narrow is TopicNarrow) {
      final channelId = narrow is ChannelNarrow ? narrow.streamId : (narrow as TopicNarrow).streamId;
      assert(streams.any((stream) => stream.streamId == channelId),
        'Add a channel with "streamId" the same as of $narrow.streamId to the store.');
    }
    addTearDown(testBinding.reset);
    final account = eg.account(user: selfUser ?? eg.selfUser);
    await testBinding.globalStore.add(account, eg.initialSnapshot(
      realmWaitingPeriodThreshold: realmWaitingPeriodThreshold));

    store = await testBinding.globalStore.perAccount(account.id);

    await store.addUsers([selfUser ?? eg.selfUser, ...users]);
    await store.addStreams(streams);
    connection = store.connection as FakeApiConnection;

    if (narrow is ChannelNarrow) {
      // Ensure topics are loaded before testing actual logic.
      connection.prepare(body:
        jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
    }
    final controllerKey = GlobalKey<ComposeBoxController>();
    await tester.pumpWidget(TestZulipApp(accountId: account.id,
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
      final channel = eg.stream();
      final key = await prepareComposeBox(tester,
        narrow: ChannelNarrow(channel.streamId), streams: [channel]);
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: true);
    });

    testWidgets('_FixedDestinationComposeBox', (tester) async {
      final channel = eg.stream();
      final key = await prepareComposeBox(tester,
        narrow: TopicNarrow(channel.streamId, 'topic'), streams: [channel]);
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: false);
    });
  });

  group('message-send request response', () {
    Future<void> setupAndTapSend(WidgetTester tester, {
      required void Function(int messageId) prepareResponse,
    }) async {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepareComposeBox(tester, narrow: const TopicNarrow(123, 'some topic'),
        streams: [eg.stream(streamId: 123)]);

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
        final channel = eg.stream();
        final controllerKey = await prepareComposeBox(tester,
          narrow: ChannelNarrow(channel.streamId), streams: [channel]);
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
        final channel = eg.stream();
        final controllerKey = await prepareComposeBox(tester,
          narrow: ChannelNarrow(channel.streamId), streams: [channel]);
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

  group('compose box replacing with error banner', () {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

    Finder inputFieldFinder() => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.byType(TextField));

    Finder attachButtonFinder(IconData icon) => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.widgetWithIcon(IconButton, icon));

    void checkComposeBoxParts({required bool areShown}) {
      final inputFieldCount = inputFieldFinder().evaluate().length;
      areShown ? check(inputFieldCount).isGreaterThan(0) : check(inputFieldCount).equals(0);
      check(attachButtonFinder(Icons.attach_file).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.image).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.camera_alt).evaluate().length).equals(areShown ? 1 : 0);
    }

    void checkBannerWithLabel(String label, {required bool isShown}) {
      check(find.text(label).evaluate().length).equals(isShown ? 1 : 0);
    }

    void checkComposeBoxIsShown(bool isShown, {required String bannerLabel}) {
      checkComposeBoxParts(areShown: isShown);
      checkBannerWithLabel(bannerLabel, isShown: !isShown);
    }

    group('in DMs with deactivated users', () {
      void checkComposeBox({required bool isShown}) => checkComposeBoxIsShown(isShown,
        bannerLabel: zulipLocalizations.errorBannerDeactivatedDmLabel);

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

    group('in topic/channel narrow according to channel post policy', () {
      void checkComposeBox({required bool isShown}) => checkComposeBoxIsShown(isShown,
        bannerLabel: zulipLocalizations.errorBannerCannotPostInChannelLabel);

      final testCases = [
        (ChannelPostPolicy.unknown,        UserRole.unknown,       true),
        (ChannelPostPolicy.unknown,        UserRole.guest,         true),
        (ChannelPostPolicy.unknown,        UserRole.member,        true),
        (ChannelPostPolicy.unknown,        UserRole.moderator,     true),
        (ChannelPostPolicy.unknown,        UserRole.administrator, true),
        (ChannelPostPolicy.unknown,        UserRole.owner,         true),
        (ChannelPostPolicy.any,            UserRole.unknown,       true),
        (ChannelPostPolicy.any,            UserRole.guest,         true),
        (ChannelPostPolicy.any,            UserRole.member,        true),
        (ChannelPostPolicy.any,            UserRole.moderator,     true),
        (ChannelPostPolicy.any,            UserRole.administrator, true),
        (ChannelPostPolicy.any,            UserRole.owner,         true),
        (ChannelPostPolicy.fullMembers,    UserRole.unknown,       true),
        (ChannelPostPolicy.fullMembers,    UserRole.guest,         false),
        (ChannelPostPolicy.fullMembers,    UserRole.member,        true),
        (ChannelPostPolicy.fullMembers,    UserRole.moderator,     true),
        (ChannelPostPolicy.fullMembers,    UserRole.administrator, true),
        (ChannelPostPolicy.fullMembers,    UserRole.owner,         true),
        (ChannelPostPolicy.moderators,     UserRole.unknown,       true),
        (ChannelPostPolicy.moderators,     UserRole.guest,         false),
        (ChannelPostPolicy.moderators,     UserRole.member,        false),
        (ChannelPostPolicy.moderators,     UserRole.moderator,     true),
        (ChannelPostPolicy.moderators,     UserRole.administrator, true),
        (ChannelPostPolicy.moderators,     UserRole.owner,         true),
        (ChannelPostPolicy.administrators, UserRole.unknown,       true),
        (ChannelPostPolicy.administrators, UserRole.guest,         false),
        (ChannelPostPolicy.administrators, UserRole.member,        false),
        (ChannelPostPolicy.administrators, UserRole.moderator,     false),
        (ChannelPostPolicy.administrators, UserRole.administrator, true),
        (ChannelPostPolicy.administrators, UserRole.owner,         true),
      ];

      for (final testCase in testCases) {
        final (ChannelPostPolicy policy, UserRole role, bool canPost) = testCase;

        testWidgets('"${role.name}" user ${canPost ? 'can' : "can't"} post in channel with "${policy.name}" policy', (tester) async {
          final selfUser = eg.user(role: role);
          await prepareComposeBox(tester,
            narrow: const ChannelNarrow(1),
            selfUser: selfUser,
            streams: [eg.stream(streamId: 1, channelPostPolicy: policy)]);
          checkComposeBox(isShown: canPost);
        });

        testWidgets('"${role.name}" user ${canPost ? 'can' : "can't"} post in topic with "${policy.name}" channel policy', (tester) async {
          final selfUser = eg.user(role: role);
          await prepareComposeBox(tester,
            narrow: const TopicNarrow(1, 'topic'),
            selfUser: selfUser,
            streams: [eg.stream(streamId: 1, channelPostPolicy: policy)]);
          checkComposeBox(isShown: canPost);
        });
      }

      group('only "full member" user can post in channel with "fullMembers" policy', () {
        testWidgets('"full member" -> can post in channel', (tester) async {
          final selfUser = eg.user(role: UserRole.member,
            dateJoined: DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
          await prepareComposeBox(tester,
            narrow: const ChannelNarrow(1),
            selfUser: selfUser,
            realmWaitingPeriodThreshold: 30,
            streams: [eg.stream(streamId: 1, channelPostPolicy: ChannelPostPolicy.fullMembers)]);
          checkComposeBox(isShown: true);
        });

        testWidgets('not a "full member" -> cannot post in channel', (tester) async {
          final selfUser = eg.user(role: UserRole.member,
            dateJoined: DateTime.now().subtract(const Duration(days: 29)).toIso8601String());
          await prepareComposeBox(tester,
            narrow: const ChannelNarrow(1),
            selfUser: selfUser,
            realmWaitingPeriodThreshold: 30,
            streams: [eg.stream(streamId: 1, channelPostPolicy: ChannelPostPolicy.fullMembers)]);
          checkComposeBox(isShown: false);
        });
      });

      Future<void> changeUserRole(WidgetTester tester,
          {required User user, required UserRole role}) async {
        await store.handleEvent(RealmUserUpdateEvent(id: 1,
          userId: user.userId, role: role));
        await tester.pump();
      }

      Future<void> changeChannelPolicy(WidgetTester tester,
          {required ZulipStream channel, required ChannelPostPolicy policy}) async {
        await store.handleEvent(eg.channelUpdateEvent(channel,
          property: ChannelPropertyName.channelPostPolicy, value: policy));
        await tester.pump();
      }

      testWidgets('user role decreases -> compose box is replaced with the banner', (tester) async {
        final selfUser = eg.user(role: UserRole.administrator);
        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [eg.stream(streamId: 1, channelPostPolicy: ChannelPostPolicy.administrators)]);
        checkComposeBox(isShown: true);

        await changeUserRole(tester, user: selfUser, role: UserRole.moderator);
        checkComposeBox(isShown: false);
      });

      testWidgets('user role increases -> banner is replaced with the compose box', (tester) async {
        final selfUser = eg.user(role: UserRole.guest);
        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [eg.stream(streamId: 1, channelPostPolicy: ChannelPostPolicy.moderators)]);
        checkComposeBox(isShown: false);

        await changeUserRole(tester, user: selfUser, role: UserRole.administrator);
        checkComposeBox(isShown: true);
      });

      testWidgets('channel policy becomes stricter -> compose box is replaced with the banner', (tester) async {
        final selfUser = eg.user(role: UserRole.guest);
        final channel = eg.stream(streamId: 1, channelPostPolicy: ChannelPostPolicy.any);
        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [channel]);
        checkComposeBox(isShown: true);

        await changeChannelPolicy(tester, channel: channel, policy: ChannelPostPolicy.fullMembers);
        checkComposeBox(isShown: false);
      });

      testWidgets('channel policy becomes less strict -> banner is replaced with the compose box', (tester) async {
        final selfUser = eg.user(role: UserRole.moderator);
        final channel = eg.stream(streamId: 1, channelPostPolicy: ChannelPostPolicy.administrators);
        await prepareComposeBox(tester,
          narrow: const ChannelNarrow(1),
          selfUser: selfUser,
          streams: [channel]);
        checkComposeBox(isShown: false);

        await changeChannelPolicy(tester, channel: channel, policy: ChannelPostPolicy.moderators);
        checkComposeBox(isShown: true);
      });
    });
  });
}
