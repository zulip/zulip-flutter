import 'dart:convert';
import 'dart:math';

import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/model/submessage.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/api/route/realm.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import 'model/test_store.dart';
import 'stdlib_checks.dart';

void _checkPositive(int? value, String description) {
  assert(value == null || value > 0, '$description should be positive');
}

Object nullCheckError() {
  try { null!; } catch (e) { return e; } // ignore: null_check_always_fails
}

////////////////////////////////////////////////////////////////
// Realm-wide (or server-wide) metadata.
//

final Uri realmUrl = Uri.parse('https://chat.example/');
Uri get _realmUrl => realmUrl;

const String recentZulipVersion = '9.0';
const int recentZulipFeatureLevel = 278;
const int futureZulipFeatureLevel = 9999;

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
  String? realmIcon,
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
    realmIcon: realmIcon ?? '$realmUrl/icon.png',
    realmDescription: realmDescription ?? 'An example Zulip organization',
    realmWebPublicAccessEnabled: realmWebPublicAccessEnabled ?? false,
  );
}

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

////////////////////////////////////////////////////////////////
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
/// If `email` is not given, it defaults to `deliveryEmail` if given,
/// or else to a value resembling the Zulip server's generated fake emails.
User user({
  int? userId,
  String? deliveryEmail,
  String? email,
  String? fullName,
  String? dateJoined,
  bool? isActive,
  bool? isBot,
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
    isBillingAdmin: false,
    isBot: isBot ?? false,
    botType: null,
    botOwnerId: null,
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
    email: email,
    apiKey: apiKey ?? 'aeouasdf',
    userId: user.userId,
    zulipFeatureLevel: zulipFeatureLevel ?? recentZulipFeatureLevel,
    zulipVersion: zulipVersion ?? recentZulipVersion,
    zulipMergeBase: zulipMergeBase ?? recentZulipVersion,
    ackedPushToken: ackedPushToken,
  );
}

final User selfUser = user(fullName: 'Self User');
final Account selfAccount = account(
  id: 1001,
  user: selfUser,
  apiKey: 'dQcEJWTq3LczosDkJnRTwf31zniGvMrO', // A Zulip API key is 32 digits of base64.
);

final User otherUser = user(fullName: 'Other User');
final Account otherAccount = account(
  id: 1002,
  user: otherUser,
  apiKey: '6dxT4b73BYpCTU+i4BB9LAKC5h/CufqY', // A Zulip API key is 32 digits of base64.
);

final User thirdUser = user(fullName: 'Third User');

final User fourthUser  = user(fullName: 'Fourth User');

