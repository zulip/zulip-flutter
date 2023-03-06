import 'dart:async';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/model/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;

void main() {
  test('GlobalStore.perAccount sequential case', () async {
    final accounts = {1: eg.selfAccount, 2: eg.otherAccount};
    final globalStore = TestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
        globalStore.completers[accounts[accountId]]!;

    final future1 = globalStore.perAccount(1);
    final store1 = PerAccountStore.fromInitialSnapshot(
      account: eg.selfAccount,
      connection: FakeApiConnection.fromAccount(eg.selfAccount),
      initialSnapshot: eg.initialSnapshot,
    );
    completers(1).single.complete(store1);
    check(await future1).identicalTo(store1);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(completers(1)).length.equals(1);

    final future2 = globalStore.perAccount(2);
    final store2 = PerAccountStore.fromInitialSnapshot(
        account: eg.otherAccount,
        connection: FakeApiConnection.fromAccount(eg.otherAccount),
        initialSnapshot: eg.initialSnapshot,
    );
    completers(2).single.complete(store2);
    check(await future2).identicalTo(store2);
    check(await globalStore.perAccount(2)).identicalTo(store2);
    check(await globalStore.perAccount(1)).identicalTo(store1);

    // Only one loadPerAccount call was made per account.
    check(completers(1)).length.equals(1);
    check(completers(2)).length.equals(1);
  });

  test('GlobalStore.perAccount concurrent case', () async {
    final accounts = {1: eg.selfAccount, 2: eg.otherAccount};
    final globalStore = TestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
        globalStore.completers[accounts[accountId]]!;

    final future1a = globalStore.perAccount(1);
    final future1b = globalStore.perAccount(1);
    // These should produce just one loadPerAccount call.
    check(completers(1)).length.equals(1);

    final future2 = globalStore.perAccount(2);
    final store1 = PerAccountStore.fromInitialSnapshot(
      account: eg.selfAccount,
      connection: FakeApiConnection.fromAccount(eg.selfAccount),
      initialSnapshot: eg.initialSnapshot,
    );
    final store2 = PerAccountStore.fromInitialSnapshot(
      account: eg.otherAccount,
      connection: FakeApiConnection.fromAccount(eg.otherAccount),
      initialSnapshot: eg.initialSnapshot,
    );
    completers(1).single.complete(store1);
    completers(2).single.complete(store2);
    check(await future1a).identicalTo(store1);
    check(await future1b).identicalTo(store1);
    check(await future2).identicalTo(store2);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(await globalStore.perAccount(2)).identicalTo(store2);
    check(completers(1)).length.equals(1);
    check(completers(2)).length.equals(1);
  });

  test('GlobalStore.perAccountSync', () async {
    final accounts = {1: eg.selfAccount, 2: eg.otherAccount};
    final globalStore = TestGlobalStore(accounts: accounts);
    List<Completer<PerAccountStore>> completers(int accountId) =>
        globalStore.completers[accounts[accountId]]!;

    check(globalStore.perAccountSync(1)).isNull();
    final future1 = globalStore.perAccount(1);
    check(globalStore.perAccountSync(1)).isNull();
    final store1 = PerAccountStore.fromInitialSnapshot(
      account: eg.selfAccount,
      connection: FakeApiConnection.fromAccount(eg.selfAccount),
      initialSnapshot: eg.initialSnapshot,
    );
    completers(1).single.complete(store1);
    await pumpEventQueue();
    check(globalStore.perAccountSync(1)).identicalTo(store1);
    check(await future1).identicalTo(store1);
    check(globalStore.perAccountSync(1)).identicalTo(store1);
    check(await globalStore.perAccount(1)).identicalTo(store1);
    check(completers(1)).length.equals(1);
  });
}

class TestGlobalStore extends GlobalStore {
  TestGlobalStore({required super.accounts});

  Map<Account, List<Completer<PerAccountStore>>> completers = {};

  @override
  Future<PerAccountStore> loadPerAccount(Account account) {
    final completer = Completer<PerAccountStore>();
    (completers[account] ??= []).add(completer);
    return completer.future;
  }
}
