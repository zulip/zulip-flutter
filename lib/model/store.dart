import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/core.dart';
import '../api/exception.dart';
import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/events.dart';
import '../api/backoff.dart';
import '../api/route/realm.dart';
import '../log.dart';
import 'actions.dart';
import 'autocomplete.dart';
import 'database.dart';
import 'emoji.dart';
import 'localizations.dart';
import 'message.dart';
import 'presence.dart';
import 'push_device.dart';
import 'realm.dart';
import 'recent_dm_conversations.dart';
import 'recent_senders.dart';
import 'server_support.dart';
import 'channel.dart';
import 'saved_snippet.dart';
import 'settings.dart';
import 'typing_status.dart';
import 'unreads.dart';
import 'user.dart';
import 'user_group.dart';

export 'package:drift/drift.dart' show Value;
export 'database.dart' show Account, AccountsCompanion, AccountAlreadyExistsException;

/// An underlying data store that can support a [GlobalStore],
/// possibly storing the data to persist between runs of the app.
///
/// In the real app, the implementation used is [LiveGlobalStoreBackend],
/// which stores data persistently in a database on the user's device.
/// This interface enables tests to use a different implementation.
abstract class GlobalStoreBackend {
  /// Update the global settings in the underlying data store.
  ///
  /// This should only be called from [GlobalSettingsStore].
  Future<void> doUpdateGlobalSettings(GlobalSettingsCompanion data);

  /// Set or unset the given bool-valued setting in the underlying data store.
  ///
  /// This should only be called from [GlobalSettingsStore].
  Future<void> doSetBoolGlobalSetting(BoolGlobalSetting setting, bool? value);

  /// Set or unset the given int-valued setting in the underlying data store.
  ///
  /// This should only be called from [GlobalSettingsStore].
  Future<void> doSetIntGlobalSetting(IntGlobalSetting setting, int? value);

  // TODO move here the similar methods for accounts;
  //   perhaps the rest of the GlobalStore abstract methods, too.
}

/// Store for all the user's data.
///
/// From UI code, use [GlobalStoreWidget.of] to get hold of an appropriate
/// instance of this class.
///
/// This object carries data that is independent of the account, like some
/// settings. It also includes a small amount of data for each account: enough
/// to authenticate as the active account, if there is one.
///
/// For other data associated with a particular account, a [GlobalStore]
/// provides a [PerAccountStore] for each account, which can be reached with
/// [GlobalStore.perAccount] or [GlobalStore.perAccountSync].
///
/// See also:
///  * [LiveGlobalStore], the implementation of this class that
///    we use outside of tests.
abstract class GlobalStore extends ChangeNotifier {
  GlobalStore({
    required GlobalStoreBackend backend,
    required GlobalSettingsData globalSettings,
    required Map<BoolGlobalSetting, bool> boolGlobalSettings,
    required Map<IntGlobalSetting, int> intGlobalSettings,
    required Iterable<Account> accounts,
  })
    : settings = GlobalSettingsStore(backend: backend,
        data: globalSettings, boolData: boolGlobalSettings, intData: intGlobalSettings),
      _accounts = Map.fromEntries(accounts.map((a) => MapEntry(a.id, a)));

  /// The store for the user's account-independent settings.
  ///
  /// When the settings data changes, the [GlobalSettingsStore] will notify
  /// its listeners, but the [GlobalStore] will not notify its own listeners.
  /// Consider using [GlobalStoreWidget.settingsOf], which automatically
  /// subscribes to changes in the [GlobalSettingsStore].
  final GlobalSettingsStore settings;

  /// A cache of the [Accounts] table in the underlying data store.
  final Map<int, Account> _accounts;

  // TODO push token, and other data corresponding to GlobalSessionState

  /// Construct a new [ApiConnection], real or fake as appropriate.
  ///
  /// Where a per-account store is available, use [PerAccountStore.connection].
  /// This method is for use before a per-account store exists, such as in
  /// the login flow.
  ApiConnection apiConnection({
    required Uri realmUrl,
    required int? zulipFeatureLevel, // required even though nullable; see [ApiConnection.zulipFeatureLevel]
    String? email,
    String? apiKey,
  });

  ApiConnection apiConnectionFromAccount(Account account) {
    return apiConnection(
      realmUrl: account.realmUrl, zulipFeatureLevel: account.zulipFeatureLevel,
      email: account.email, apiKey: account.apiKey);
  }

  final Map<int, PerAccountStore> _perAccountStores = {};

  int get debugNumPerAccountStoresLoading => _perAccountStoresLoading.length;
  final Map<int, Future<PerAccountStore>> _perAccountStoresLoading = {};

  /// The store's per-account data for the given account, if already loaded.
  ///
  /// When not null, this is the same [PerAccountStore] that would be returned
  /// by the asynchronous [perAccount].
  PerAccountStore? perAccountSync(int accountId) => _perAccountStores[accountId];

  /// The store's per-account data for the given account.
  ///
  /// If the data for this account is not already loaded, this will ensure a
  /// request is made to load it, and the returned future will complete when
  /// the data is ready.
  ///
  /// The [GlobalStore] will avoid making redundant requests for the same data,
  /// even if this method is called many times.  The futures returned from each
  /// call for the same account will all complete once the data is ready.
  ///
  /// Consider checking [perAccountSync] before calling this function, so that if
  /// the data is already available it can be used immediately (e.g., in the
  /// current frame.)
  ///
  /// See also:
  ///  * [PerAccountStoreWidget.of], for getting the relevant [PerAccountStore]
  ///    from UI code.
  Future<PerAccountStore> perAccount(int accountId) async {
    // First, see if we have the store already.
    PerAccountStore? store = _perAccountStores[accountId];
    if (store != null) {
      return store;
    }

    // Next, see if another call has already started loading one.
    Future<PerAccountStore>? future = _perAccountStoresLoading[accountId];
    if (future != null) {
      return future;
    }

    // It's up to us.  Start loading.
    future = loadPerAccount(accountId);
    _perAccountStoresLoading[accountId] = future;
    try {
      store = await future;
      _setPerAccount(accountId, store);
      return store;
    } finally {
      unawaited(_perAccountStoresLoading.remove(accountId));
    }
  }

  Future<void> _reloadPerAccount(int accountId) async {
    assert(_accounts.containsKey(accountId));
    assert(_perAccountStores.containsKey(accountId));
    assert(!_perAccountStoresLoading.containsKey(accountId));
    final store = await loadPerAccount(accountId);
    _setPerAccount(accountId, store);
  }

  void _setPerAccount(int accountId, PerAccountStore store) {
    final oldStore = _perAccountStores[accountId];
    _perAccountStores[accountId] = store;
    notifyListeners();
    oldStore?.dispose();
  }

