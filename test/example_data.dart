import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';

const String realmUrl = 'https://chat.example/';

const String recentZulipVersion = '6.1';
const int recentZulipFeatureLevel = 164;

final Account selfAccount = Account(
  realmUrl: realmUrl,
  email: 'self@example',
  apiKey: 'asdfqwer',
  userId: 123,
  zulipFeatureLevel: recentZulipFeatureLevel,
  zulipVersion: recentZulipVersion,
  zulipMergeBase: recentZulipVersion,
);

final Account otherAccount = Account(
  realmUrl: realmUrl,
  email: 'other@example',
  apiKey: 'sdfgwert',
  userId: 234,
  zulipFeatureLevel: recentZulipFeatureLevel,
  zulipVersion: recentZulipVersion,
  zulipMergeBase: recentZulipVersion,
);

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
  maxFileUploadSizeMib: 25,
);
