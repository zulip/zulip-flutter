import 'dart:convert';
import 'dart:math';

import 'package:zulip/api/core.dart';
import 'package:zulip/api/exception.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/message.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/model/store.dart';

import 'model/binding.dart';
import 'model/test_store.dart';
import 'stdlib_checks.dart';

void _checkPositive(int? value, String description) {
  assert(value == null || value > 0, '$description should be positive');
}

//|//////////////////////////////////////////////////////////////
// Error objects.
//

Object nullCheckError() {
  try { null!; } catch (e) { return e; } // ignore: null_check_always_fails
}

/// A Zulip API error with the generic "BAD_REQUEST" error code.
///
/// The server returns this error code for a wide range of error conditions;
/// it's the default within the server code when no more-specific code is chosen.
ZulipApiException apiBadRequest({
    String routeName = 'someRoute', String message = 'Something failed'}) {
  return ZulipApiException(
    routeName: routeName,
    httpStatus: 400, code: 'BAD_REQUEST',
    data: {}, message: message);
}

/// The error for the "events" route when the target event queue has been
/// garbage collected.
///
/// https://zulip.com/api/get-events#bad_event_queue_id-errors
ZulipApiException apiExceptionBadEventQueueId({
  String queueId = 'fb67bf8a-c031-47cc-84cf-ed80accacda8',
}) {
  return ZulipApiException(
    routeName: 'events', httpStatus: 400, code: 'BAD_EVENT_QUEUE_ID',
    data: {'queue_id': queueId}, message: 'Bad event queue ID: $queueId');
}

/// The error the server gives when the client's credentials
/// (API key together with email and realm URL) are no longer valid.
///
/// This isn't really documented, but comes from experiment and from
/// reading the server implementation.  See:
///   https://github.com/zulip/zulip-flutter/pull/1183#discussion_r1945865983
///   https://chat.zulip.org/#narrow/channel/378-api-design/topic/general.20handling.20HTTP.20status.20code.20401/near/2090024
ZulipApiException apiExceptionUnauthorized({String routeName = 'someRoute'}) {
  return ZulipApiException(
    routeName: routeName,
    httpStatus: 401, code: 'UNAUTHORIZED',
    data: {}, message: 'Invalid API key');
}

//|//////////////////////////////////////////////////////////////
// Time values.
//

final timeInPast = DateTime.utc(2025, 4, 1, 8, 30, 0);

/// The UNIX timestamp, in UTC seconds.
///
/// This is the commonly used format in the Zulip API for timestamps.
int utcTimestamp([DateTime? dateTime]) {
  dateTime ??= timeInPast;
  return dateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
}

//|//////////////////////////////////////////////////////////////
// Realm-wide (or server-wide) metadata.
//

final Uri realmUrl = Uri.parse('https://chat.example/');
Uri get _realmUrl => realmUrl;

final Uri realmIcon = Uri.parse('/user_avatars/2/realm/icon.png?version=3');
Uri get _realmIcon => realmIcon;

const String recentZulipVersion = '9.0';
const int recentZulipFeatureLevel = 382;
const int futureZulipFeatureLevel = 9999;
const int ancientZulipFeatureLevel = kMinSupportedZulipFeatureLevel - 1;

GetServerSettingsResult serverSettings({
  Map<String, bool>? authenticationMethods,
  List<ExternalAuthenticationMethod>? externalAuthenticationMethods,
  int? zulipFeatureLevel,
  String? zulipVersion,
  String? zulipMergeBase,
  bool? pushNotificationsEnabled,
  bool? isIncompatible,
  bool? emailAuthEnabled,
  bool? requireEmailFormatUsernames,
  Uri? realmUrl,
  String? realmName,
  Uri? realmIcon,
  String? realmDescription,
  bool? realmWebPublicAccessEnabled,
}) {
  return GetServerSettingsResult(
    authenticationMethods: authenticationMethods ?? {},
    externalAuthenticationMethods: externalAuthenticationMethods ?? [],
    zulipFeatureLevel: zulipFeatureLevel ?? recentZulipFeatureLevel,
    zulipVersion: zulipVersion ?? recentZulipVersion,
    zulipMergeBase: zulipMergeBase ?? recentZulipVersion,
    pushNotificationsEnabled: pushNotificationsEnabled ?? true,
    isIncompatible: isIncompatible ?? false,
    emailAuthEnabled: emailAuthEnabled ?? true,
    requireEmailFormatUsernames: requireEmailFormatUsernames ?? true,
    realmUrl: realmUrl ?? _realmUrl,
    realmName: realmName ?? 'Example Zulip organization',
    realmIcon: realmIcon ?? _realmIcon,
    realmDescription: realmDescription ?? 'An example Zulip organization',
    realmWebPublicAccessEnabled: realmWebPublicAccessEnabled ?? false,
  );
}

CustomProfileField customProfileField(
  int id,
  CustomProfileFieldType type, {
  int? order,
  bool? displayInProfileSummary,
  String? fieldData,
}) {
  return CustomProfileField(
    id: id,
    type: type,
    order: order ?? id,
    name: 'field$id',
    hint: 'hint$id',
    fieldData: fieldData ?? '',
    displayInProfileSummary: displayInProfileSummary ?? false,
  );
}

ServerEmojiData _immutableServerEmojiData({
    required Map<String, List<String>> codeToNames}) {
  return ServerEmojiData(
    codeToNames: Map.unmodifiable(codeToNames.map(
      (k, v) => MapEntry(k, List<String>.unmodifiable(v)))));
}

final ServerEmojiData serverEmojiDataPopular = _immutableServerEmojiData(codeToNames: {
  '1f44d': ['+1', 'thumbs_up', 'like'],
  '1f389': ['tada'],
  '1f642': ['slight_smile'],
  '2764': ['heart', 'love', 'love_you'],
  '1f6e0': ['working_on_it', 'hammer_and_wrench', 'tools'],
  '1f419': ['octopus'],
});

ServerEmojiData serverEmojiDataPopularPlus(ServerEmojiData data) {
  final a = serverEmojiDataPopular;
  final b = data;
  final result = ServerEmojiData(
    codeToNames: {...a.codeToNames, ...b.codeToNames},
  );
  assert(
    result.codeToNames.length == a.codeToNames.length + b.codeToNames.length,
    'eg.serverEmojiDataPopularPlus called with data that collides with eg.serverEmojiDataPopular',
  );
  return result;
}

