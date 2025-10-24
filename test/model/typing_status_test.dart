import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../stdlib_checks.dart';
import 'binding.dart';
import 'test_store.dart';

void checkSetTypingStatusRequests(
  List<http.BaseRequest> requests,
  List<(TypingOp, SendableNarrow)> expected,
) {
  Condition<Object?> conditionTypingRequest(Map<String, String> expected) {
    return (Subject<Object?> it) => it.isA<http.Request>()
      ..method.equals('POST')
      ..url.path.equals('/api/v1/typing')
      ..bodyFields.deepEquals(expected);
  }

  check(requests).deepEquals([
    for (final (op, narrow) in expected)
      switch (narrow) {
        TopicNarrow() => conditionTypingRequest({
          'type': 'channel',
          'op': op.toJson(),
          'stream_id': narrow.streamId.toString(),
          'topic': narrow.topic.apiName}),
        DmNarrow() => conditionTypingRequest({
          'type': 'direct',
          'op': op.toJson(),
          'to': jsonEncode(narrow.allRecipientIds)}),
      }
  ]);
}

void main() {
  TestZulipBinding.ensureInitialized();

  late TypingStatus model;
  late int notifiedCount;

  void checkNotNotified() {
    check(notifiedCount).equals(0);
  }

  void checkNotifiedOnce() {
    check(notifiedCount).equals(1);
    notifiedCount = 0;
  }

  void handleTypingEvent(SendableNarrow narrow, TypingOp op, User sender) {
    assert(sender != eg.selfUser);
    model.handleTypingEvent(eg.typingEvent(narrow, op, sender.userId));
  }

  void checkTypists(Map<SendableNarrow, List<User>> typistsByNarrow) {
    final actualTypistsByNarrow = <SendableNarrow, Iterable<int>>{};
    for (final narrow in model.debugActiveNarrows) {
      actualTypistsByNarrow[narrow] = model.typistIdsInNarrow(narrow);
    }
    check(actualTypistsByNarrow).deepEquals(
      typistsByNarrow.map((k, v) => MapEntry(k, v.map((e) => e.userId))));
  }

  void prepareModel({
    int? selfUserId,
    Map<SendableNarrow, List<User>> typistsByNarrow = const {},
  }) {
    final store = eg.store(
      account: eg.selfAccount.copyWith(id: selfUserId),
      initialSnapshot: eg.initialSnapshot(
        serverTypingStartedExpiryPeriodMilliseconds: 15000));
    model = store.typingStatus;
    check(model.debugActiveNarrows).isEmpty();
    notifiedCount = 0;
    model.addListener(() => notifiedCount += 1);

    typistsByNarrow.forEach((narrow, typists) {
      for (final typist in typists) {
        handleTypingEvent(narrow, TypingOp.start, typist);
        checkNotifiedOnce();
      }
    });
    checkTypists(typistsByNarrow);
  }

  final stream = eg.stream();
  final topicNarrow = eg.topicNarrow(stream.streamId, 'foo');

  final dmNarrow = DmNarrow.withUser(eg.otherUser.userId, selfUserId: eg.selfUser.userId);
  final groupNarrow = DmNarrow.withOtherUsers(
    [eg.otherUser.userId, eg.thirdUser.userId], selfUserId: eg.selfUser.userId);

  test('dispose', () => awaitFakeAsync((async) async {
    prepareModel(typistsByNarrow: {dmNarrow: [eg.otherUser]});

    model.dispose();
    checkTypists({});
    check(async.pendingTimers).isEmpty();
  }));

  group('handle typing start events', () {
    test('add typists in separate narrows', () {
      prepareModel();

      handleTypingEvent(dmNarrow, TypingOp.start, eg.otherUser);
      checkTypists({dmNarrow: [eg.otherUser]});
      checkNotifiedOnce();

      handleTypingEvent(groupNarrow, TypingOp.start, eg.thirdUser);
      checkTypists({dmNarrow: [eg.otherUser], groupNarrow: [eg.thirdUser]});
      checkNotifiedOnce();

      handleTypingEvent(topicNarrow, TypingOp.start, eg.fourthUser);
      checkTypists({
        dmNarrow: [eg.otherUser],
        groupNarrow: [eg.thirdUser],
        topicNarrow: [eg.fourthUser]});
      checkNotifiedOnce();
    });

    test('add a typist in the same narrow', () {
      prepareModel(typistsByNarrow: {groupNarrow: [eg.otherUser]});

      handleTypingEvent(groupNarrow, TypingOp.start, eg.thirdUser);
      checkTypists({groupNarrow: [eg.otherUser, eg.thirdUser]});
      checkNotifiedOnce();
    });

    test('ignore adding self as typist', () {
      prepareModel();

      model.handleTypingEvent(
        eg.typingEvent(groupNarrow, TypingOp.start, eg.selfUser.userId));
      checkTypists({});
      checkNotNotified();
    });
  });

  group('handle typing stop events', () {
    test('remove a typist from an unknown narrow', () {
      prepareModel(typistsByNarrow:  {groupNarrow: [eg.otherUser]});

      handleTypingEvent(dmNarrow, TypingOp.stop, eg.otherUser);
      checkTypists({groupNarrow: [eg.otherUser]});
      checkNotNotified();
    });

    test('remove an unknown typist from a known narrow', () {
      prepareModel(typistsByNarrow:  {groupNarrow: [eg.otherUser]});

      handleTypingEvent(groupNarrow, TypingOp.stop, eg.thirdUser);
      checkTypists({groupNarrow: [eg.otherUser]});
      checkNotNotified();
    });

    test('remove one of two typists in the same narrow', () {
      prepareModel(typistsByNarrow: {
        groupNarrow: [eg.otherUser, eg.thirdUser],
      });

      handleTypingEvent(groupNarrow, TypingOp.stop, eg.otherUser);
      checkTypists({groupNarrow: [eg.thirdUser]});
      checkNotifiedOnce();
    });

    test('remove all typists in a narrow', () {
      prepareModel(typistsByNarrow: {dmNarrow: [eg.otherUser]});

      handleTypingEvent(dmNarrow, TypingOp.stop, eg.otherUser);
      checkTypists({});
      checkNotifiedOnce();
    });

    test('remove typists from different narrows', () {
      prepareModel(typistsByNarrow: {
        dmNarrow: [eg.otherUser],
        groupNarrow: [eg.thirdUser],
        topicNarrow: [eg.fourthUser],
      });

      handleTypingEvent(groupNarrow, TypingOp.stop, eg.thirdUser);
      checkTypists({dmNarrow: [eg.otherUser], topicNarrow: [eg.fourthUser]});
      checkNotifiedOnce();

      handleTypingEvent(dmNarrow, TypingOp.stop, eg.otherUser);
      checkTypists({topicNarrow: [eg.fourthUser]});
      checkNotifiedOnce();

      handleTypingEvent(topicNarrow, TypingOp.stop, eg.fourthUser);
      checkTypists({});
      checkNotifiedOnce();
    });
  });

  group('typing start expiry period', () {
    test('typist is removed when the expiry period ends', () => awaitFakeAsync((async) async {
      prepareModel(typistsByNarrow: {dmNarrow: [eg.otherUser]});

      async.elapse(const Duration(seconds: 5));
      checkTypists({dmNarrow: [eg.otherUser]});
      checkNotNotified();

      async.elapse(const Duration(seconds: 10));
      checkTypists({});
      check(async.pendingTimers).isEmpty();
      checkNotifiedOnce();
    }));

    test('early typing stop event cancels the timer', () => awaitFakeAsync((async) async {
      prepareModel(typistsByNarrow: {dmNarrow: [eg.otherUser]});
      check(async.pendingTimers).length.equals(1);

      handleTypingEvent(dmNarrow, TypingOp.stop, eg.otherUser);
      checkTypists({});
      check(async.pendingTimers).isEmpty();
      checkNotifiedOnce();
    }));

    test('repeated typing start event resets the timer', () => awaitFakeAsync((async) async {
      prepareModel(typistsByNarrow: {dmNarrow: [eg.otherUser]});
      check(async.pendingTimers).length.equals(1);

      async.elapse(const Duration(seconds: 10));
      checkTypists({dmNarrow: [eg.otherUser]});
      // The timer should restart from the event.
      handleTypingEvent(dmNarrow, TypingOp.start, eg.otherUser);
      check(async.pendingTimers).length.equals(1);
      checkNotNotified();

      async.elapse(const Duration(seconds: 10));
      checkTypists({dmNarrow: [eg.otherUser]});
      check(async.pendingTimers).length.equals(1);
      checkNotNotified();

      async.elapse(const Duration(seconds: 5));
      checkTypists({});
      check(async.pendingTimers).isEmpty();
      checkNotifiedOnce();
    }));
  });

  group('handle set typing status', () {
    late PerAccountStore store;
    late TypingNotifier model;
    late FakeApiConnection connection;
    late TopicNarrow narrow;

    void checkTypingRequest(TypingOp op, SendableNarrow narrow) =>
      checkSetTypingStatusRequests(connection.takeRequests(), [(op, narrow)]);

    Future<void> prepare() async {
      addTearDown(testBinding.reset);
      // Only test with the latest behavior of the setTypingStatus API.
      // (Legacy variations are covered by setTypingStatus's own tests.)
      final account = eg.account(
        user: eg.selfUser, zulipFeatureLevel: eg.futureZulipFeatureLevel);
      store = eg.store(account: account, initialSnapshot: eg.initialSnapshot(
        zulipFeatureLevel: eg.futureZulipFeatureLevel));
      model = store.typingNotifier;
      connection = store.connection as FakeApiConnection;

      final channel = eg.stream();
      await store.addStream(channel);
      await store.addSubscription(eg.subscription(channel));
      narrow = eg.topicNarrow(channel.streamId, 'topic');
    }

    /// Prepares store and triggers a "typing started" notice.
    Future<void> prepareStartTyping(FakeAsync async) async {
      await prepare();
      connection.prepare(json: {});
      model.keystroke(narrow);
      checkTypingRequest(TypingOp.start, narrow);

      // Finish the pending API request first,
      // so that the idle timer is the only timer left.
      async.elapse(Duration.zero);
      check(async.pendingTimers).single;
    }

    test('start typing repeatedly extends idle timer', () => awaitFakeAsync((async) async {
      // t = 0ms: Start typing. The idle timer is set to typingStoppedWaitPeriod.
      await prepareStartTyping(async);

      const waitTime = Duration(milliseconds: 100);
      // [waitTime] should not be long enough
      // to trigger a "typing stopped" notice.
      assert(waitTime < store.serverTypingStoppedWaitPeriod);

      async.elapse(waitTime);
      // t = 100ms: The idle timer is reset to typingStoppedWaitPeriod.
      connection.prepare(json: {});
      model.keystroke(narrow);
      check(connection.lastRequest).isNull();
      check(async.pendingTimers).single;

      async.elapse(store.serverTypingStoppedWaitPeriod - const Duration(milliseconds: 1));
      // t = typingStoppedWaitPeriod + 99ms:
      //   Since the timer was reset at t = 100ms, the "typing stopped" notice has
      //   not been sent yet.
      check(connection.lastRequest).isNull();
      check(async.pendingTimers).single;

      async.elapse(const Duration(milliseconds: 1));
      // t = typingStoppedWaitPeriod + 100ms:
      //   The new timer expires and the "typing stopped" notice is sent.
      checkTypingRequest(TypingOp.stop, narrow);
    }));

    test('start typing repeatedly does not resend "typing started" notices', () => awaitFakeAsync((async) async {
      // t = 0ms: Start typing.
      await prepareStartTyping(async);

      const waitInterval = Duration(milliseconds: 2000);
      // [waitInterval] should not be long enough
      // to trigger a "typing stopped" notice.
      assert(waitInterval < store.serverTypingStoppedWaitPeriod);
      // [waitInterval] should be short enough
      // that the loop below runs more than once.
      assert(waitInterval < store.serverTypingStartedWaitPeriod);

      while (async.elapsed <= store.serverTypingStartedWaitPeriod) {
        // t <= typingStartedWaitPeriod: "Typing started" notices are throttled.
        model.keystroke(narrow);
        check(connection.lastRequest).isNull();

        async.elapse(waitInterval);
      }

      // t > typingStartedWaitPeriod: Resume sending "typing started" notices.
      connection.prepare(json: {});
      model.keystroke(narrow);
      checkTypingRequest(TypingOp.start, narrow);

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      async.flushTimers();
      checkTypingRequest(TypingOp.stop, narrow);
    }));

    test('after stopped wait period, send a "typing stopped" notice', () => awaitFakeAsync((async) async {
      await prepareStartTyping(async);

      connection.prepare(json: {});
      async.elapse(store.serverTypingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
      check(async.pendingTimers).isEmpty();
    }));

    test('actively stopping typing cancels the idle timer', () => awaitFakeAsync((async) async {
      await prepareStartTyping(async);

      connection.prepare(json: {});
      model.stoppedComposing();
      checkTypingRequest(TypingOp.stop, narrow);

      async.elapse(Duration.zero);
      check(async.pendingTimers).isEmpty();
    }));

    test('stop typing then start typing should result in a new "typing started" notice', () => awaitFakeAsync((async) async {
      await prepareStartTyping(async);

      connection.prepare(json: {});
      model.stoppedComposing();
      checkTypingRequest(TypingOp.stop, narrow);

      // The "typing started" notice would have been throttled if we did not
      // reset the TypingNotifier internal states before sending the "typing
      // stopped" notice.
      connection.prepare(json: {});
      model.keystroke(narrow);
      checkTypingRequest(TypingOp.start, narrow);

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      async.flushTimers();
      checkTypingRequest(TypingOp.stop, narrow);
    }));

    test('disposing store cancels the idle timer', () => awaitFakeAsync((async) async {
      await prepareStartTyping(async);

      store.dispose();
      check(async.pendingTimers).isEmpty();
    }));

    test('start typing in a different destination resets the idle timer', () => awaitFakeAsync((async) async {
      await prepare();
      final topicNarrow = narrow;
      final dmNarrow = DmNarrow.withUsers(
        [eg.otherUser.userId], selfUserId: eg.selfUser.userId);

      const waitTime = Duration(milliseconds: 100);
      // [waitTime] should not be long enough
      // to trigger a "typing stopped" notice.
      assert(waitTime < store.serverTypingStoppedWaitPeriod);

      // t = 0ms: Start typing. The idle timer is set to typingStoppedWaitPeriod.
      connection.prepare(json: {});
      model.keystroke(topicNarrow);
      checkTypingRequest(TypingOp.start, topicNarrow);

      async.elapse(Duration.zero);
      check(async.pendingTimers).single;

      async.elapse(waitTime);
      // t = 100ms:
      //   Start typing in a different narrow. The timer should be reset
      //   and the previous typing indicator should be dismissed.
      connection.prepare(json: {});
      connection.prepare(json: {});
      model.keystroke(dmNarrow);
      checkSetTypingStatusRequests(connection.takeRequests(),
        [(TypingOp.stop, topicNarrow), (TypingOp.start, dmNarrow)]);

      async.elapse(Duration.zero);
      check(async.pendingTimers).single;

      async.elapse(store.serverTypingStoppedWaitPeriod - waitTime);
      // t = typingStoppedPeriod:
      //   Because the old timer has been canceled at t = 100ms,
      //   no "typing stopped" notice has been sent yet.
      check(connection.lastRequest).isNull();
      check(async.pendingTimers).single;

      connection.prepare(json: {});
      async.elapse(waitTime);
      // t = typingStoppedPeriod + 100ms:
      //   The new timer has expired, and a "typing stopped" notice is expected.
      checkTypingRequest(TypingOp.stop, dmNarrow);
    }));

    test('start typing in a different destination resets typing started wait timeout', () => awaitFakeAsync((async) async {
      await prepare();
      final topicNarrow = narrow;
      final dmNarrow = DmNarrow.withUsers(
        [eg.otherUser.userId], selfUserId: eg.selfUser.userId);

      const waitInterval = Duration(milliseconds: 2000);
      // [waitInterval] should not be long enough
      // to trigger a "typing stopped" notice.
      assert(waitInterval < store.serverTypingStoppedWaitPeriod);

      // t = 0ms: Start typing. The typing started time is set to 0ms.
      connection.prepare(json: {});
      model.keystroke(topicNarrow);
      checkTypingRequest(TypingOp.start, topicNarrow);

      async.elapse(waitInterval);
      // t = waitInterval * 1:
      //   Start typing in a different narrow.  The last time we sent
      //   a "typing started" notice should be reset to t.
      //   The previous typing indicator should be dismissed
      //   as we start the new one, which results in two requests.
      connection.prepare(json: {});
      connection.prepare(json: {});
      model.keystroke(dmNarrow);
      checkSetTypingStatusRequests(connection.takeRequests(),
        [(TypingOp.stop, topicNarrow), (TypingOp.start, dmNarrow)]);

      while (async.elapsed <= store.serverTypingStartedWaitPeriod) {
        // t <= typingStartedWaitPeriod: "still typing" requests are throttled.
        model.keystroke(dmNarrow);
        check(connection.lastRequest).isNull();

        async.elapse(waitInterval);
      }

      assert(async.elapsed > store.serverTypingStartedWaitPeriod);
      assert(async.elapsed <= store.serverTypingStartedWaitPeriod + waitInterval);
      // typingStartedWaitPeriod < t <= typingStartedWaitPeriod + waitInterval * 1:
      //   The "still typing" requests are still throttled, because it hasn't
      //   been a full typingStartedWaitPeriod since the last time we sent
      //   a "typing started" notice at t = waitInterval * 1.
      model.keystroke(dmNarrow);
      check(connection.lastRequest).isNull();

      async.elapse(waitInterval);
      // t > typingStartedWaitPeriod + waitInterval * 1:
      //   Resume sending "typing started" notices, because it has been just
      //   enough time since the last time we sent a "typing started" notice.
      connection.prepare(json: {});
      model.keystroke(dmNarrow);
      checkTypingRequest(TypingOp.start, dmNarrow);

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      async.flushTimers();
      checkTypingRequest(TypingOp.stop, dmNarrow);
    }));
  });
}
