import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import 'narrow.dart';
import 'store.dart';

/// A per-account manager for the view-models of autocomplete interactions.
///
/// There should be exactly one of these per PerAccountStore.
///
/// Since this manages a cache of user data, the handleRealmUser…Event functions
/// must be called as appropriate.
///
/// On reassemble, call [reassemble].
class AutocompleteViewManager {
  final Set<MentionAutocompleteView> _mentionAutocompleteViews = {};

  AutocompleteDataCache autocompleteDataCache = AutocompleteDataCache();

  void registerMentionAutocomplete(MentionAutocompleteView view) {
    final added = _mentionAutocompleteViews.add(view);
    assert(added);
  }

  void unregisterMentionAutocomplete(MentionAutocompleteView view) {
    final removed = _mentionAutocompleteViews.remove(view);
    assert(removed);
  }

  void handleRealmUserAddEvent(RealmUserAddEvent event) {
    for (final view in _mentionAutocompleteViews) {
      view.refreshStaleUserResults();
    }
  }

  void handleRealmUserRemoveEvent(RealmUserRemoveEvent event) {
    for (final view in _mentionAutocompleteViews) {
      view.refreshStaleUserResults();
    }
    autocompleteDataCache.invalidateUser(event.userId);
  }

  void handleRealmUserUpdateEvent(RealmUserUpdateEvent event) {
    for (final view in _mentionAutocompleteViews) {
      view.refreshStaleUserResults();
    }
    autocompleteDataCache.invalidateUser(event.userId);
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// Calls [MentionAutocompleteView.reassemble] for all that are registered.
  ///
  void reassemble() {
    for (final view in _mentionAutocompleteViews) {
      view.reassemble();
    }
  }
}

/// A view-model for a mention-autocomplete interaction.
///
/// The owner of one of these objects must call [dispose] when the object
/// will no longer be used, in order to free resources on the [PerAccountStore].
///
/// Lifecycle:
///  * Create with [init].
///  * Add listeners with [addListener].
///  * Use the [query] setter to start a search for a query.
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
class MentionAutocompleteView extends ChangeNotifier {
  MentionAutocompleteView._({required this.store, required this.narrow});

  factory MentionAutocompleteView.init({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    final view = MentionAutocompleteView._(store: store, narrow: narrow);
    store.autocompleteViewManager.registerMentionAutocomplete(view);
    return view;
  }

  @override
  void dispose() {
    store.autocompleteViewManager.unregisterMentionAutocomplete(this);
    // We cancel in-progress computations by checking [hasListeners] between tasks.
    // After [super.dispose] is called, [hasListeners] returns false.
    // TODO test that logic (may involve detecting an unhandled Future rejection; how?)
    super.dispose();
  }

  final PerAccountStore store;
  final Narrow narrow;

  MentionAutocompleteQuery? _currentQuery;
  set query(MentionAutocompleteQuery query) {
    _currentQuery = query;
    _startSearch(query);
  }

  /// Recompute user results for the current query, if any.
  ///
  /// Called in particular when we get a [RealmUserEvent].
  void refreshStaleUserResults() {
    if (_currentQuery != null) {
      _startSearch(_currentQuery!);
    }
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo the search from scratch for the current query, if any.
  void reassemble() {
    if (_currentQuery != null) {
      _startSearch(_currentQuery!);
    }
  }

  Iterable<MentionAutocompleteResult> get results => _results;
  List<MentionAutocompleteResult> _results = [];

  _startSearch(MentionAutocompleteQuery query) async {
    List<MentionAutocompleteResult>? newResults;

    while (true) {
      try {
        newResults = await _computeResults(query);
        break;
      } on ConcurrentModificationError {
        // Retry
        // TODO backoff?
      }
    }

    if (newResults == null) {
      // Query was old; new search is in progress. Or, no listeners to notify.
      return;
    }

    _results = newResults;
    notifyListeners();
  }

  Future<List<MentionAutocompleteResult>?> _computeResults(MentionAutocompleteQuery query) async {
    final List<MentionAutocompleteResult> results = [];
    final Iterable<User> users = store.users.values;

    final iterator = users.iterator;
    bool isDone = false;
    while (!isDone) {
      // CPU perf: End this task; enqueue a new one for resuming this work
      await Future(() {});

      if (query != _currentQuery || !hasListeners) { // false if [dispose] has been called.
        return null;
      }

      for (int i = 0; i < 1000; i++) {
        if (!iterator.moveNext()) { // Can throw ConcurrentModificationError
          isDone = true;
          break;
        }

        final User user = iterator.current;
        if (query.testUser(user, store.autocompleteViewManager.autocompleteDataCache)) {
          results.add(UserMentionAutocompleteResult(userId: user.userId));
        }
      }
    }
    return results;
  }
}

class MentionAutocompleteQuery {
  MentionAutocompleteQuery(this.raw)
    : _lowercaseWords = raw.toLowerCase().split(' ');

  final String raw;

  final List<String> _lowercaseWords;

  bool testUser(User user, AutocompleteDataCache cache) {
    // TODO test email too, not just name
    // TODO test with diacritics stripped, where appropriate

    final List<String> nameWords = cache.nameWordsForUser(user);

    int nameWordsIndex = 0;
    int queryWordsIndex = 0;
    while (true) {
      if (queryWordsIndex == _lowercaseWords.length) {
        return true;
      }
      if (nameWordsIndex == nameWords.length) {
        return false;
      }

      if (nameWords[nameWordsIndex].startsWith(_lowercaseWords[queryWordsIndex])) {
        queryWordsIndex++;
      }
      nameWordsIndex++;
    }
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'MentionAutocompleteQuery')}(raw: $raw})';
  }

  @override
  bool operator ==(Object other) {
    return other is MentionAutocompleteQuery && other.raw == raw;
  }

  @override
  int get hashCode => Object.hash('MentionAutocompleteQuery', raw);
}

class AutocompleteDataCache {
  final Map<int, List<String>> _nameWordsByUser = {};

  List<String> nameWordsForUser(User user) {
    return _nameWordsByUser[user.userId] ??= user.fullName.toLowerCase().split(' ');
  }

  void invalidateUser(int userId) {
    _nameWordsByUser.remove(userId);
  }
}

abstract class MentionAutocompleteResult {}

class UserMentionAutocompleteResult extends MentionAutocompleteResult {
  UserMentionAutocompleteResult({required this.userId});

  final int userId;
}

enum WildcardMentionType {
  all,
  everyone,
  stream,
}

class WildcardMentionAutocompleteResult extends MentionAutocompleteResult {
  WildcardMentionAutocompleteResult({required this.type});

  final WildcardMentionType type;
}


class UserGroupMentionAutocompleteResult extends MentionAutocompleteResult {
  UserGroupMentionAutocompleteResult({required this.userGroupId});

  final int userGroupId;
}
