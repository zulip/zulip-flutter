import 'dart:math';

import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';

import 'api/fake_api.dart';
import 'stdlib_checks.dart';

////////////////////////////////////////////////////////////////
// Realm-wide (or server-wide) metadata.
//

final Uri realmUrl = Uri.parse('https://chat.example/');
Uri get _realmUrl => realmUrl;

const String recentZulipVersion = '8.0';
const int recentZulipFeatureLevel = 185;
const int futureZulipFeatureLevel = 9999;

////////////////////////////////////////////////////////////////
// Users and accounts.
//

User user({
  int? userId,
  String? email,
  String? fullName,
  String? avatarUrl,
  Map<int, ProfileFieldUserData>? profileData,
}) {
  return User(
    userId: userId ?? 123, // TODO generate example IDs
    deliveryEmailStaleDoNotUse: 'name@example.com',
    email: email ?? 'name@example.com', // TODO generate example emails
    fullName: fullName ?? 'A user', // TODO generate example names
    dateJoined: '2023-04-28',
    isActive: true,
    isOwner: false,
    isAdmin: false,
    isGuest: false,
    isBillingAdmin: false,
    isBot: false,
    botType: null,
    botOwnerId: null,
    role: UserRole.member,
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
}) {
  return Account(
    id: id ?? 1000, // TODO generate example IDs
    realmUrl: realmUrl ?? _realmUrl,
    email: user.email,
    apiKey: apiKey ?? 'aeouasdf',
    userId: user.userId,
    zulipFeatureLevel: recentZulipFeatureLevel,
    zulipVersion: recentZulipVersion,
    zulipMergeBase: recentZulipVersion,
  );
}

final User selfUser = user(fullName: 'Self User', email: 'self@example', userId: 123);
final Account selfAccount = account(
  id: 1001,
  user: selfUser,
  apiKey: 'asdfqwer',
);

final User otherUser = user(fullName: 'Other User', email: 'other@example', userId: 234);
final Account otherAccount = account(
  id: 1002,
  user: otherUser,
  apiKey: 'sdfgwert',
);

final User thirdUser = user(fullName: 'Third User', email: 'third@example', userId: 345);

////////////////////////////////////////////////////////////////
// Streams and subscriptions.
//

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
  StreamPostPolicy? streamPostPolicy,
  int? canRemoveSubscribersGroupId,
}) {
  return ZulipStream(
    streamId: streamId ?? 123, // TODO generate example IDs
    name: name ?? 'A stream', // TODO generate example names
    description: description ?? 'A description', // TODO generate example descriptions
    renderedDescription: renderedDescription ?? '<p>A description</p>', // TODO generate random
    dateCreated: dateCreated ?? 1686774898,
    firstMessageId: firstMessageId,
    inviteOnly: inviteOnly ?? false,
    isWebPublic: isWebPublic ?? false,
    historyPublicToSubscribers: historyPublicToSubscribers ?? true,
    messageRetentionDays: messageRetentionDays,
    streamPostPolicy: streamPostPolicy ?? StreamPostPolicy.any,
    canRemoveSubscribersGroupId: canRemoveSubscribersGroupId ?? 123,
  );
}
const _stream = stream;

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

/// Construct an example stream message.
///
/// If the message ID `id` is not given, it will be generated from a random
/// but increasing sequence, which is shared with [dmMessage].
/// Use an explicit `id` only if the ID needs to correspond to some other data
/// in the test, or if the IDs need to increase in a different order from the
/// calls to [streamMessage] and [dmMessage].
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
}) {
  final effectiveStream = stream ?? _stream();
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
    'reactions': reactions == null ? [] : Reactions(reactions),
    'flags': flags ?? [],
    'id': id ?? _nextMessageId(),
    'last_edit_timestamp': lastEditTimestamp,
    'subject': topic ?? 'example topic',
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
}) {
  assert(!to.any((user) => user.userId == from.userId));
  return DmMessage.fromJson(deepToJson({
    ..._messagePropertiesBase,
    ..._messagePropertiesFromSender(from),
    ..._messagePropertiesFromContent(content, contentMarkdown),
    'display_recipient': [from, ...to]
      .map((u) => {'id': u.userId, 'email': u.email, 'full_name': u.fullName})
      .toList(growable: false),
    'reactions': [],
    'flags': flags ?? [],
    'id': id ?? _nextMessageId(),
    'last_edit_timestamp': lastEditTimestamp,
    'subject': '',
    'timestamp': timestamp ?? 1678139636,
    'type': 'private',
  }) as Map<String, dynamic>);
}

////////////////////////////////////////////////////////////////
// Aggregate data structures.
//

