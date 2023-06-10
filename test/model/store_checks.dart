import 'package:checks/checks.dart';
import 'package:zulip/model/store.dart';

extension GlobalStoreChecks on Subject<GlobalStore> {
  Subject<Iterable<Account>> get accounts => has((x) => x.accounts, 'accounts');
  Subject<Iterable<int>> get accountIds => has((x) => x.accountIds, 'accountIds');
  Subject<Iterable<({ int accountId, Account account })>> get accountEntries => has((x) => x.accountEntries, 'accountEntries');
  Subject<Account?> getAccount(int id) => has((x) => x.getAccount(id), 'getAccount($id)');
}
