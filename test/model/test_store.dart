import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/store.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;

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

  final Map<
    ({Uri realmUrl, int? zulipFeatureLevel, String? email, String? apiKey}),
    FakeApiConnection
  > _apiConnections = {};

  /// Whether [apiConnection] should return a cached connection.
  ///
  /// If true, [apiConnection] will return a cached [FakeApiConnection]
  /// from a previous call, if it is still open ([FakeApiConnection.isOpen]).
  /// If there is a cached connection but it has been closed
  /// with [ApiConnection.close], that connection will be ignored in favor
  /// of returning (and saving for next time) a fresh connection after all.
  ///
  /// If false (the default), returns a fresh connection each time.
  ///
  /// Setting this to true is useful if a test needs to access the same
  /// [FakeApiConnection] that the code under test will get, so as to use
  /// [FakeApiConnection.prepare] or [FakeApiConnection.lastRequest].
  /// The behavior with `true` breaches the base method's contract slightly --
  /// the base method would return a fresh connection each time --
  /// but that breach is sometimes convenient for tests.
  bool useCachedApiConnections = false;

  void clearCachedApiConnections() {
    _apiConnections.clear();
  }

  /// Get or construct a [FakeApiConnection] with the given arguments.
  ///
  /// To access the same [FakeApiConnection] that the code under test will get,
  /// so as to use [FakeApiConnection.prepare] or [FakeApiConnection.lastRequest],
  /// see [useCachedApiConnections].
  @override
  FakeApiConnection apiConnection({
      required Uri realmUrl, required int? zulipFeatureLevel,
      String? email, String? apiKey}) {
    final key = (realmUrl: realmUrl, zulipFeatureLevel: zulipFeatureLevel,
      email: email, apiKey: apiKey);
    if (useCachedApiConnections) {
      final connection = _apiConnections[key];
      if (connection != null && connection.isOpen) {
        return connection;
      }
    }
    return (_apiConnections[key] = FakeApiConnection(
      realmUrl: realmUrl, zulipFeatureLevel: zulipFeatureLevel,
      email: email, apiKey: apiKey));
  }

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
    // Check for duplication is typically handled by the database but since
    // we're not using a real database, this needs to be handled here.
    // See [AppDatabase.createAccount].
    // TODO: Ensure that parallel account insertions do not bypass this check.
    if (accounts.any((account) =>
          data.realmUrl.value == account.realmUrl
          && (data.userId.value == account.userId
              || data.email.value == account.email))) {
      throw AccountAlreadyExistsException();
    }

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
      ackedPushToken: data.ackedPushToken.value,
    );
  }

  @override
  Future<void> doUpdateAccount(int accountId, AccountsCompanion data) async {
    // Nothing to do.
  }

  static const Duration removeAccountDuration = Duration(milliseconds: 1);
  Duration? loadPerAccountDuration;

  /// Consume the log of calls made to [doRemoveAccount].
  List<int> takeDoRemoveAccountCalls() {
    final result = _doRemoveAccountCalls;
    _doRemoveAccountCalls = null;
    return result ?? [];
  }
  List<int>? _doRemoveAccountCalls;

  @override
  Future<void> doRemoveAccount(int accountId) async {
    (_doRemoveAccountCalls ??= []).add(accountId);
    await Future<void>.delayed(removeAccountDuration);
    // Nothing else to do.
  }

  @override
  Future<PerAccountStore> doLoadPerAccount(int accountId) async {
    if (loadPerAccountDuration != null) {
      await Future<void>.delayed(loadPerAccountDuration!);
    }
    final initialSnapshot = _initialSnapshots[accountId]!;
    final store = PerAccountStore.fromInitialSnapshot(
      globalStore: this,
      accountId: accountId,
      initialSnapshot: initialSnapshot,
    );
    updateMachines[accountId] = UpdateMachine.fromInitialSnapshot(
      store: store, initialSnapshot: initialSnapshot);
    return Future.value(store);
  }
}

extension PerAccountStoreTestExtension on PerAccountStore {
  Future<void> addUser(User user) async {
    await handleEvent(RealmUserAddEvent(id: 1, person: user));
  }

  Future<void> addUsers(Iterable<User> users) async {
    for (final user in users) {
      await addUser(user);
    }
  }

  Future<void> addStream(ZulipStream stream) async {
    await addStreams([stream]);
  }

  Future<void> addStreams(List<ZulipStream> streams) async {
    await handleEvent(ChannelCreateEvent(id: 1, streams: streams));
  }

  Future<void> addSubscription(Subscription subscription) async {
    await addSubscriptions([subscription]);
  }

  Future<void> addSubscriptions(List<Subscription> subscriptions) async {
    await handleEvent(SubscriptionAddEvent(id: 1, subscriptions: subscriptions));
  }

  Future<void> addUserTopic(ZulipStream stream, String topic, UserTopicVisibilityPolicy visibilityPolicy) async {
    await handleEvent(eg.userTopicEvent(stream.streamId, topic, visibilityPolicy));
  }

  Future<void> addMessage(Message message) async {
    await handleEvent(MessageEvent(id: 1, message: message));
  }

  Future<void> addMessages(Iterable<Message> messages) async {
    for (final message in messages) {
      await addMessage(message);
    }
  }
}