  /// Load per-account data for the given account, unconditionally.
  ///
  /// The account for `accountId` must exist.
  ///
  /// Throws [AccountNotFoundException] if after any async gap
  /// the account has been removed.
  ///
  /// This method should be called only by the implementation of [perAccount].
  /// Other callers interested in per-account data should use [perAccount]
  /// and/or [perAccountSync].
  Future<PerAccountStore> loadPerAccount(int accountId) async {
    assert(_accounts.containsKey(accountId));
    final PerAccountStore store;
    try {
      store = await doLoadPerAccount(accountId);
    } on AccountNotFoundException {
      rethrow;
    } catch (e) {
      final account = getAccount(accountId);
      assert(account != null); // doLoadPerAccount would have thrown AccountNotFoundException
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      switch (e) {
        case ServerVersionUnsupportedException():
          reportErrorToUserModally(
            zulipLocalizations.errorCouldNotConnectTitle,
            message: zulipLocalizations.errorServerVersionUnsupportedMessage(
              account!.realmUrl.toString(),
              e.data.zulipVersion,
              kMinSupportedZulipVersion),
            learnMoreButtonUrl: kServerSupportDocUrl);
          // The important thing is to tear down per-account UI,
          // and logOutAccount conveniently handles that already.
          // It's not ideal to force the user to reauthenticate when they retry,
          // and we can revisit that later if needed.
          await logOutAccount(this, accountId);
          throw AccountNotFoundException();
        case HttpException(httpStatus: 401):
          // The API key is invalid and the store can never be loaded
          // unless the user retries manually.
          reportErrorToUserModally(
            zulipLocalizations.errorCouldNotConnectTitle,
            message: zulipLocalizations.errorInvalidApiKeyMessage(
              account!.realmUrl.toString()));
          await logOutAccount(this, accountId);
          throw AccountNotFoundException();
        default:
          rethrow;
      }
    }
    // doLoadPerAccount would have thrown AccountNotFoundException
    assert(_accounts.containsKey(accountId));
    return store;
  }

  /// Load per-account data for the given account, unconditionally.
  ///
  /// The account for `accountId` must exist.
  ///
  /// Throws [AccountNotFoundException] if after any async gap
  /// the account has been removed.
  ///
  /// This method should be called only by [loadPerAccount].
  Future<PerAccountStore> doLoadPerAccount(int accountId);

  // Just the Iterables, not the actual Map, to avoid clients mutating the map.
  // Mutations should go through the setters/mutators below.
  Iterable<Account> get accounts => _accounts.values;
  Iterable<int> get accountIds => _accounts.keys;
  Iterable<({ int accountId, Account account })> get accountEntries {
    return _accounts.entries.map((entry) {
      return (accountId: entry.key, account: entry.value);
    });
  }

  Account? getAccount(int id) => _accounts[id];

  Account? get lastVisitedAccount {
    final id = settings.getInt(IntGlobalSetting.lastVisitedAccountId);
    if (id == null) return null; // No account has been visited yet.

    // (Will be null if `id` refers to an account that has been logged out.)
    return getAccount(id);
  }

  Future<void> setLastVisitedAccount(int accountId) {
    return settings.setInt(IntGlobalSetting.lastVisitedAccountId, accountId);
  }

  /// Add an account to the store, returning its assigned account ID.
  Future<int> insertAccount(AccountsCompanion data) async {
    final account = await doInsertAccount(data);
    assert(!_accounts.containsKey(account.id));
    _accounts[account.id] = account;
    notifyListeners();
    return account.id;
  }

  /// Add an account to the underlying data store.
  Future<Account> doInsertAccount(AccountsCompanion data);

  /// Update an account in the store, returning the new version.
  ///
  /// The account with the given account ID will be updated.
  /// It must already exist in the store.
  ///
  /// Fields that are present in `data` will be updated,
  /// and fields not present will be left unmodified.
  ///
  /// Some fields should never change on an account,
  /// and must not be present in `data`: namely `id`, `realmUrl`, `userId`.
  Future<Account> updateAccount(int accountId, AccountsCompanion data) async {
    assert(!data.id.present && !data.realmUrl.present && !data.userId.present);
    assert(_accounts.containsKey(accountId));
    await doUpdateAccount(accountId, data);
    final result = _accounts.update(accountId, (value) => value.copyWithCompanion(data));
    notifyListeners();
    return result;
  }

  /// Update an account with [ZulipVersionData], returning the new version.
  ///
  /// The account must already exist in the store.
  Future<Account> updateZulipVersionData(int accountId, ZulipVersionData data) async {
    assert(_accounts.containsKey(accountId));
    return updateAccount(accountId, AccountsCompanion(
      zulipVersion: Value(data.zulipVersion),
      zulipMergeBase: Value(data.zulipMergeBase),
      zulipFeatureLevel: Value(data.zulipFeatureLevel)));
  }

  /// Update an account with [realmName] and [realmIcon], returning the new version.
  ///
  /// The account must already exist in the store.
  Future<Account> updateRealmData(int accountId, {
    required String realmName,
    required Uri realmIcon,
  }) async {
    final account = getAccount(accountId)!;
    if (account.realmName == realmName && account.realmIcon == realmIcon) {
      return account;
    }

    return updateAccount(accountId,  AccountsCompanion(
      realmName: account.realmName != realmName
        ? Value(realmName)
        : const Value.absent(),
      realmIcon: account.realmIcon != realmIcon
        ? Value(realmIcon)
        : const Value.absent(),
    ));
  }

  /// Update an account in the underlying data store.
  Future<void> doUpdateAccount(int accountId, AccountsCompanion data);

  /// Remove an account from the store.
  ///
  /// The account for `accountId` must exist.
  Future<void> removeAccount(int accountId) async {
    assert(_accounts.containsKey(accountId));
    await doRemoveAccount(accountId);
    if (!_accounts.containsKey(accountId)) return; // Already removed.
    _accounts.remove(accountId);
    _perAccountStores.remove(accountId)?.dispose();
    unawaited(_perAccountStoresLoading.remove(accountId));
    notifyListeners();
  }

  /// Remove an account from the underlying data store.
  Future<void> doRemoveAccount(int accountId);

  @override
  String toString() => '${objectRuntimeType(this, 'GlobalStore')}#${shortHash(this)}';
}

class AccountNotFoundException implements Exception {}

/// A bundle of items that are useful to [PerAccountStore] and its substores.
///
/// Each instance of this class is constructed as part of constructing a
/// [PerAccountStore] instance,
/// and is shared by that [PerAccountStore] and its substores.
/// Calling [PerAccountStore.dispose] also disposes the [CorePerAccountStore]
/// (for example, it calls [ApiConnection.dispose] on [connection]).
class CorePerAccountStore {
  CorePerAccountStore._({
    required GlobalStore globalStore,
    required this.connection,
    required this.queueId,
    required this.accountId,
    required this.selfUserId,
  }) : _globalStore = globalStore,
       assert(connection.realmUrl == globalStore.getAccount(accountId)!.realmUrl);

  final GlobalStore _globalStore;
  final ApiConnection connection; // TODO(#135): update zulipFeatureLevel with events
  final String queueId;
  final int accountId;

  // This isn't strictly needed as a field; it could be a getter
  // that uses `_globalStore.getAccount(accountId)`.
  // But we denormalize it here to save a hash-table lookup every time
  // the self-user ID is needed, which can be often.
  // It never changes on the account; see [GlobalStore.updateAccount].
  final int selfUserId;
}

/// A base class for [PerAccountStore] and its substores,
/// with getters providing the items in [CorePerAccountStore].
abstract class PerAccountStoreBase {
  PerAccountStoreBase({required this.core});

  @protected
  final CorePerAccountStore core;

  //|//////////////////////////////
  // Where data comes from in the first place.

  GlobalStore get _globalStore => core._globalStore;

  ApiConnection get connection => core.connection;

  String get queueId => core.queueId;