/// Like [serverEmojiDataPopular], but with the legacy '1f642': ['smile']
/// instead of '1f642': ['slight_smile']; see zulip/zulip@9feba0f16f.
///
/// zulip/zulip@9feba0f16f is a Server 11 commit.
// TODO(server-11) can drop this
final ServerEmojiData serverEmojiDataPopularLegacy = _immutableServerEmojiData(codeToNames: {
  '1f44d': ['+1', 'thumbs_up', 'like'],
  '1f389': ['tada'],
  '1f642': ['smile'],
  '2764': ['heart', 'love', 'love_you'],
  '1f6e0': ['working_on_it', 'hammer_and_wrench', 'tools'],
  '1f419': ['octopus'],
});

/// A fresh user-group ID, from a random but always strictly increasing sequence.
int _nextUserGroupId() => (_lastUserGroupId += 1 + Random().nextInt(10));
int _lastUserGroupId = 100;

UserGroup userGroup({
  int? id,
  Iterable<int>? members,
  Iterable<int>? directSubgroupIds,
  String? name,
  String? description,
  bool isSystemGroup = false,
  bool deactivated = false,
}) {
  return UserGroup(
    id: id ??= _nextUserGroupId(),
    members: Set.of(members ?? []),
    directSubgroupIds: Set.of(directSubgroupIds ?? []),
    name: name ??= 'group-$id',
    description: description ?? 'A group named $name',
    isSystemGroup: isSystemGroup,
    deactivated: deactivated,
  );
}

final UserGroup nobodyGroup = userGroup(
  isSystemGroup: true,
  name: 'role:nobody', description: 'Nobody',
  members: [], directSubgroupIds: [],
);

GroupSettingValueNameless groupSetting({
  List<int>? members,
  List<int>? subgroups,
}) => GroupSettingValueNameless(
  directMembers: members ?? [],
  directSubgroups: subgroups ?? [],
);

RealmEmojiItem realmEmojiItem({
  required String emojiCode,
  required String emojiName,
  String? sourceUrl,
  String? stillUrl,
  bool deactivated = false,
  int? authorId,
}) {
  assert(RegExp(r'^[1-9][0-9]*$').hasMatch(emojiCode));
  return RealmEmojiItem(
    emojiCode: emojiCode,
    name: emojiName,
    sourceUrl: sourceUrl ?? '/emoji/$emojiCode.png',
    stillUrl: stillUrl,
    deactivated: deactivated,
    authorId: authorId ?? user().userId,
  );
}

//|//////////////////////////////////////////////////////////////
// Users and accounts.
//

/// A fresh user ID, from a random but always strictly increasing sequence.
int _nextUserId() => (_lastUserId += 1 + Random().nextInt(100));
int _lastUserId = 1000;

/// A random email address, different from previously generated ones.
String _nextEmail() => 'mail${_lastEmailSuffix += 1 + Random().nextInt(1000)}@example.com';
int _lastEmailSuffix = 1000;

/// Construct an example user.
///
/// If user ID `userId` is not given, it will be generated from a random
/// but increasing sequence.
/// Use an explicit `userId` only if the ID needs to correspond to some
/// other data in the test, or if the IDs need to increase in a different order
/// from the calls to [user].
///
/// If `email` is not given, it defaults to `deliveryEmail` if given and non-null,
/// or else to a value resembling the Zulip server's generated fake emails.
User user({
  int? userId,
  String? deliveryEmail,
  String? email,
  String? fullName,
  String? dateJoined,
  bool? isActive,
  bool? isBot,
  int? botOwnerId,
  UserRole? role,
  String? avatarUrl,
  Map<int, ProfileFieldUserData>? profileData,
}) {
  _checkPositive(userId, 'user ID');
  final effectiveUserId = userId ?? _nextUserId();
  return User(
    userId: effectiveUserId,
    deliveryEmail: deliveryEmail,
    email: email ?? deliveryEmail ?? 'user$effectiveUserId@${realmUrl.host}',
    fullName: fullName ?? 'A user', // TODO generate example names
    dateJoined: dateJoined ?? '2024-02-24T11:18+00:00',
    isActive: isActive ?? true,
    isBot: isBot ?? false,
    botType: null,
    botOwnerId: botOwnerId,
    role: role ?? UserRole.member,
    timezone: 'UTC',
    avatarUrl: avatarUrl,
    avatarVersion: 0,
    profileData: profileData,
    isSystemBot: false,
  );
}

Account account({
  int? id,
  Uri? realmUrl,
  String? realmName,
  Uri? realmIcon,
  required User user,
  String? apiKey,
  int? zulipFeatureLevel,
  String? zulipVersion,
  String? zulipMergeBase,
  String? ackedPushToken,
}) {
  _checkPositive(id, 'account ID');
  // When `user.deliveryEmail` is null, using `user.email`
  // wouldn't be realistic: it's going to be a fake email address
  // generated to serve as a "Zulip API email".
  final email = user.deliveryEmail ?? _nextEmail();
  return Account(
    id: id ?? 1000, // TODO generate example IDs
    realmUrl: realmUrl ?? _realmUrl,
    realmName: realmName ?? 'Example Zulip organization',
    realmIcon: realmIcon ?? _realmIcon,
    email: email,
    apiKey: apiKey ?? 'aeouasdf',
    userId: user.userId,
    zulipFeatureLevel: zulipFeatureLevel ?? recentZulipFeatureLevel,
    zulipVersion: zulipVersion ?? recentZulipVersion,
    zulipMergeBase: zulipMergeBase ?? recentZulipVersion,
    ackedPushToken: ackedPushToken,
  );
}
const _account = account;

/// A [User] which throws on attempting to mutate any of its fields.
///
/// We use this to prevent any tests from leaking state through having a
/// [PerAccountStore] (which will be discarded when [TestZulipBinding.reset]
/// is called at the end of the test case) mutate a [User] in its [UserStore]
/// which happens to a value in this file like [selfUser] (which will not be
/// discarded by [TestZulipBinding.reset]).  That was the cause of issue #1712.
class _ImmutableUser extends User {
  _ImmutableUser.copyUser(User user) : super(
    // When adding a field here, be sure to add the corresponding setter below.
    userId: user.userId,
    deliveryEmail: user.deliveryEmail,
    email: user.email,
    fullName: user.fullName,
    dateJoined: user.dateJoined,
    isActive: user.isActive,
    isBot: user.isBot,
    botType: user.botType,
    botOwnerId: user.botOwnerId,
    role: user.role,
    timezone: user.timezone,
    avatarUrl: user.avatarUrl,
    avatarVersion: user.avatarVersion,
    profileData: user.profileData == null ? null : Map.unmodifiable(user.profileData!),
    isSystemBot: user.isSystemBot,
    // When adding a field here, be sure to add the corresponding setter below.
  );

