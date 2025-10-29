import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/model/permission.dart';
import 'store.dart';
import 'user_group.dart';

/// The portion of [PerAccountStore] for realm settings, server settings,
/// and similar data about the whole realm or server.
///
/// See also:
///  * [RealmStoreImpl] for the implementation of this that does the work.
///  * [HasRealmStore] for an implementation useful for other substores.
mixin RealmStore on PerAccountStoreBase, UserGroupStore {
  @protected
  UserGroupStore get userGroupStore;

  //|//////////////////////////////////////////////////////////////
  // Server settings, explicitly so named.

  Duration get serverPresencePingInterval => Duration(seconds: serverPresencePingIntervalSeconds);
  int get serverPresencePingIntervalSeconds;
  Duration get serverPresenceOfflineThreshold => Duration(seconds: serverPresenceOfflineThresholdSeconds);
  int get serverPresenceOfflineThresholdSeconds;

  Duration get serverTypingStartedExpiryPeriod => Duration(milliseconds: serverTypingStartedExpiryPeriodMilliseconds);
  int get serverTypingStartedExpiryPeriodMilliseconds;
  Duration get serverTypingStoppedWaitPeriod => Duration(milliseconds: serverTypingStoppedWaitPeriodMilliseconds);
  int get serverTypingStoppedWaitPeriodMilliseconds;
  Duration get serverTypingStartedWaitPeriod => Duration(milliseconds: serverTypingStartedWaitPeriodMilliseconds);
  int get serverTypingStartedWaitPeriodMilliseconds;

  //|//////////////////////////////////////////////////////////////
  // Realm settings.

  //|//////////////////////////////
  // Realm settings found in realm/update_dict events:
  //   https://zulip.com/api/get-events#realm-update_dict
  //
  // In order of appearance in the realm/update_dict event doc.
  // TODO(#668): update all these realm settings on events.

  bool get realmAllowMessageEditing;
  GroupSettingValue? get realmCanDeleteAnyMessageGroup; // TODO(server-10)
  GroupSettingValue? get realmCanDeleteOwnMessageGroup; // TODO(server-10)
  bool get realmEnableReadReceipts;
  bool get realmMandatoryTopics;
  int get maxFileUploadSizeMib;
  int? get realmMessageContentDeleteLimitSeconds;
  Duration? get realmMessageContentEditLimit =>
    realmMessageContentEditLimitSeconds == null ? null
      : Duration(seconds: realmMessageContentEditLimitSeconds!);
  int? get realmMessageContentEditLimitSeconds;
  bool get realmPresenceDisabled;
  int get realmWaitingPeriodThreshold;

  //|//////////////////////////////
  // Realm settings previously found in realm/update_dict events,
  // but now deprecated.

  RealmWildcardMentionPolicy get realmWildcardMentionPolicy; // TODO(#662): replaced by can_mention_many_users_group
  RealmDeleteOwnMessagePolicy? get realmDeleteOwnMessagePolicy; // TODO(server-10) remove

  //|//////////////////////////////
  // Realm settings that lack events.
  // (Each of these is probably secretly a server setting.)

  /// The display name to use for empty topics.
  ///
  /// This should only be accessed when FL >= 334, since topics cannot
  /// be empty otherwise.
  // TODO(server-10) simplify this
  String get realmEmptyTopicDisplayName;

  Map<String, RealmDefaultExternalAccount> get realmDefaultExternalAccounts;

  int get maxChannelNameLength;
  int get maxTopicLength;

  //|//////////////////////////////
  // Realm settings with their own events.

  List<CustomProfileField> get customProfileFields;

  //|//////////////////////////////////////////////////////////////
  // Methods that examine the settings.

  /// Process the given topic to match how it would appear
  /// on a message object from the server.
  ///
  /// This returns the [TopicName] the server would be predicted to include
  /// in a message object resulting from sending to the given [TopicName]
  /// in a [sendMessage] request.
  ///
  /// The [TopicName] is required to have no leading or trailing whitespace.
  ///
  /// For a client that supports empty topics, when FL>=334, the server converts
  /// `store.realmEmptyTopicDisplayName` to an empty string; when FL>=370,
  /// the server converts "(no topic)" to an empty string as well.
  ///
  /// See API docs:
  ///   https://zulip.com/api/send-message#parameter-topic
  TopicName processTopicLikeServer(TopicName topic) {
    final apiName = topic.apiName;
    assert(apiName.trim() == apiName);
    // TODO(server-10) simplify this away
    if (zulipFeatureLevel < 334) {
      // From the API docs:
      // > Before Zulip 10.0 (feature level 334), empty string was not a valid
      // > topic name for channel messages.
      assert(apiName.isNotEmpty);
      return topic;
    }

    // TODO(server-10) simplify this away
    if (zulipFeatureLevel < 370 && apiName == kNoTopicTopic) {
      // From the API docs:
      // > Before Zulip 10.0 (feature level 370), "(no topic)" was not
      // > interpreted as an empty string.
      return TopicName(kNoTopicTopic);
    }

    if (apiName == kNoTopicTopic || apiName == realmEmptyTopicDisplayName) {
      // From the API docs:
      // > When "(no topic)" or the value of realm_empty_topic_display_name
      // > found in the POST /register response is used for [topic],
      // > it is interpreted as an empty string.
      return TopicName('');
    }
    return topic;
  }

  /// Whether the self-user has passed the realm's waiting period
  /// to be a full member.
  ///
  /// See:
  ///   https://zulip.com/api/roles-and-permissions#determining-if-a-user-is-a-full-member
  ///
  /// To determine if the self-user is a full member,
  /// callers must also check that the user's role is at least [UserRole.member].
  bool selfHasPassedWaitingPeriod({required DateTime byDate});

  /// Whether the self-user has the given (group-based) permission.
  ///
  /// If the server doesn't know about the permission,
  /// pass null for [value] and a reasonable default will be chosen.
  bool selfHasPermissionForGroupSetting(GroupSettingValue? value,
    GroupSettingType type, String name);
}