  //|//////////////////////////////
  // Data attached to the realm or the server.

  /// Always equal to `account.realmUrl` and `connection.realmUrl`.
  Uri get realmUrl => connection.realmUrl;

  /// Always equal to `account.realmName`.
  String get realmName => account.realmName!;

  /// The full, resolved URL for the Zulip realm icon.
  ///
  /// Returned URL is derived by resolving [account.realmIcon] (relative) URL
  /// against the base [realmUrl].
  Uri get resolvedRealmIcon => realmUrl.resolveUri(account.realmIcon!);

  /// Resolve [reference] as a URL relative to [realmUrl].
  ///
  /// This returns null if [reference] fails to parse as a URL.
  Uri? tryResolveUrl(String reference) => _tryResolveUrl(realmUrl, reference);

  /// Always equal to `connection.zulipFeatureLevel`
  /// and `account.zulipFeatureLevel`.
  int get zulipFeatureLevel => connection.zulipFeatureLevel!;

  String get zulipVersion => account.zulipVersion;

  //|//////////////////////////////
  // Data attached to the self-account on the realm.

  int get accountId => core.accountId;

  /// The [Account] this store belongs to.
  ///
  /// Will throw if the account has been removed from the global store,
  /// which is possible only if [PerAccountStore.dispose] has been called
  /// on this store.
  Account get account => _globalStore.getAccount(accountId)!;

  /// The user ID of the "self-user",
  /// i.e. the account the person using this app is logged into.
  ///
  /// This always equals the [Account.userId] on [account].
  ///
  /// For the corresponding [User] object, see [UserStore.selfUser].
  int get selfUserId => core.selfUserId;
}

const _tryResolveUrl = tryResolveUrl;

/// Like [Uri.resolve], but on failure return null instead of throwing.
Uri? tryResolveUrl(Uri baseUrl, String reference) {
  try {
    return baseUrl.resolve(reference);
  } on FormatException {
    return null;
  }
}

