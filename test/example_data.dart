import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';

import 'api/fake_api.dart';

final Uri realmUrl = Uri.parse('https://chat.example/');

const String recentZulipVersion = '8.0';
const int recentZulipFeatureLevel = 185;
const int futureZulipFeatureLevel = 9999;

User user({
  int? userId,
  String? email,
  String? fullName,
  String? avatarUrl,
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
    role: 400,
    timezone: 'UTC',
    avatarUrl: avatarUrl,
    avatarVersion: 0,
    profileData: null,
  );
}

final User selfUser = user(fullName: 'Self User', email: 'self@example', userId: 123);
final Account selfAccount = Account(
  id: 1001,
  realmUrl: realmUrl,
  email: selfUser.email,
  apiKey: 'asdfqwer',
  userId: selfUser.userId,
  zulipFeatureLevel: recentZulipFeatureLevel,
  zulipVersion: recentZulipVersion,
  zulipMergeBase: recentZulipVersion,
);

final User otherUser = user(fullName: 'Other User', email: 'other@example', userId: 234);
final Account otherAccount = Account(
  id: 1002,
  realmUrl: realmUrl,
  email: otherUser.email,
  apiKey: 'sdfgwert',
  userId: otherUser.userId,
  zulipFeatureLevel: recentZulipFeatureLevel,
  zulipVersion: recentZulipVersion,
  zulipMergeBase: recentZulipVersion,
);

final User thirdUser = user(fullName: 'Third User', email: 'third@example', userId: 345);

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
  int? streamPostPolicy,
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
    streamPostPolicy: streamPostPolicy ?? 1,
    canRemoveSubscribersGroupId: canRemoveSubscribersGroupId ?? 123,
  );
}

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

const _stream = stream;

StreamMessage streamMessage({
  int? id,
  User? sender,
  ZulipStream? stream,
  String? topic,
  String? content,
  String? contentMarkdown,
  int? lastEditTimestamp,
  List<String>? flags,
}) {
  final effectiveStream = stream ?? _stream();
  // The use of JSON here is convenient in order to delegate parts of the data
  // to helper functions.  The main downside is that it loses static typing
  // of the properties as we're constructing the data.  That's probably OK
  // because (a) this is only for tests; (b) the types do get checked
  // dynamically in the constructor, so any ill-typing won't propagate further.
  return StreamMessage.fromJson({
    ..._messagePropertiesBase,
    ..._messagePropertiesFromSender(sender),
    ..._messagePropertiesFromContent(content, contentMarkdown),
    'display_recipient': effectiveStream.name,
    'stream_id': effectiveStream.streamId,
    'reactions': [],
    'flags': flags ?? [],
    'id': id ?? 1234567, // TODO generate example IDs
    'last_edit_timestamp': lastEditTimestamp,
    'subject': topic ?? 'example topic',
    'timestamp': 1678139636,
    'type': 'stream',
  });
}

/// Construct an example direct message.
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
  List<String>? flags,
}) {
  assert(!to.any((user) => user.userId == from.userId));
  return DmMessage.fromJson({
    ..._messagePropertiesBase,
    ..._messagePropertiesFromSender(from),
    ..._messagePropertiesFromContent(content, contentMarkdown),
    'display_recipient': [from, ...to]
      .map((u) => {'id': u.userId, 'email': u.email, 'full_name': u.fullName})
      .toList(growable: false),
    'reactions': [],
    'flags': flags ?? [],
    'id': id ?? 1234567, // TODO generate example IDs
    'last_edit_timestamp': lastEditTimestamp,
    'subject': '',
    'timestamp': 1678139636,
    'type': 'private',
  });
}

// TODO example data for many more types

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
  List<ZulipStream>? streams,
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
    streams: streams ?? [], // TODO add streams to default
    maxFileUploadSizeMib: maxFileUploadSizeMib ?? 25,
    realmUsers: realmUsers ?? [],
    realmNonActiveUsers: realmNonActiveUsers ?? [],
    crossRealmBots: crossRealmBots ?? [],
  );
}

PerAccountStore store() {
  return PerAccountStore.fromInitialSnapshot(
    account: selfAccount,
    connection: FakeApiConnection.fromAccount(selfAccount),
    initialSnapshot: initialSnapshot(),
  );
}
