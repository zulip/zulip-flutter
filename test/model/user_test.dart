import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';

import '../api/model/model_checks.dart';
import '../example_data.dart' as eg;

void main() {
  group('RealmUserUpdateEvent', () {
    // TODO write more tests for handling RealmUserUpdateEvent

    test('deliveryEmail', () async {
      final user = eg.user(deliveryEmail: 'a@mail.example');
      final store = eg.store(initialSnapshot: eg.initialSnapshot(
        realmUsers: [eg.selfUser, user]));

      User getUser() => store.users[user.userId]!;

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
}