/// Store for the user's data for a given Zulip account.
///
/// This should always have a consistent snapshot of the state on the server,
/// as provided by the Zulip event system.
///
/// This class does not attempt to poll an event queue
/// to keep the data up to date.  For that behavior, see
/// [UpdateMachine].
class PerAccountStore extends PerAccountStoreBase with
    ChangeNotifier,
    UserGroupStore, ProxyUserGroupStore,
    RealmStore, ProxyRealmStore,
    EmojiStore, ProxyEmojiStore,
    SavedSnippetStore,
    UserStore, ProxyUserStore,
    ChannelStore, ProxyChannelStore,
    MessageStore, ProxyMessageStore {
  /// Construct a store for the user's data, starting from the given snapshot.
  ///
  /// The global store must already have been updated with
  /// [GlobalStore.updateAccount], if applicable, so that its data for
  /// the given account agrees with the snapshot.
  ///
  /// If the [connection] parameter is omitted, it defaults
  /// to `globalStore.apiConnectionFromAccount(account)`.
  /// When present, it should be a connection that came from that method call,
  /// but it may have already been used for other requests.
  factory PerAccountStore.fromInitialSnapshot({
    required GlobalStore globalStore,
    required int accountId,
    ApiConnection? connection,
    required InitialSnapshot initialSnapshot,
  }) {
    final account = globalStore.getAccount(accountId)!;
    assert(account.zulipVersion == initialSnapshot.zulipVersion
      && account.zulipMergeBase == initialSnapshot.zulipMergeBase
      && account.zulipFeatureLevel == initialSnapshot.zulipFeatureLevel);
    assert(account.realmName == initialSnapshot.realmName
      && account.realmIcon == initialSnapshot.realmIconUrl);

    connection ??= globalStore.apiConnectionFromAccount(account);
    assert(connection.zulipFeatureLevel == account.zulipFeatureLevel);

    final queueId = initialSnapshot.queueId;
    if (queueId == null) {
      // The queueId is optional in the type, but should only be missing in the
      // case of unauthenticated access to a web-public realm.  We authenticated.
      throw Exception("bad initial snapshot: missing queueId");
    }

    final core = CorePerAccountStore._(
      globalStore: globalStore,
      connection: connection,
      queueId: queueId,
      accountId: accountId,
      selfUserId: account.userId,
    );

    final userMap = UserStoreImpl.userMapFromInitialSnapshot(initialSnapshot);
    final selfUser = userMap[core.selfUserId];
    if (selfUser == null) {
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      reportErrorToUserModally(
        zulipLocalizations.errorCouldNotConnectTitle,
        message: zulipLocalizations.errorMalformedResponseWithCause(200,
          // skip-i18n: This would be an unlikely bug (in the server?).  We're
          //   showing the user these details at all only because it would be a
          //   very nasty bug (so, important to resolve ASAP) if it ever did happen.
          'self-user missing from user list'));
      throw Exception("bad initial snapshot: self-user missing from user list");
    }

    final groups = UserGroupStoreImpl(core: core,
      groups: initialSnapshot.realmUserGroups);
    final realm = RealmStoreImpl(groups: groups, initialSnapshot: initialSnapshot,
      selfUser: selfUser);
    final users = UserStoreImpl(realm: realm, initialSnapshot: initialSnapshot,
      userMap: userMap);
    final channels = ChannelStoreImpl(users: users,
      initialSnapshot: initialSnapshot);
    return PerAccountStore._(
      core: core,
      groups: groups,
      realm: realm,
      emoji: EmojiStoreImpl(core: core,
        allRealmEmoji: initialSnapshot.realmEmoji),
      userSettings: initialSnapshot.userSettings,
      pushDevices: PushDeviceManager(core: core),
      savedSnippets: SavedSnippetStoreImpl(core: core,
        savedSnippets: initialSnapshot.savedSnippets ?? []),
      typingNotifier: TypingNotifier(realm: realm),
      users: users,
      typingStatus: TypingStatus(realm: realm),
      presence: Presence(realm: realm,
        initial: initialSnapshot.presences),
      channels: channels,
      messages: MessageStoreImpl(channels: channels),
      unreads: Unreads(core: core, channelStore: channels,
        initial: initialSnapshot.unreadMsgs),
      recentDmConversationsView: RecentDmConversationsView(core: core,
        initial: initialSnapshot.recentPrivateConversations),
      recentSenders: RecentSenders(),
    );
  }

  PerAccountStore._({
    required super.core,
    required UserGroupStoreImpl groups,
    required RealmStoreImpl realm,
    required EmojiStoreImpl emoji,
    required this.userSettings,
    required this.pushDevices,
    required SavedSnippetStoreImpl savedSnippets,
    required this.typingNotifier,
    required UserStoreImpl users,
    required this.typingStatus,
    required this.presence,
    required ChannelStoreImpl channels,
    required MessageStoreImpl messages,
    required this.unreads,
    required this.recentDmConversationsView,
    required this.recentSenders,
  }) : _groups = groups,
       _realm = realm,
       _emoji = emoji,
       _savedSnippets = savedSnippets,
       _users = users,
       _channels = channels,
       _messages = messages;

  //|//////////////////////////////////////////////////////////////
  // Data.

  //|//////////////////////////////
  // Where data comes from in the first place.

  UpdateMachine? get updateMachine => _updateMachine;
  UpdateMachine? _updateMachine;
  set updateMachine(UpdateMachine? value) {
    assert(_updateMachine == null);
    assert(value != null);
    _updateMachine = value;
  }

  bool get isRecoveringEventStream => _isRecoveringEventStream;
  bool _isRecoveringEventStream = false;
  @visibleForTesting
  set isRecoveringEventStream(bool value) {
    if (_isRecoveringEventStream == value) return;
    _isRecoveringEventStream = value;
    notifyListeners();
  }

  //|//////////////////////////////
  // Data attached to the realm or the server.

  // (User groups come before even realm settings,
  // because they'll be used for interpreting many realm settings.)
  @protected
  @override
  UserGroupStore get userGroupStore => _groups;
  final UserGroupStoreImpl _groups;

  @protected
  @override
  RealmStore get realmStore => _realm;
  final RealmStoreImpl _realm;

  void setServerEmojiData(ServerEmojiData data) {
    _emoji.setServerEmojiData(data);
    notifyListeners();
  }

  @protected
  @override
  EmojiStore get emojiStore => _emoji;
  final EmojiStoreImpl _emoji;

  //|//////////////////////////////
  // Data attached to the self-account on the realm.

  final UserSettings userSettings;

  final PushDeviceManager pushDevices;

  @override
  Map<int, SavedSnippet> get savedSnippets => _savedSnippets.savedSnippets;
  final SavedSnippetStoreImpl _savedSnippets;

  final TypingNotifier typingNotifier;

  //|//////////////////////////////
  // Users and data about them.

  @protected
  @override
  UserStore get userStore => _users;
  final UserStoreImpl _users;

  final TypingStatus typingStatus;

  final Presence presence;

  //|//////////////////////////////
  // Streams, topics, and stuff about them.

  @protected
  @override
  ChannelStore get channelStore => _channels;
  final ChannelStoreImpl _channels;

  //|//////////////////////////////
  // Messages, and summaries of messages.

  /// Reconcile a batch of just-fetched messages with the store,
  /// mutating the list.
  ///
  /// This is called after a [getMessages] request to report the result
  /// to the store.
  ///
  /// The list's length will not change, but some entries may be replaced
  /// by a different [Message] object with the same [Message.id],
  /// and the store will also be updated.
  /// When this method returns, all [Message] objects in the list
  /// will be present in the map `this.messages`.
  ///
  /// The list entries may be mutated to remove
  /// [Message.matchContent] and [Message.matchTopic]
  /// (since these are appropriate for search views but not the central store).
  /// The values of those fields should therefore be captured,
  /// as needed for search, before this is called.
  void reconcileMessages(List<Message> messages) {
    _messages.reconcileMessages(messages);
    // TODO(#649) notify [unreads] of the just-fetched messages
    // TODO(#650) notify [recentDmConversationsView] of the just-fetched messages
  }

  @protected
  @override
  MessageStore get messageStore => _messages;
  final MessageStoreImpl _messages;

  final Unreads unreads;

  final RecentDmConversationsView recentDmConversationsView;

  final RecentSenders recentSenders;

  //|//////////////////////////////
  // Other digests of data.

  final AutocompleteViewManager autocompleteViewManager = AutocompleteViewManager();

  // End of data.
  //|//////////////////////////////////////////////////////////////

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo from scratch any computations we can, such as parsing
  /// message contents.  It won't repeat network requests.
  void reassemble() {
    _messages.reassemble();
    autocompleteViewManager.reassemble();
  }

  bool _disposed = false;

  @override
  void dispose() {
    assert(!_disposed);
    recentDmConversationsView.dispose();
    unreads.dispose();
    _messages.dispose();
    presence.dispose();
    typingStatus.dispose();
    typingNotifier.dispose();
    pushDevices.dispose();
    updateMachine?.dispose();
    connection.close();
    _disposed = true;
    super.dispose();
  }

  Future<void> handleEvent(Event event) async {
    assert(!_disposed);

    switch (event) {
      case HeartbeatEvent():
        assert(debugLog("server event: heartbeat"));

      case RealmEmojiUpdateEvent():
        assert(debugLog("server event: realm_emoji/update"));
        _emoji.handleRealmEmojiUpdateEvent(event);
        notifyListeners();

      case AlertWordsEvent():
        assert(debugLog("server event: alert_words"));
        // We don't yet store this data, so there's nothing to update.

      case UserSettingsUpdateEvent():
        assert(debugLog("server event: user_settings/update ${event.property?.name ?? '[unrecognized]'}"));
        if (event.property == null) {
          // unrecognized setting; do nothing
          return;
        }
        switch (event.property!) {
          case UserSettingName.twentyFourHourTime:
            userSettings.twentyFourHourTime        = event.value as TwentyFourHourTimeMode;
          case UserSettingName.displayEmojiReactionUsers:
            userSettings.displayEmojiReactionUsers = event.value as bool;
          case UserSettingName.emojiset:
            userSettings.emojiset                  = event.value as Emojiset;
          case UserSettingName.presenceEnabled:
            userSettings.presenceEnabled           = event.value as bool;
        }
        notifyListeners();

      case CustomProfileFieldsEvent():
        assert(debugLog("server event: custom_profile_fields"));
        _realm.handleCustomProfileFieldsEvent(event);
        notifyListeners();

      case UserGroupEvent():
        assert(debugLog("server event: user_group/${event.op}"));
        _groups.handleUserGroupEvent(event);
        if (event is UserGroupRemoveEvent) {
          autocompleteViewManager.handleUserGroupRemoveEvent(event);
        } else if (event is UserGroupUpdateEvent) {
          autocompleteViewManager.handleUserGroupUpdateEvent(event);
        }
        notifyListeners();

      case RealmUserAddEvent():
        assert(debugLog("server event: realm_user/add"));
        _users.handleRealmUserEvent(event);
        notifyListeners();

      case RealmUserRemoveEvent():
        assert(debugLog("server event: realm_user/remove"));
        _users.handleRealmUserEvent(event);
        autocompleteViewManager.handleRealmUserRemoveEvent(event);
        notifyListeners();

      case RealmUserUpdateEvent():
        assert(debugLog("server event: realm_user/update"));
        _groups.handleRealmUserUpdateEvent(event);
        _realm.handleRealmUserUpdateEvent(event);
        _users.handleRealmUserEvent(event);
        autocompleteViewManager.handleRealmUserUpdateEvent(event);
        notifyListeners();

      case SavedSnippetsEvent():
        assert(debugLog('server event: saved_snippets/${event.op}'));
        _savedSnippets.handleSavedSnippetsEvent(event);
        notifyListeners();

      case ChannelEvent():
        assert(debugLog("server event: stream/${event.op}"));
        if (event is ChannelDeleteEvent) {
          _messages.handleChannelDeleteEvent(event);
        }
        _channels.handleChannelEvent(event);
        notifyListeners();

      case SubscriptionEvent():
        assert(debugLog("server event: subscription/${event.op}"));
        if (event is SubscriptionRemoveEvent) {
          _messages.handleSubscriptionRemoveEvent(event);
        }
        _channels.handleSubscriptionEvent(event);
        notifyListeners();

      case ChannelFolderEvent():
        assert(debugLog("server event: channel_folder/${event.op}"));
        _channels.handleChannelFolderEvent(event);
        break;

      case UserStatusEvent():
        assert(debugLog("server event: user_status"));
        _users.handleUserStatusEvent(event);
        notifyListeners();

      case UserTopicEvent():
        assert(debugLog("server event: user_topic"));
        _messages.handleUserTopicEvent(event);
        // Update _channels last, so other handlers can compare to the old value.
        _channels.handleUserTopicEvent(event);
        notifyListeners();

      case MessageEvent():
        assert(debugLog("server event: message ${jsonEncode(event.message.toJson())}"));
        // Assert against malformed events that might be created in test code.
        assert(event.message.matchContent == null);
        assert(event.message.matchTopic == null);

        _messages.handleMessageEvent(event);
        unreads.handleMessageEvent(event);
        recentDmConversationsView.handleMessageEvent(event);
        recentSenders.handleMessage(event.message); // TODO(#824)
        // When adding anything here (to handle [MessageEvent]),
        // it probably belongs in [reconcileMessages] too.

      case UpdateMessageEvent():
        assert(debugLog("server event: update_message ${event.messageId}"));
        _messages.handleUpdateMessageEvent(event);
        unreads.handleUpdateMessageEvent(event);

      case DeleteMessageEvent():
        assert(debugLog("server event: delete_message ${event.messageIds}"));
        // This should be called before [_messages.handleDeleteMessageEvent(event)],
        // as we need to know about each message for [event.messageIds],
        // specifically, their `senderId`s. By calling this after the
        // aforementioned line, we'll lose reference to those messages.
        recentSenders.handleDeleteMessageEvent(event, messages);
        _messages.handleDeleteMessageEvent(event);
        unreads.handleDeleteMessageEvent(event);

      case UpdateMessageFlagsEvent():
        assert(debugLog("server event: update_message_flags/${event.op} ${event.flag.toJson()}"));
        _messages.handleUpdateMessageFlagsEvent(event);
        unreads.handleUpdateMessageFlagsEvent(event);

      case SubmessageEvent():
        assert(debugLog("server event: submessage ${event.content}"));
        _messages.handleSubmessageEvent(event);

      case TypingEvent():
        assert(debugLog("server event: typing/${event.op} ${event.messageType}"));
        typingStatus.handleTypingEvent(event);

      case PresenceEvent():
        assert(debugLog("server event: presence ${event.userId}"));
        // TODO(#1618) handle
        break;

      case ReactionEvent():
        assert(debugLog("server event: reaction/${event.op}"));
        _messages.handleReactionEvent(event);

      case MutedUsersEvent():
        assert(debugLog("server event: muted_users"));
        _messages.handleMutedUsersEvent(event);
        // Update _users last, so other handlers can compare to the old value.
        _users.handleMutedUsersEvent(event);
        notifyListeners();

      case UnexpectedEvent():
        assert(debugLog("server event: ${jsonEncode(event.toJson())}")); // TODO log better
    }
  }

  @override
  String toString() => '${objectRuntimeType(this, 'PerAccountStore')}#${shortHash(this)}';
}

