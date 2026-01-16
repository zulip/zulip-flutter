import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/user.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import 'test_store.dart';

typedef StatusData = (String? statusText, String? emojiName, String? emojiCode,
  String? reactionType);

void main() {
  group('userDisplayName', () {
    test('on a known user', () async {
      final user = eg.user(fullName: 'Some User');
      final store = eg.store();
      await store.addUser(user);
      check(store.userDisplayName(user.userId)).equals('Some User');
    });

    test('on an unknown user', () {
      final store = eg.store();
      check(store.userDisplayName(eg.user().userId)).equals('(unknown user)');
    });
  });

  group('senderDisplayName', () {
    test('on a known user', () async {
      final store = eg.store();
      final user = eg.user(fullName: 'Old Name');
      await store.addUser(user);
      final message = eg.streamMessage(sender: user);
      await store.addMessage(message);
      check(store.senderDisplayName(message)).equals('Old Name');

      // If the user's name changes, `store.senderDisplayName` should update...
      await store.handleEvent(RealmUserUpdateEvent(id: 1,
        userId: user.userId, fullName: 'New Name'));
      check(store.senderDisplayName(message)).equals('New Name');
      // ... even though the Message object itself still has the old name.
      check(store.messages[message.id]!).senderFullName.equals('Old Name');
    });

    test('on an unknown user', () async {
      final store = eg.store();
      final message = eg.streamMessage(sender: eg.user(fullName: 'Some User'));
      await store.addMessage(message);
      // If the user is unknown, `store.senderDisplayName` should fall back
      // to the name in the message...
      check(store.senderDisplayName(message)).equals('Some User');
      // ... even though `store.userDisplayName` (with no message available
      // for fallback) only has a generic fallback name.
      check(store.userDisplayName(message.senderId)).equals('(unknown user)');
    });
  });

  group('RealmUserUpdateEvent', () {
    // TODO write more tests for handling RealmUserUpdateEvent

    test('deliveryEmail', () async {
      final user = eg.user(deliveryEmail: 'a@mail.example');
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        realmUsers: [eg.selfUser, user]));

      User getUser() => store.getUser(user.userId)!;

      await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
        deliveryEmail: null));
      check(getUser()).deliveryEmail.equals('a@mail.example');

      await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
        deliveryEmail: const JsonNullable(null)));
      check(getUser()).deliveryEmail.isNull();

      await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
        deliveryEmail: const JsonNullable('b@mail.example')));
      check(getUser()).deliveryEmail.equals('b@mail.example');

      await store.handleEvent(RealmUserUpdateEvent(id: 1, userId: user.userId,
        deliveryEmail: const JsonNullable('c@mail.example')));
      check(getUser()).deliveryEmail.equals('c@mail.example');
    });
  });

  testWidgets('UserStatusEvent', (tester) async {
    UserStatusChange userStatus(StatusData data) => UserStatusChange.fromJson({
      'status_text': data.$1,
      'emoji_name': data.$2,
      'emoji_code': data.$3,
      'reaction_type': data.$4,
    });

    void checkUserStatus(UserStatus userStatus, StatusData expected) {
      check(userStatus).text.equals(expected.$1);

      switch (expected) {
        case (_, String emojiName, String emojiCode, String reactionType):
          check(userStatus.emoji!)
            ..emojiName.equals(emojiName)
            ..emojiCode.equals(emojiCode)
            ..reactionType.equals(ReactionType.fromApiValue(reactionType));
        default:
          check(userStatus.emoji).isNull();
      }
    }

    UserStatusEvent userStatusEvent(StatusData data, {required int userId}) =>
      UserStatusEvent(
        id: 1,
        userId: userId,
        change: UserStatusChange.fromJson({
          'status_text': data.$1,
          'emoji_name': data.$2,
          'emoji_code': data.$3,
          'reaction_type': data.$4,
        }));

    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      userStatuses: {
        1: userStatus(('Busy', 'working_on_it', '1f6e0', 'unicode_emoji')),
        2: userStatus((null, 'calendar', '1f4c5', 'unicode_emoji')),
        3: userStatus(('Commuting', null, null, null)),
      }));
    checkUserStatus(store.getUserStatus(1),
      ('Busy', 'working_on_it', '1f6e0', 'unicode_emoji'));
    checkUserStatus(store.getUserStatus(2),
      (null, 'calendar', '1f4c5', 'unicode_emoji'));
    checkUserStatus(store.getUserStatus(3),
      ('Commuting', null, null, null));
    check(store.getUserStatus(4))..text.isNull()..emoji.isNull();
    check(store.getUserStatus(5))..text.isNull()..emoji.isNull();

    await store.handleEvent(userStatusEvent(userId: 1,
      ('Out sick', 'sick', '1f912', 'unicode_emoji')));
    checkUserStatus(store.getUserStatus(1),
      ('Out sick', 'sick', '1f912', 'unicode_emoji'));

    await store.handleEvent(userStatusEvent(userId: 2,
      ('In a meeting', null, null, null)));
    checkUserStatus(store.getUserStatus(2),
      ('In a meeting', 'calendar', '1f4c5', 'unicode_emoji'));

    await store.handleEvent(userStatusEvent(userId: 3,
      ('', 'bus', '1f68c', 'unicode_emoji')));
    checkUserStatus(store.getUserStatus(3),
      (null, 'bus', '1f68c', 'unicode_emoji'));

    await store.handleEvent(userStatusEvent(userId: 4,
      ('Vacationing', null, null, null)));
    checkUserStatus(store.getUserStatus(4),
      ('Vacationing', null, null, null));

    await store.handleEvent(userStatusEvent(userId: 5,
      ('Working remotely', '', '', '')));
    checkUserStatus(store.getUserStatus(5),
      ('Working remotely', null, null, null));

    await store.handleEvent(userStatusEvent(userId: 1,
      ('', '', '', '')));
    checkUserStatus(store.getUserStatus(1),
      (null, null, null, null));
  });

  group('MutedUsersEvent', () {
    testWidgets('smoke', (tester) async {
      late PerAccountStore store;

      void checkDmConversationMuted(List<int> otherUserIds, bool expected) {
        final narrow = DmNarrow.withOtherUsers(otherUserIds, selfUserId: store.selfUserId);
        check(store.shouldMuteDmConversation(narrow)).equals(expected);
      }

      final user1 = eg.user(userId: 1);
      final user2 = eg.user(userId: 2);
      final user3 = eg.user(userId: 3);

      store = eg.store(initialSnapshot: eg.initialSnapshot(
        realmUsers: [user1, user2, user3, eg.selfUser],
        mutedUsers: [MutedUserItem(id: 2), MutedUserItem(id: 1)]));
      check(store.isUserMuted(1)).isTrue();
      check(store.isUserMuted(2)).isTrue();
      check(store.isUserMuted(3)).isFalse();
      checkDmConversationMuted([1], true);
      checkDmConversationMuted([1, 2], true);
      checkDmConversationMuted([2, 3], false);
      checkDmConversationMuted([1, 2, 3], false);

      await store.handleEvent(eg.mutedUsersEvent([2, 1, 3]));
      check(store.isUserMuted(1)).isTrue();
      check(store.isUserMuted(2)).isTrue();
      check(store.isUserMuted(3)).isTrue();
      checkDmConversationMuted([1, 2, 3], true);

      await store.handleEvent(eg.mutedUsersEvent([2, 3]));
      check(store.isUserMuted(1)).isFalse();
      check(store.isUserMuted(2)).isTrue();
      check(store.isUserMuted(3)).isTrue();
      checkDmConversationMuted([1], false);
      checkDmConversationMuted([], false);
    });

    group('willAffectShouldMuteDmConversation', () {
      void doTest(
        String description,
        List<int> before,
        List<int> after,
        MutedUsersVisibilityEffect expected,
      ) {
        testWidgets(description, (tester) async {
          final store = eg.store();
          await store.addUser(eg.selfUser);
          await store.addUsers(before.map((id) => eg.user(userId: id)));
          await store.setMutedUsers(before);
          final event = eg.mutedUsersEvent(after);
          check(store.willAffectShouldMuteDmConversation(event)).equals(expected);
        });
      }

      doTest('none', [1], [1], MutedUsersVisibilityEffect.none);
      doTest('none (empty to empty)', [], [], MutedUsersVisibilityEffect.none);
      doTest('muted', [1], [1, 2], MutedUsersVisibilityEffect.muted);
      doTest('unmuted', [1, 2], [1], MutedUsersVisibilityEffect.unmuted);
      doTest('mixed', [1, 2, 3], [1, 2, 4], MutedUsersVisibilityEffect.mixed);
      doTest('mixed (all replaced)', [1], [2], MutedUsersVisibilityEffect.mixed);
    });
  });
}
