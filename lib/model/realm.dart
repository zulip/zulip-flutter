import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import 'store.dart';

/// The portion of [PerAccountStore] for realm settings, server settings,
/// and similar data about the whole realm or server.
///
/// See also:
///  * [RealmStoreImpl] for the implementation of this that does the work.
mixin RealmStore {
  int get serverPresencePingIntervalSeconds;
  int get serverPresenceOfflineThresholdSeconds;

  RealmWildcardMentionPolicy get realmWildcardMentionPolicy;
  bool get realmMandatoryTopics;
  /// For docs, please see [InitialSnapshot.realmWaitingPeriodThreshold].
  int get realmWaitingPeriodThreshold;
  bool get realmAllowMessageEditing;
  int? get realmMessageContentEditLimitSeconds;
  bool get realmPresenceDisabled;
  int get maxFileUploadSizeMib;

  /// The display name to use for empty topics.
  ///
  /// This should only be accessed when FL >= 334, since topics cannot
  /// be empty otherwise.
  // TODO(server-10) simplify this
  String get realmEmptyTopicDisplayName;

  Map<String, RealmDefaultExternalAccount> get realmDefaultExternalAccounts;
  List<CustomProfileField> get customProfileFields;
  /// For docs, please see [InitialSnapshot.emailAddressVisibility].
  EmailAddressVisibility? get emailAddressVisibility;
}

/// The implementation of [RealmStore] that does the work.
class RealmStoreImpl extends PerAccountStoreBase with RealmStore {
  RealmStoreImpl({
    required super.core,
    required InitialSnapshot initialSnapshot,
  }) :
    serverPresencePingIntervalSeconds = initialSnapshot.serverPresencePingIntervalSeconds,
    serverPresenceOfflineThresholdSeconds = initialSnapshot.serverPresenceOfflineThresholdSeconds,
    realmWildcardMentionPolicy = initialSnapshot.realmWildcardMentionPolicy,
    realmMandatoryTopics = initialSnapshot.realmMandatoryTopics,
    realmWaitingPeriodThreshold = initialSnapshot.realmWaitingPeriodThreshold,
    realmPresenceDisabled = initialSnapshot.realmPresenceDisabled,
    maxFileUploadSizeMib = initialSnapshot.maxFileUploadSizeMib,
    _realmEmptyTopicDisplayName = initialSnapshot.realmEmptyTopicDisplayName,
    realmAllowMessageEditing = initialSnapshot.realmAllowMessageEditing,
    realmMessageContentEditLimitSeconds = initialSnapshot.realmMessageContentEditLimitSeconds,
    realmDefaultExternalAccounts = initialSnapshot.realmDefaultExternalAccounts,
    customProfileFields = _sortCustomProfileFields(initialSnapshot.customProfileFields),
    emailAddressVisibility = initialSnapshot.emailAddressVisibility;

  @override
  final int serverPresencePingIntervalSeconds;
  @override
  final int serverPresenceOfflineThresholdSeconds;

  @override
  final RealmWildcardMentionPolicy realmWildcardMentionPolicy; // TODO(#668): update this realm setting
  @override
  final bool realmMandatoryTopics;  // TODO(#668): update this realm setting
  @override
  final int realmWaitingPeriodThreshold;  // TODO(#668): update this realm setting
  @override
  final bool realmAllowMessageEditing; // TODO(#668): update this realm setting
  @override
  final int? realmMessageContentEditLimitSeconds; // TODO(#668): update this realm setting
  @override
  final bool realmPresenceDisabled; // TODO(#668): update this realm setting
  @override
  final int maxFileUploadSizeMib; // No event for this.

  @override
  String get realmEmptyTopicDisplayName {
    assert(zulipFeatureLevel >= 334); // TODO(server-10)
    assert(_realmEmptyTopicDisplayName != null); // TODO(log)
    return _realmEmptyTopicDisplayName ?? 'general chat';
  }
  final String? _realmEmptyTopicDisplayName; // TODO(#668): update this realm setting

  @override
  final Map<String, RealmDefaultExternalAccount> realmDefaultExternalAccounts;

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

  @override
  final EmailAddressVisibility? emailAddressVisibility; // TODO(#668): update this realm setting

  void handleCustomProfileFieldsEvent(CustomProfileFieldsEvent event) {
    customProfileFields = _sortCustomProfileFields(event.fields);
  }
}