/// A [GlobalStoreBackend] that uses a live, persistent local database.
///
/// Used as part of a [LiveGlobalStore].
/// The underlying data store is an [AppDatabase] corresponding to a
/// SQLite database file in the app's persistent storage on the device.
class LiveGlobalStoreBackend implements GlobalStoreBackend {
  LiveGlobalStoreBackend._({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  @override
  Future<void> doUpdateGlobalSettings(GlobalSettingsCompanion data) async {
    final rowsAffected = await _db.update(_db.globalSettings).write(data);
    assert(rowsAffected == 1);
  }

  @override
  Future<void> doSetBoolGlobalSetting(BoolGlobalSetting setting, bool? value) async {
    if (value == null) {
      final query = _db.delete(_db.boolGlobalSettings)
        ..where((r) => r.name.equals(setting.name));
      await query.go();
    } else {
      await _db.into(_db.boolGlobalSettings).insertOnConflictUpdate(
        BoolGlobalSettingRow(name: setting.name, value: value));
    }
  }

  @override
  Future<void> doSetIntGlobalSetting(IntGlobalSetting setting, int? value) async {
    if (value == null) {
      await (_db.delete(_db.intGlobalSettings)
        ..where((r) => r.name.equals(setting.name))
      ).go();
    } else {
      await _db.into(_db.intGlobalSettings).insertOnConflictUpdate(
        IntGlobalSettingRow(name: setting.name, value: value));
    }
  }
}

/// A [GlobalStore] that uses a live server and live, persistent local database.
///
/// The underlying data store is an [AppDatabase] corresponding to a SQLite
/// database file in the app's persistent storage on the device.
///
/// The per-account stores will use a live [ApiConnection],
/// and will have an associated [UpdateMachine].
class LiveGlobalStore extends GlobalStore {
  LiveGlobalStore._({
    required LiveGlobalStoreBackend backend,
    required super.globalSettings,
    required super.boolGlobalSettings,
    required super.intGlobalSettings,
    required super.accounts,
  }) : _backend = backend,
       super(backend: backend);

  @override
  ApiConnection apiConnection({
      required Uri realmUrl, required int? zulipFeatureLevel,
      String? email, String? apiKey}) {
    return ApiConnection.live(
      realmUrl: realmUrl, zulipFeatureLevel: zulipFeatureLevel,
      email: email, apiKey: apiKey);
  }

  // We keep the API simple and synchronous for the bulk of the app's code
  // by doing this loading up front before constructing a [GlobalStore].
  static Future<GlobalStore> load() async {
    // Loading this data takes roughly 80-100ms (measured on a Pixel 8).
    // That's only a small increment on the time spent loading server data,
    // so we don't worry about optimizing it further.
    // In a future where we keep server data locally between runs (#477) --
    // which will also mean having much more data to load from the database --
    // we'd invest in this area more.  For example we'd try doing these
    // in parallel, or deferring some to be concurrent with loading server data.
    final stopwatch = Stopwatch()..start();
    final db = AppDatabase(NativeDatabase.createInBackground(await _dbFile()));
    final t1 = stopwatch.elapsed;
    final globalSettings = await db.getGlobalSettings();
    final t2 = stopwatch.elapsed;
    final boolGlobalSettings = await db.getBoolGlobalSettings();
    final t3 = stopwatch.elapsed;
    final intGlobalSettings = await db.getIntGlobalSettings();
    final t4 = stopwatch.elapsed;
    final accounts = await db.select(db.accounts).get();
    final t5 = stopwatch.elapsed;
    if (kProfileMode) {
      String format(Duration d) =>
        "${(d.inMicroseconds / 1000.0).toStringAsFixed(1)}ms";
      profilePrint("db load time ${format(t5)} total: ${format(t1)} init, "
        "${format(t2 - t1)} settings, ${format(t3 - t2)} bool-settings, "
        "${format(t4 - t3)} int-settings, ${format(t5 - t4)} accounts");
    }

    return LiveGlobalStore._(
      backend: LiveGlobalStoreBackend._(db: db),
      globalSettings: globalSettings,
      boolGlobalSettings: boolGlobalSettings,
      intGlobalSettings: intGlobalSettings,
      accounts: accounts);
  }

  /// The file path to use for the app database.
  static Future<File> _dbFile() async {
    // What directory should we use?
    //   path_provider's getApplicationSupportDirectory:
    //     on Android, -> Flutter's PathUtils.getFilesDir -> https://developer.android.com/reference/android/content/Context#getFilesDir()
    //       -> empirically /data/data/com.zulipmobile/files/
    //     on iOS, -> "Library/Application Support" via https://developer.apple.com/documentation/foundation/nssearchpathdirectory/nsapplicationsupportdirectory
    //     on Linux, -> "${XDG_DATA_HOME:-~/.local/share}/com.zulip.flutter/"
    //     All seem reasonable.
    //   path_provider's getApplicationDocumentsDirectory:
    //     on Android, -> Flutter's PathUtils.getDataDirectory -> https://developer.android.com/reference/android/content/Context#getDir(java.lang.String,%20int)
    //       with https://developer.android.com/reference/android/content/Context#MODE_PRIVATE
    //     on iOS, "Document directory" via https://developer.apple.com/documentation/foundation/nssearchpathdirectory/nsdocumentdirectory
    //     on Linux, -> `xdg-user-dir DOCUMENTS` -> e.g. ~/Documents
    //     That Linux answer is definitely not a fit.  Harder to tell about the rest.
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'zulip.db'));
  }

