// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import '../api/core.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/events.dart';
import '../credential_fixture.dart' as credentials;
import 'message_list.dart';

class PerAccountStore extends ChangeNotifier {
  PerAccountStore._({
    required this.account,
    required this.connection,
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

    return processInitialSnapshot(account, connection, initialSnapshot);
  }

  final Account account;
  final ApiConnection connection;

  final String zulip_version;
  final Map<int, Subscription> subscriptions;

  // TODO lots more data

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

  // TODO handle server events.  Update data here and also on _messageListViews.
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
  final subscriptions = Map.fromEntries(initialSnapshot.subscriptions
      .map((subscription) => MapEntry(subscription.stream_id, subscription)));

  return PerAccountStore._(
    account: account,
    connection: connection,
    zulip_version: initialSnapshot.zulip_version,
    subscriptions: subscriptions,
  );
}