  static final Error _error = UnsupportedError(
    'Cannot mutate immutable User.\n'
    'When a test needs to have the store handle an event which will\n'
    'modify a user, use `eg.user()` to make a fresh User object\n'
    'instead of using a shared User object like `eg.selfUser`.');

  // userId already immutable
  @override set deliveryEmail(_) => throw _error;
  @override set email(_) => throw _error;
  @override set fullName(_) => throw _error;
  // dateJoined already immutable
  @override set isActive(_) => throw _error;
  // isBot already immutable
  // botType already immutable
  @override set botOwnerId(_) => throw _error;
  @override set role(_) => throw _error;
  @override set timezone(_) => throw _error;
  @override set avatarUrl(_) => throw _error;
  @override set avatarVersion(_) => throw _error;
  @override set profileData(_) => throw _error;
  // isSystemBot already immutable
}

final User selfUser = _ImmutableUser.copyUser(user(fullName: 'Self User'));
final User otherUser = _ImmutableUser.copyUser(user(fullName: 'Other User'));
final User thirdUser = _ImmutableUser.copyUser(user(fullName: 'Third User'));
final User fourthUser  = _ImmutableUser.copyUser(user(fullName: 'Fourth User'));

// There's no need for an [Account] analogue of [_ImmutableUser],
// because [Account] (which is generated by Drift) is already immutable.
final Account selfAccount = account(
  id: 1001,
  user: selfUser,
  apiKey: 'dQcEJWTq3LczosDkJnRTwf31zniGvMrO', // A Zulip API key is 32 digits of base64.
);
final Account otherAccount = account(
  id: 1002,
  user: otherUser,
  apiKey: '6dxT4b73BYpCTU+i4BB9LAKC5h/CufqY', // A Zulip API key is 32 digits of base64.
);
final Account thirdAccount = account(
  id: 1003,
  user: thirdUser,
  apiKey: 'q8HdN7u5Yz3Wc9LhQv1Rb4o2sXjKf6Ut', // A Zulip API key is 32 digits of base64.
);

//|//////////////////////////////////////////////////////////////
// Data attached to the self-account on the realm
//

int _nextSavedSnippetId() => _lastSavedSnippetId++;
int _lastSavedSnippetId = 1;

SavedSnippet savedSnippet({
  int? id,
  String? title,
  String? content,
  int? dateCreated,
}) {
  _checkPositive(id, 'saved snippet ID');
  return SavedSnippet(
    id: id ?? _nextSavedSnippetId(),
    title: title ?? 'A saved snippet',
    content: content ?? 'foo bar baz',
    dateCreated: dateCreated ?? 1234567890, // TODO generate timestamp
  );
}

//|//////////////////////////////////////////////////////////////
// Streams and subscriptions.
//

/// A fresh stream ID, from a random but always strictly increasing sequence.
int _nextStreamId() => (_lastStreamId += 1 + Random().nextInt(10));
int _lastStreamId = 200;

/// Construct an example stream.
///
/// If stream ID `streamId` is not given, it will be generated from a random
/// but increasing sequence.
/// Use an explicit `streamId` only if the ID needs to correspond to some
/// other data in the test, or if the IDs need to increase in a different order
/// from the calls to [stream].
ZulipStream stream({
  int? streamId,
  String? name,
  String? description,
  bool? isArchived,
  String? renderedDescription,
  int? dateCreated,
  int? firstMessageId,
  bool? inviteOnly,
  bool? isWebPublic,
  bool? historyPublicToSubscribers,
  int? messageRetentionDays,
  ChannelPostPolicy? channelPostPolicy,
  int? folderId,
  GroupSettingValue? canAddSubscribersGroup,
  GroupSettingValue? canDeleteAnyMessageGroup,
  GroupSettingValue? canDeleteOwnMessageGroup,
  GroupSettingValue? canSendMessageGroup,
  GroupSettingValue? canSubscribeGroup,
  int? streamWeeklyTraffic,
}) {
  if (channelPostPolicy == null) {
    // Set a default for realmCanDeleteOwnMessageGroup, but only if we're
    // not trying to test legacy behavior with channelPostPolicy.
    canSendMessageGroup ??= groupSetting(members: [selfUser.userId]);
  }

  _checkPositive(streamId, 'stream ID');
  _checkPositive(firstMessageId, 'message ID');
  var effectiveStreamId = streamId ?? _nextStreamId();
  var effectiveName = name ?? 'stream $effectiveStreamId';
  var effectiveDescription = description ?? 'Description of $effectiveName';
  return ZulipStream(
    streamId: effectiveStreamId,
    name: effectiveName,
    isArchived: isArchived ?? false,
    description: effectiveDescription,
    renderedDescription: renderedDescription ?? '<p>$effectiveDescription</p>',
    dateCreated: dateCreated ?? 1686774898,
    firstMessageId: firstMessageId,
    inviteOnly: inviteOnly ?? false,
    isWebPublic: isWebPublic ?? false,
    historyPublicToSubscribers: historyPublicToSubscribers ?? true,
    messageRetentionDays: messageRetentionDays,
    channelPostPolicy: channelPostPolicy ?? ChannelPostPolicy.any,
    folderId: folderId,
    canAddSubscribersGroup: canAddSubscribersGroup ?? GroupSettingValueNamed(nobodyGroup.id),
    canDeleteAnyMessageGroup: canDeleteAnyMessageGroup ?? GroupSettingValueNamed(nobodyGroup.id),
    canDeleteOwnMessageGroup: canDeleteOwnMessageGroup ?? GroupSettingValueNamed(nobodyGroup.id),
    canSendMessageGroup: canSendMessageGroup,
    canSubscribeGroup: canSubscribeGroup ?? GroupSettingValueNamed(nobodyGroup.id),
    streamWeeklyTraffic: streamWeeklyTraffic,
  );
}
const _stream = stream;

GetStreamTopicsEntry getStreamTopicsEntry({int? maxId, String? name}) {
  maxId ??= 123;
  return GetStreamTopicsEntry(maxId: maxId,
    name: TopicName(name ?? 'Test Topic #$maxId'));
}