  final LiveGlobalStoreBackend _backend;

  // The methods that use this should probably all move to [GlobalStoreBackend]
  // and [LiveGlobalStoreBackend] anyway (see comment on the former);
  // so let the latter be the canonical home of the [AppDatabase].
  // This getter just simplifies the transition.
  AppDatabase get _db => _backend._db;

  @override
  Future<PerAccountStore> doLoadPerAccount(int accountId) async {
    final updateMachine = await UpdateMachine.load(this, accountId);
    return updateMachine.store;
  }

  @override
  Future<Account> doInsertAccount(AccountsCompanion data) async {
    final accountId = await _db.createAccount(data); // TODO(log): db errors
    // We can *basically* predict what the Account will contain
    // based on the AccountsCompanion and the account ID.  But
    // if we did that and then there was some subtle case where we
    // didn't match the database's behavior, that'd be a nasty bug.
    // This isn't a hot path, so just make the extra query.
    return await (_db.select(_db.accounts) // TODO perhaps put this logic in AppDatabase
      ..where((a) => a.id.equals(accountId))
    ).getSingle();
  }

  @override
  Future<void> doUpdateAccount(int accountId, AccountsCompanion data) async {
    final rowsAffected = await (_db.update(_db.accounts)
      ..where((a) => a.id.equals(accountId))
    ).write(data);
    assert(rowsAffected == 1);
  }

  @override
  Future<void> doRemoveAccount(int accountId) async {
    final rowsAffected = await (_db.delete(_db.accounts)
      ..where((a) => a.id.equals(accountId))
    ).go();
    assert(rowsAffected == 1);
  }

  @override
  String toString() => '${objectRuntimeType(this, 'LiveGlobalStore')}#${shortHash(this)}';
}

/// A [PerAccountStore] plus an event-polling loop to stay up to date.
class UpdateMachine {
  UpdateMachine.fromInitialSnapshot({
    required this.store,
    required InitialSnapshot initialSnapshot,
  }) : lastEventId = initialSnapshot.lastEventId {
    store.updateMachine = this;
  }

  /// Load data for the given account from the server,
  /// and start an event queue going.
  ///
  /// The account for `accountId` must exist.
  ///
  /// Throws [AccountNotFoundException] if after any async gap
  /// the account has been removed.
  ///
  /// In the future this might load an old snapshot from local storage first.
  static Future<UpdateMachine> load(GlobalStore globalStore, int accountId) async {
    final connection = globalStore.apiConnectionFromAccount(
      globalStore.getAccount(accountId)!);

    void stopAndThrowIfNoAccount() {
      final account = globalStore.getAccount(accountId);
      if (account == null) {
        assert(debugLog('Account logged out during UpdateMachine.load'));
        connection.close();
        throw AccountNotFoundException();
      }
    }

    final stopwatch = Stopwatch()..start();
    InitialSnapshot? initialSnapshot;
    try {
      initialSnapshot = await _registerQueueWithRetry(connection,
        stopAndThrowIfNoAccount: stopAndThrowIfNoAccount);
    } on ServerVersionUnsupportedException catch (e) {
      // `!` is OK because _registerQueueWithRetry would have thrown a
      // not-ServerVersionUnsupportedException if no account
      final account = globalStore.getAccount(accountId)!;
      if (!e.data.matchesAccount(account)) {
        await globalStore.updateZulipVersionData(accountId, e.data);
      }
      connection.close();
      rethrow;
    }
    if (kProfileMode) {
      profilePrint("initial fetch time: ${stopwatch.elapsed.inMilliseconds}ms");
    }

    final zulipVersionData = ZulipVersionData.fromInitialSnapshot(initialSnapshot);
    // `!` is OK because _registerQueueWithRetry would have thrown if no account
    if (!zulipVersionData.matchesAccount(globalStore.getAccount(accountId)!)) {
      await globalStore.updateZulipVersionData(accountId, zulipVersionData);
      connection.zulipFeatureLevel = zulipVersionData.zulipFeatureLevel;
    }

    // TODO(#668) update realmName and realmIcon on realm update events
    await globalStore.updateRealmData(accountId,
      realmName: initialSnapshot.realmName,
      realmIcon: initialSnapshot.realmIconUrl);

    final store = PerAccountStore.fromInitialSnapshot(
      globalStore: globalStore,
      accountId: accountId,
      connection: connection,
      initialSnapshot: initialSnapshot,
    );
    final updateMachine = UpdateMachine.fromInitialSnapshot(
      store: store, initialSnapshot: initialSnapshot);
    updateMachine.poll();
    unawaited(updateMachine.fetchEmojiData(initialSnapshot.serverEmojiDataUrl));
    store.presence.start();
    return updateMachine;
  }

  final PerAccountStore store;
  int lastEventId;

  bool _disposed = false;

  /// Make the register-queue request, with retries.
  ///
  /// After each async gap, calls [stopAndThrowIfNoAccount].
  static Future<InitialSnapshot> _registerQueueWithRetry(
    ApiConnection connection, {
    required void Function() stopAndThrowIfNoAccount,
  }) async {
    BackoffMachine? backoffMachine;
    while (true) {
      InitialSnapshot? result;
      try {
        result = await registerQueue(connection);
      } catch (e, stackTrace) {
        stopAndThrowIfNoAccount();
        // TODO(#890): tell user if initial-fetch errors persist, or look non-transient
        final ZulipVersionData? zulipVersionData;
        switch (e) {
          case MalformedServerResponseException()
            when (zulipVersionData = ZulipVersionData.fromMalformedServerResponseException(e))
              ?.isUnsupported == true:
            throw ServerVersionUnsupportedException(zulipVersionData!);
          case HttpException(httpStatus: 401):
            // We cannot recover from this error through retrying.
            // Leave it to [GlobalStore.loadPerAccount].
            rethrow;
          default:
            assert(debugLog('Error fetching initial snapshot: $e'));
            // Print stack trace in its own log entry; log entries are truncated
            // at 1 kiB (at least on Android), and stack can be longer than that.
            assert(debugLog('Stack:\n$stackTrace'));
            if (e case NetworkException(cause: SocketException())) {
              // A [SocketException] is common when the device is asleep.
            } else {
              // TODO: When the error seems transient, do keep retrying but
              //   don't spam this feedback.
              // TODO(#1948) Break the retry loop on non-transient errors.
              _reportConnectionErrorToUserAndPromiseRetry(e,
                realmUrl: connection.realmUrl,
                // The stack trace is mostly useful for
                // `MalformedServerResponseException`s, and will be noise for
                // routine exceptions like from network problems.
                stackTrace: e is ApiRequestException ? null : stackTrace);
            }
        }
        assert(debugLog('Backing off, then will retry…'));
        await (backoffMachine ??= BackoffMachine()).wait();
        stopAndThrowIfNoAccount();
        assert(debugLog('… Backoff wait complete, retrying initial fetch.'));
      }
      if (result != null) {
        stopAndThrowIfNoAccount();
        final zulipVersionData = ZulipVersionData.fromInitialSnapshot(result);
        if (zulipVersionData.isUnsupported) {
          throw ServerVersionUnsupportedException(zulipVersionData);
        }
        return result;
      }
    }
  }

