import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/narrow.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/actions.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/unreads_checks.dart';
import '../stdlib_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;
  late BuildContext context;

  Future<void> prepare(WidgetTester tester, {
    UnreadMessagesSnapshot? unreadMsgs,
    String? ackedPushToken = '123',
    bool skipAssertAccountExists = false,
  }) async {
    addTearDown(testBinding.reset);
    final selfAccount = eg.selfAccount.copyWith(ackedPushToken: Value(ackedPushToken));
    await testBinding.globalStore.add(selfAccount, eg.initialSnapshot(
      unreadMsgs: unreadMsgs));
    store = await testBinding.globalStore.perAccount(selfAccount.id);
    connection = store.connection as FakeApiConnection;

    await tester.pumpWidget(TestZulipApp(
      accountId: selfAccount.id,
      skipAssertAccountExists: skipAssertAccountExists,
      child: const Scaffold(body: Placeholder())));
    await tester.pump();
    context = tester.element(find.byType(Placeholder));
  }

  group('markNarrowAsRead', () {
    testWidgets('smoke test on modern server', (tester) async {
      final narrow = TopicNarrow.ofMessage(eg.streamMessage());
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: true).toJson());
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      final apiNarrow = narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread));
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode(apiNarrow),
            'op': 'add',
            'flag': 'read',
          });
    });

    testWidgets('use is:unread optimization', (tester) async {
      const narrow = CombinedFeedNarrow();
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: true).toJson());
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': json.encode([{'operator': 'is', 'operand': 'unread'}]),
            'op': 'add',
            'flag': 'read',
          });
    });

    testWidgets('on mark-all-as-read when Unreads.oldUnreadsMissing: true', (tester) async {
      const narrow = CombinedFeedNarrow();
      await prepare(tester);
      store.unreads.oldUnreadsMissing = true;

      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: true).toJson());
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(store.unreads.oldUnreadsMissing).isFalse();
    });

    testWidgets('CombinedFeedNarrow on legacy server', (tester) async {
      const narrow = CombinedFeedNarrow();
      await prepare(tester);
      // Might as well test with oldUnreadsMissing: true.
      store.unreads.oldUnreadsMissing = true;

      connection.zulipFeatureLevel = 154;
      connection.prepare(json: {});
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_all_as_read')
        ..bodyFields.deepEquals({});

      // Check that [Unreads.handleAllMessagesReadSuccess] wasn't called;
      // in the legacy protocol, that'd be redundant with the mark-read event.
      check(store.unreads).oldUnreadsMissing.isTrue();
    });

    testWidgets('ChannelNarrow on legacy server', (tester) async {
      final stream = eg.stream();
      final narrow = ChannelNarrow(stream.streamId);
      await prepare(tester);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json: {});
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_stream_as_read')
        ..bodyFields.deepEquals({
            'stream_id': stream.streamId.toString(),
          });
    });

    testWidgets('TopicNarrow on legacy server', (tester) async {
      final narrow = TopicNarrow.ofMessage(eg.streamMessage());
      await prepare(tester);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json: {});
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/mark_topic_as_read')
        ..bodyFields.deepEquals({
            'stream_id': narrow.streamId.toString(),
            'topic_name': narrow.topic,
          });
    });

    testWidgets('DmNarrow on legacy server', (tester) async {
      final message = eg.dmMessage(from: eg.otherUser, to: [eg.selfUser]);
      final narrow = DmNarrow.ofMessage(message, selfUserId: eg.selfUser.userId);
      final unreadMsgs = eg.unreadMsgs(dms: [
        UnreadDmSnapshot(otherUserId: eg.otherUser.userId,
          unreadMessageIds: [message.id]),
      ]);
      await prepare(tester, unreadMsgs: unreadMsgs);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json:
        UpdateMessageFlagsResult(messages: [message.id]).toJson());
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags')
        ..bodyFields.deepEquals({
            'messages': jsonEncode([message.id]),
            'op': 'add',
            'flag': 'read',
          });
    });

    testWidgets('MentionsNarrow on legacy server', (tester) async {
      const narrow = MentionsNarrow();
      final message = eg.streamMessage(flags: [MessageFlag.mentioned]);
      final unreadMsgs = eg.unreadMsgs(mentions: [message.id]);
      await prepare(tester, unreadMsgs: unreadMsgs);
      connection.zulipFeatureLevel = 154;
      connection.prepare(json:
        UpdateMessageFlagsResult(messages: [message.id]).toJson());
      final future = ZulipAction.markNarrowAsRead(context, narrow);
      await tester.pump(Duration.zero);
      await future;
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags')
        ..bodyFields.deepEquals({
            'messages': jsonEncode([message.id]),
            'op': 'add',
            'flag': 'read',
          });
    });
  });

  group('updateMessageFlagsStartingFromAnchor', () {
    String onCompletedMessage(int count) => 'onCompletedMessage($count)';
    const progressMessage = 'progressMessage';
    const onFailedTitle = 'onFailedTitle';
    final narrow = TopicNarrow.ofMessage(eg.streamMessage());
    final apiNarrow = narrow.apiEncode()..add(ApiNarrowIs(IsOperand.unread));

    Future<bool> invokeUpdateMessageFlagsStartingFromAnchor() =>
      ZulipAction.updateMessageFlagsStartingFromAnchor(
        context: context,
        apiNarrow: apiNarrow,
        op: UpdateMessageFlagsOp.add,
        flag: MessageFlag.read,
        includeAnchor: false,
        anchor: AnchorCode.oldest,
        onCompletedMessage: onCompletedMessage,
        onFailedTitle: onFailedTitle,
        progressMessage: progressMessage);

    testWidgets('smoke test', (tester) async {
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 11, updatedCount: 3,
        firstProcessedId: 1, lastProcessedId: 1980,
        foundOldest: true, foundNewest: true).toJson());
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      await tester.pump(Duration.zero);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode(apiNarrow),
            'op': 'add',
            'flag': 'read',
          });
      check(await didPass).isTrue();
    });

    testWidgets('pagination', (tester) async {
      // Check that `lastProcessedId` returned from an initial
      // response is used as `anchorId` for the subsequent request.
      await prepare(tester);

      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 1000, updatedCount: 890,
        firstProcessedId: 1, lastProcessedId: 1989,
        foundOldest: true, foundNewest: false).toJson());
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode(apiNarrow),
            'op': 'add',
            'flag': 'read',
          });

      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 20, updatedCount: 10,
        firstProcessedId: 2000, lastProcessedId: 2023,
        foundOldest: false, foundNewest: true).toJson());
      await tester.pump(Duration.zero);
      check(find.bySubtype<SnackBar>().evaluate()).length.equals(1);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': '1989',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode(apiNarrow),
            'op': 'add',
            'flag': 'read',
          });
      check(await didPass).isTrue();
    });

    testWidgets('on invalid response', (tester) async {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepare(tester);
      connection.prepare(json: UpdateMessageFlagsForNarrowResult(
        processedCount: 1000, updatedCount: 0,
        firstProcessedId: null, lastProcessedId: null,
        foundOldest: true, foundNewest: false).toJson());
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      await tester.pump(Duration.zero);
      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages/flags/narrow')
        ..bodyFields.deepEquals({
            'anchor': 'oldest',
            'include_anchor': 'false',
            'num_before': '0',
            'num_after': '1000',
            'narrow': jsonEncode(apiNarrow),
            'op': 'add',
            'flag': 'read',
          });
      checkErrorDialog(tester,
        expectedTitle: onFailedTitle,
        expectedMessage: zulipLocalizations.errorInvalidResponse);
      check(await didPass).isFalse();
    });

    testWidgets('catch-all api errors', (tester) async {
      await prepare(tester);
      connection.prepare(httpException: http.ClientException('Oops'));
      final didPass = invokeUpdateMessageFlagsStartingFromAnchor();
      await tester.pump(Duration.zero);
      checkErrorDialog(tester,
        expectedTitle: onFailedTitle,
        expectedMessage: 'NetworkException: Oops (ClientException: Oops)');
      check(await didPass).isFalse();
    });
  });
}