////////////////////////////////////////////////////////////////
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
  String? renderedDescription,
  int? dateCreated,
  int? firstMessageId,
  bool? inviteOnly,
  bool? isWebPublic,
  bool? historyPublicToSubscribers,
  int? messageRetentionDays,
  ChannelPostPolicy? channelPostPolicy,
  int? streamWeeklyTraffic,
}) {
  _checkPositive(streamId, 'stream ID');
  _checkPositive(firstMessageId, 'message ID');
  var effectiveStreamId = streamId ?? _nextStreamId();
  var effectiveName = name ?? 'stream $effectiveStreamId';
  var effectiveDescription = description ?? 'Description of $effectiveName';
  return ZulipStream(
    streamId: effectiveStreamId,
    name: effectiveName,
    description: effectiveDescription,
    renderedDescription: renderedDescription ?? '<p>$effectiveDescription</p>',
    dateCreated: dateCreated ?? 1686774898,
    firstMessageId: firstMessageId,
    inviteOnly: inviteOnly ?? false,
    isWebPublic: isWebPublic ?? false,
    historyPublicToSubscribers: historyPublicToSubscribers ?? true,
    messageRetentionDays: messageRetentionDays,
    channelPostPolicy: channelPostPolicy ?? ChannelPostPolicy.any,
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
    description: stream.description,
    renderedDescription: stream.renderedDescription,
    dateCreated: stream.dateCreated,
    firstMessageId: stream.firstMessageId,
    inviteOnly: stream.inviteOnly,
    isWebPublic: stream.isWebPublic,
    historyPublicToSubscribers: stream.historyPublicToSubscribers,
    messageRetentionDays: stream.messageRetentionDays,
    channelPostPolicy: stream.channelPostPolicy,
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

/// The [TopicName] constructor, but shorter.
///
/// Useful in test code that mentions a lot of topics in a compact format.
TopicName t(String apiName) => TopicName(apiName);

TopicNarrow topicNarrow(int channelId, String topicName) {
  return TopicNarrow(channelId, TopicName(topicName));
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

////////////////////////////////////////////////////////////////
// Messages, and pieces of messages.
//

Reaction unicodeEmojiReaction = Reaction(
  emojiName: 'thumbs_up',
  emojiCode: '1f44d',
  reactionType: ReactionType.unicodeEmoji,
  userId: selfUser.userId,
);

Reaction realmEmojiReaction = Reaction(
  emojiName: 'twocents',
  emojiCode: '181',
  reactionType: ReactionType.realmEmoji,
  userId: selfUser.userId,
);

Reaction zulipExtraEmojiReaction = Reaction(
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

/// A GetMessagesResult the server might return on an `anchor=newest` request.
GetMessagesResult newestGetMessagesResult({
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    // These anchor, foundAnchor, and foundNewest values are what the server
    // appears to always return when the request had `anchor=newest`.
    anchor: 10000000000000000, // that's 16 zeros
    foundAnchor: false,
    foundNewest: true,

    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
}

/// A GetMessagesResult the server might return when we request older messages.
GetMessagesResult olderGetMessagesResult({
  required int anchor,
  bool foundAnchor = false, // the value if the server understood includeAnchor false
  required bool foundOldest,
  bool historyLimited = false,
  required List<Message> messages,
}) {
  return GetMessagesResult(
    anchor: anchor,
    foundAnchor: foundAnchor,
    foundNewest: false, // empirically always this, even when anchor happens to be latest
    foundOldest: foundOldest,
    historyLimited: historyLimited,
    messages: messages,
  );
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

////////////////////////////////////////////////////////////////
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

////////////////////////////////////////////////////////////////
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
  bool? renderingOnly = false,
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
    origStreamId: origMessage is StreamMessage ? origMessage.streamId : null,
    newStreamId: null,
    propagateMode: null,
    origTopic: null,
    newTopic: null,
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
  assert(newTopic != origTopic
         || (newStreamId != null && newStreamId != origStreamId));
  assert(messageIds.isNotEmpty);
  return UpdateMessageEvent(
    id: 0,
    userId: selfUser.userId,
    renderingOnly: false,
    messageId: messageIds.first,
    messageIds: messageIds,
    flags: flags,
    editTimestamp: 1234567890, // TODO generate timestamp
    origStreamId: origStreamId,
    newStreamId: newStreamId,
    propagateMode: propagateMode,
    origTopic: origTopic,
    newTopic: newTopic,
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

////////////////////////////////////////////////////////////////
// The entire per-account or global state.
//

TestGlobalStore globalStore({List<Account> accounts = const []}) {
  return TestGlobalStore(accounts: accounts);
}

InitialSnapshot initialSnapshot({
  String? queueId,
  int? lastEventId,
  int? zulipFeatureLevel,
  String? zulipVersion,
  String? zulipMergeBase,
  List<String>? alertWords,
  List<CustomProfileField>? customProfileFields,
  EmailAddressVisibility? emailAddressVisibility,
  int? serverTypingStartedExpiryPeriodMilliseconds,
  int? serverTypingStoppedWaitPeriodMilliseconds,
  int? serverTypingStartedWaitPeriodMilliseconds,
  Map<String, RealmEmojiItem>? realmEmoji,
  List<RecentDmConversation>? recentPrivateConversations,
  List<Subscription>? subscriptions,
  UnreadMessagesSnapshot? unreadMsgs,
  List<ZulipStream>? streams,
  UserSettings? userSettings,
  List<UserTopicItem>? userTopics,
  int? realmWaitingPeriodThreshold,
  Map<String, RealmDefaultExternalAccount>? realmDefaultExternalAccounts,
  int? maxFileUploadSizeMib,
  Uri? serverEmojiDataUrl,
  List<User>? realmUsers,
  List<User>? realmNonActiveUsers,
  List<User>? crossRealmBots,
}) {
  return InitialSnapshot(
    queueId: queueId ?? '1:2345',
    lastEventId: lastEventId ?? -1,
    zulipFeatureLevel: zulipFeatureLevel ?? recentZulipFeatureLevel,
    zulipVersion: zulipVersion ?? recentZulipVersion,
    zulipMergeBase: zulipMergeBase ?? recentZulipVersion,
    alertWords: alertWords ?? ['klaxon'],
    customProfileFields: customProfileFields ?? [],
    emailAddressVisibility: emailAddressVisibility ?? EmailAddressVisibility.everyone,
    serverTypingStartedExpiryPeriodMilliseconds:
      serverTypingStartedExpiryPeriodMilliseconds ?? 15000,
    serverTypingStoppedWaitPeriodMilliseconds:
      serverTypingStoppedWaitPeriodMilliseconds ?? 5000,
    serverTypingStartedWaitPeriodMilliseconds:
      serverTypingStartedWaitPeriodMilliseconds ?? 10000,
    realmEmoji: realmEmoji ?? {},
    recentPrivateConversations: recentPrivateConversations ?? [],
    subscriptions: subscriptions ?? [], // TODO add subscriptions to default
    unreadMsgs: unreadMsgs ?? _unreadMsgs(),
    streams: streams ?? [], // TODO add streams to default
    userSettings: userSettings ?? UserSettings(
      twentyFourHourTime: false,
      displayEmojiReactionUsers: true,
      emojiset: Emojiset.google,
    ),
    userTopics: userTopics,
    realmWaitingPeriodThreshold: realmWaitingPeriodThreshold ?? 0,
    realmDefaultExternalAccounts: realmDefaultExternalAccounts ?? {},
    maxFileUploadSizeMib: maxFileUploadSizeMib ?? 25,
    serverEmojiDataUrl: serverEmojiDataUrl
      ?? realmUrl.replace(path: '/static/emoji.json'),
    realmUsers: realmUsers ?? [],
    realmNonActiveUsers: realmNonActiveUsers ?? [],
    crossRealmBots: crossRealmBots ?? [],
  );
}
const _initialSnapshot = initialSnapshot;

PerAccountStore store({Account? account, InitialSnapshot? initialSnapshot}) {
  final effectiveAccount = account ?? selfAccount;
  return PerAccountStore.fromInitialSnapshot(
    globalStore: globalStore(accounts: [effectiveAccount]),
    accountId: effectiveAccount.id,
    initialSnapshot: initialSnapshot ?? _initialSnapshot(),
  );
}
const _store = store;

UpdateMachine updateMachine({Account? account, InitialSnapshot? initialSnapshot}) {
  initialSnapshot ??= _initialSnapshot();
  final store = _store(account: account, initialSnapshot: initialSnapshot);
  return UpdateMachine.fromInitialSnapshot(
    store: store, initialSnapshot: initialSnapshot);
}