  /// Fetch emoji data from the server, and update the store with the result.
  ///
  /// This functions a lot like [registerQueue] and the surrounding logic
  /// in [load] above, but it's unusual in that we've separated it out.
  /// Effectively it's data that *would have* been in the [registerQueue]
  /// response, except that we pulled it out to its own endpoint as part of
  /// a caching strategy, because the data changes infrequently.
  ///
  /// Conveniently (a) this deferred fetch doesn't cause any fetch/event race,
  /// because this data doesn't get updated by events anyway (it can change
  /// only on a server restart); and (b) we don't need this data for displaying
  /// messages or anything else, only for certain UIs like the emoji picker,
  /// so it's fine that we go without it for a while.
  Future<void> fetchEmojiData(Uri serverEmojiDataUrl) async {
    if (!debugEnableFetchEmojiData) return;
    BackoffMachine? backoffMachine;
    ServerEmojiData data;
    while (true) {
      try {
        data = await fetchServerEmojiData(store.connection,
          emojiDataUrl: serverEmojiDataUrl);
        assert(debugLog('Got emoji data: ${data.codeToNames.length} emoji'));
        break;
      } catch (e) {
        assert(debugLog('Error fetching emoji data: $e\n' // TODO(log)
          'Backing off, then will retry…'));
        // The emoji data is a lot less urgent than the initial fetch,
        // or even the event-queue poll request.  So wait longer.
        backoffMachine ??= BackoffMachine(firstBound: const Duration(seconds: 2),
                                          maxBound: const Duration(minutes: 2));
        await backoffMachine.wait();
      }
    }

    store.setServerEmojiData(data);
  }

  Completer<void>? _debugLoopSignal;
  Object? _debugLoopError;

  /// In debug mode, causes the polling loop to pause before the next
  /// request and wait for [debugAdvanceLoop] to be called.
  void debugPauseLoop() {
    assert((){
      assert(_debugLoopSignal == null);
      _debugLoopSignal = Completer();
      return true;
    }());
  }

  /// In debug mode, causes the next [debugAdvanceLoop] call to induce
  /// the given error to be thrown from the polling loop.
  void debugPrepareLoopError(Object error) {
    assert(() {
      assert(_debugLoopError == null);
      _debugLoopError = error;
      return true;
    }());
  }

  /// In debug mode, after a call to [debugPauseLoop], causes the
  /// polling loop to make one more request and then pause again.
  ///
  /// If [debugPrepareLoopError] was called since the last [debugAdvanceLoop]
  /// or [debugPauseLoop], the polling loop will throw the prepared error
  /// instead of making a request.
  void debugAdvanceLoop() {
    assert((){
      if (_debugLoopError != null) {
        _debugLoopSignal!.completeError(_debugLoopError!);
      } else {
        _debugLoopSignal!.complete();
      }
      return true;
    }());
  }

  Future<void> _debugLoopWait() async {
    await _debugLoopSignal!.future;
    if (_disposed) return;
    assert(() {
      _debugLoopSignal = Completer();
      return true;
    }());
  }

  void poll() async {
    assert(!_disposed);
    try {
      while (true) {
        if (_debugLoopSignal != null) {
          await _debugLoopWait();
          if (_disposed) return;
        }

        final GetEventsResult result;
        try {
          result = await getEvents(store.connection,
            queueId: store.queueId,
            lastEventId: lastEventId,
            // If the UI shows we're busy getting event-polling to work again,
            // ask the server to tell us immediately that it's working again,
            // rather than waiting for an event, which could take up to a minute
            // in the case of a heartbeat event. See #979.
            dontBlock: store.isRecoveringEventStream ? true : null);
          if (_disposed) return;
        } catch (e, stackTrace) {
          if (_disposed) return;
          await _handlePollRequestError(e, stackTrace); // may rethrow
          if (_disposed) return;
          continue;
        }
        _clearPollErrors();

        final events = result.events;
        for (final event in events) {
          try {
            await store.handleEvent(event);
            if (_disposed) return;
          } catch (e, stackTrace) {
            if (_disposed) return;
            Error.throwWithStackTrace(
              _EventHandlingException(cause: e, event: event), stackTrace);
          }
        }
        if (events.isNotEmpty) {
          lastEventId = events.last.id;
        }
      }
    } catch (e, stackTrace) {
      if (_disposed) return;
      await _handlePollError(e, stackTrace);
      assert(_disposed);
      return;
    }
  }

  // This is static so that it persists through new UpdateMachine instances
  // as we attempt to fix things by reloading data from scratch.  In principle
  // it could also be per-account (or per-realm or per-server); but currently
  // we skip that complication, as well as attempting to reset backoff on
  // later success.  After all, these unexpected errors should be uncommon;
  // ideally they'd never happen.
  static BackoffMachine get _unexpectedErrorBackoffMachine {
    return __unexpectedErrorBackoffMachine
      ??= BackoffMachine(maxBound: const Duration(seconds: 60));
  }
  static BackoffMachine? __unexpectedErrorBackoffMachine;

  BackoffMachine? _pollBackoffMachine;

  /// This controls when we start to report transient errors to the user when
  /// polling.
  ///
  /// At the 6th failure, the expected time elapsed since the first failure
  /// will be 1.55 seocnds.
  static const transientFailureCountNotifyThreshold = 5;

  int _accumulatedTransientFailureCount = 0;

  void _clearPollErrors() {
    // After one successful request, we reset backoff to its initial state.
    // That way if the user is off the network and comes back on, the app
    // doesn't wind up in a state where it's slow to recover the next time
    // one request fails.
    //
    // This does mean that if the server is having trouble and handling some
    // but not all of its requests, we'll end up doing a lot more retries than
    // if we stayed at the max backoff interval; partway toward what would
    // happen if we weren't backing off at all.
    //
    // Successful retries won't actually space out the requests, because retries
    // are done with the `dont_block` param, asking the server to respond
    // immediately instead of waiting through the long-poll period.
    // (See comments on that code for why this behavior is helpful.)
    // If server logs show pressure from too many requests, we can investigate.
    _pollBackoffMachine = null;

    store.isRecoveringEventStream = false;
    _accumulatedTransientFailureCount = 0;
    reportErrorToUserBriefly(null);
  }