enum GroupSettingType { realm, stream, group }

mixin ProxyRealmStore on RealmStore {
  @protected
  RealmStore get realmStore;

  @override
  int get serverPresencePingIntervalSeconds => realmStore.serverPresencePingIntervalSeconds;
  @override
  int get serverPresenceOfflineThresholdSeconds => realmStore.serverPresenceOfflineThresholdSeconds;
  @override
  int get serverTypingStartedExpiryPeriodMilliseconds => realmStore.serverTypingStartedExpiryPeriodMilliseconds;
  @override
  int get serverTypingStoppedWaitPeriodMilliseconds => realmStore.serverTypingStoppedWaitPeriodMilliseconds;
  @override
  int get serverTypingStartedWaitPeriodMilliseconds => realmStore.serverTypingStartedWaitPeriodMilliseconds;
  @override
  bool get realmAllowMessageEditing => realmStore.realmAllowMessageEditing;
  @override
  GroupSettingValue? get realmCanDeleteAnyMessageGroup => realmStore.realmCanDeleteAnyMessageGroup;
  @override
  GroupSettingValue? get realmCanDeleteOwnMessageGroup => realmStore.realmCanDeleteOwnMessageGroup;
  @override
  bool get realmEnableReadReceipts => realmStore.realmEnableReadReceipts;
  @override
  bool get realmMandatoryTopics => realmStore.realmMandatoryTopics;
  @override
  int get maxFileUploadSizeMib => realmStore.maxFileUploadSizeMib;
  @override
  int? get realmMessageContentDeleteLimitSeconds => realmStore.realmMessageContentDeleteLimitSeconds;
  @override
  int? get realmMessageContentEditLimitSeconds => realmStore.realmMessageContentEditLimitSeconds;
  @override
  bool get realmPresenceDisabled => realmStore.realmPresenceDisabled;
  @override
  int get realmWaitingPeriodThreshold => realmStore.realmWaitingPeriodThreshold;
  @override
  RealmWildcardMentionPolicy get realmWildcardMentionPolicy => realmStore.realmWildcardMentionPolicy;
  @override
  RealmDeleteOwnMessagePolicy? get realmDeleteOwnMessagePolicy => realmStore.realmDeleteOwnMessagePolicy;
  @override
  String get realmEmptyTopicDisplayName => realmStore.realmEmptyTopicDisplayName;
  @override
  Map<String, RealmDefaultExternalAccount> get realmDefaultExternalAccounts => realmStore.realmDefaultExternalAccounts;
  @override
  int get maxChannelNameLength => realmStore.maxChannelNameLength;
  @override
  int get maxTopicLength => realmStore.maxTopicLength;
  @override
  List<CustomProfileField> get customProfileFields => realmStore.customProfileFields;
  @override
  bool selfHasPassedWaitingPeriod({required DateTime byDate}) =>
    realmStore.selfHasPassedWaitingPeriod(byDate: byDate);
  @override
  bool selfHasPermissionForGroupSetting(GroupSettingValue? value, GroupSettingType type, String name) =>
    realmStore.selfHasPermissionForGroupSetting(value, type, name);
}

