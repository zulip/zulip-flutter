import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import 'test_store.dart';

typedef StatusData = (String? statusText, String? emojiName,
  String? emojiCode, ReactionType? reactionType);

typedef StatusEventData = (int userId, String? statusText, String? emojiName,
  String? emojiCode, UserStatusEventReactionType? reactionType);

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
    UserStatus userStatus(StatusData data) => UserStatus(statusText: data.$1,
      emojiName: data.$2, emojiCode: data.$3, reactionType: data.$4);

    void checkUserStatus(UserStatus userStatus, StatusData expected) {
      check(userStatus)
        ..statusText.equals(expected.$1)
        ..emojiName.equals(expected.$2)
        ..emojiCode.equals(expected.$3)
        ..reactionType.equals(expected.$4);
    }

    UserStatusEvent userStatusEvent(StatusEventData data) => UserStatusEvent(
      id: 1, userId: data.$1, statusText: data.$2, emojiName: data.$3,
      emojiCode: data.$4, reactionType: data.$5);

    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      userStatuses: {
        1: userStatus(('Busy', 'working_on_it', '1f6e0', ReactionType.unicodeEmoji)),
        2: userStatus((null, 'calendar', '1f4c5', ReactionType.unicodeEmoji)),
        3: userStatus(('Commuting', null, null, null)),
      }
    ));
    checkUserStatus(store.getUserStatus(1)!,
      ('Busy', 'working_on_it', '1f6e0', ReactionType.unicodeEmoji));
    checkUserStatus(store.getUserStatus(2)!,
      (null, 'calendar', '1f4c5', ReactionType.unicodeEmoji));
    checkUserStatus(store.getUserStatus(3)!,
      ('Commuting', null, null, null));
    check(store.getUserStatus(4)).isNull();
    check(store.getUserStatus(5)).isNull();

    await store.handleEvent(userStatusEvent((1,
      'Out sick', 'sick', '1f912', UserStatusEventReactionType.unicodeEmoji)));
    checkUserStatus(store.getUserStatus(1)!,
      ('Out sick', 'sick', '1f912', ReactionType.unicodeEmoji));

    await store.handleEvent(userStatusEvent((2,
      'In a meeting', null, null, null)));
    checkUserStatus(store.getUserStatus(2)!,
      ('In a meeting', 'calendar', '1f4c5', ReactionType.unicodeEmoji));

    await store.handleEvent(userStatusEvent((3,
      '', 'bus', '1f68c', UserStatusEventReactionType.unicodeEmoji)));
    checkUserStatus(store.getUserStatus(3)!,
      (null, 'bus', '1f68c', ReactionType.unicodeEmoji));

    await store.handleEvent(userStatusEvent((4,
      'Vacationing', null, null, null)));
    checkUserStatus(store.getUserStatus(4)!,
      ('Vacationing', null, null, null));

    await store.handleEvent(userStatusEvent((5,
      'Working remotely', '', '', UserStatusEventReactionType.empty)));
    checkUserStatus(store.getUserStatus(5)!,
      ('Working remotely', null, null, null));
  });

  testWidgets('MutedUsersEvent', (tester) async {
    final user1 = eg.user(userId: 1);
    final user2 = eg.user(userId: 2);
    final user3 = eg.user(userId: 3);

    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUsers: [user1, user2, user3],
      mutedUsers: [MutedUserItem(id: 2), MutedUserItem(id: 1)]));
    check(store.isUserMuted(1)).isTrue();
    check(store.isUserMuted(2)).isTrue();
    check(store.isUserMuted(3)).isFalse();

    await store.handleEvent(eg.mutedUsersEvent([2, 1, 3]));
    check(store.isUserMuted(1)).isTrue();
    check(store.isUserMuted(2)).isTrue();
    check(store.isUserMuted(3)).isTrue();

    await store.handleEvent(eg.mutedUsersEvent([2, 3]));
    check(store.isUserMuted(1)).isFalse();
    check(store.isUserMuted(2)).isTrue();
    check(store.isUserMuted(3)).isTrue();
  });
}
