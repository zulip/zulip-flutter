import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import 'store.dart';

/// The portion of [PerAccountStore] for realm settings, server settings,
/// and similar data about the whole realm or server.
///
/// See also:
///  * [RealmStoreImpl] for the implementation of this that does the work.
///  * [HasRealmStore] for an implementation useful for other substores.
mixin RealmStore on PerAccountStoreBase {
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
}

mixin ProxyRealmStore on RealmStore {
  @protected
  RealmStore get realmStore;

  @override
  int get serverPresencePingIntervalSeconds => realmStore.serverPresencePingIntervalSeconds;
  @override
  int get serverPresenceOfflineThresholdSeconds => realmStore.serverPresenceOfflineThresholdSeconds;
  @override
  RealmWildcardMentionPolicy get realmWildcardMentionPolicy => realmStore.realmWildcardMentionPolicy;
  @override
  bool get realmMandatoryTopics => realmStore.realmMandatoryTopics;
  @override
  int get realmWaitingPeriodThreshold => realmStore.realmWaitingPeriodThreshold;
  @override
  bool get realmAllowMessageEditing => realmStore.realmAllowMessageEditing;
  @override
  int? get realmMessageContentEditLimitSeconds => realmStore.realmMessageContentEditLimitSeconds;
  @override
  bool get realmPresenceDisabled => realmStore.realmPresenceDisabled;
  @override
  int get maxFileUploadSizeMib => realmStore.maxFileUploadSizeMib;
  @override
  String get realmEmptyTopicDisplayName => realmStore.realmEmptyTopicDisplayName;
  @override
  Map<String, RealmDefaultExternalAccount> get realmDefaultExternalAccounts => realmStore.realmDefaultExternalAccounts;
  @override
  List<CustomProfileField> get customProfileFields => realmStore.customProfileFields;
  @override
  EmailAddressVisibility? get emailAddressVisibility => realmStore.emailAddressVisibility;
}

/// A base class for [PerAccountStore] substores that need access to [RealmStore]
/// as well as to [CorePerAccountStore].
abstract class HasRealmStore extends PerAccountStoreBase with RealmStore, ProxyRealmStore {
  HasRealmStore({required RealmStore realm})
    : realmStore = realm, super(core: realm.core);

  @protected
  @override
  final RealmStore realmStore;
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