/// A base class for [PerAccountStore] substores that need access to [RealmStore]
/// as well as to [CorePerAccountStore].
abstract class HasRealmStore extends HasUserGroupStore with RealmStore, ProxyRealmStore {
  HasRealmStore({required RealmStore realm})
    : realmStore = realm, super(groups: realm.userGroupStore);

  @protected
  @override
  final RealmStore realmStore;
}

/// The implementation of [RealmStore] that does the work.
class RealmStoreImpl extends HasUserGroupStore with RealmStore {
  RealmStoreImpl({
    required super.groups,
    required InitialSnapshot initialSnapshot,
    required User selfUser,
  }) :
    _selfUserRole = selfUser.role,
    _selfUserDateJoined = selfUser.dateJoined,
    serverPresencePingIntervalSeconds = initialSnapshot.serverPresencePingIntervalSeconds,
    serverPresenceOfflineThresholdSeconds = initialSnapshot.serverPresenceOfflineThresholdSeconds,
    serverTypingStartedExpiryPeriodMilliseconds = initialSnapshot.serverTypingStartedExpiryPeriodMilliseconds,
    serverTypingStoppedWaitPeriodMilliseconds = initialSnapshot.serverTypingStoppedWaitPeriodMilliseconds,
    serverTypingStartedWaitPeriodMilliseconds = initialSnapshot.serverTypingStartedWaitPeriodMilliseconds,
    realmAllowMessageEditing = initialSnapshot.realmAllowMessageEditing,
    realmCanDeleteAnyMessageGroup = initialSnapshot.realmCanDeleteAnyMessageGroup,
    realmCanDeleteOwnMessageGroup = initialSnapshot.realmCanDeleteOwnMessageGroup,
    realmMandatoryTopics = initialSnapshot.realmMandatoryTopics,
    maxFileUploadSizeMib = initialSnapshot.maxFileUploadSizeMib,
    realmMessageContentDeleteLimitSeconds = initialSnapshot.realmMessageContentDeleteLimitSeconds,
    realmMessageContentEditLimitSeconds = initialSnapshot.realmMessageContentEditLimitSeconds,
    realmEnableReadReceipts = initialSnapshot.realmEnableReadReceipts,
    realmPresenceDisabled = initialSnapshot.realmPresenceDisabled,
    realmWaitingPeriodThreshold = initialSnapshot.realmWaitingPeriodThreshold,
    realmWildcardMentionPolicy = initialSnapshot.realmWildcardMentionPolicy,
    realmDeleteOwnMessagePolicy = initialSnapshot.realmDeleteOwnMessagePolicy,
    _realmEmptyTopicDisplayName = initialSnapshot.realmEmptyTopicDisplayName,
    realmDefaultExternalAccounts = initialSnapshot.realmDefaultExternalAccounts,
    maxChannelNameLength = initialSnapshot.maxChannelNameLength,
    maxTopicLength = initialSnapshot.maxTopicLength,
    customProfileFields = _sortCustomProfileFields(initialSnapshot.customProfileFields);

