import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../widgets/compose_box.dart';
import 'narrow.dart';
import 'store.dart';

extension Autocomplete on ComposeContentController {
  AutocompleteIntent? autocompleteIntent() {
    if (!selection.isValid || !selection.isNormalized) {
      // We don't require [isCollapsed] to be true because we've seen that
      // autocorrect and even backspace involve programmatically expanding the
      // selection to the left. Once we know where the syntax starts, we can at
      // least require that the selection doesn't extend leftward past that;
      // see below.
      return null;
    }
    final textUntilCursor = text.substring(0, selection.end);
    for (
      int position = selection.end - 1;
      position >= 0 && (selection.end - position <= 30);
      position--
    ) {
      if (textUntilCursor[position] != '@') {
        continue;
      }
      final match = mentionAutocompleteMarkerRegex.matchAsPrefix(textUntilCursor, position);
      if (match == null) {
        continue;
      }
      if (selection.start < position) {
        // See comment about [TextSelection.isCollapsed] above.
        return null;
      }
      return AutocompleteIntent(
        syntaxStart: position,
        query: MentionAutocompleteQuery(match[2]!, silent: match[1]! == '_'),
        textEditingValue: value);
    }
    return null;
  }
}

final RegExp mentionAutocompleteMarkerRegex = (() {
  // What's likely to come before an @-mention: the start of the string,
  // whitespace, or punctuation. Letters are unlikely; in that case an email
  // might be intended. (By punctuation, we mean *some* punctuation, like "(".
  // We could refine this.)
  const beforeAtSign = r'(?<=^|\s|\p{Punctuation})';

  // Characters that would defeat searches in full_name and emails, since
  // they're prohibited in both forms. These are all the characters prohibited
  // in full_name except "@", which appears in emails. (For the form of
  // full_name, find uses of UserProfile.NAME_INVALID_CHARS in zulip/zulip.)
  const fullNameAndEmailCharExclusions = r'\*`\\>"\p{Other}';

  return RegExp(
    beforeAtSign
    + r'@(_?)' // capture, so we can distinguish silent mentions
    + r'(|'
      // Reject on whitespace right after "@" or "@_". Emails can't start with
      // it, and full_name can't either (it's run through Python's `.strip()`).
      + r'[^\s' + fullNameAndEmailCharExclusions + r']'
      + r'[^'   + fullNameAndEmailCharExclusions + r']*'
    + r')$',
    unicode: true);
})();

/// The content controller's recognition that the user might want autocomplete UI.
class AutocompleteIntent {
  AutocompleteIntent({
    required this.syntaxStart,
    required this.query,
    required this.textEditingValue,
  });

  /// At what index the intent's syntax starts. E.g., 3, in "Hi @chris".
  ///
  /// May be used with [textEditingValue] to make a new [TextEditingValue] with
  /// the autocomplete interaction's result: e.g., one that replaces "Hi @chris"
  /// with "Hi @**Chris Bobbe** ". (Assume [textEditingValue.selection.end] is
  /// the end of the syntax.)
  ///
  /// Using this to index into something other than [textEditingValue] will give
  /// undefined behavior and might cause a RangeError; it should be avoided.
  // If a subclassed [TextEditingValue] could itself be the source of
  // [syntaxStart], then the safe behavior would be accomplished more
  // naturally, I think. But [TextEditingController] doesn't support subclasses
  // that use a custom/subclassed [TextEditingValue], so that's not convenient.
  final int syntaxStart;

  final MentionAutocompleteQuery query; // TODO other autocomplete query types

  /// The [TextEditingValue] whose text [syntaxStart] refers to.
  final TextEditingValue textEditingValue;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'AutocompleteIntent')}(syntaxStart: $syntaxStart, query: $query, textEditingValue: $textEditingValue})';
  }
}

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

  MentionAutocompleteQuery? get query => _query;
  MentionAutocompleteQuery? _query;
  set query(MentionAutocompleteQuery? query) {
    _query = query;
    if (query != null) {
      _startSearch(query);
    }
  }

  /// Recompute user results for the current query, if any.
  ///
  /// Called in particular when we get a [RealmUserEvent].
  void refreshStaleUserResults() {
    if (_query != null) {
      _startSearch(_query!);
    }
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo the search from scratch for the current query, if any.
  void reassemble() {
    if (_query != null) {
      _startSearch(_query!);
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

      if (query != _query || !hasListeners) { // false if [dispose] has been called.
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
    return results; // TODO(#228) sort for most relevant first
  }
}

class MentionAutocompleteQuery {
  MentionAutocompleteQuery(this.raw, {this.silent = false})
    : _lowercaseWords = raw.toLowerCase().split(' ');

  final String raw;

  /// Whether the user wants a silent mention (@_query, vs. @query).
  final bool silent;

  final List<String> _lowercaseWords;

  bool testUser(User user, AutocompleteDataCache cache) {
    // TODO(#236) test email too, not just name
    // TODO(#237) test with diacritics stripped, where appropriate

    if (!user.isActive) return false;

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
    return '${objectRuntimeType(this, 'MentionAutocompleteQuery')}(raw: $raw, silent: $silent})';
  }

  @override
  bool operator ==(Object other) {
    return other is MentionAutocompleteQuery && other.raw == raw && other.silent == silent;
  }

  @override
  int get hashCode => Object.hash('MentionAutocompleteQuery', raw, silent);
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

sealed class MentionAutocompleteResult {}

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