/// Construct an example subscription from a stream.
///
/// We only allow overrides of values specific to the [Subscription], all
/// other properties are copied from the [ZulipStream] provided.
Subscription subscription(
  ZulipStream stream, {
  bool? desktopNotifications,
  bool? emailNotifications,
  bool? wildcardMentionsNotify,
  bool? pushNotifications,
  bool? audibleNotifications,
  bool? pinToTop,
  bool? isMuted,
  int? color,
}) {
  return Subscription(
    streamId: stream.streamId,
    name: stream.name,
    isArchived: stream.isArchived,
    description: stream.description,
    renderedDescription: stream.renderedDescription,
    dateCreated: stream.dateCreated,
    firstMessageId: stream.firstMessageId,
    inviteOnly: stream.inviteOnly,
    isWebPublic: stream.isWebPublic,
    historyPublicToSubscribers: stream.historyPublicToSubscribers,
    messageRetentionDays: stream.messageRetentionDays,
    channelPostPolicy: stream.channelPostPolicy,
    folderId: stream.folderId,
    canAddSubscribersGroup: stream.canAddSubscribersGroup,
    canDeleteAnyMessageGroup: stream.canDeleteAnyMessageGroup,
    canDeleteOwnMessageGroup: stream.canDeleteOwnMessageGroup,
    canSendMessageGroup: stream.canSendMessageGroup,
    canSubscribeGroup: stream.canSubscribeGroup,
    streamWeeklyTraffic: stream.streamWeeklyTraffic,
    desktopNotifications: desktopNotifications ?? false,
    emailNotifications: emailNotifications ?? false,
    wildcardMentionsNotify: wildcardMentionsNotify ?? false,
    pushNotifications: pushNotifications ?? false,
    audibleNotifications: audibleNotifications ?? false,
    pinToTop: pinToTop ?? false,
    isMuted: isMuted ?? false,
    color: color ?? 0xFFFF0000,
  );
}

/// A fresh channel folder ID,
/// from a random but always strictly increasing sequence.
int _nextChannelFolderId() => (_lastChannelFolderId += 1 + Random().nextInt(100));
int _lastChannelFolderId = 1000;

ChannelFolder channelFolder({
  int? id,
  String? name,
  int? order,
  int? dateCreated,
  int? creatorId,
  String? description,
  String? renderedDescription,
  bool? isArchived,
}) {
  final effectiveId = id ?? _nextChannelFolderId();
  final effectiveDescription = description ?? 'An example channel folder.';
  return ChannelFolder(
    id: effectiveId,
    name: name ?? 'channel folder $effectiveId',
    order: order,
    dateCreated: dateCreated ?? utcTimestamp(),
    creatorId: creatorId ?? selfUser.userId,
    description: effectiveDescription,
    renderedDescription: renderedDescription ?? '<p>$effectiveDescription</p>',
    isArchived: isArchived ?? false,
  );
}

ChannelFolderChange channelFolderChange({
  String? name,
  String? description,
  String? renderedDescription,
  bool? isArchived,
}) {
  return ChannelFolderChange(
    name: name,
    description: description,
    renderedDescription: renderedDescription,
    isArchived: isArchived,
  );
}

/// The [TopicName] constructor, but shorter.
///
/// Useful in test code that mentions a lot of topics in a compact format.
TopicName t(String apiName) => TopicName(apiName);

TopicNarrow topicNarrow(int channelId, String topicName, {int? with_}) {
  return TopicNarrow(channelId, TopicName(topicName), with_: with_);
}

UserTopicItem userTopicItem(
    ZulipStream stream, String topic, UserTopicVisibilityPolicy policy) {
  return UserTopicItem(
    streamId: stream.streamId,
    topicName: TopicName(topic),
    lastUpdated: 1234567890,
    visibilityPolicy: policy,
  );
}

//|//////////////////////////////////////////////////////////////
// Messages, and pieces of messages.
//

final Reaction unicodeEmojiReaction = Reaction(
  emojiName: 'thumbs_up',
  emojiCode: '1f44d',
  reactionType: ReactionType.unicodeEmoji,
  userId: selfUser.userId,
);

final Reaction realmEmojiReaction = Reaction(
  emojiName: 'twocents',
  emojiCode: '181',
  reactionType: ReactionType.realmEmoji,
  userId: selfUser.userId,
);

final Reaction zulipExtraEmojiReaction = Reaction(
  emojiName: 'zulip',
  emojiCode: 'zulip',
  reactionType: ReactionType.zulipExtraEmoji,
  userId: selfUser.userId,
);

final _messagePropertiesBase = {
  'is_me_message': false,
  'recipient_id': 32, // obsolescent in API, and ignored
};

Map<String, dynamic> _messagePropertiesFromSender(User? sender) {
  return {
    'client': 'ExampleClient',
    'sender_email': sender?.email ?? 'a-person@example',
    'sender_full_name': sender?.fullName ?? 'A Person',
    'sender_id': sender?.userId ?? 12345, // TODO generate example IDs
    'sender_realm_str': 'zulip',
  };
}

Map<String, dynamic> _messagePropertiesFromContent(String? content, String? contentMarkdown) {
  if (contentMarkdown != null) {
    assert(content == null);
    return {
      'content': contentMarkdown,
      'content_type': 'text/x-markdown',
    };
  } else {
    return {
      'content': content ?? '<p>This is an example message.</p>',
      'content_type': 'text/html',
    };
  }
}

/// A fresh message ID, from a random but always strictly increasing sequence.
int _nextMessageId() => (_lastMessageId += 1 + Random().nextInt(100));
int _lastMessageId = 1000;

const defaultStreamMessageStreamId = 123;

/// The default topic used by [streamMessage].
///
/// Tests generally shouldn't need this information directly.
/// Instead, either
///  * use [StreamMessage.topic] to read off an example message's topic;
///  * or pick an example topic, and pass it both to [streamMessage]
///    and wherever else the same topic is needed.
final _defaultTopic = 'example topic ${Random().nextInt(1000)}';

/// Construct an example stream message.
///
/// If the message ID `id` is not given, it will be generated from a random
/// but increasing sequence, which is shared with [dmMessage].
/// Use an explicit `id` only if the ID needs to correspond to some other data
/// in the test, or if the IDs need to increase in a different order from the
/// calls to [streamMessage] and [dmMessage].
///
/// The message will be in `stream` if given.  Otherwise,
/// an example stream with ID `defaultStreamMessageStreamId` will be used.
///
/// If `topic` is not given, a default topic name is used.
/// The default is randomly chosen, but remains the same
/// for subsequent calls to this function.
///
/// See also:
///  * [dmMessage], to construct an example direct message.
StreamMessage streamMessage({
  int? id,
  User? sender,
  ZulipStream? stream,
  String? topic,
  String? content,
  String? contentMarkdown,
  int? lastEditTimestamp,
  List<Reaction>? reactions,
  int? timestamp,
  List<MessageFlag>? flags,
  String? matchContent,
  String? matchTopic,
  List<Submessage>? submessages,
}) {
  _checkPositive(id, 'message ID');
  final effectiveStream = stream ?? _stream(streamId: defaultStreamMessageStreamId);
  // The use of JSON here is convenient in order to delegate parts of the data
  // to helper functions.  The main downside is that it loses static typing
  // of the properties as we're constructing the data.  That's probably OK
  // because (a) this is only for tests; (b) the types do get checked
  // dynamically in the constructor, so any ill-typing won't propagate further.
  return StreamMessage.fromJson(deepToJson({
    ..._messagePropertiesBase,
    ..._messagePropertiesFromSender(sender),
    ..._messagePropertiesFromContent(content, contentMarkdown),
    'display_recipient': effectiveStream.name,
    'stream_id': effectiveStream.streamId,
    'reactions': reactions == null ? <Reaction>[] : Reactions(reactions),
    'flags': flags ?? [],
    'id': id ?? _nextMessageId(),
    'last_edit_timestamp': lastEditTimestamp,
    'subject': topic ?? _defaultTopic,
    'submessages': submessages ?? [],
    'timestamp': timestamp ?? 1678139636,
    'type': 'stream',
    'match_content': matchContent,
    'match_subject': matchTopic,
  }) as Map<String, dynamic>);
}

