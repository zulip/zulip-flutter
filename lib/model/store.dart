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

/// Store for the user's cross-account data.
///
/// This includes data that is independent of the account, like some settings.
/// It also includes a small amount of data for each account: enough to
/// authenticate as the active account, if there is one.
class GlobalStore extends ChangeNotifier {
  GlobalStore._({required Map<int, Account> accounts})
      : _accounts = accounts;

  // For convenience, a number we won't use as an ID in the database table.
  static const fixtureAccountId = -1;

  // We keep the API simple and synchronous for the bulk of the app's code
  // by doing this loading up front before constructing a [GlobalStore].
  static Future<GlobalStore> load() async {
    const accounts = {fixtureAccountId: _fixtureAccount};
    return GlobalStore._(accounts: accounts);
  }

  final Map<int, Account> _accounts;

  // TODO settings (those that are per-device rather than per-account)
  // TODO push token, and other data corresponding to GlobalSessionState

  // Just an Iterable, not the actual Map, to avoid clients mutating the map.
  // Mutations should go through the setters/mutators below.
  Iterable<Account> get accounts => _accounts.values;

  Account? getAccount(int id) => _accounts[id];

  // TODO add setters/mutators; will want to write to database
  // Future<void> insertAccount...
  // Future<void> updateAccount...

  // TODO add a registry of [PerAccountStore]s, like the latter's of [MessageListView]
  //   That will allow us to have many [PerAccountStoreWidget]s for a given
  //   account, e.g. at the top of each page; and to access server data from
  //   outside any [PerAccountStoreWidget], e.g. for handling a notification.
}

/// Store for the user's data for a given Zulip account.
///
/// This should always have a consistent snapshot of the state on the server,
/// as maintained by the Zulip event system.
class PerAccountStore extends ChangeNotifier {
  PerAccountStore.fromInitialSnapshot({
    required this.account,
    required this.connection,
    required InitialSnapshot initialSnapshot,
  })  : queue_id = initialSnapshot.queue_id ?? (() {
            // The queue_id is optional in the type, but should only be missing in the
            // case of unauthenticated access to a web-public realm.  We authenticated.
            throw Exception("bad initial snapshot: missing queue_id");
          })(),
        last_event_id = initialSnapshot.last_event_id,
        zulip_version = initialSnapshot.zulip_version,
        subscriptions = Map.fromEntries(initialSnapshot.subscriptions.map(
                (subscription) => MapEntry(subscription.stream_id, subscription)));

  /// Load the user's data from the server, and start an event queue going.
  ///
  /// In the future this might load an old snapshot from local storage first.
  static Future<PerAccountStore> load(Account account) async {
    final connection = LiveApiConnection(auth: account);

    final stopwatch = Stopwatch()..start();
    final initialSnapshot = await registerQueue(connection); // TODO retry
    final t = (stopwatch..stop()).elapsed;
    // TODO log the time better
    if (kDebugMode) print("initial fetch time: ${t.inMilliseconds}ms");

    final store = PerAccountStore.fromInitialSnapshot(
      account: account,
      connection: connection,
      initialSnapshot: initialSnapshot,
    );
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

@immutable
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
