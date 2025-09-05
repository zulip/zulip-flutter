import 'package:checks/checks.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/autocomplete.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/recent_dm_conversations.dart';
import 'package:zulip/model/server_support.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/unreads.dart';

extension GlobalSettingsDataChecks on Subject<GlobalSettingsData> {
  Subject<ThemeSetting?> get themeSetting => has((x) => x.themeSetting, 'themeSetting');
  Subject<BrowserPreference?> get browserPreference => has((x) => x.browserPreference, 'browserPreference');
}

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

extension GlobalSettingsStoreChecks on Subject<GlobalSettingsStore> {
  Subject<ThemeSetting?> get themeSetting => has((x) => x.themeSetting, 'themeSetting');
  Subject<BrowserPreference?> get browserPreference => has((x) => x.browserPreference, 'browserPreference');
  Subject<BrowserPreference> get effectiveBrowserPreference => has((x) => x.effectiveBrowserPreference, 'effectiveBrowserPreference');
  Subject<UrlLaunchMode> getUrlLaunchMode(Uri url) => has((x) => x.getUrlLaunchMode(url), 'getUrlLaunchMode');
  Subject<VisitFirstUnreadSetting> get visitFirstUnread => has((x) => x.visitFirstUnread, 'visitFirstUnread');
  Subject<MarkReadOnScrollSetting> get markReadOnScroll => has((x) => x.markReadOnScroll, 'markReadOnScroll');
  Subject<bool> getBool(BoolGlobalSetting setting) => has((x) => x.getBool(setting), 'getBool(${setting.name}');
  Subject<int?> getInt(IntGlobalSetting setting) => has((x) => x.getInt(setting), 'getInt(${setting.name}');
}

extension GlobalStoreChecks on Subject<GlobalStore> {
  Subject<GlobalSettingsStore> get settings => has((x) => x.settings, 'settings');
  Subject<Iterable<Account>> get accounts => has((x) => x.accounts, 'accounts');
  Subject<Iterable<int>> get accountIds => has((x) => x.accountIds, 'accountIds');
  Subject<Iterable<({ int accountId, Account account })>> get accountEntries => has((x) => x.accountEntries, 'accountEntries');
  Subject<Account?> getAccount(int id) => has((x) => x.getAccount(id), 'getAccount($id)');
}

extension PerAccountStoreChecks on Subject<PerAccountStore> {
  Subject<ApiConnection> get connection => has((x) => x.connection, 'connection');
  Subject<bool> get isRecoveringEventStream => has((x) => x.isRecoveringEventStream, 'isRecoveringEventStream');
  Subject<Uri> get realmUrl => has((x) => x.realmUrl, 'realmUrl');
  Subject<String> get zulipVersion => has((x) => x.zulipVersion, 'zulipVersion');
  Subject<bool> get realmMandatoryTopics => has((x) => x.realmMandatoryTopics, 'realmMandatoryTopics');
  Subject<int> get maxFileUploadSizeMib => has((x) => x.maxFileUploadSizeMib, 'maxFileUploadSizeMib');
  Subject<Map<String, RealmDefaultExternalAccount>> get realmDefaultExternalAccounts => has((x) => x.realmDefaultExternalAccounts, 'realmDefaultExternalAccounts');
  Subject<List<CustomProfileField>> get customProfileFields => has((x) => x.customProfileFields, 'customProfileFields');
  Subject<int> get accountId => has((x) => x.accountId, 'accountId');
  Subject<Account> get account => has((x) => x.account, 'account');
  Subject<int> get selfUserId => has((x) => x.selfUserId, 'selfUserId');
  Subject<UserSettings> get userSettings => has((x) => x.userSettings, 'userSettings');
  Subject<Map<int, SavedSnippet>> get savedSnippets => has((x) => x.savedSnippets, 'savedSnippets');
  Subject<Map<int, ZulipStream>> get streams => has((x) => x.streams, 'streams');
  Subject<Map<String, ZulipStream>> get streamsByName => has((x) => x.streamsByName, 'streamsByName');
  Subject<Map<int, Subscription>> get subscriptions => has((x) => x.subscriptions, 'subscriptions');
  Subject<Map<int, Message>> get messages => has((x) => x.messages, 'messages');
  Subject<Unreads> get unreads => has((x) => x.unreads, 'unreads');
  Subject<RecentDmConversationsView> get recentDmConversationsView => has((x) => x.recentDmConversationsView, 'recentDmConversationsView');
  Subject<AutocompleteViewManager> get autocompleteViewManager => has((x) => x.autocompleteViewManager, 'autocompleteViewManager');
}

extension ZulipVersionDataChecks on Subject<ZulipVersionData> {
  Subject<String> get zulipVersion => has((x) => x.zulipVersion, 'zulipVersion');
  Subject<String?> get zulipMergeBase => has((x) => x.zulipMergeBase, 'zulipMergeBase');
  Subject<int> get zulipFeatureLevel => has((x) => x.zulipFeatureLevel, 'zulipFeatureLevel');
}
