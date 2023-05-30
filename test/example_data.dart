import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';

import 'api/fake_api.dart';

final Uri realmUrl = Uri.parse('https://chat.example/');

const String recentZulipVersion = '6.1';
const int recentZulipFeatureLevel = 164;

User user({int? userId, String? email, String? fullName}) {
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
    avatarUrl: null,
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

final _messagePropertiesBase = {
  'is_me_message': false,
  'last_edit_timestamp': null,
  'recipient_id': 32, // obsolescent in API, and ignored
};

// When we have a User object, this can take that as an argument.
Map<String, dynamic> _messagePropertiesFromSender() {
  return {
    'client': 'ExampleClient',
    'sender_email': 'a-person@example',
    'sender_full_name': 'A Person',
    'sender_id': 12345, // TODO generate example IDs
    'sender_realm_str': 'zulip',
  };
}

// When we have a Stream object, this can take that as an argument.
// Also it can default explicitly to an example stream.
StreamMessage streamMessage(
    {String? streamName, int? streamId}) {
  // The use of JSON here is convenient in order to delegate parts of the data
  // to helper functions.  The main downside is that it loses static typing
  // of the properties as we're constructing the data.  That's probably OK
  // because (a) this is only for tests; (b) the types do get checked
  // dynamically in the constructor, so any ill-typing won't propagate further.
  return StreamMessage.fromJson({
    ..._messagePropertiesBase,
    ..._messagePropertiesFromSender(),
    'display_recipient': streamName ?? 'a stream',
    'stream_id': streamId ?? 123, // TODO generate example IDs

    'content': '<p>This is an example stream message.</p>',
    'content_type': 'text/html',
    'flags': [],
    'id': 1234567, // TODO generate example IDs
    'subject': 'example topic',
    'timestamp': 1678139636,
    'type': 'stream',
  });
}

// TODO example data for many more types

final InitialSnapshot initialSnapshot = InitialSnapshot(
  queueId: '1:2345',
  lastEventId: 1,
  zulipFeatureLevel: recentZulipFeatureLevel,
  zulipVersion: recentZulipVersion,
  zulipMergeBase: recentZulipVersion,
  alertWords: ['klaxon'],
  customProfileFields: [],
  subscriptions: [], // TODO add subscriptions to example initial snapshot
  streams: [], // TODO add streams to example initial snapshot
  maxFileUploadSizeMib: 25,
  realmUsers: [],
  realmNonActiveUsers: [],
  crossRealmBots: [],
);

PerAccountStore store() {
  return PerAccountStore.fromInitialSnapshot(
    account: selfAccount,
    connection: FakeApiConnection.fromAccount(selfAccount),
    initialSnapshot: initialSnapshot,
  );
}
