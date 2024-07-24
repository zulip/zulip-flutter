import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/message_list.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/compose_box.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import 'message_list_test.dart';
import 'test_store.dart';
import 'autocomplete_checks.dart';

void main() {
  group('ComposeContentController.autocompleteIntent', () {
    parseMarkedText(String markedText) {
      final TextSelection selection;
      int? expectedSyntaxStart;
      final textBuffer = StringBuffer();
      final caretPositions = <int>[];
      int i = 0;
      for (final char in markedText.codeUnits) {
        if (char == 94 /* ^ */) {
          caretPositions.add(i);
          continue;
        } else if (char == 126 /* ~ */) {
          if (expectedSyntaxStart != null) {
            throw Exception('Test error: too many ~ in input');
          }
          expectedSyntaxStart = i;
          continue;
        }
        textBuffer.writeCharCode(char);
        i++;
      }
      switch (caretPositions.length) {
        case 0:
          selection = const TextSelection.collapsed(offset: -1);
        case 1:
          selection = TextSelection(baseOffset: caretPositions[0], extentOffset: caretPositions[0]);
        case 2:
          selection = TextSelection(baseOffset: caretPositions[0], extentOffset: caretPositions[1]);
        default:
          throw Exception('Test error: too many ^ in input');
      }
      return (
        value: TextEditingValue(text: textBuffer.toString(), selection: selection),
        expectedSyntaxStart: expectedSyntaxStart);
    }

    /// Test the given input, in a convenient format.
    ///
    /// Represent selection handles as "^". For convenience, a single "^" can
    /// represent a collapsed selection (cursor position). For a null selection,
    /// as when the input has never been focused, just omit "^" from the string.
    ///
    /// Represent the expected syntax start index (the index of "@" in a
    /// mention-autocomplete attempt) as "~".
    ///
    /// For example, "~@chris^" means the text is "@chris", the selection is
    /// collapsed at index 6, and we expect the syntax to start at index 0.
    doTest(String markedText, MentionAutocompleteQuery? expectedQuery) {
      final description = expectedQuery != null
        ? 'in ${jsonEncode(markedText)}, query ${jsonEncode(expectedQuery.raw)}'
        : 'no query in ${jsonEncode(markedText)}';
      test(description, () {
        final controller = ComposeContentController();
        final parsed = parseMarkedText(markedText);
        assert((expectedQuery == null) == (parsed.expectedSyntaxStart == null));
        controller.value = parsed.value;
        if (expectedQuery == null) {
          check(controller).autocompleteIntent.isNull();
        } else {
          check(controller).autocompleteIntent.isNotNull()
            ..query.equals(expectedQuery)
            ..syntaxStart.equals(parsed.expectedSyntaxStart!);
        }
      });
    }

    MentionAutocompleteQuery queryOf(String raw) => MentionAutocompleteQuery(raw, silent: false);
    MentionAutocompleteQuery silentQueryOf(String raw) => MentionAutocompleteQuery(raw, silent: true);

    doTest('', null);
    doTest('^', null);

    doTest('!@#\$%&*()_+', null);

    doTest('^@', null);                doTest('^@_', null);
    doTest('^@abc', null);             doTest('^@_abc', null);
    doTest('@abc', null);              doTest('@_abc', null); // (no cursor)

    doTest('@ ^', null);      // doTest('@_ ^', null); // (would fail, but OK… technically "_" could start a word in full_name)
    doTest('@*^', null);      doTest('@_*^', null);
    doTest('@`^', null);      doTest('@_`^', null);
    doTest('@\\^', null);     doTest('@_\\^', null);
    doTest('@>^', null);      doTest('@_>^', null);
    doTest('@"^', null);      doTest('@_"^', null);
    doTest('@\n^', null);     doTest('@_\n^', null); // control character
    doTest('@\u0000^', null); doTest('@_\u0000^', null); // control
    doTest('@\u061C^', null); doTest('@_\u061C^', null); // format character
    doTest('@\u0600^', null); doTest('@_\u0600^', null); // format
    doTest('@\uD834^', null); doTest('@_\uD834^', null); // leading surrogate

    doTest('email support@^', null);
    doTest('email support@zulip^', null);
    doTest('email support@zulip.com^', null);
    doTest('support@zulip.com^', null);
    doTest('email support@ with details of the issue^', null);
    doTest('email support@^ with details of the issue', null);

    doTest('Ask @**Chris Bobbe**^', null); doTest('Ask @_**Chris Bobbe**^', null);
    doTest('Ask @**Chris Bobbe^**', null); doTest('Ask @_**Chris Bobbe^**', null);
    doTest('Ask @**Chris^ Bobbe**', null); doTest('Ask @_**Chris^ Bobbe**', null);
    doTest('Ask @**^Chris Bobbe**', null); doTest('Ask @_**^Chris Bobbe**', null);

    doTest('`@chris^', null); doTest('`@_chris^', null);

    doTest('~@^_', queryOf('')); // Odd/unlikely, but should not crash

    doTest('~@__^', silentQueryOf('_'));

    doTest('~@^abc^', queryOf('abc')); doTest('~@_^abc^', silentQueryOf('abc'));
    doTest('~@a^bc^', queryOf('abc')); doTest('~@_a^bc^', silentQueryOf('abc'));
    doTest('~@ab^c^', queryOf('abc')); doTest('~@_ab^c^', silentQueryOf('abc'));
    doTest('~^@^', queryOf(''));       doTest('~^@_^', silentQueryOf(''));
    // but:
    doTest('^hello @chris^', null);    doTest('^hello @_chris^', null);

    doTest('~@me@zulip.com^', queryOf('me@zulip.com'));  doTest('~@_me@zulip.com^', silentQueryOf('me@zulip.com'));
    doTest('~@me@^zulip.com^', queryOf('me@zulip.com')); doTest('~@_me@^zulip.com^', silentQueryOf('me@zulip.com'));
    doTest('~@me^@zulip.com^', queryOf('me@zulip.com')); doTest('~@_me^@zulip.com^', silentQueryOf('me@zulip.com'));
    doTest('~@^me@zulip.com^', queryOf('me@zulip.com')); doTest('~@_^me@zulip.com^', silentQueryOf('me@zulip.com'));

    doTest('~@abc^', queryOf('abc'));   doTest('~@_abc^', silentQueryOf('abc'));
    doTest(' ~@abc^', queryOf('abc'));  doTest(' ~@_abc^', silentQueryOf('abc'));
    doTest('(~@abc^', queryOf('abc'));  doTest('(~@_abc^', silentQueryOf('abc'));
    doTest('—~@abc^', queryOf('abc'));  doTest('—~@_abc^', silentQueryOf('abc'));
    doTest('"~@abc^', queryOf('abc'));  doTest('"~@_abc^', silentQueryOf('abc'));
    doTest('“~@abc^', queryOf('abc'));  doTest('“~@_abc^', silentQueryOf('abc'));
    doTest('。~@abc^', queryOf('abc')); doTest('。~@_abc^', silentQueryOf('abc'));
    doTest('«~@abc^', queryOf('abc'));  doTest('«~@_abc^', silentQueryOf('abc'));

    doTest('~@ab^c', queryOf('ab')); doTest('~@_ab^c', silentQueryOf('ab'));
    doTest('~@a^bc', queryOf('a'));  doTest('~@_a^bc', silentQueryOf('a'));
    doTest('~@^abc', queryOf(''));   doTest('~@_^abc', silentQueryOf(''));
    doTest('~@^', queryOf(''));      doTest('~@_^', silentQueryOf(''));

    doTest('~@abc ^', queryOf('abc '));  doTest('~@_abc ^', silentQueryOf('abc '));
    doTest('~@abc^ ^', queryOf('abc ')); doTest('~@_abc^ ^', silentQueryOf('abc '));
    doTest('~@ab^c ^', queryOf('abc ')); doTest('~@_ab^c ^', silentQueryOf('abc '));
    doTest('~@^abc ^', queryOf('abc ')); doTest('~@_^abc ^', silentQueryOf('abc '));

    doTest('Please ask ~@chris^', queryOf('chris'));             doTest('Please ask ~@_chris^', silentQueryOf('chris'));
    doTest('Please ask ~@chris bobbe^', queryOf('chris bobbe')); doTest('Please ask ~@_chris bobbe^', silentQueryOf('chris bobbe'));

    doTest('~@Rodion Romanovich Raskolnikov^', queryOf('Rodion Romanovich Raskolnikov'));
    doTest('~@_Rodion Romanovich Raskolniko^', silentQueryOf('Rodion Romanovich Raskolniko'));
    doTest('~@Родион Романович Раскольников^', queryOf('Родион Романович Раскольников'));
    doTest('~@_Родион Романович Раскольнико^', silentQueryOf('Родион Романович Раскольнико'));
    doTest('If @chris is around, please ask him.^', null); // @ sign is too far away from cursor
    doTest('If @_chris is around, please ask him.^', null); // @ sign is too far away from cursor
  });

  test('MentionAutocompleteView misc', () async {
    const narrow = StreamNarrow(1);
    final store = eg.store();
    await store.addUsers([eg.selfUser, eg.otherUser, eg.thirdUser]);
    final view = MentionAutocompleteView.init(store: store, narrow: narrow);

    bool done = false;
    view.addListener(() { done = true; });
    view.query = MentionAutocompleteQuery('Third');
    await Future(() {});
    check(done).isTrue();
    check(view.results).single
      .isA<UserMentionAutocompleteResult>()
      .userId.equals(eg.thirdUser.userId);
  });

  test('MentionAutocompleteView not starve timers', () {
    fakeAsync((binding) async {
      const narrow = StreamNarrow(1);
      final store = eg.store();
      await store.addUsers([eg.selfUser, eg.otherUser, eg.thirdUser]);
      final view = MentionAutocompleteView.init(store: store, narrow: narrow);

      bool searchDone = false;
      view.addListener(() {
        searchDone = true;
      });

      // Schedule a timer event with zero delay.
      // This stands in for a user interaction, or frame rendering timer,
      // placing an urgent task on the event queue.
      bool timerDone = false;
      Timer(const Duration(), () {
        timerDone = true;
        // The timer should go first, before the search does its work.
        check(searchDone).isFalse();
      });

      view.query = MentionAutocompleteQuery('Third');
      check(timerDone).isFalse();
      check(searchDone).isFalse();

      binding.elapse(const Duration(seconds: 1));

      check(timerDone).isTrue();
      check(searchDone).isTrue();
      check(view.results).single
        .isA<UserMentionAutocompleteResult>()
        .userId.equals(eg.thirdUser.userId);
    });
  });

  test('MentionAutocompleteView yield between batches of 1000', () async {
    const narrow = StreamNarrow(1);
    final store = eg.store();
    for (int i = 0; i < 2500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    final view = MentionAutocompleteView.init(store: store, narrow: narrow);

    bool done = false;
    view.addListener(() { done = true; });
    view.query = MentionAutocompleteQuery('User 2222');

    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isTrue();
    check(view.results).single
      .isA<UserMentionAutocompleteResult>()
      .userId.equals(2222);
  });

  test('MentionAutocompleteView new query during computation replaces old', () async {
    const narrow = StreamNarrow(1);
    final store = eg.store();
    for (int i = 0; i < 1500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    final view = MentionAutocompleteView.init(store: store, narrow: narrow);

    bool done = false;
    view.addListener(() { done = true; });
    view.query = MentionAutocompleteQuery('User 1111');

    await Future(() {});
    check(done).isFalse();
    view.query = MentionAutocompleteQuery('User 0');

    // …new query goes through all batches
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isTrue(); // new result is set
    check(view.results).single
      .isA<UserMentionAutocompleteResult>()
      .userId.equals(0);

    // new result sticks; it isn't clobbered with old query's result
    for (int i = 0; i < 10; i++) { // for good measure
      await Future(() {});
      check(view.results).single
        .isA<UserMentionAutocompleteResult>()
        .userId.equals(0);
    }
  });

  test('MentionAutocompleteView mutating store.users while in progress does not '
      'prevent query from finishing', () async {
    const narrow = StreamNarrow(1);
    final store = eg.store();
    for (int i = 0; i < 2500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    final view = MentionAutocompleteView.init(store: store, narrow: narrow);

    bool done = false;
    view.addListener(() { done = true; });
    view.query = MentionAutocompleteQuery('User 110');

    await Future(() {});
    check(done).isFalse();
    await store.addUser(eg.user(userId: 11000, email: 'user11000@example.com', fullName: 'User 11000'));
    await Future(() {});
    check(done).isFalse();
    for (int i = 0; i < 3; i++) {
      await Future(() {});
      if (done) break;
    }
    check(done).isTrue();
    final results = view.results
      .map((e) => (e as UserMentionAutocompleteResult).userId);
    check(results)
      ..contains(110)
      ..contains(1100)
      // Does not include the newly-added user as we finish the query with stale users.
      ..not((results) => results.contains(11000));
  });

  group('MentionAutocompleteQuery.testUser', () {
    doCheck(String rawQuery, User user, bool expected) {
      final result = MentionAutocompleteQuery(rawQuery)
        .testUser(user, AutocompleteDataCache());
      expected ? check(result).isTrue() : check(result).isFalse();
    }

    test('user is always excluded when not active regardless of other criteria', () {
      doCheck('Full Name', eg.user(fullName: 'Full Name', isActive: false), false);
      // When active then other criteria will be checked
      doCheck('Full Name', eg.user(fullName: 'Full Name', isActive: true), true);
    });

    test('user is included if fullname words match the query', () {
      doCheck('', eg.user(fullName: 'Full Name'), true);
      doCheck('', eg.user(fullName: ''), true); // Unlikely case, but should not crash
      doCheck('Full Name', eg.user(fullName: 'Full Name'), true);
      doCheck('full name', eg.user(fullName: 'Full Name'), true);
      doCheck('Full Name', eg.user(fullName: 'full name'), true);
      doCheck('Full', eg.user(fullName: 'Full Name'), true);
      doCheck('Name', eg.user(fullName: 'Full Name'), true);
      doCheck('Full Name', eg.user(fullName: 'Fully Named'), true);
      doCheck('Full Four', eg.user(fullName: 'Full Name Four Words'), true);
      doCheck('Name Words', eg.user(fullName: 'Full Name Four Words'), true);
      doCheck('Full F', eg.user(fullName: 'Full Name Four Words'), true);
      doCheck('F Four', eg.user(fullName: 'Full Name Four Words'), true);
      doCheck('full full', eg.user(fullName: 'Full Full Name'), true);
      doCheck('full full', eg.user(fullName: 'Full Name Full'), true);

      doCheck('F', eg.user(fullName: ''), false); // Unlikely case, but should not crash
      doCheck('Fully Named', eg.user(fullName: 'Full Name'), false);
      doCheck('Full Name', eg.user(fullName: 'Full'), false);
      doCheck('Full Name', eg.user(fullName: 'Name'), false);
      doCheck('ull ame', eg.user(fullName: 'Full Name'), false);
      doCheck('ull Name', eg.user(fullName: 'Full Name'), false);
      doCheck('Full ame', eg.user(fullName: 'Full Name'), false);
      doCheck('Full Full', eg.user(fullName: 'Full Name'), false);
      doCheck('Name Name', eg.user(fullName: 'Full Name'), false);
      doCheck('Name Full', eg.user(fullName: 'Full Name'), false);
      doCheck('Name Four Full Words', eg.user(fullName: 'Full Name Four Words'), false);
      doCheck('F Full', eg.user(fullName: 'Full Name Four Words'), false);
      doCheck('Four F', eg.user(fullName: 'Full Name Four Words'), false);
    });
  });

  group('MentionAutocompleteView sorting users results', () {
    late PerAccountStore store;

    Future<void> prepare({
      List<User> users = const [],
      List<RecentDmConversation> dmConversations = const [],
      List<Message> messages = const [],
    }) async {
      store = eg.store(initialSnapshot: eg.initialSnapshot(
        recentPrivateConversations: dmConversations));
      await store.addUsers(users);
      await store.addMessages(messages);
    }

    group('compareRecentMessageIds', () {
      test('both a and b are non-null', () async {
        check(MentionAutocompleteView.compareRecentMessageIds(2, 5)).isLessThan(0);
        check(MentionAutocompleteView.compareRecentMessageIds(5, 2)).isGreaterThan(0);
        check(MentionAutocompleteView.compareRecentMessageIds(5, 5)).equals(0);
      });

      test('one of a and b is null', () async {
        check(MentionAutocompleteView.compareRecentMessageIds(null, 5)).isLessThan(0);
        check(MentionAutocompleteView.compareRecentMessageIds(5, null)).isGreaterThan(0);
      });

      test('both of a and b are null', () async {
        check(MentionAutocompleteView.compareRecentMessageIds(null, null)).equals(0);
      });
    });

    group('compareByRecency', () {
      final userA = eg.otherUser;
      final userB = eg.thirdUser;
      final stream = eg.stream();
      const topic1 = 'topic1';
      const topic2 = 'topic2';

      Message message(User sender, String topic) {
        return eg.streamMessage(sender: sender, stream: stream, topic: topic);
      }

      int compareAB({required String? topic}) {
        final resultAB = MentionAutocompleteView.compareByRecency(userA, userB,
          streamId: stream.streamId, topic: topic, store: store);
        final resultBA = MentionAutocompleteView.compareByRecency(userB, userA,
          streamId: stream.streamId, topic: topic, store: store);
        switch (resultAB) {
          case <0: check(resultBA).isGreaterThan(0);
          case >0: check(resultBA).isLessThan(0);
          default: check(resultBA).equals(0);
        }
        return resultAB;
      }

      test('favor user most recent in topic', () async {
        await prepare(messages: [message(userA, topic1), message(userB, topic1)]);
        check(compareAB(topic: topic1)).isGreaterThan(0);
      });

      test('favor most recent in topic ahead of most recent in stream', () async {
        await prepare(messages: [
          message(userA, topic1), message(userB, topic1), message(userA, topic2)]);
        check(compareAB(topic: topic1)).isGreaterThan(0);
      });

      test('no activity in topic -> favor user most recent in stream', () async {
        await prepare(messages: [message(userA, topic1), message(userB, topic1)]);
        check(compareAB(topic: topic2)).isGreaterThan(0);
      });

      test('no topic provided -> favor user most recent in stream', () async {
        await prepare(messages: [message(userA, topic1), message(userB, topic2)]);
        check(compareAB(topic: null)).isGreaterThan(0);
      });

      test('no activity in topic/stream -> favor none', () async {
        await prepare(messages: []);
        check(compareAB(topic: null)).equals(0);
      });
    });

    group('compareByDms', () {
      const idA = 1;
      const idB = 2;

      int compareAB() => MentionAutocompleteView.compareByDms(
        eg.user(userId: idA),
        eg.user(userId: idB),
        store: store,
      );

      test('has DMs with userA and userB, latest with userA -> prioritizes userA', () async {
        await prepare(dmConversations: [
          RecentDmConversation(userIds: [idA],      maxMessageId: 200),
          RecentDmConversation(userIds: [idA, idB], maxMessageId: 100),
        ]);
        check(compareAB()).isLessThan(0);
      });

      test('has DMs with userA and userB, latest with userB -> prioritizes userB', () async {
        await prepare(dmConversations: [
          RecentDmConversation(userIds: [idB],      maxMessageId: 200),
          RecentDmConversation(userIds: [idA, idB], maxMessageId: 100),
        ]);
        check(compareAB()).isGreaterThan(0);
      });

      test('has DMs with userA and userB, equally recent -> prioritizes neither', () async {
        await prepare(dmConversations: [
          RecentDmConversation(userIds: [idA, idB], maxMessageId: 100),
        ]);
        check(compareAB()).equals(0);
      });

      test('has DMs with userA but not userB -> prioritizes userA', () async {
        await prepare(dmConversations: [
          RecentDmConversation(userIds: [idA], maxMessageId: 100),
        ]);
        check(compareAB()).isLessThan(0);
      });

      test('has DMs with userB but not userA -> prioritizes userB', () async {
        await prepare(dmConversations: [
          RecentDmConversation(userIds: [idB], maxMessageId: 100),
        ]);
        check(compareAB()).isGreaterThan(0);
      });

      test('has no DMs with userA or userB -> prioritizes neither', () async {
        await prepare(dmConversations: []);
        check(compareAB()).equals(0);
      });
    });

    group('ranking across signals', () {
      void checkPrecedes(Narrow narrow, User userA, Iterable<User> usersB) {
        final view = MentionAutocompleteView.init(store: store, narrow: narrow);
        for (final userB in usersB) {
          check(view.debugCompareUsers(userA, userB)).isLessThan(0);
          check(view.debugCompareUsers(userB, userA)).isGreaterThan(0);
        }
      }

      void checkRankEqual(Narrow narrow, List<User> users) {
        final view = MentionAutocompleteView.init(store: store, narrow: narrow);
        for (int i = 0; i < users.length; i++) {
          for (int j = i + 1; j < users.length; j++) {
            check(view.debugCompareUsers(users[i], users[j])).equals(0);
            check(view.debugCompareUsers(users[j], users[i])).equals(0);
          }
        }
      }

      test('TopicNarrow: topic recency > stream recency > DM recency', () async {
        final users = List.generate(5, (i) => eg.user());
        final stream = eg.stream();
        final narrow = TopicNarrow(stream.streamId, 'this');
        await prepare(users: users, messages: [
          eg.streamMessage(sender: users[1], stream: stream, topic: 'this'),
          eg.streamMessage(sender: users[0], stream: stream, topic: 'this'),
          eg.streamMessage(sender: users[2], stream: stream, topic: 'other'),
          eg.streamMessage(sender: users[1], stream: stream, topic: 'other'),
          eg.dmMessage(from: users[3], to: [users[4], eg.selfUser]),
          eg.dmMessage(from: users[2], to: [eg.selfUser]),
        ]);
        checkPrecedes(narrow, users[0], users.skip(1));
        checkPrecedes(narrow, users[1], users.skip(2));
        checkPrecedes(narrow, users[2], users.skip(3));
        checkRankEqual(narrow, [users[3], users[4]]);
      });

      test('StreamNarrow: stream recency > DM recency', () async {
        final users = List.generate(4, (i) => eg.user());
        final stream = eg.stream();
        final narrow = StreamNarrow(stream.streamId);
        await prepare(users: users, messages: [
          eg.streamMessage(sender: users[1], stream: stream),
          eg.streamMessage(sender: users[0], stream: stream),
          eg.dmMessage(from: users[2], to: [users[3], eg.selfUser]),
          eg.dmMessage(from: users[1], to: [eg.selfUser]),
        ]);
        checkPrecedes(narrow, users[0], users.skip(1));
        checkPrecedes(narrow, users[1], users.skip(2));
        checkRankEqual(narrow, [users[2], users[3]]);
      });

      test('DmNarrow: DM recency > this-conversation recency or stream recency', () async {
        final users = List.generate(4, (i) => eg.user());
        await prepare(users: users, messages: [
          eg.dmMessage(from: users[3], to: [eg.selfUser]),
          eg.dmMessage(from: users[1], to: [users[2], eg.selfUser]),
          eg.dmMessage(from: users[0], to: [eg.selfUser]),
          eg.streamMessage(sender: users[1]),
          eg.streamMessage(sender: users[2]),
          eg.streamMessage(sender: users[3]),
        ]);
        for (final narrow in [
          DmNarrow.withUser(users[3].userId, selfUserId: eg.selfUser.userId),
          DmNarrow.withOtherUsers([users[1].userId, users[2].userId],
            selfUserId: eg.selfUser.userId),
          DmNarrow.withUser(users[1].userId, selfUserId: eg.selfUser.userId),
        ]) {
          checkPrecedes(narrow, users[0], users.skip(1));
          checkRankEqual(narrow, [users[1], users[2]]);
          checkPrecedes(narrow, users[1], users.skip(3));
          checkPrecedes(narrow, users[2], users.skip(3));
        }
      });
    });

    group('autocomplete suggests relevant users in the intended order', () {
      // The order should be:
      // 1. Users most recent in the current topic/stream.
      // 2. Users most recent in the DM conversations.

      final stream = eg.stream();
      const topic = 'topic';
      final streamNarrow = StreamNarrow(stream.streamId);
      final topicNarrow = TopicNarrow(stream.streamId, topic);
      final dmNarrow = DmNarrow.withUser(eg.selfUser.userId, selfUserId: eg.selfUser.userId);

      final users = List.generate(5, (i) => eg.user(userId: i));

      final dmConversations = [
        RecentDmConversation(userIds: [3],    maxMessageId: 300),
        RecentDmConversation(userIds: [0],    maxMessageId: 200),
        RecentDmConversation(userIds: [0, 1], maxMessageId: 100),
      ];

      StreamMessage streamMessage({required int id, required int senderId, String? topic}) =>
        eg.streamMessage(id: id, sender: users[senderId], topic: topic, stream: stream);

      final messages = [
        streamMessage(id: 50, senderId: 0, topic: topic),
        streamMessage(id: 60, senderId: 4),
      ];

      Future<void> prepareStore({bool includeMessageHistory = false}) async {
        await prepare(users: users, dmConversations: dmConversations,
          messages: includeMessageHistory ? messages : []);
      }

      Future<void> checkResultsIn(Narrow narrow, {required List<int> expected}) async {
        final view = MentionAutocompleteView.init(store: store, narrow: narrow);

        bool done = false;
        view.addListener(() { done = true; });
        view.query = MentionAutocompleteQuery('');
        await Future(() {});
        check(done).isTrue();
        final results = view.results
          .map((e) => (e as UserMentionAutocompleteResult).userId);
        check(results).deepEquals(expected);
      }

      group('StreamNarrow & TopicNarrow', () {
        late FakeApiConnection connection;
        late MessageListView messageList;

        Future<void> fetchInitialMessagesIn(Narrow narrow) async {
          connection = store.connection as FakeApiConnection;
          connection.prepare(json: newestResult(
            foundOldest: false,
            messages: narrow is StreamNarrow
              ? messages
              : messages.where((m) => m.topic == topic).toList(),
          ).toJson());
          messageList = MessageListView.init(store: store, narrow: narrow);
          await messageList.fetchInitial();
        }

        Future<void> checkInitialResultsIn(Narrow narrow,
            {required List<int> expected, bool includeStream = false}) async {
          assert(narrow is! StreamNarrow || !includeStream);
          await prepareStore(includeMessageHistory: includeStream);
          await fetchInitialMessagesIn(narrow);
          await checkResultsIn(narrow, expected: expected);
        }

        test('StreamNarrow', () async {
          await checkInitialResultsIn(streamNarrow, expected: [4, 0, 3, 1, 2]);
        });

        test('StreamNarrow, new message arrives', () async {
          await checkInitialResultsIn(streamNarrow, expected: [4, 0, 3, 1, 2]);

          // Until now, latest message id in [stream] is 60.
          await store.addMessage(streamMessage(id: 70, senderId: 2));

          await checkResultsIn(streamNarrow, expected: [2, 4, 0, 3, 1]);
        });

        test('StreamNarrow, a batch of older messages arrives', () async {
          await checkInitialResultsIn(streamNarrow, expected: [4, 0, 3, 1, 2]);

          // Until now, oldest message id in [stream] is 50.
          final oldMessages = [
            streamMessage(id: 30, senderId: 1),
            streamMessage(id: 40, senderId: 2),
          ];
          connection.prepare(json: olderResult(
            anchor: 50, foundOldest: false,
            messages: oldMessages,
          ).toJson());
          await messageList.fetchOlder();

          await checkResultsIn(streamNarrow, expected: [4, 0, 2, 1, 3]);
        });

        test('TopicNarrow, no other messages are in stream', () async {
          await checkInitialResultsIn(topicNarrow, expected: [0, 3, 1, 2, 4]);
        });

        test('TopicNarrow, other messages are in stream', () async {
          await checkInitialResultsIn(topicNarrow, expected: [0, 4, 3, 1, 2],
            includeStream: true);
        });

        test('TopicNarrow, new message arrives', () async {
          await checkInitialResultsIn(topicNarrow, expected: [0, 3, 1, 2, 4]);

          // Until now, latest message id in [topic] is 50.
          await store.addMessage(streamMessage(id: 60, senderId: 2, topic: topic));

          await checkResultsIn(topicNarrow, expected: [2, 0, 3, 1, 4]);
        });

        test('TopicNarrow, a batch of older messages arrives', () async {
          await checkInitialResultsIn(topicNarrow, expected: [0, 3, 1, 2, 4]);

          // Until now, oldest message id in [topic] is 50.
          final oldMessages = [
            streamMessage(id: 30, senderId: 2, topic: topic),
            streamMessage(id: 40, senderId: 4, topic: topic),
          ];
          connection.prepare(json: olderResult(
            anchor: 50, foundOldest: false,
            messages: oldMessages,
          ).toJson());

          await messageList.fetchOlder();
          await checkResultsIn(topicNarrow, expected: [0, 4, 2, 3, 1]);
        });
      });

      group('DmNarrow', () {
        test('DmNarrow, with no topic/stream message history', () async {
          await prepareStore();
          await checkResultsIn(dmNarrow, expected: [3, 0, 1, 2, 4]);
        });

        test('DmNarrow, with topic/stream message history', () async {
          await prepareStore(includeMessageHistory: true);
          await checkResultsIn(dmNarrow, expected: [3, 0, 1, 2, 4]);
        });

        test('DmNarrow, new message arrives', () async {
          await prepareStore();
          await checkResultsIn(dmNarrow, expected: [3, 0, 1, 2, 4]);

          // Until now, latest message id in recent DMs is 300.
          await store.addMessage(eg.dmMessage(id: 400, from: users[1], to: [eg.selfUser]));

          await checkResultsIn(dmNarrow, expected: [1, 3, 0, 2, 4]);
        });
      });

      test('CombinedFeedNarrow', () async {
        await prepareStore();
        // As we do not expect a compose box in [CombinedFeedNarrow], it should
        // not proceed to show any results.
        await check(checkResultsIn(
          const CombinedFeedNarrow(),
          expected: [0, 1, 2, 3, 4])
        ).throws();
      });
    });
  });
}
