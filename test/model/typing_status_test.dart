import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/typing_status.dart';

import '../example_data.dart' as eg;
import '../fake_async.dart';

void main() {
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
    model = TypingStatus(
      selfUserId: selfUserId ?? eg.selfUser.userId,
      typingStartedExpiryPeriod: const Duration(milliseconds: 15000));
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
  final topicNarrow = TopicNarrow(stream.streamId, 'foo');

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
}
