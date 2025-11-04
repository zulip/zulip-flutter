import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/generated/l10n/zulip_localizations.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/compose.dart';
import 'package:zulip/model/emoji.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/compose_box.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../stdlib_checks.dart';
import 'test_store.dart';
import 'autocomplete_checks.dart';

typedef MarkedTextParse = ({int? expectedSyntaxStart, TextEditingValue value});

final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

void main() {
  ({int? expectedSyntaxStart, TextEditingValue value}) parseMarkedText(String markedText) {
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

  group('ComposeContentController.autocompleteIntent', () {
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
    void doTest(String markedText, ComposeAutocompleteQuery? expectedQuery) {
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

    MentionAutocompleteQuery mention(String raw) => MentionAutocompleteQuery(raw, silent: false);
    MentionAutocompleteQuery silentMention(String raw) => MentionAutocompleteQuery(raw, silent: true);
    EmojiAutocompleteQuery emoji(String raw) => EmojiAutocompleteQuery(raw);

    doTest('', null);
    doTest('^', null);

    doTest('!@#\$%&*()_+', null);

    // @-mentions.

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

    doTest('~@^_', mention('')); // Odd/unlikely, but should not crash

    doTest('~@__^', silentMention('_'));

    doTest('~@^abc^', mention('abc')); doTest('~@_^abc^', silentMention('abc'));
    doTest('~@a^bc^', mention('abc')); doTest('~@_a^bc^', silentMention('abc'));
    doTest('~@ab^c^', mention('abc')); doTest('~@_ab^c^', silentMention('abc'));
    doTest('~^@^', mention(''));       doTest('~^@_^', silentMention(''));
    // but:
    doTest('^hello @chris^', null);    doTest('^hello @_chris^', null);

    doTest('~@me@zulip.com^', mention('me@zulip.com'));  doTest('~@_me@zulip.com^', silentMention('me@zulip.com'));
    doTest('~@me@^zulip.com^', mention('me@zulip.com')); doTest('~@_me@^zulip.com^', silentMention('me@zulip.com'));
    doTest('~@me^@zulip.com^', mention('me@zulip.com')); doTest('~@_me^@zulip.com^', silentMention('me@zulip.com'));
    doTest('~@^me@zulip.com^', mention('me@zulip.com')); doTest('~@_^me@zulip.com^', silentMention('me@zulip.com'));

    doTest('~@abc^', mention('abc'));   doTest('~@_abc^', silentMention('abc'));
    doTest(' ~@abc^', mention('abc'));  doTest(' ~@_abc^', silentMention('abc'));
    doTest('(~@abc^', mention('abc'));  doTest('(~@_abc^', silentMention('abc'));
    doTest('—~@abc^', mention('abc'));  doTest('—~@_abc^', silentMention('abc'));
    doTest('"~@abc^', mention('abc'));  doTest('"~@_abc^', silentMention('abc'));
    doTest('“~@abc^', mention('abc'));  doTest('“~@_abc^', silentMention('abc'));
    doTest('。~@abc^', mention('abc')); doTest('。~@_abc^', silentMention('abc'));
    doTest('«~@abc^', mention('abc'));  doTest('«~@_abc^', silentMention('abc'));

    doTest('~@ab^c', mention('ab')); doTest('~@_ab^c', silentMention('ab'));
    doTest('~@a^bc', mention('a'));  doTest('~@_a^bc', silentMention('a'));
    doTest('~@^abc', mention(''));   doTest('~@_^abc', silentMention(''));
    doTest('~@^', mention(''));      doTest('~@_^', silentMention(''));

    doTest('~@abc ^', mention('abc '));  doTest('~@_abc ^', silentMention('abc '));
    doTest('~@abc^ ^', mention('abc ')); doTest('~@_abc^ ^', silentMention('abc '));
    doTest('~@ab^c ^', mention('abc ')); doTest('~@_ab^c ^', silentMention('abc '));
    doTest('~@^abc ^', mention('abc ')); doTest('~@_^abc ^', silentMention('abc '));

    doTest('Please ask ~@chris^', mention('chris'));             doTest('Please ask ~@_chris^', silentMention('chris'));
    doTest('Please ask ~@chris bobbe^', mention('chris bobbe')); doTest('Please ask ~@_chris bobbe^', silentMention('chris bobbe'));

    doTest('~@Rodion Romanovich Raskolnikov^', mention('Rodion Romanovich Raskolnikov'));
    doTest('~@_Rodion Romanovich Raskolniko^', silentMention('Rodion Romanovich Raskolniko'));
    doTest('~@Родион Романович Раскольников^', mention('Родион Романович Раскольников'));
    doTest('~@_Родион Романович Раскольнико^', silentMention('Родион Романович Раскольнико'));
    doTest('If @chris is around, please ask him.^', null); // @ sign is too far away from cursor
    doTest('If @_chris is around, please ask him.^', null); // @ sign is too far away from cursor

    // Emoji (":smile:").

    // Basic positive examples, to contrast with all the negative examples below.
    doTest('~:^', emoji(''));
    doTest('~:a^', emoji('a'));
    doTest('~:a ^', emoji('a '));
    doTest('~:a_^', emoji('a_'));
    doTest('~:a b^', emoji('a b'));
    doTest('ok ~:s^', emoji('s'));
    doTest('this: ~:s^', emoji('s'));

    doTest('^:', null);
    doTest('^:abc', null);
    doTest(':abc', null); // (no cursor)

    // Avoid interpreting colons in normal prose as queries.
    doTest(': ^', null);
    doTest(':\n^', null);
    doTest('this:^', null);
    doTest('this: ^', null);
    doTest('là ~:^', emoji('')); // ambiguous in French prose, tant pis
    doTest('là : ^', null);
    doTest('8:30^', null);

    // Avoid interpreting already-entered `:foo:` syntax as queries.
    doTest(':smile:^', null);

    // Avoid interpreting emoticons as queries.
    doTest(':-^', null);
    doTest(':)^', null); doTest(':-)^', null);
    doTest(':(^', null); doTest(':-(^', null);
    doTest(':/^', null); doTest(':-/^', null);
    doTest('~:p^', emoji('p')); // ambiguously an emoticon
    doTest(':-p^', null);

    // Avoid interpreting as queries some ways colons appear in source code.
    doTest('::^', null);
    doTest(':<^', null);
    doTest(':=^', null);

    // Emoji names may have letters and numbers in various scripts.
    // (A few appear in the server's list of Unicode emoji;
    // many more might be in a given realm's custom emoji.)
    doTest('~:コ^', emoji('コ'));
    doTest('~:空^', emoji('空'));
    doTest('~:φ^', emoji('φ'));
    doTest('~:100^', emoji('100'));
    doTest('~:１^', emoji('１')); // U+FF11 FULLWIDTH DIGIT ONE
    doTest('~:٢^', emoji('٢')); // U+0662 ARABIC-INDIC DIGIT TWO

    // Emoji names may have dashes '-'.
    doTest('~:e-m^', emoji('e-m'));
    doTest('~:jack-o-l^', emoji('jack-o-l'));

    // Just one emoji has a '+' in its name, namely ':+1:'.
    doTest('~:+^', emoji('+'));
    doTest('~:+1^', emoji('+1'));
    doTest(':+2^', null);
    doTest(':+100^', null);
    doTest(':+1 ^', null);
    doTest(':1+1^', null);

    // Accept punctuation before the emoji: opening…
    doTest('(~:^', emoji('')); doTest('(~:a^', emoji('a'));
    doTest('[~:^', emoji('')); doTest('[~:a^', emoji('a'));
    doTest('«~:^', emoji('')); doTest('«~:a^', emoji('a'));
    doTest('（~:^', emoji('')); doTest('（~:a^', emoji('a'));
    // … closing…
    doTest(')~:^', emoji('')); doTest(')~:a^', emoji('a'));
    doTest(']~:^', emoji('')); doTest(']~:a^', emoji('a'));
    doTest('»~:^', emoji('')); doTest('»~:a^', emoji('a'));
    doTest('）~:^', emoji('')); doTest('）~:a^', emoji('a'));
    // … and other.
    doTest('.~:^', emoji('')); doTest('.~:a^', emoji('a'));
    doTest(',~:^', emoji('')); doTest(',~:a^', emoji('a'));
    doTest('，~:^', emoji('')); doTest('，~:a^', emoji('a'));
    doTest('。~:^', emoji('')); doTest('。~:a^', emoji('a'));
  });

  test('MentionAutocompleteView misc', () async {
    const narrow = ChannelNarrow(1);
    final store = eg.store();
    await store.addUsers([eg.selfUser, eg.otherUser, eg.thirdUser]);

    final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
      narrow: narrow, query: MentionAutocompleteQuery('Third'));
    bool done = false;
    view.addListener(() { done = true; });
    await Future(() {});
    await Future(() {});
    check(done).isTrue();
    check(view.results).single
      .isA<UserMentionAutocompleteResult>()
      .userId.equals(eg.thirdUser.userId);
  });

  test('MentionAutocompleteView not starve timers', () {
    return awaitFakeAsync((binding) async {
      const narrow = ChannelNarrow(1);
      final store = eg.store();
      await store.addUsers([eg.selfUser, eg.otherUser, eg.thirdUser]);

      bool searchDone = false;

      // Schedule a timer event with zero delay.
      // This stands in for a user interaction, or frame rendering timer,
      // placing an urgent task on the event queue.
      bool timerDone = false;
      Timer(const Duration(), () {
        timerDone = true;
        // The timer should go first, before the search does its work.
        check(searchDone).isFalse();
      });

      final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
        narrow: narrow, query: MentionAutocompleteQuery('Third'));
      view.addListener(() {
        searchDone = true;
      });

      binding.elapse(const Duration(seconds: 1));

      check(timerDone).isTrue();
      check(searchDone).isTrue();
      check(view.results).single
        .isA<UserMentionAutocompleteResult>()
        .userId.equals(eg.thirdUser.userId);
    });
  });

  test('MentionAutocompleteView yield between batches of 1000', () async {
    const narrow = ChannelNarrow(1);
    final store = eg.store();
    for (int i = 1; i <= 2500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    for (int i = 1; i <= 2500; i++) {
      await store.addUserGroup(eg.userGroup(id: i, name: 'User Group $i'));
    }

    bool done = false;
    final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
      narrow: narrow, query: MentionAutocompleteQuery('User 2222'));
    view.addListener(() { done = true; });

    // three batches for users
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isFalse();

    // three batches for user groups
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isTrue();

    check(view.results).deepEquals(<Condition<Object?>>[
      (it) => it
        .isA<UserMentionAutocompleteResult>()
        .userId.equals(2222),
      (it) => it
        .isA<UserGroupMentionAutocompleteResult>()
        .groupId.equals(2222),
    ]);
  });

  test('MentionAutocompleteView new query during computation replaces old', () async {
    const narrow = ChannelNarrow(1);
    final store = eg.store();
    for (int i = 1; i <= 1500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    for (int i = 1; i <= 1500; i++) {
      await store.addUserGroup(eg.userGroup(id: i, name: 'User Group $i'));
    }

    bool done = false;
    final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
      narrow: narrow, query: MentionAutocompleteQuery('User 1111'));
    view.addListener(() { done = true; });

    await Future(() {});
    check(done).isFalse();
    view.query = MentionAutocompleteQuery('User 234');

    // …new query goes through all user batches
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isFalse();
    // …and all user-group batches
    await Future(() {});
    check(done).isFalse();
    await Future(() {});
    check(done).isTrue(); // new result is set

    void checkResult() {
      check(view.results).deepEquals(<Condition<Object?>>[
        (it) => it
          .isA<UserMentionAutocompleteResult>()
          .userId.equals(234),
        (it) => it
          .isA<UserGroupMentionAutocompleteResult>()
          .groupId.equals(234),
      ]);
    }
    checkResult();

    // new result sticks; it isn't clobbered with old query's result
    for (int i = 0; i < 10; i++) { // for good measure
      await Future(() {});
      checkResult();
    }
  });

  test('MentionAutocompleteView mutating user store while in progress does not '
      'prevent query from finishing', () async {
    const narrow = ChannelNarrow(1);
    final store = eg.store();
    for (int i = 1; i <= 2500; i++) {
      await store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }

    bool done = false;
    final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
      narrow: narrow, query: MentionAutocompleteQuery('User 110'));
    view.addListener(() { done = true; });

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

  group('MentionAutocompleteView sorting results', () {
    late PerAccountStore store;

    Future<void> prepare({
      User? selfUser,
      List<User> users = const [],
      List<UserGroup> userGroups = const [],
      List<RecentDmConversation> dmConversations = const [],
      List<Message> messages = const [],
    }) async {
      selfUser ??= eg.selfUser;
      if (!users.contains(selfUser)) {
        users = [...users, selfUser];
      }
      store = eg.store(selfUser: selfUser, initialSnapshot: eg.initialSnapshot(
        realmUsers: users,
        recentPrivateConversations: dmConversations));
      await store.addUserGroups(userGroups);
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
        final realTopic = topic == null ? null : TopicName(topic);
        final resultAB = MentionAutocompleteView.compareByRecency(userA, userB,
          streamId: stream.streamId, topic: realTopic, store: store);
        final resultBA = MentionAutocompleteView.compareByRecency(userB, userA,
          streamId: stream.streamId, topic: realTopic, store: store);
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

    group('compareByBotStatus', () {
      final humanUser = eg.user(isBot: false);
      final botUser = eg.user(isBot: true);

      int compareAB(User a, User b) => MentionAutocompleteView.compareByBotStatus(a, b);

      test('userA is human, userB is bot -> favor userA', () {
        check(compareAB(humanUser, botUser)).isLessThan(0);
      });

      test('userA is bot, userB is human -> favor userB', () {
        check(compareAB(botUser, humanUser)).isGreaterThan(0);
      });

      test('both users have the same bot status -> favor none', () {
        check(compareAB(humanUser, humanUser)).equals(0);
        check(compareAB(botUser, botUser)).equals(0);
      });
    });

    group('compareByAlphabeticalOrder', () {
      int compareAB(String aName, String bName) => MentionAutocompleteView.compareByAlphabeticalOrder(
        eg.user(fullName: aName), eg.user(fullName: bName), store: store);

      test("userA's fullName comes first than userB's fullName -> favor userA", () async {
        await prepare();
        check(compareAB('alice', 'brian')).isLessThan(0);
        check(compareAB('alice', 'BRIAN')).isLessThan(0);
        // TODO(i18n): add locale-aware sorting
        // check(compareAB('čarolína', 'david')).isLessThan(0);
      });

      test("userB's fullName comes first than userA's fullName -> favor userB", () async {
        await prepare();
        check(compareAB('brian', 'alice')).isGreaterThan(0);
        check(compareAB('BRIAN', 'alice')).isGreaterThan(0);
        // TODO(i18n): add locale-aware sorting
        // check(compareAB('david', 'čarolína')).isGreaterThan(0);
      });

      test('both users have identical fullName -> favor none', () async {
        await prepare();
        check(compareAB('alice', 'alice')).equals(0);
        check(compareAB('BRIAN', 'brian')).equals(0);
        // TODO(i18n): add locale-aware sorting
        // check(compareAB('čarolína', 'carolina')).equals(0);
      });
    });

    group('ranking across signals', () {
      void checkPrecedes(Narrow narrow, User userA, Iterable<User> usersB) {
        final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
          narrow: narrow, query: MentionAutocompleteQuery(''));
        for (final userB in usersB) {
          check(view.debugCompareUsers(userA, userB)).isLessThan(0);
          check(view.debugCompareUsers(userB, userA)).isGreaterThan(0);
        }
      }

      void checkRankEqual(Narrow narrow, List<User> users) {
        final view = MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
          narrow: narrow, query: MentionAutocompleteQuery(''));
        for (int i = 0; i < users.length; i++) {
          for (int j = i + 1; j < users.length; j++) {
            check(view.debugCompareUsers(users[i], users[j])).equals(0);
            check(view.debugCompareUsers(users[j], users[i])).equals(0);
          }
        }
      }

      test('TopicNarrow: topic recency > stream recency > DM recency > human/bot > name', () async {
        // The user with the greatest topic recency ranks last on each of the
        // other criteria, but comes out first in the end, showing that
        // topic recency comes first.  Then among the remaining users, the one
        // with the greatest stream recency ranks last on each of the remaining
        // criteria, but comes out second in the end; and so on.
        final users = [
          eg.user(fullName: 'Z', isBot: true), // wins by topic recency
          eg.user(fullName: 'Y', isBot: true), // runner-up, by stream recency
          eg.user(fullName: 'X', isBot: true), // runner-up, by DM recency
          eg.user(fullName: 'W', isBot: false), // runner-up, by human-vs-bot
          eg.user(fullName: 'A', isBot: true), // runner-up, by name
          eg.user(fullName: 'B', isBot: true), // tied because no remaining criteria
          eg.user(fullName: 'b', isBot: true),
        ];
        final stream = eg.stream();
        final narrow = eg.topicNarrow(stream.streamId, 'this');
        await prepare(users: users, messages: [
          eg.streamMessage(sender: users[1], stream: stream, topic: 'this'),
          eg.streamMessage(sender: users[0], stream: stream, topic: 'this'),
          eg.streamMessage(sender: users[2], stream: stream, topic: 'other'),
          eg.streamMessage(sender: users[1], stream: stream, topic: 'other'),
          eg.dmMessage(from: users[3], to: [...users.skip(4), eg.selfUser]),
          eg.dmMessage(from: users[2], to: [eg.selfUser]),
        ]);
        checkPrecedes(narrow, users[0], users.skip(1));
        checkPrecedes(narrow, users[1], users.skip(2));
        checkPrecedes(narrow, users[2], users.skip(3));
        checkPrecedes(narrow, users[3], users.skip(4));
        checkPrecedes(narrow, users[4], users.skip(5));
        checkRankEqual(narrow, [users[5], users[6]]);
      });

      test('ChannelNarrow: stream recency > DM recency > human/bot > name', () async {
        // Same principle as for TopicNarrow; see that test case above.
        final users = [
          eg.user(fullName: 'Z', isBot: true), // wins by stream recency
          eg.user(fullName: 'Y', isBot: true), // runner-up, by DM recency
          eg.user(fullName: 'X', isBot: false), // runner-up, by human-vs-bot
          eg.user(fullName: 'A', isBot: true), // runner-up, by name
          eg.user(fullName: 'B', isBot: true), // tied because no remaining criteria
          eg.user(fullName: 'b', isBot: true),
        ];
        final stream = eg.stream();
        final narrow = ChannelNarrow(stream.streamId);
        await prepare(users: users, messages: [
          eg.streamMessage(sender: users[1], stream: stream),
          eg.streamMessage(sender: users[0], stream: stream),
          eg.dmMessage(from: users[2], to: [...users.skip(3), eg.selfUser]),
          eg.dmMessage(from: users[1], to: [eg.selfUser]),
        ]);
        checkPrecedes(narrow, users[0], users.skip(1));
        checkPrecedes(narrow, users[1], users.skip(2));
        checkPrecedes(narrow, users[2], users.skip(3));
        checkPrecedes(narrow, users[3], users.skip(4));
        checkRankEqual(narrow, [users[4], users[5]]);
      });

      test('DmNarrow: DM recency > human/bot > name, ignore this-conversation recency and stream recency', () async {
        // Same principle as for TopicNarrow; see that test case above.
        final users = [
          // First user wins by DM recency.
          eg.user(fullName: 'Z', isBot: true),
          // Next two are runners-up by DM recency, and have a two-way tie
          // despite different this-conversation recency (because that doesn't count).
          eg.user(fullName: 'Y', isBot: true),
          eg.user(fullName: 'y', isBot: true),
          // Next user is the runner-up due to DM recency, and comes after the
          // above users even when it has greater this-conversation recency
          // (because that doesn't count).
          eg.user(fullName: 'X', isBot: true),
          // Remainder have no DM recency and so come later.
          // Next user is the runner-up due to human-vs-bot.
          eg.user(fullName: 'W', isBot: false),
          // Next user is the runner-up due to name.
          eg.user(fullName: 'A', isBot: true),
          // Remaining users are tied, even though they differ in stream recency
          // (because that doesn't count).
          eg.user(fullName: 'B', isBot: true),
          eg.user(fullName: 'b', isBot: true),
        ];
        await prepare(users: users, messages: [
          eg.dmMessage(from: users[3], to: [eg.selfUser]),
          eg.dmMessage(from: users[1], to: [users[2], eg.selfUser]),
          eg.dmMessage(from: users[0], to: [eg.selfUser]),
          for (final user in users.skip(1))
            eg.streamMessage(sender: user),
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
          checkPrecedes(narrow, users[3], users.skip(4));
          checkPrecedes(narrow, users[4], users.skip(5));
          checkPrecedes(narrow, users[5], users.skip(6));
          checkRankEqual(narrow, [users[6], users[7]]);
        }
      });

      test('CombinedFeedNarrow gives error', () async {
        await prepare(users: [eg.user(), eg.user()], messages: []);
        const narrow = CombinedFeedNarrow();
        check(() => MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
                      narrow: narrow, query: MentionAutocompleteQuery('')))
          .throws<AssertionError>();
      });

      test('MentionsNarrow gives error', () async {
        await prepare(users: [eg.user(), eg.user()], messages: []);
        const narrow = MentionsNarrow();
        check(() => MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
                      narrow: narrow, query: MentionAutocompleteQuery('')))
          .throws<AssertionError>();
      });

      test('StarredMessagesNarrow gives error', () async {
        await prepare(users: [eg.user(), eg.user()], messages: []);
        const narrow = StarredMessagesNarrow();
        check(() => MentionAutocompleteView.init(store: store, localizations: zulipLocalizations,
                      narrow: narrow, query: MentionAutocompleteQuery('')))
          .throws<AssertionError>();
      });
    });

    test('final results end-to-end', () async {
      Future<Iterable<MentionAutocompleteResult>> getResults(
          Narrow narrow, MentionAutocompleteQuery query) async {
        bool done = false;
        final view = MentionAutocompleteView.init(store: store,
          localizations: zulipLocalizations, narrow: narrow, query: query);
        view.addListener(() { done = true; });
        await Future(() {}); // users
        await Future(() {}); // groups
        check(done).isTrue();
        final results = view.results;
        view.dispose();
        return results;
      }

      Condition<Object?> isUser(int userId) {
        return (it) => it.isA<UserMentionAutocompleteResult>()
          .userId.equals(userId);
      }

      Condition<Object?> isUserGroup(int id) {
        return (it) => it.isA<UserGroupMentionAutocompleteResult>()
          .groupId.equals(id);
      }

      Condition<Object?> isWildcard(WildcardMentionOption option) {
        return (it) => it.isA<WildcardMentionAutocompleteResult>()
          .wildcardOption.equals(option);
      }

      final stream = eg.stream();
      const topic = 'topic';
      final topicNarrow = eg.topicNarrow(stream.streamId, topic);

      final users = [
        eg.user(userId: 1, fullName: 'User One'),
        eg.user(userId: 2, fullName: 'User Two'),
        eg.user(userId: 3, fullName: 'User Three'),
        eg.user(userId: 4, fullName: 'User Four'),
        eg.user(userId: 5, fullName: 'User Five'),
        eg.user(userId: 6, fullName: 'User Six', isBot: true),
        eg.user(userId: 7, fullName: 'User Seven'),
      ];
      final selfUser = users.last;

      final userGroups = [
        eg.userGroup(id: 1, name: 'User Group One'),
        eg.userGroup(id: 2, name: 'User Group Two'),
        eg.userGroup(id: 3, name: 'User Group Three'),
        eg.userGroup(id: 4, name: 'User Group Four'),
      ];

      await prepare(users: users, selfUser: selfUser, userGroups: userGroups,
        messages: [
          eg.streamMessage(sender: users[1-1], stream: stream, topic: topic),
          eg.streamMessage(sender: users[5-1], stream: stream, topic: 'other $topic'),
          eg.dmMessage(from: users[1-1], to: [users[2-1], selfUser]),
          eg.dmMessage(from: users[1-1], to: [selfUser]),
          eg.dmMessage(from: users[4-1], to: [selfUser]),
        ]);

      // Check the ranking of the full list of mentions,
      // i.e. the results for an empty query.
      // The order should be:
      // 1. Wildcards before individual users; user groups (alphabetically) after.
      // 2. Users most recent in the current topic/stream.
      // 3. Users most recent in the DM conversations.
      // 4. Human vs. Bot users (human users come first).
      // 5. Users by name alphabetical order.
      // 6. User groups by name alphabetical order.
      check(await getResults(topicNarrow, MentionAutocompleteQuery(''))).deepEquals([
        isWildcard(WildcardMentionOption.all),
        isWildcard(WildcardMentionOption.topic),
        ...[1, 5, 4, 2, 7, 3, 6].map(isUser),
        ...[4, 1, 3, 2].map(isUserGroup),
      ]);

      // Check the ranking applies also to results filtered by a query.
      check(await getResults(topicNarrow, MentionAutocompleteQuery('t'))).deepEquals([
        isWildcard(WildcardMentionOption.stream),
        isWildcard(WildcardMentionOption.topic),
        isUser(2), isUser(3), // 2 before 3 by DM recency
        isUserGroup(3), isUserGroup(2), // 3 before 2 by alphabet ("…Three" before "…Two")
      ]);
      check(await getResults(topicNarrow, MentionAutocompleteQuery('f'))).deepEquals([
        isUser(5), isUser(4),
        isUserGroup(4),
      ]);
    });
  });

  group('MentionAutocompleteView.computeWildcardMentionResults', () {
    Iterable<WildcardMentionOption> getWildcardOptionsFor(String rawQuery, {
      bool isSilent = false,
      required Narrow narrow,
      int? zulipFeatureLevel,
      ZulipLocalizations? localizations,
    }) {
      final store = eg.store(
        account: eg.account(user: eg.selfUser, zulipFeatureLevel: zulipFeatureLevel),
        initialSnapshot: eg.initialSnapshot(zulipFeatureLevel: zulipFeatureLevel));
      localizations ??= zulipLocalizations;
      final view = MentionAutocompleteView.init(store: store, localizations: localizations,
        narrow: narrow, query: MentionAutocompleteQuery(rawQuery, silent: isSilent));
      final results = <MentionAutocompleteResult>[];
      view.computeWildcardMentionResults(results: results,
        isComposingChannelMessage: narrow is ChannelNarrow
          || narrow is TopicNarrow);
      view.dispose();
      return results.map((e) => (e as WildcardMentionAutocompleteResult).wildcardOption);
    }

    const channelNarrow = ChannelNarrow(1);
    const topicNarrow = TopicNarrow(1, TopicName('topic'));
    final dmNarrow = DmNarrow.withUser(10, selfUserId: 5);

    final testCases = [
      ('',          channelNarrow, [WildcardMentionOption.all, WildcardMentionOption.topic]),
      ('',          topicNarrow,   [WildcardMentionOption.all, WildcardMentionOption.topic]),
      ('',          dmNarrow,      [WildcardMentionOption.all]),

      ('c',         channelNarrow, [WildcardMentionOption.channel, WildcardMentionOption.topic]),
      ('ch',        topicNarrow,   [WildcardMentionOption.channel]),
      ('str',       channelNarrow, [WildcardMentionOption.stream]),
      ('e',         topicNarrow,   [WildcardMentionOption.everyone]),
      ('everyone',  channelNarrow, [WildcardMentionOption.everyone]),
      ('t',         topicNarrow,   [WildcardMentionOption.stream, WildcardMentionOption.topic]),
      ('topic',     channelNarrow, [WildcardMentionOption.topic]),
      ('topic etc', topicNarrow,   <WildcardMentionOption>[]),

      ('a',         dmNarrow,      [WildcardMentionOption.all]),
      ('every',     dmNarrow,      [WildcardMentionOption.everyone]),
      ('channel',   dmNarrow,      <WildcardMentionOption>[]),
      ('stream',    dmNarrow,      <WildcardMentionOption>[]),
      ('topic',     dmNarrow,      <WildcardMentionOption>[]),
    ];

    for (final (String query, Narrow narrow, List<WildcardMentionOption> wildcardOptions) in testCases) {
      test('query "$query" in ${narrow.runtimeType} -> $wildcardOptions', () async {
        check(getWildcardOptionsFor(query, narrow: narrow)).deepEquals(wildcardOptions);
      });
    }

    WildcardTester wildcardTesterForLocale(bool Function(Locale) localePredicate) {
      final locale = ZulipLocalizations.supportedLocales.firstWhere(localePredicate);
      final localizations = lookupZulipLocalizations(locale);

      return (String query, Narrow narrow, List<WildcardMentionOption> expected) {
        test('locale "$locale" -> query "$query" in ${narrow.runtimeType} -> $expected', () {
          check(getWildcardOptionsFor(query, narrow: narrow,
            localizations: localizations)).deepEquals(expected);
        });
      };
    }

    for (final option in WildcardMentionOption.values) {
      // These are hard-coded, and they happened to be lowercase and without
      // diacritics when written.
      // Throw if that changes, to not accidentally break fuzzy matching.
      check(option.canonicalString).equals(
        AutocompleteQuery.lowercaseAndStripDiacritics(option.canonicalString));
    }

    final testArabic = wildcardTesterForLocale((locale) => locale.languageCode == 'ar');
    testArabic('ال',        channelNarrow, [WildcardMentionOption.all, WildcardMentionOption.topic]);
    testArabic('الجميع',    topicNarrow,   [WildcardMentionOption.all]);
    testArabic('الموضوع',   channelNarrow, [WildcardMentionOption.topic]);
    testArabic('ق',         topicNarrow,   [WildcardMentionOption.channel]);
    testArabic('دفق',       channelNarrow, [WildcardMentionOption.stream]);
    testArabic('الكل',      dmNarrow,      [WildcardMentionOption.everyone]);
    testArabic('top',       channelNarrow, [WildcardMentionOption.topic]);
    testArabic('channel',   topicNarrow,   [WildcardMentionOption.channel]);
    testArabic('every',     dmNarrow,      [WildcardMentionOption.everyone]);

    final testEnglish = wildcardTesterForLocale((locale) => locale.languageCode == 'en');
    testEnglish('topic',     topicNarrow,   [WildcardMentionOption.topic]);
    testEnglish('Topic',     topicNarrow,   [WildcardMentionOption.topic]);

    final testGerman = wildcardTesterForLocale((locale) => locale.languageCode == 'de');
    testGerman('Thema',     topicNarrow,   [WildcardMentionOption.topic]);
    testGerman('thema',     topicNarrow,   [WildcardMentionOption.topic]);

    final testPolish = wildcardTesterForLocale((locale) => locale.languageCode == 'pl');
    testPolish('wątek',     topicNarrow,   [WildcardMentionOption.topic]);
    testPolish('watek',     topicNarrow,   [WildcardMentionOption.topic]);

    test('no wildcards for a silent mention', () {
      check(getWildcardOptionsFor('', isSilent: true, narrow: channelNarrow))
        .isEmpty();
      check(getWildcardOptionsFor('all', isSilent: true, narrow: topicNarrow))
        .isEmpty();
      check(getWildcardOptionsFor('everyone', isSilent: true, narrow: dmNarrow))
        .isEmpty();
    });

    test('${WildcardMentionOption.channel} is available FL-247 onwards', () {
      check(getWildcardOptionsFor('channel',
          narrow: channelNarrow, zulipFeatureLevel: 247))
        .deepEquals([WildcardMentionOption.channel]);
    });

    test('${WildcardMentionOption.channel} is not available before FL-247', () {
      check(getWildcardOptionsFor('channel',
          narrow: channelNarrow, zulipFeatureLevel: 246))
        .deepEquals([]);
    });

    test('${WildcardMentionOption.topic} is available FL-224 onwards', () {
      check(getWildcardOptionsFor('topic',
          narrow: channelNarrow, zulipFeatureLevel: 224))
        .deepEquals([WildcardMentionOption.topic]);
    });

    test('${WildcardMentionOption.topic} is not available before FL-224', () {
      check(getWildcardOptionsFor('topic',
          narrow: channelNarrow, zulipFeatureLevel: 223))
        .deepEquals([]);
    });
  });

  group('MentionAutocompleteQuery.testUser', () {
    late PerAccountStore store;

    void doCheck(String rawQuery, User user, bool expected) {
      final result = MentionAutocompleteQuery(rawQuery).testUser(user, store);
      expected
        ? check(result).isA<UserMentionAutocompleteResult>()
        : check(result).isNull();
    }

    test('user is always excluded when not active regardless of other criteria', () {
      store = eg.store();

      doCheck('Full Name', eg.user(fullName: 'Full Name', isActive: false), false);
      // When active then other criteria will be checked
      doCheck('Full Name', eg.user(fullName: 'Full Name', isActive: true), true);
    });

    test('user is always excluded when muted, regardless of other criteria', () async {
      store = eg.store();
      await store.setMutedUsers([1]);
      doCheck('Full Name', eg.user(userId: 1, fullName: 'Full Name'), false);
      // When not muted, then other criteria will be checked
      doCheck('Full Name', eg.user(userId: 2, fullName: 'Full Name'), true);
    });

    test('user is included if fullname words match the query', () {
      store = eg.store();

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

  group('MentionAutocompleteQuery ranking', () {
    // This gets filled lazily, but never reset.
    // We're counting on this group's tests never doing anything to mutate it.
    PerAccountStore? store;

    int? rankOf(String queryStr, Object candidate) {
      final query = MentionAutocompleteQuery(queryStr);
      final result = switch (candidate) {
        WildcardMentionOption() => query.testWildcardOption(candidate,
          localizations: GlobalLocalizations.zulipLocalizations),
        User() => query.testUser(candidate, (store ??= eg.store())),
        UserGroup() => query.testUserGroup(candidate, (store ??= eg.store())),
        _ => throw StateError('invalid candidate'),
      };
      return result?.rank;
    }

    void checkPrecedes(String query, Object a, Object b) {
      check(rankOf(query, a)!).isLessThan(rankOf(query, b)!);
    }

    void checkSameRank(String query, Object a, Object b) {
      check(rankOf(query, a)!).equals(rankOf(query, b)!);
    }

    void checkAllSameRank(String query, Iterable<Object> candidates) {
      // (i.e. throw here if it's not a match)
      final firstCandidateRank = rankOf(query, candidates.first)!;

      final ranks = candidates.skip(1).map((candidate) => rankOf(query, candidate));
      check(ranks).every((it) => it.equals(firstCandidateRank));
    }

    test('wildcards, then users', () {
      checkSameRank('', WildcardMentionOption.all, WildcardMentionOption.topic);
      checkPrecedes('', WildcardMentionOption.topic, eg.user());
      checkSameRank('', eg.user(), eg.user());
    });

    test('wildcard-vs-user more significant than match quality', () {
      // Make the query an exact match for the user's name.
      final user = eg.user(fullName: 'Ann');
      checkPrecedes(user.fullName, WildcardMentionOption.channel, user);
    });

    test('user name match is case- and diacritics-insensitive', () {
      final users = [
        eg.user(fullName: 'Édith Piaf'),
        eg.user(fullName: 'édith piaf'),
        eg.user(fullName: 'Edith Piaf'),
        eg.user(fullName: 'edith piaf'),
      ];

      checkAllSameRank('Édith Piaf', users); // exact
      checkAllSameRank('Edith Piaf', users); // exact
      checkAllSameRank('édith piaf', users); // exact
      checkAllSameRank('edith piaf', users); // exact

      checkAllSameRank('Édith Pi',   users); // total-prefix
      checkAllSameRank('Edith Pi',   users); // total-prefix
      checkAllSameRank('édith pi',   users); // total-prefix
      checkAllSameRank('edith pi',   users); // total-prefix

      checkAllSameRank('Éd Pi',      users); // word-prefixes
      checkAllSameRank('Ed Pi',      users); // word-prefixes
      checkAllSameRank('éd pi',      users); // word-prefixes
      checkAllSameRank('ed pi',      users); // word-prefixes
    });

    test('user name match: exact over total-prefix', () {
      final user1 = eg.user(fullName: 'Chris');
      final user2 = eg.user(fullName: 'Chris Bobbe');

      checkPrecedes('chris', user1, user2);
    });

    test('user name match: total-prefix over word-prefixes', () {
      final user1 = eg.user(fullName: 'So Many Ideas');
      final user2 = eg.user(fullName: 'Some Merry User');

      checkPrecedes('so m', user1, user2);
    });

    test('group name is case- and diacritics-insensitive', () {
      final userGroups = [
        eg.userGroup(name: 'Mobile Team'),
        eg.userGroup(name: 'mobile team'),
        eg.userGroup(name: 'möbile team'),
      ];

      checkAllSameRank('mobile team', userGroups); // exact
      checkAllSameRank('mobile te',   userGroups); // total-prefix
      checkAllSameRank('mob te',      userGroups); // word-prefixes
    });

    test('group name match: exact over total-prefix', () {
      final userGroup1 = eg.userGroup(name: 'Mobile');
      final userGroup2 = eg.userGroup(name: 'Mobile Team');

      checkPrecedes('mobile', userGroup1, userGroup2);
    });

    test('group name match: total-prefix over word-prefixes', () {
      final userGroup1 = eg.userGroup(name: 'So Many Ideas');
      final userGroup2 = eg.userGroup(name: 'Some Merry Group');

      checkPrecedes('so m', userGroup1, userGroup2);
    });

    test('email match is case- and diacritics-insensitive', () {
      // "z" name to prevent accidental name match with example data
      final users = [
        eg.user(fullName: 'z', deliveryEmail: 'email@example.com'),
        eg.user(fullName: 'z', deliveryEmail: 'EmAiL@ExAmPlE.com'),
        eg.user(fullName: 'z', deliveryEmail: 'ēmail@example.com'),
      ];

      checkAllSameRank('email@example.com', users);
      checkAllSameRank('email@e',           users);
      checkAllSameRank('email@',            users);
      checkAllSameRank('email',             users);
      checkAllSameRank('ema',               users);
    });

    test('email match is by prefix only', () {
      // "z" name to prevent accidental name match with example data
      final user = eg.user(fullName: 'z', deliveryEmail: 'email@example.com');

      check(rankOf('e',           user)).isNotNull();
      check(rankOf('mail',        user)).isNull();
      check(rankOf('example',     user)).isNull();
      check(rankOf('example.com', user)).isNull();
    });

    test('full list of ranks', () {
      final user1 = eg.user(fullName: 'some user', deliveryEmail: 'email@example.com');
      final userGroup1 = eg.userGroup(name: 'some user group');
      check([
        rankOf('', WildcardMentionOption.all), // wildcard
        rankOf('some user', user1),            // user, exact name match
        rankOf('some us', user1),              // user, total-prefix name match
        rankOf('so us', user1),                // user, word-prefixes name match
        rankOf('some user group', userGroup1), // user group, exact name match
        rankOf('some us', userGroup1),         // user group, total-prefix name match
        rankOf('so us gr', userGroup1),        // user group, word-prefixes name match
        rankOf('email', user1),                // user, no name match, email match
      ]).deepEquals([0, 1, 2, 3, 4, 5, 6, 7]);
    });
  });

  group('ComposeTopicAutocomplete.autocompleteIntent', () {
    void doTest(String markedText, TopicAutocompleteQuery? expectedQuery) {
      final parsed = parseMarkedText(markedText);

      final description = 'topic-input with text: $markedText produces: ${expectedQuery?.raw ?? 'No Query!'}';
      test(description, () {
        final store = eg.store();
        final controller = ComposeTopicController(store: store);
        controller.value = parsed.value;
        if (expectedQuery == null) {
          check(controller).autocompleteIntent.isNull();
        } else {
          check(controller).autocompleteIntent.isNotNull()
            ..query.equals(expectedQuery)
            ..syntaxStart.equals(0); // query is the whole value
        }
      });
    }

    /// if there is any input, produced query should match input text
    doTest('', TopicAutocompleteQuery(''));
    doTest('^abc', TopicAutocompleteQuery('abc'));
    doTest('a^bc', TopicAutocompleteQuery('abc'));
    doTest('abc^', TopicAutocompleteQuery('abc'));
    doTest('a^bc^', TopicAutocompleteQuery('abc'));
  });

  Condition<Object?> isTopic(TopicName topic) {
    return (it) => it.isA<TopicAutocompleteResult>().topic.equals(topic);
  }

  test('TopicAutocompleteView misc', () async {
    final store = eg.store();
    final connection = store.connection as FakeApiConnection;
    final first = eg.getChannelTopicsEntry(maxId: 1, name: 'First Topic');
    final second = eg.getChannelTopicsEntry(maxId: 2, name: 'Second Topic');
    final third = eg.getChannelTopicsEntry(maxId: 3, name: 'Third Topic');
    connection.prepare(json: GetChannelTopicsResult(
      topics: [first, second, third]).toJson());

    final view = TopicAutocompleteView.init(
      store: store,
      streamId: eg.stream().streamId,
      query: TopicAutocompleteQuery('Third'));
    bool done = false;
    view.addListener(() { done = true; });

    // those are here to wait for topics to be loaded
    await Future(() {});
    await Future(() {});
    check(done).isTrue();
    check(view.results).single.which(isTopic(third.name));
  });

  test('TopicAutocompleteView updates results when topics are loaded', () async {
    final store = eg.store();
    final connection = store.connection as FakeApiConnection;
    connection.prepare(json: GetChannelTopicsResult(
      topics: [eg.getChannelTopicsEntry(name: 'test')]
    ).toJson());

    final view = TopicAutocompleteView.init(
      store: store,
      streamId: eg.stream().streamId,
      query: TopicAutocompleteQuery('te'));
    bool done = false;
    view.addListener(() { done = true; });

    check(done).isFalse();
    await Future(() {});
    check(done).isTrue();
  });

  test('TopicAutocompleteView getChannelTopics request', () async {
    final store = eg.store();
    final connection = store.connection as FakeApiConnection;

    connection.prepare(json: GetChannelTopicsResult(
      topics: [eg.getChannelTopicsEntry(name: '')],
    ).toJson());
    TopicAutocompleteView.init(store: store, streamId: 1000,
      query: TopicAutocompleteQuery('foo'));
    check(connection.lastRequest).isA<http.Request>()
      ..method.equals('GET')
      ..url.path.equals('/api/v1/users/me/1000/topics')
      ..url.queryParameters['allow_empty_topic_name'].equals('true');
  });

  group('TopicAutocompleteQuery.testTopic', () {
    final store = eg.store();
    void doCheck(String rawQuery, String topic, bool expected) {
      final result = TopicAutocompleteQuery(rawQuery).testTopic(eg.t(topic), store);
      expected ? check(result).isTrue() : check(result).isFalse();
    }

    test('topic is included if it matches the query', () {
      doCheck('', 'Top Name', true);
      doCheck('Name', 'Name', false);
      doCheck('name', 'Name', true);
      doCheck('name', 'Nam', false);
      doCheck('nam', 'Name', true);
    });
  });
}

typedef WildcardTester = void Function(String query, Narrow narrow, List<WildcardMentionOption> expected);
