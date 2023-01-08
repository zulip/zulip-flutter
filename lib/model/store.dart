// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/core.dart';
import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/events.dart';
import '../api/route/messages.dart';
import '../credential_fixture.dart' as credentials;
import 'message_list.dart';

class PerAccountStore extends ChangeNotifier {
  PerAccountStore._({
    required this.account,
    required this.connection,
    required this.queue_id,
    required this.last_event_id,
    required this.zulip_version,
    required this.subscriptions,
  });

  // Load the user's data from storage.  (Once we have such a thing.)
  static Future<PerAccountStore> load() async {
    const account = _fixtureAccount;
    final connection = ApiConnection(auth: account);

    final stopwatch = Stopwatch()..start();
    final initialSnapshot = await registerQueue(connection); // TODO retry
    final t = (stopwatch..stop()).elapsed;
    // TODO log the time better
    if (kDebugMode) print("initial fetch time: ${t.inMilliseconds}ms");

    final store = processInitialSnapshot(account, connection, initialSnapshot);
    store.poll();
    return store;
  }

  final Account account;
  final ApiConnection connection;

  final String queue_id;
  int last_event_id;

  final String zulip_version;
  final Map<int, Subscription> subscriptions;

  // TODO lots more data.  When adding, be sure to update handleEvent too.

  final Set<MessageListView> _messageListViews = {};

  void registerMessageList(MessageListView view) {
    final added = _messageListViews.add(view);
    assert(added);
  }

  void unregisterMessageList(MessageListView view) {
    final removed = _messageListViews.remove(view);
    assert(removed);
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo from scratch any computations we can, such as parsing
  /// message contents.  It won't repeat network requests.
  void reassemble() {
    for (final view in _messageListViews) {
      view.reassemble();
    }
  }

  void poll() async {
    while (true) {
      final result = await getEvents(connection,
          queue_id: queue_id, last_event_id: last_event_id);
      // TODO handle errors on get-events; retry with backoff
      // TODO abort long-poll on [dispose]
      final events = result.events;
      for (final event in events) {
        handleEvent(event);
      }
      if (events.isNotEmpty) {
        last_event_id = events.last.id;
      }
    }
  }

  void handleEvent(Event event) {
    if (event is HeartbeatEvent) {
      debugPrint("server event: heartbeat");
    } else if (event is AlertWordsEvent) {
      debugPrint("server event: alert_words");
      // We don't yet store this data, so there's nothing to update.
    } else if (event is MessageEvent) {
      debugPrint("server event: message ${jsonEncode(event.message.toJson())}");
      for (final view in _messageListViews) {
        view.maybeAddMessage(event.message);
      }
    } else if (event is UnexpectedEvent) {
      debugPrint("server event: ${jsonEncode(event.toJson())}"); // TODO log better
    } else {
      // TODO(dart-3): Use a sealed class / pattern-matching to exclude this.
      throw Exception("Event object of impossible type: ${event.toString()}");
    }
  }

  Future<void> sendStreamMessage({required String topic, required String content}) {
    // TODO implement outbox; see design at
    //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/.23M3881.20Sending.20outbox.20messages.20is.20fraught.20with.20issues/near/1405739
    return sendMessage(connection, topic: topic, content: content);
  }
}

/// A scaffolding hack for while prototyping.
///
/// See "Server credentials" in the project README for how to fill in the
/// `credential_fixture.dart` file this requires.
const Account _fixtureAccount = Account(
  realmUrl: credentials.realm_url,
  email: credentials.email,
  apiKey: credentials.api_key,
);

class Account implements Auth {
  const Account(
      {required this.realmUrl, required this.email, required this.apiKey});

  @override
  final String realmUrl;
  @override
  final String email;
  @override
  final String apiKey;
}

PerAccountStore processInitialSnapshot(Account account,
    ApiConnection connection, InitialSnapshot initialSnapshot) {
  final queue_id = initialSnapshot.queue_id;
  if (queue_id == null) {
    // The queue_id is optional in the type, but should only be missing in the
    // case of unauthenticated access to a web-public realm.  We authenticated.
    throw Exception("bad initial snapshot: missing queue_id");
  }

  final subscriptions = Map.fromEntries(initialSnapshot.subscriptions
      .map((subscription) => MapEntry(subscription.stream_id, subscription)));

  return PerAccountStore._(
    account: account,
    connection: connection,
    queue_id: queue_id,
    last_event_id: initialSnapshot.last_event_id,
    zulip_version: initialSnapshot.zulip_version,
    subscriptions: subscriptions,
  );
}
