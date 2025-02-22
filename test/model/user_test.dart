import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;
import 'store_checks.dart';
import 'test_store.dart';

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

  testWidgets('MutedUsersEvent', (tester) async {
    final user1 = eg.user(userId: 1);
    final user2 = eg.user(userId: 2);
    final user3 = eg.user(userId: 3);

    final store = eg.store(initialSnapshot: eg.initialSnapshot(
      realmUsers: [user1, user2, user3],
      mutedUsers: [MutedUserItem(id: 2), MutedUserItem(id: 1)]));
    check(store).mutedUsers.deepEquals({2, 1});

    await store.handleEvent(eg.mutedUsersEvent([2, 1, 3]));
    check(store).mutedUsers.deepEquals({2, 1, 3});

    await store.handleEvent(eg.mutedUsersEvent([2, 3]));
    check(store).mutedUsers.deepEquals({2, 3});
  });
}
