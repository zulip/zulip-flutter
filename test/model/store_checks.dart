import 'package:checks/checks.dart';
import 'package:zulip/model/store.dart';

extension AccountChecks on Subject<Account> {
  Subject<int> get id => has((x) => x.id, 'id');
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<int> get userId => has((x) => x.userId, 'userId');
  Subject<String> get email => has((x) => x.email, 'email');
  Subject<String> get apiKey => has((x) => x.apiKey, 'apiKey');
  Subject<String> get zulipVersion => has((x) => x.zulipVersion, 'zulipVersion');
  Subject<String?> get zulipMergeBase => has((x) => x.zulipMergeBase, 'zulipMergeBase');
  Subject<int> get zulipFeatureLevel => has((x) => x.zulipFeatureLevel, 'zulipFeatureLevel');
  Subject<String?> get ackedPushToken => has((x) => x.ackedPushToken, 'ackedPushToken');
}

extension GlobalStoreChecks on Subject<GlobalStore> {
  Subject<Iterable<Account>> get accounts => has((x) => x.accounts, 'accounts');
  Subject<Iterable<int>> get accountIds => has((x) => x.accountIds, 'accountIds');
  Subject<Iterable<({ int accountId, Account account })>> get accountEntries => has((x) => x.accountEntries, 'accountEntries');
  Subject<Account?> getAccount(int id) => has((x) => x.getAccount(id), 'getAccount($id)');
}
