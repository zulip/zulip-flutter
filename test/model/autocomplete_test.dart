import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/widgets/compose_box.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';
import 'autocomplete_checks.dart';

void main() {
  group('ComposeContentController.autocompleteIntent', () {
    parseMarkedText(String markedText) {
      final TextSelection selection;
      int? expectedSyntaxStart;
      final textBuffer = StringBuffer();
      final caretPositions = [];
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
    const narrow = CombinedFeedNarrow();
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
      const narrow = CombinedFeedNarrow();
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
    const narrow = CombinedFeedNarrow();
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
    const narrow = CombinedFeedNarrow();
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

  test('MentionAutocompleteView mutating store.users while in progress causes retry', () async {
    const narrow = CombinedFeedNarrow();
    final store = eg.store();
    for (int i = 0; i < 1500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    final view = MentionAutocompleteView.init(store: store, narrow: narrow);

    bool done = false;
    view.addListener(() { done = true; });
    view.query = MentionAutocompleteQuery('User 10000');

    await Future(() {});
    check(done).isFalse();
    await store.addUser(eg.user(userId: 10000, email: 'user10000@example.com', fullName: 'User 10000'));
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isTrue();
    check(view.results).single
      .isA<UserMentionAutocompleteResult>()
      .userId.equals(10000);
    // new result sticks; no "zombie" result from `store.users` pre-mutation
    for (int i = 0; i < 10; i++) { // for good measure
      await Future(() {});
      check(view.results).single
        .isA<UserMentionAutocompleteResult>()
        .userId.equals(10000);
    }
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
}