/// Construct an example direct message.
///
/// If the message ID `id` is not given, it will be generated from a random
/// but increasing sequence, which is shared with [streamMessage].
/// Use an explicit `id` only if the ID needs to correspond to some other data
/// in the test, or if the IDs need to increase in a different order from the
/// calls to [streamMessage] and [dmMessage].
///
/// See also:
///  * [streamMessage], to construct an example stream message.
DmMessage dmMessage({
  int? id,
  required User from,
  required List<User> to,
  String? content,
  String? contentMarkdown,
  int? lastEditTimestamp,
  int? timestamp,
  List<MessageFlag>? flags,
  List<Submessage>? submessages,
}) {
  _checkPositive(id, 'message ID');
  assert(!to.any((user) => user.userId == from.userId));
  return DmMessage.fromJson(deepToJson({
    ..._messagePropertiesBase,
    ..._messagePropertiesFromSender(from),
    ..._messagePropertiesFromContent(content, contentMarkdown),
    'display_recipient': [from, ...to]
      .map((u) => {'id': u.userId, 'email': u.email, 'full_name': u.fullName})
      .toList(growable: false),
    'reactions': <Reaction>[],
    'flags': flags ?? [],
    'id': id ?? _nextMessageId(),
    'last_edit_timestamp': lastEditTimestamp,
    'subject': '',
    'submessages': submessages ?? [],
    'timestamp': timestamp ?? 1678139636,
    'type': 'private',
  }) as Map<String, dynamic>);
}