  @override
  bool selfHasPassedWaitingPeriod({required DateTime byDate}) {
    // [User.dateJoined] is in UTC. For logged-in users, the format is:
    // YYYY-MM-DDTHH:mm+00:00, which includes the timezone offset for UTC.
    // For logged-out spectators, the format is: YYYY-MM-DD, which doesn't
    // include the timezone offset. In the later case, [DateTime.parse] will
    // interpret it as the client's local timezone, which could lead to
    // incorrect results; but that's acceptable for now because the app
    // doesn't support viewing as a spectator.
    //
    // See the related discussion:
    //   https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/provide.20an.20explicit.20format.20for.20.60realm_user.2Edate_joined.60/near/1980194
    final dateJoined = DateTime.parse(_selfUserDateJoined);
    return byDate.difference(dateJoined).inDays >= realmWaitingPeriodThreshold;
  }

  @override
  bool selfHasPermissionForGroupSetting(GroupSettingValue? value,
      GroupSettingType type, String name) {
    // Compare web's settings_data.user_has_permission_for_group_setting.
    //
    // In the whole web app, there's just one caller for that function with
    // a user other than the self user: stream_data.can_post_messages_in_stream,
    // and only for get_current_user_and_their_bots_with_post_messages_permission,
    // with only the self-user's own bots as the arguments.
    // That exists for deciding whether to offer the "Generate email address"
    // button, and if so then which users to offer in the dropdown;
    // it's predicting whether /api/get-stream-email-address would succeed.

    final config = _groupSettingConfig(type, name);

    if (_selfUserRole == UserRole.guest && !config.allowEveryoneGroup) {
      return false;
    }

    if (value == null) {
      // The server doesn't know about the permission. *We* know about it
      // (or presumably we wouldn't have called this method),
      // and we know a reasonable default; use that.
      return _hasPermissionByDefault(config);
    }

    return selfInGroupSetting(value);
  }

  bool _hasPermissionByDefault(PermissionSettingsItem config) {
    switch (config.defaultGroupName) {
      case DefaultGroupNameUnknown():
        // When we know about a permission, we should also know about the group
        // we've said is the default value for it.
        assert(false);
        return true;
      case PseudoSystemGroupName.streamCreatorOrNobody:
        // TODO(#1102) implement
        assert(() {
          throw UnimplementedError();
        }());
        return true;
      case SystemGroupName.everyoneOnInternet:
      case SystemGroupName.everyone:
        return true;
      case SystemGroupName.members:
        return _selfUserRole.isAtLeast(UserRole.member);
      case SystemGroupName.fullMembers:
        // There aren't any permissions where this is the default, and we
        // probably won't add any. So for now we skip the complication of
        // doing the waiting-period check.
        assert(() {
          throw UnimplementedError();
        }());
        return _selfUserRole.isAtLeast(UserRole.member);
      case SystemGroupName.moderators:
        return _selfUserRole.isAtLeast(UserRole.moderator);
      case SystemGroupName.administrators:
        return _selfUserRole.isAtLeast(UserRole.administrator);
      case SystemGroupName.owners:
        return _selfUserRole.isAtLeast(UserRole.owner);
      case SystemGroupName.nobody:
        return false;
    }
  }

  /// The metadata for how to interpret the given group-based permission setting.
  PermissionSettingsItem _groupSettingConfig(GroupSettingType type, String name) {
    final supportedSettings = SupportedPermissionSettings.fixture;

    // Compare web's group_permission_settings.get_group_permission_setting_config.
    final configGroup = switch (type) {
      GroupSettingType.realm => supportedSettings.realm,
      GroupSettingType.stream => supportedSettings.stream,
      GroupSettingType.group => supportedSettings.group,
    };
    final config = configGroup[name];
    return config!; // TODO(log)
  }