  /// Sort out an error from the network request in [poll]:
  /// either wait for a backoff duration (and possibly report the error),
  /// or rethrow.
  ///
  /// If the request should be retried, this method uses [_pollBackoffMachine]
  /// to wait an appropriate backoff duration for that retry,
  /// after reporting the error if appropriate to the user and/or developer.
  ///
  /// Otherwise this method rethrows the error, with no other side effects.
  ///
  /// See also:
  ///  * [_handlePollError], which handles errors from the rest of [poll]
  ///    and errors this method rethrows.
  Future<void> _handlePollRequestError(Object error, StackTrace stackTrace) async {
    store.isRecoveringEventStream = true;

    if (error is! ApiRequestException) {
      // Some unexpected error, outside even making the HTTP request.
      // Definitely a bug in our code.
      Error.throwWithStackTrace(error, stackTrace);
    }

    bool shouldReportToUser;
    switch (error) {
      case NetworkException(cause: SocketException()):
        // A [SocketException] is common when the app returns from sleep.
        shouldReportToUser = false;

      case NetworkException():
      case Server5xxException():
        shouldReportToUser = true;

      case HttpException(httpStatus: 429):
      case ZulipApiException(code: 'RATE_LIMIT_HIT'):
        // TODO(#946) handle rate-limit errors more generally, in ApiConnection
        shouldReportToUser = true;

      case ZulipApiException(code: 'BAD_EVENT_QUEUE_ID'):
        Error.throwWithStackTrace(error, stackTrace);

      case ZulipApiException():
      case MalformedServerResponseException():
        // Either a 4xx we didn't expect, or a malformed response;
        // in either case, a mismatch of the client's expectations to the
        // server's behavior, and therefore a bug in one or the other.
        // TODO(#1054) handle auth failures specifically
        Error.throwWithStackTrace(error, stackTrace);
    }

    assert(debugLog('Transient error polling event queue for $store: $error\n'
        'Backing off, then will retry…'));
    if (shouldReportToUser) {
      _maybeReportToUserTransientError(error);
    }
    await (_pollBackoffMachine ??= BackoffMachine()).wait();
    if (_disposed) return;
    assert(debugLog('… Backoff wait complete, retrying poll.'));
  }

  /// Deal with an error in [poll]: reload server data to replace the store,
  /// after reporting the error as appropriate to the user and/or developer.
  ///
  /// See also:
  ///  * [_handlePollRequestError], which handles certain errors
  ///    and causes them not to reach this method.
  Future<void> _handlePollError(Object error, StackTrace stackTrace) async {
    // An error occurred, other than the transient request errors we retry on.
    // This means either a lost/expired event queue on the server (which is
    // normal after the app is offline for a period like 10 minutes),
    // or an unexpected exception representing a bug in our code or the server.
    // Either way, the show must go on.  So reload server data from scratch.

    store.isRecoveringEventStream = true;

    bool isUnexpected;
    // TODO(#1054): handle auth failure
    switch (error) {
      case ZulipApiException(code: 'BAD_EVENT_QUEUE_ID'):
        assert(debugLog('Lost event queue for $store.  Replacing…'));
        // The old event queue is gone, so we need a new one.  This is normal.
        isUnexpected = false;

      case _EventHandlingException(:final cause, :final event):
        assert(debugLog('BUG: Error handling an event: $cause\n' // TODO(log)
          '  event: $event\n'
          'Replacing event queue…'));
        reportErrorToUserBriefly(
          GlobalLocalizations.zulipLocalizations.errorHandlingEventTitle,
          details: GlobalLocalizations.zulipLocalizations.errorHandlingEventDetails(
            store.realmUrl.toString(), cause.toString(), event.toString()));
        // We can't just continue with the next event, because our state
        // may be garbled due to failing to apply this one (and worse,
        // any invariants that were left in a broken state from where
        // the exception was thrown).  So reload from scratch.
        // Hopefully (probably?) the bug only affects our implementation of
        // the *change* in state represented by the event, and when we get the
        // new state in a fresh InitialSnapshot we'll handle that just fine.
        isUnexpected = true;

      default:
        assert(debugLog('BUG: Unexpected error in event polling: $error')); // TODO(log)
        // Print stack trace in its own log entry; log entries are truncated
        // at 1 kiB (at least on Android), and stack can be longer than that.
        assert(debugLog('Stack trace:\n$stackTrace'));
        assert(debugLog('Replacing event queue…'));
        _reportConnectionErrorToUserAndPromiseRetry(error,
          realmUrl: store.realmUrl,
          stackTrace: stackTrace);
        // Similar story to the _EventHandlingException case;
        // separate only so that that other case can print more context.
        // The bug here could be in the server if it's an ApiRequestException,
        // but our remedy is the same either way.
        isUnexpected = true;
    }

    if (isUnexpected) {
      // We don't know the cause of the failure; it might well keep happening.
      // Avoid creating a retry storm.
      await _unexpectedErrorBackoffMachine.wait();
      if (_disposed) return;
    }

    try {
      await store._globalStore._reloadPerAccount(store.accountId);
    } on AccountNotFoundException {
      assert(debugLog('… Event queue not replaced; account was logged out.'));
      return;
    } finally {
      assert(_disposed);
    }
    assert(debugLog('… Event queue replaced.'));
  }

  /// This only reports transient errors after reaching
  /// a pre-defined threshold of retries.
  void _maybeReportToUserTransientError(Object error) {
    _accumulatedTransientFailureCount++;
    if (_accumulatedTransientFailureCount > transientFailureCountNotifyThreshold) {
      _reportConnectionErrorToUserAndPromiseRetry(error, realmUrl: store.realmUrl);
    }
  }

  /// Give brief UI feedback that we failed to connect to the server
  /// and that we'll try again.
  static void _reportConnectionErrorToUserAndPromiseRetry(
    Object error, {
    StackTrace? stackTrace,
    required Uri realmUrl,
  }) {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;

    final details = StringBuffer()..write(error.toString());
    if (stackTrace != null) {
      details.write('\nStack:\n$stackTrace');
    }

    reportErrorToUserBriefly(
      zulipLocalizations.errorConnectingToServerShort,
      details: zulipLocalizations.errorConnectingToServerDetails(
        realmUrl.toString(), details.toString()));
  }

  /// Cleans up resources and tells the instance not to make new API requests.
  ///
  /// After this is called, the instance is not in a usable state
  /// and should be abandoned.
  ///
  /// To abort polling mid-request, [store]'s [PerAccountStore.connection]
  /// needs to be closed using [ApiConnection.close], which causes in-progress
  /// requests to error. [PerAccountStore.dispose] does that.
  void dispose() {
    assert(!_disposed);
    _disposed = true;
  }

  /// In debug mode, controls whether [fetchEmojiData] should
  /// have its normal effect.
  ///
  /// Outside of debug mode, this is always true and the setter has no effect.
  static bool get debugEnableFetchEmojiData {
    bool result = true;
    assert(() {
      result = _debugEnableFetchEmojiData;
      return true;
    }());
    return result;
  }
  static bool _debugEnableFetchEmojiData = true;
  static set debugEnableFetchEmojiData(bool value) {
    assert(() {
      _debugEnableFetchEmojiData = value;
      return true;
    }());
  }

  @override
  String toString() => '${objectRuntimeType(this, 'UpdateMachine')}#${shortHash(this)}';
}

class _EventHandlingException implements Exception {
  final Object cause;
  final Event event;

  _EventHandlingException({required this.cause, required this.event});
}
