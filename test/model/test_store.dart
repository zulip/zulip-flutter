import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';

/// A [GlobalStore] containing data provided by callers,
/// and that causes no database queries or network requests.
///
/// Tests can provide data to the store by calling [add].
///
/// The per-account stores will use [FakeApiConnection].
///
/// Unlike with [LiveGlobalStore] and the associated [UpdateMachine.load],
/// there is no automatic event-polling loop or other automated requests.
/// For each account loaded, there is a corresponding [UpdateMachine]
/// in [updateMachines], which tests can use for invoking that logic
/// explicitly when desired.
///
/// See also [TestZulipBinding.globalStore], which provides one of these.
class TestGlobalStore extends GlobalStore {
  TestGlobalStore({required super.accounts});

  /// A corresponding [UpdateMachine] for each loaded account.
  final Map<int, UpdateMachine> updateMachines = {};

  final Map<int, InitialSnapshot> _initialSnapshots = {};

  /// Add an account and corresponding server data to the test data.
  ///
  /// The given account will be added to the store.
  /// The given initial snapshot will be used to initialize a corresponding
  /// [PerAccountStore] when [perAccount] is subsequently called for this
  /// account, in particular when a [PerAccountStoreWidget] is mounted.
  Future<void> add(Account account, InitialSnapshot initialSnapshot) async {
    await insertAccount(account.toCompanion(false));
    assert(!_initialSnapshots.containsKey(account.id));
    _initialSnapshots[account.id] = initialSnapshot;
  }

  int _nextAccountId = 1;

  @override
  Future<Account> doInsertAccount(AccountsCompanion data) async {
    final accountId = data.id.present ? data.id.value : _nextAccountId++;
    return Account(
      id: accountId,
      realmUrl: data.realmUrl.value,
      userId: data.userId.value,
      email: data.email.value,
      apiKey: data.apiKey.value,
      zulipFeatureLevel: data.zulipFeatureLevel.value,
      zulipVersion: data.zulipVersion.value,
      zulipMergeBase: data.zulipMergeBase.value,
    );
  }

  @override
  Future<PerAccountStore> loadPerAccount(Account account) {
    final initialSnapshot = _initialSnapshots[account.id]!;
    final store = PerAccountStore.fromInitialSnapshot(
      globalStore: this,
      account: account,
      connection: FakeApiConnection.fromAccount(account),
      initialSnapshot: initialSnapshot,
    );
    updateMachines[account.id] = UpdateMachine.fromInitialSnapshot(
      store: store, initialSnapshot: initialSnapshot);
    return Future.value(store);
  }
}

extension PerAccountStoreTestExtension on PerAccountStore {
  void addUser(User user) {
    handleEvent(RealmUserAddEvent(id: 1, person: user));
  }

  void addUsers(Iterable<User> users) {
    for (final user in users) {
      addUser(user);
    }
  }

  void addStream(ZulipStream stream) {
    addStreams([stream]);
  }

  void addStreams(List<ZulipStream> streams) {
    handleEvent(StreamCreateEvent(id: 1, streams: streams));
  }

  void addSubscription(Subscription subscription) {
    addSubscriptions([subscription]);
  }

  void addSubscriptions(List<Subscription> subscriptions) {
    handleEvent(SubscriptionAddEvent(id: 1, subscriptions: subscriptions));
  }

  void addUserTopic(ZulipStream stream, String topic, UserTopicVisibilityPolicy visibilityPolicy) {
    handleEvent(UserTopicEvent(
      id: 1,
      streamId: stream.streamId,
      topicName: topic,
      lastUpdated: 1234567890,
      visibilityPolicy: visibilityPolicy,
    ));
  }
}