UnreadMessagesSnapshot unreadMsgs({
  int? count,
  List<UnreadDmSnapshot>? dms,
  List<UnreadStreamSnapshot>? streams,
  List<UnreadHuddleSnapshot>? huddles,
  List<int>? mentions,
  bool? oldUnreadsMissing,
}) {
  return UnreadMessagesSnapshot(
    count: count ?? 0,
    dms: dms ?? [],
    streams: streams ?? [],
    huddles: huddles ?? [],
    mentions: mentions ?? [],
    oldUnreadsMissing: oldUnreadsMissing ?? false,
  );
}
const _unreadMsgs = unreadMsgs;

////////////////////////////////////////////////////////////////
// Events.
//

UpdateMessageEvent updateMessageEditEvent(
  Message origMessage, {
  int? userId = -1, // null means null; default is [selfUser.userId]
  bool? renderingOnly = false,
  int? messageId,
  List<MessageFlag>? flags,
  int? editTimestamp,
  String? streamName,
  String? renderedContent,
  bool isMeMessage = false,
}) {
  messageId ??= origMessage.id;
  return UpdateMessageEvent(
    id: 0,
    userId: userId == -1 ? selfUser.userId : userId,
    renderingOnly: renderingOnly,
    messageId: messageId,
    messageIds: [messageId],
    flags: flags ?? origMessage.flags,
    editTimestamp: editTimestamp ?? 1234567890, // TODO generate timestamp
    streamName: streamName,
    streamId: origMessage is StreamMessage ? origMessage.streamId : null,
    newStreamId: null,
    propagateMode: null,
    origSubject: null,
    subject: null,
    origContent: 'some probably-mismatched old Markdown',
    origRenderedContent: origMessage.content,
    content: 'some probably-mismatched new Markdown',
    renderedContent: renderedContent ?? origMessage.content,
    isMeMessage: isMeMessage,
  );
}

UpdateMessageFlagsRemoveEvent updateMessageFlagsRemoveEvent(
  MessageFlag flag,
  Iterable<Message> messages, {
  int? selfUserId,
}) {
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
            topic: message.subject,
            userIds: null,
          ),
          DmMessage() => UpdateMessageFlagsMessageDetail(
            type: MessageType.private,
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

////////////////////////////////////////////////////////////////
// The entire per-account state.
//

InitialSnapshot initialSnapshot({
  String? queueId,
  int? lastEventId,
  int? zulipFeatureLevel,
  String? zulipVersion,
  String? zulipMergeBase,
  List<String>? alertWords,
  List<CustomProfileField>? customProfileFields,
  List<RecentDmConversation>? recentPrivateConversations,
  List<Subscription>? subscriptions,
  UnreadMessagesSnapshot? unreadMsgs,
  List<ZulipStream>? streams,
  UserSettings? userSettings,
  Map<String, RealmDefaultExternalAccount>? realmDefaultExternalAccounts,
  int? maxFileUploadSizeMib,
  List<User>? realmUsers,
  List<User>? realmNonActiveUsers,
  List<User>? crossRealmBots,
}) {
  return InitialSnapshot(
    queueId: queueId ?? '1:2345',
    lastEventId: lastEventId ?? 1,
    zulipFeatureLevel: zulipFeatureLevel ?? recentZulipFeatureLevel,
    zulipVersion: zulipVersion ?? recentZulipVersion,
    zulipMergeBase: zulipMergeBase ?? recentZulipVersion,
    alertWords: alertWords ?? ['klaxon'],
    customProfileFields: customProfileFields ?? [],
    recentPrivateConversations: recentPrivateConversations ?? [],
    subscriptions: subscriptions ?? [], // TODO add subscriptions to default
    unreadMsgs: unreadMsgs ?? _unreadMsgs(),
    streams: streams ?? [], // TODO add streams to default
    userSettings: userSettings, // TODO add userSettings to default
    realmDefaultExternalAccounts: realmDefaultExternalAccounts ?? {},
    maxFileUploadSizeMib: maxFileUploadSizeMib ?? 25,
    realmUsers: realmUsers ?? [],
    realmNonActiveUsers: realmNonActiveUsers ?? [],
    crossRealmBots: crossRealmBots ?? [],
  );
}
const _initialSnapshot = initialSnapshot;

PerAccountStore store({Account? account, InitialSnapshot? initialSnapshot}) {
  return PerAccountStore.fromInitialSnapshot(
    account: account ?? selfAccount,
    connection: FakeApiConnection.fromAccount(account ?? selfAccount),
    initialSnapshot: initialSnapshot ?? _initialSnapshot(),
  );
}

LivePerAccountStore liveStore({Account? account, InitialSnapshot? initialSnapshot}) {
  return LivePerAccountStore.fromInitialSnapshot(
    account: account ?? selfAccount,
    connection: FakeApiConnection.fromAccount(account ?? selfAccount),
    initialSnapshot: initialSnapshot ?? _initialSnapshot(),
  );
}