  /// The [User.role] of the self-user.
  ///
  /// The main home of this information is [UserStore]: `store.selfUser.role`.
  /// We need it here for interpreting some permission settings;
  /// so we denormalize it here to avoid a cycle between substores.
  ///
  /// See also [_selfUserDateJoined].
  UserRole _selfUserRole;

  /// The [User.dateJoined] of the self-user.
  ///
  /// The main home of this information is [UserStore]:
  /// `store.selfUser.dateJoined`.
  /// We need it here for interpreting some permission settings;
  /// so we denormalize it here to avoid a cycle between substores.
  ///
  /// See also [_selfUserRole].
  final String _selfUserDateJoined;

  @override
  final int serverPresencePingIntervalSeconds;
  @override
  final int serverPresenceOfflineThresholdSeconds;

  @override
  final int serverTypingStartedExpiryPeriodMilliseconds;
  @override
  final int serverTypingStoppedWaitPeriodMilliseconds;
  @override
  final int serverTypingStartedWaitPeriodMilliseconds;

  @override
  final bool realmAllowMessageEditing;
  @override
  final GroupSettingValue? realmCanDeleteAnyMessageGroup;
  @override
  final GroupSettingValue? realmCanDeleteOwnMessageGroup;
  @override
  final bool realmEnableReadReceipts;
  @override
  final bool realmMandatoryTopics;
  @override
  final int maxFileUploadSizeMib;
  @override
  final int? realmMessageContentDeleteLimitSeconds;
  @override
  final int? realmMessageContentEditLimitSeconds;
  @override
  final bool realmPresenceDisabled;
  @override
  final int realmWaitingPeriodThreshold;

  @override
  final RealmWildcardMentionPolicy realmWildcardMentionPolicy;
  @override
  final RealmDeleteOwnMessagePolicy? realmDeleteOwnMessagePolicy;

  @override
  String get realmEmptyTopicDisplayName {
    assert(zulipFeatureLevel >= 334); // TODO(server-10)
    assert(_realmEmptyTopicDisplayName != null); // TODO(log)
    return _realmEmptyTopicDisplayName ?? 'general chat';
  }
  final String? _realmEmptyTopicDisplayName;

  @override
  final Map<String, RealmDefaultExternalAccount> realmDefaultExternalAccounts;

  @override
  final int maxChannelNameLength;
  @override
  final int maxTopicLength;

  @override
  List<CustomProfileField> customProfileFields;

  static List<CustomProfileField> _sortCustomProfileFields(List<CustomProfileField> initialCustomProfileFields) {
    // TODO(server): The realm-wide field objects have an `order` property,
    //   but the actual API appears to be that the fields should be shown in
    //   the order they appear in the array (`custom_profile_fields` in the
    //   API; our `realmFields` array here.)  See chat thread:
    //     https://chat.zulip.org/#narrow/stream/378-api-design/topic/custom.20profile.20fields/near/1382982
    //
    // We go on to put at the start of the list any fields that are marked for
    // displaying in the "profile summary".  (Possibly they should be at the
    // start of the list in the first place, but make sure just in case.)
    final displayFields = initialCustomProfileFields.where((e) => e.displayInProfileSummary == true);
    final nonDisplayFields = initialCustomProfileFields.where((e) => e.displayInProfileSummary != true);
    return displayFields.followedBy(nonDisplayFields).toList();
  }

  void handleCustomProfileFieldsEvent(CustomProfileFieldsEvent event) {
    customProfileFields = _sortCustomProfileFields(event.fields);
  }

  void handleRealmUserUpdateEvent(RealmUserUpdateEvent event) {
    // Compare [UserStoreImpl.handleRealmUserEvent].
    if (event.userId == selfUserId) {
      if (event.role != null) _selfUserRole = event.role!;
    }
  }
}
