import 'dart:async';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/narrow.dart';

import '../example_data.dart' as eg;
import 'test_store.dart';
import 'autocomplete_checks.dart';

void main() {
  test('MentionAutocompleteView misc', () async {
    const narrow = AllMessagesNarrow();
    final store = eg.store()
      ..addUsers([eg.selfUser, eg.otherUser, eg.thirdUser]);
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
    fakeAsync((binding) {
      const narrow = AllMessagesNarrow();
      final store = eg.store()
        ..addUsers([eg.selfUser, eg.otherUser, eg.thirdUser]);
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
    const narrow = AllMessagesNarrow();
    final store = eg.store();
    for (int i = 0; i < 2500; i++) {
      store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
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
    const narrow = AllMessagesNarrow();
    final store = eg.store();
    for (int i = 0; i < 1500; i++) {
      store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
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
    const narrow = AllMessagesNarrow();
    final store = eg.store();
    for (int i = 0; i < 1500; i++) {
      store.addUser(eg.user(userId: i, email: 'user$i@example.com', fullName: 'User $i'));
    }
    final view = MentionAutocompleteView.init(store: store, narrow: narrow);

    bool done = false;
    view.addListener(() { done = true; });
    view.query = MentionAutocompleteQuery('User 10000');

    await Future(() {});
    check(done).isFalse();
    store.addUser(eg.user(userId: 10000, email: 'user10000@example.com', fullName: 'User 10000'));
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

  test('MentionAutocompleteQuery.testUser', () {
    doCheck(String rawQuery, User user, bool expected) {
      final result = MentionAutocompleteQuery(rawQuery)
        .testUser(user, AutocompleteDataCache());
      expected ? check(result).isTrue() : check(result).isFalse();
    }

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
}