/// A GetMessagesResult the server might return for
/// a request that sent the given [anchor].
///
/// The request's anchor controls the response's [GetMessagesResult.anchor],
/// affects the default for [foundAnchor],
/// and in some cases forces the value of [foundOldest] or [foundNewest].
GetMessagesResult getMessagesResult({
  required Anchor anchor,
  bool? foundAnchor,
  bool? foundOldest,
  bool? foundNewest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  final resultAnchor = switch (anchor) {
    AnchorCode.oldest => 0,
    NumericAnchor(:final messageId) => messageId,
    AnchorCode.firstUnread =>
      throw ArgumentError("firstUnread not accepted in this helper; try NumericAnchor"),
    AnchorCode.newest => 10_000_000_000_000_000, // that's 16 zeros
  };

  switch (anchor) {
    case AnchorCode.oldest || AnchorCode.newest:
      assert(foundAnchor == null);
      foundAnchor = false;
    case AnchorCode.firstUnread || NumericAnchor():
      foundAnchor ??= true;
  }

  if (anchor == AnchorCode.oldest) {
    assert(foundOldest == null);
    foundOldest = true;
  } else if (anchor == AnchorCode.newest) {
    assert(foundNewest == null);
    foundNewest = true;
  }
  if (foundOldest == null || foundNewest == null) throw ArgumentError();

  return GetMessagesResult(
    anchor: resultAnchor,
    foundAnchor: foundAnchor,
    foundOldest: foundOldest,
    foundNewest: foundNewest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

/// A GetMessagesResult the server might return on an `anchor=newest` request,
/// or `anchor=first_unread` when there are no unreads.
GetMessagesResult newestGetMessagesResult({
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return getMessagesResult(anchor: AnchorCode.newest, foundOldest: foundOldest,
    historyLimited: historyLimited, messages: messages);
}

/// A GetMessagesResult the server might return on an initial request
/// when the anchor is in the middle of history (e.g., a /near/ link).
GetMessagesResult nearGetMessagesResult({
  required int anchor,
  bool foundAnchor = true,
  required bool foundOldest,
  required bool foundNewest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    anchor: anchor,
    foundAnchor: foundAnchor,
    foundOldest: foundOldest,
    foundNewest: foundNewest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

/// A GetMessagesResult the server might return when we request older messages.
GetMessagesResult olderGetMessagesResult({
  required int anchor,
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    anchor: anchor,
    foundAnchor: false,
    foundNewest: false, // empirically always this, even when anchor happens to be latest
    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

/// A GetMessagesResult the server might return when we request newer messages.
GetMessagesResult newerGetMessagesResult({
  required int anchor,
  required bool foundNewest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    anchor: anchor,
    foundAnchor: false,
    foundOldest: false,
    foundNewest: foundNewest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

int _nextLocalMessageId = 1;

StreamOutboxMessage streamOutboxMessage({
  int? localMessageId,
  int? selfUserId,
  int? timestamp,
  ZulipStream? stream,
  String? topic,
  String? content,
}) {
  final effectiveStream = stream ?? _stream(streamId: defaultStreamMessageStreamId);
  return OutboxMessage.fromConversation(
    StreamConversation(
      effectiveStream.streamId, TopicName(topic ?? 'topic'),
      displayRecipient: null,
    ),
    localMessageId: localMessageId ?? _nextLocalMessageId++,
    selfUserId: selfUserId ?? selfUser.userId,
    timestamp: timestamp ?? utcTimestamp(),
    contentMarkdown: content ?? 'content') as StreamOutboxMessage;
}

DmOutboxMessage dmOutboxMessage({
  int? localMessageId,
  required User from,
  required List<User> to,
  int? timestamp,
  String? content,
}) {
  final allRecipientIds =
    [from, ...to].map((user) => user.userId).toList()..sort();
  return OutboxMessage.fromConversation(
    DmConversation(allRecipientIds: allRecipientIds),
    localMessageId: localMessageId ?? _nextLocalMessageId++,
    selfUserId: from.userId,
    timestamp: timestamp ?? utcTimestamp(),
    contentMarkdown: content ?? 'content') as DmOutboxMessage;
}

PollWidgetData pollWidgetData({
  required String question,
  required List<String> options,
}) {
  return PollWidgetData(
    extraData: PollWidgetExtraData(question: question, options: options));
}

Submessage submessage({
  SubmessageType? msgType,
  required SubmessageData? content,
  int? senderId,
}) {
  return Submessage(
    msgType: msgType ?? SubmessageType.widget,
    content: jsonEncode(content),
    senderId: senderId ?? selfUser.userId,
  );
}

//|//////////////////////////////////////////////////////////////
// Aggregate data structures.
//

UnreadChannelSnapshot unreadChannelMsgs({
  required String topic,
  required int streamId,
  required List<int> unreadMessageIds,
}) {
  return UnreadChannelSnapshot(
    topic: TopicName(topic),
    streamId: streamId,
    unreadMessageIds: unreadMessageIds,
  );
}

UnreadMessagesSnapshot unreadMsgs({
  int? count,
  List<UnreadDmSnapshot>? dms,
  List<UnreadChannelSnapshot>? channels,
  List<UnreadHuddleSnapshot>? huddles,
  List<int>? mentions,
  bool? oldUnreadsMissing,
}) {
  return UnreadMessagesSnapshot(
    count: count ?? 0,
    dms: dms ?? [],
    channels: channels ?? [],
    huddles: huddles ?? [],
    mentions: mentions ?? [],
    oldUnreadsMissing: oldUnreadsMissing ?? false,
  );
}
const _unreadMsgs = unreadMsgs;

//|//////////////////////////////////////////////////////////////
// Events.
//

UserTopicEvent userTopicEvent(
    int streamId, String topic, UserTopicVisibilityPolicy visibilityPolicy) {
  return UserTopicEvent(
    id: 1,
    streamId: streamId,
    topicName: TopicName(topic),
    lastUpdated: 1234567890,
    visibilityPolicy: visibilityPolicy,
  );
}

MutedUsersEvent mutedUsersEvent(List<int> userIds) {
  return MutedUsersEvent(id: 1,
    mutedUsers: userIds.map((id) => MutedUserItem(id: id)).toList());
}

MessageEvent messageEvent(Message message, {int? localMessageId}) =>
  MessageEvent(id: 0, message: message, localMessageId: localMessageId?.toString());

DeleteMessageEvent deleteMessageEvent(List<StreamMessage> messages) {
  assert(messages.isNotEmpty);
  final streamId = messages.first.streamId;
  final topic = messages.first.topic;
  assert(messages.every((m) => m.streamId == streamId));
  assert(messages.every((m) => m.topic == topic));
  return DeleteMessageEvent(
    id: 0,
    messageIds: messages.map((message) => message.id).toList(),
    messageType: MessageType.stream,
    streamId: messages[0].streamId,
    topic: messages[0].topic,
  );
}

UpdateMessageEvent updateMessageEditEvent(
  Message origMessage, {
  int? userId = -1, // null means null; default is [selfUser.userId]
  bool renderingOnly = false,
  int? messageId,
  List<MessageFlag>? flags,
  int? editTimestamp,
  String? renderedContent,
  bool isMeMessage = false,
}) {
  _checkPositive(messageId, 'message ID');
  messageId ??= origMessage.id;
  return UpdateMessageEvent(
    id: 0,
    userId: userId == -1 ? selfUser.userId : userId,
    renderingOnly: renderingOnly,
    messageId: messageId,
    messageIds: [messageId],
    flags: flags ?? origMessage.flags,
    editTimestamp: editTimestamp ?? 1234567890, // TODO generate timestamp
    moveData: null,
    origContent: 'some probably-mismatched old Markdown',
    origRenderedContent: origMessage.content,
    content: 'some probably-mismatched new Markdown',
    renderedContent: renderedContent ?? origMessage.content,
    isMeMessage: isMeMessage,
  );
}

UpdateMessageEvent _updateMessageMoveEvent(
  List<int> messageIds, {
  required int origStreamId,
  int? newStreamId,
  required TopicName origTopic,
  TopicName? newTopic,
  String? origContent,
  String? newContent,
  required List<MessageFlag> flags,
  PropagateMode propagateMode = PropagateMode.changeOne,
}) {
  _checkPositive(origStreamId, 'stream ID');
  _checkPositive(newStreamId, 'stream ID');
  assert(messageIds.isNotEmpty);
  return UpdateMessageEvent(
    id: 0,
    userId: selfUser.userId,
    renderingOnly: false,
    messageId: messageIds.first,
    messageIds: messageIds,
    flags: flags,
    editTimestamp: 1234567890, // TODO generate timestamp
    moveData: UpdateMessageMoveData(
      origStreamId: origStreamId,
      newStreamId: newStreamId ?? origStreamId,
      origTopic: origTopic,
      newTopic: newTopic ?? origTopic,
      propagateMode: propagateMode,
    ),
    origContent: origContent,
    origRenderedContent: origContent,
    content: newContent,
    renderedContent: newContent,
    isMeMessage: false,
  );
}

/// An [UpdateMessageEvent] where [origMessages] are moved to somewhere else.
UpdateMessageEvent updateMessageEventMoveFrom({
  required List<StreamMessage> origMessages,
  int? newStreamId,
  TopicName? newTopic,
  String? newTopicStr,
  String? newContent,
  PropagateMode propagateMode = PropagateMode.changeOne,
}) {
  _checkPositive(newStreamId, 'stream ID');
  assert(origMessages.isNotEmpty);
  assert(newTopic == null || newTopicStr == null);
  newTopic ??= newTopicStr == null ? null : TopicName(newTopicStr);
  final origMessage = origMessages.first;
  // Only present on content change.
  final origContent = (newContent != null) ? origMessage.content : null;
  return _updateMessageMoveEvent(origMessages.map((e) => e.id).toList(),
    origStreamId: origMessage.streamId,
    newStreamId: newStreamId,
    origTopic: origMessage.topic,
    newTopic: newTopic,
    origContent: origContent,
    newContent: newContent,
    flags: origMessage.flags,
    propagateMode: propagateMode,
  );
}

/// An [UpdateMessageEvent] where [newMessages] are moved from somewhere.
UpdateMessageEvent updateMessageEventMoveTo({
  required List<StreamMessage> newMessages,
  int? origStreamId,
  TopicName? origTopic,
  String? origTopicStr,
  String? origContent,
  PropagateMode propagateMode = PropagateMode.changeOne,
}) {
  _checkPositive(origStreamId, 'stream ID');
  assert(newMessages.isNotEmpty);
  assert(origTopic == null || origTopicStr == null);
  origTopic ??= origTopicStr == null ? null : TopicName(origTopicStr);
  final newMessage = newMessages.first;
  // Only present on topic move.
  final newTopic = (origTopic != null) ? newMessage.topic : null;
  // Only present on channel move.
  final newStreamId = (origStreamId != null) ? newMessage.streamId : null;
  // Only present on content change.
  final newContent = (origContent != null) ? newMessage.content : null;
  return _updateMessageMoveEvent(newMessages.map((e) => e.id).toList(),
    origStreamId: origStreamId ?? newMessage.streamId,
    newStreamId: newStreamId,
    origTopic: origTopic ?? newMessage.topic,
    newTopic:  newTopic,
    origContent: origContent,
    newContent: newContent,
    flags: newMessage.flags,
    propagateMode: propagateMode,
  );
}

UpdateMessageFlagsRemoveEvent updateMessageFlagsRemoveEvent(
  MessageFlag flag,
  Iterable<Message> messages, {
  int? selfUserId,
}) {
  _checkPositive(selfUserId, 'user ID');
  return UpdateMessageFlagsRemoveEvent(
    id: 0,
    flag: flag,
    messages: messages.map((m) => m.id).toList(),
    messageDetails: Map.fromEntries(messages.map((message) {
      final mentioned = message.flags.contains(MessageFlag.mentioned)
        || message.flags.contains(MessageFlag.wildcardMentioned);
      return MapEntry(
        message.id,
        switch (message) {
          StreamMessage() => UpdateMessageFlagsMessageDetail(
            type: MessageType.stream,
            mentioned: mentioned,
            streamId: message.streamId,
            topic: message.topic,
            userIds: null,
          ),
          DmMessage() => UpdateMessageFlagsMessageDetail(
            type: MessageType.direct,
            mentioned: mentioned,
            streamId: null,
            topic: null,
            userIds: DmNarrow.ofMessage(message, selfUserId: selfUserId ?? selfUser.userId)
              .otherRecipientIds,
          ),
        },
      );
    })));
}

SubmessageEvent submessageEvent(
  int messageId,
  int senderId, {
  required SubmessageData? content,
}) {
  return SubmessageEvent(
    id: 0,
    msgType: SubmessageType.widget,
    content: jsonEncode(content),
    messageId: messageId,
    senderId: senderId,
    submessageId: 100,
  );
}

TypingEvent typingEvent(SendableNarrow narrow, TypingOp op, int senderId) {
  switch (narrow) {
    case TopicNarrow():
      return TypingEvent(id: 0, op: op, senderId: senderId,
        messageType: MessageType.stream,
        streamId: narrow.streamId,
        topic: narrow.topic,
        recipientIds: null);
    case DmNarrow():
      return TypingEvent(id: 0, op: op, senderId: senderId,
        messageType: MessageType.direct,
        recipientIds: narrow.allRecipientIds,
        streamId: null,
        topic: null);
  }
}

ReactionEvent reactionEvent(Reaction reaction, ReactionOp op, int messageId) {
  return ReactionEvent(
    id: 0,
    op: op,
    emojiName: reaction.emojiName,
    emojiCode: reaction.emojiCode,
    reactionType: reaction.reactionType,
    userId: reaction.userId,
    messageId: messageId,
  );
}

ChannelUpdateEvent channelUpdateEvent(
  ZulipStream stream, {
  required ChannelPropertyName property,
  required Object? value,
}) {
  switch (property) {
    case ChannelPropertyName.name:
      assert(value is String);
    case ChannelPropertyName.isArchived:
      assert(value is bool);
    case ChannelPropertyName.description:
      assert(value is String);
    case ChannelPropertyName.firstMessageId:
      assert(value is int?);
    case ChannelPropertyName.inviteOnly:
      assert(value is bool);
    case ChannelPropertyName.messageRetentionDays:
      assert(value is int?);
    case ChannelPropertyName.channelPostPolicy:
      assert(value is ChannelPostPolicy);
    case ChannelPropertyName.folderId:
      assert(value is int?);
    case ChannelPropertyName.canAddSubscribersGroup:
    case ChannelPropertyName.canDeleteAnyMessageGroup:
    case ChannelPropertyName.canDeleteOwnMessageGroup:
    case ChannelPropertyName.canSendMessageGroup:
    case ChannelPropertyName.canSubscribeGroup:
      assert(value is GroupSettingValue);
    case ChannelPropertyName.streamWeeklyTraffic:
      assert(value is int?);
  }
  return ChannelUpdateEvent(
    id: 1,
    streamId: stream.streamId,
    name: stream.name,
    property: property,
    value: value,
  );
}

//|//////////////////////////////////////////////////////////////
// The entire per-account or global state.
//

TestGlobalStore globalStore({
  GlobalSettingsData? globalSettings,
  Map<BoolGlobalSetting, bool>? boolGlobalSettings,
  Map<IntGlobalSetting, int>? intGlobalSettings,
  List<Account> accounts = const [],
}) {
  return TestGlobalStore(
    globalSettings: globalSettings,
    boolGlobalSettings: boolGlobalSettings,
    intGlobalSettings: intGlobalSettings,
    accounts: accounts,
  );
}
const _globalStore = globalStore;

const String defaultRealmEmptyTopicDisplayName = 'test general chat';

UserSettings userSettings({
  TwentyFourHourTimeMode? twentyFourHourTime,
  bool? displayEmojiReactionUsers,
  Emojiset? emojiset,
  bool? presenceEnabled,
}) {
  return UserSettings(
    twentyFourHourTime: twentyFourHourTime ?? TwentyFourHourTimeMode.twelveHour,
    displayEmojiReactionUsers: displayEmojiReactionUsers ?? true,
    emojiset: emojiset ?? Emojiset.google,
    presenceEnabled: presenceEnabled ?? true,
  );
}
const _userSettings = userSettings;

InitialSnapshot initialSnapshot({
  String? queueId,
  int? lastEventId,
  int? zulipFeatureLevel,
  String? zulipVersion,
  String? zulipMergeBase,
  List<String>? alertWords,
  List<CustomProfileField>? customProfileFields,
  int? maxChannelNameLength,
  int? maxTopicLength,
  int? serverPresencePingIntervalSeconds,
  int? serverPresenceOfflineThresholdSeconds,
  int? serverTypingStartedExpiryPeriodMilliseconds,
  int? serverTypingStoppedWaitPeriodMilliseconds,
  int? serverTypingStartedWaitPeriodMilliseconds,
  List<MutedUserItem>? mutedUsers,
  Map<int, PerUserPresence>? presences,
  Map<String, RealmEmojiItem>? realmEmoji,
  List<UserGroup>? realmUserGroups,
  List<RecentDmConversation>? recentPrivateConversations,
  List<SavedSnippet>? savedSnippets,
  List<Subscription>? subscriptions,
  List<ChannelFolder>? channelFolders,
  UnreadMessagesSnapshot? unreadMsgs,
  List<ZulipStream>? streams,
  Map<int, UserStatusChange>? userStatuses,
  UserSettings? userSettings,
  List<UserTopicItem>? userTopics,
  GroupSettingValue? realmCanDeleteAnyMessageGroup,
  GroupSettingValue? realmCanDeleteOwnMessageGroup,
  RealmDeleteOwnMessagePolicy? realmDeleteOwnMessagePolicy,
  RealmWildcardMentionPolicy? realmWildcardMentionPolicy,
  bool? realmMandatoryTopics,
  String? realmName,
  int? realmWaitingPeriodThreshold,
  int? realmMessageContentDeleteLimitSeconds,
  bool? realmAllowMessageEditing,
  int? realmMessageContentEditLimitSeconds,
  bool? realmEnableReadReceipts,
  Uri? realmIconUrl,
  bool? realmPresenceDisabled,
  Map<String, RealmDefaultExternalAccount>? realmDefaultExternalAccounts,
  int? maxFileUploadSizeMib,
  Uri? serverEmojiDataUrl,
  String? realmEmptyTopicDisplayName,
  List<User>? realmUsers,
  List<User>? realmNonActiveUsers,
  List<User>? crossRealmBots,
}) {
  if (realmDeleteOwnMessagePolicy == null) {
    // Set a default for realmCanDeleteOwnMessageGroup, but only if we're
    // trying to simulate a modern server without realmDeleteOwnMessagePolicy.
    realmCanDeleteOwnMessageGroup ??= GroupSettingValueNamed(nobodyGroup.id);
  }
  assert((realmCanDeleteOwnMessageGroup != null) ^ (realmDeleteOwnMessagePolicy != null));

  return InitialSnapshot(
    queueId: queueId ?? '1:2345',
    lastEventId: lastEventId ?? -1,
    zulipFeatureLevel: zulipFeatureLevel ?? recentZulipFeatureLevel,
    zulipVersion: zulipVersion ?? recentZulipVersion,
    zulipMergeBase: zulipMergeBase ?? recentZulipVersion,
    alertWords: alertWords ?? ['klaxon'],
    customProfileFields: customProfileFields ?? [],
    maxChannelNameLength: maxChannelNameLength ?? 60,
    maxTopicLength: maxTopicLength ?? 60,
    serverPresencePingIntervalSeconds: serverPresencePingIntervalSeconds ?? 60,
    serverPresenceOfflineThresholdSeconds: serverPresenceOfflineThresholdSeconds ?? 140,
    serverTypingStartedExpiryPeriodMilliseconds:
      serverTypingStartedExpiryPeriodMilliseconds ?? 15000,
    serverTypingStoppedWaitPeriodMilliseconds:
      serverTypingStoppedWaitPeriodMilliseconds ?? 5000,
    serverTypingStartedWaitPeriodMilliseconds:
      serverTypingStartedWaitPeriodMilliseconds ?? 10000,
    mutedUsers: mutedUsers ?? [],
    presences: presences ?? {},
    realmEmoji: realmEmoji ?? {},
    realmUserGroups: realmUserGroups ?? [],
    recentPrivateConversations: recentPrivateConversations ?? [],
    savedSnippets: savedSnippets ?? [],
    subscriptions: subscriptions ?? [], // TODO add subscriptions to default
    channelFolders: channelFolders ?? [],
    unreadMsgs: unreadMsgs ?? _unreadMsgs(),
    streams: streams ?? [], // TODO add streams to default
    userStatuses: userStatuses ?? {},
    userSettings: userSettings ?? _userSettings(),
    userTopics: userTopics ?? [],
    // no default; allow `null` to simulate servers without this
    realmCanDeleteAnyMessageGroup: realmCanDeleteAnyMessageGroup,
    realmCanDeleteOwnMessageGroup: realmCanDeleteOwnMessageGroup,
    realmDeleteOwnMessagePolicy: realmDeleteOwnMessagePolicy,
    realmWildcardMentionPolicy: realmWildcardMentionPolicy ?? RealmWildcardMentionPolicy.everyone,
    realmMandatoryTopics: realmMandatoryTopics ?? true,
    realmName: realmName ?? 'Example Zulip organization',
    realmWaitingPeriodThreshold: realmWaitingPeriodThreshold ?? 0,
    realmMessageContentDeleteLimitSeconds: realmMessageContentDeleteLimitSeconds,
    realmAllowMessageEditing: realmAllowMessageEditing ?? true,
    realmMessageContentEditLimitSeconds: realmMessageContentEditLimitSeconds,
    realmEnableReadReceipts: realmEnableReadReceipts ?? true,
    realmIconUrl: realmIconUrl ?? _realmIcon,
    realmPresenceDisabled: realmPresenceDisabled ?? false,
    realmDefaultExternalAccounts: realmDefaultExternalAccounts ?? {},
    maxFileUploadSizeMib: maxFileUploadSizeMib ?? 25,
    serverEmojiDataUrl: serverEmojiDataUrl
      ?? realmUrl.replace(path: '/static/emoji.json'),
    realmEmptyTopicDisplayName: realmEmptyTopicDisplayName ?? defaultRealmEmptyTopicDisplayName,
    realmUsers: realmUsers ?? [selfUser],
    realmNonActiveUsers: realmNonActiveUsers ?? [],
    crossRealmBots: crossRealmBots ?? [],
  );
}
const _initialSnapshot = initialSnapshot;

PerAccountStore store({
  GlobalStore? globalStore,
  User? selfUser,
  Account? account,
  InitialSnapshot? initialSnapshot,
}) {
  assert(!(account != null && selfUser != null));
  final effectiveAccount = account
    ?? (selfUser != null ? _account(user: selfUser) : selfAccount);
  return PerAccountStore.fromInitialSnapshot(
    globalStore: globalStore ?? _globalStore(accounts: [effectiveAccount]),
    accountId: effectiveAccount.id,
    initialSnapshot: initialSnapshot ?? _initialSnapshot(),
  );
}
const _store = store;

UpdateMachine updateMachine({
  GlobalStore? globalStore,
  Account? account,
  InitialSnapshot? initialSnapshot,
}) {
  initialSnapshot ??= _initialSnapshot();
  final store = _store(globalStore: globalStore,
    account: account, initialSnapshot: initialSnapshot);
  return UpdateMachine.fromInitialSnapshot(
    store: store, initialSnapshot: initialSnapshot);
}

PackageInfo packageInfo({
  String? version,
  String? buildNumber,
  String? packageName,
}) {
  return PackageInfo(
    version: version ?? '1.0.0',
    buildNumber: buildNumber ?? '1',
    packageName: packageName ?? 'com.example.app',
  );
}
