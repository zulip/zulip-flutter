import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../widgets/compose_box.dart';
import 'narrow.dart';
import 'store.dart';

extension ComposeContentAutocomplete on ComposeContentController {
  AutocompleteIntent<MentionAutocompleteQuery>? autocompleteIntent() {
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
class AutocompleteIntent<Q extends AutocompleteQuery> {
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

  final Q query;

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

  void handleRealmUserRemoveEvent(RealmUserRemoveEvent event) {
    autocompleteDataCache.invalidateUser(event.userId);
  }

  void handleRealmUserUpdateEvent(RealmUserUpdateEvent event) {
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

  // No `dispose` method, because there's nothing for it to do.
  // The [MentionAutocompleteView]s are owned by (i.e., they get [dispose]d by)
  // the UI code that manages the autocomplete interaction, including in the
  // case where the [PerAccountStore] is replaced.  Discussion:
  //   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/.60MentionAutocompleteView.2Edispose.60/near/1791292
  // void dispose() { … }
}

/// A view-model for an autocomplete interaction.
///
/// The owner of one of these objects must call [dispose] when the object
/// will no longer be used, in order to free resources on the [PerAccountStore].
///
/// Lifecycle:
///  * Create an instance of a concrete subtype.
///  * Add listeners with [addListener].
///  * Use the [query] setter to start a search for a query.
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
abstract class AutocompleteView<Q extends AutocompleteQuery, R extends AutocompleteResult> extends ChangeNotifier {

  /// This could be used to transform results after they've been
  /// computed for sorting, filtering etc.
  final List<R> Function(List<R> results)? resultsFilter;
  final PerAccountStore store;

  AutocompleteView({this.resultsFilter, required this.store});

  Iterable<Object> getDataForQuery(Q query);

  R? testItem(Q query, Object item);

  Q? get query => _query;
  Q? _query;
  set query(Q? query) {
    _query = query;
    if (query != null) {
      _startSearch(query);
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

  Iterable<R> get results => _results;
  List<R> _results = [];

  Future<void> _startSearch(Q query) async {
    final newResults = await _computeResults(query);
    if (newResults == null) {
      // Query was old; new search is in progress. Or, no listeners to notify.
      return;
    }

    _results = newResults;
    notifyListeners();
  }

  Future<List<R>?> _computeResults(Q query) async {
    final List<R> results = [];
    final Iterable<Object> data = getDataForQuery(query);

    final iterator = data.iterator;
    bool isDone = false;
    while (!isDone) {
      // CPU perf: End this task; enqueue a new one for resuming this work
      await Future(() {});

      if (query != _query || !hasListeners) { // false if [dispose] has been called.
        return null;
      }

      for (int i = 0; i < 1000; i++) {
        if (!iterator.moveNext()) {
          isDone = true;
          break;
        }
        final Object item = iterator.current;
        final result = testItem(query, item);
        if (result != null) results.add(result);
      }
    }
    return resultsFilter?.call(results) ?? results;
  }
}

class MentionAutocompleteView extends AutocompleteView<MentionAutocompleteQuery, MentionAutocompleteResult> {
  final Narrow narrow;
  final List<User> sortedUsers;

  MentionAutocompleteView.init({
    required super.store,
    required this.narrow,
  }) : sortedUsers = _usersByRelevance(store: store, narrow: narrow)
  {
    store.autocompleteViewManager.registerMentionAutocomplete(this);
  }

  static List<User> _usersByRelevance({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    assert(narrow is! CombinedFeedNarrow);
    return store.users.values.toList()
      ..sort((userA, userB) => compareByDms(userA, userB, store: store));
  }

  @override
  Iterable<Object> getDataForQuery(MentionAutocompleteQuery query) {
    return sortedUsers;
  }

  @override
  MentionAutocompleteResult? testItem(MentionAutocompleteQuery query, Object item) {
    if (item is User) {
      if (query.testUser(item, store.autocompleteViewManager.autocompleteDataCache)) {
        return UserMentionAutocompleteResult(userId: item.userId);
      }
    }
    return null;
  }

  /// Determines which of the two users is more recent in DM conversations.
  ///
  /// Returns a negative number if [userA] is more recent than [userB],
  /// returns a positive number if [userB] is more recent than [userA],
  /// and returns `0` if both [userA] and [userB] are equally recent
  /// or there is no DM exchanged with them whatsoever.
  @visibleForTesting
  static int compareByDms(User userA, User userB, {required PerAccountStore store}) {
    final recentDms = store.recentDmConversationsView;
    final aLatestMessageId = recentDms.latestMessagesByRecipient[userA.userId];
    final bLatestMessageId = recentDms.latestMessagesByRecipient[userB.userId];

    return switch((aLatestMessageId, bLatestMessageId)) {
      (int a, int b) => -a.compareTo(b),
      (int(),     _) => -1,
      (_,     int()) => 1,
      _              => 0,
    };
  }

  @override
  void dispose() {
    store.autocompleteViewManager.unregisterMentionAutocomplete(this);
    // We cancel in-progress computations by checking [hasListeners] between tasks.
    // After [super.dispose] is called, [hasListeners] returns false.
    // TODO test that logic (may involve detecting an unhandled Future rejection; how?)
    super.dispose();
  }
}

abstract class AutocompleteQuery {
  final String raw;
  final List<String> _lowercaseWords;

  AutocompleteQuery(this.raw) : _lowercaseWords = raw.toLowerCase().split(' ');

  bool _testContainsQueryWords(List<String> nameWords) {
    // TODO(#237) test with diacritics stripped, where appropriate
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
    return '${objectRuntimeType(this, 'AutocompleteQuery')}(raw: $raw})';
  }

  @override
  bool operator ==(Object other) {
    return other is AutocompleteQuery && other.raw == raw;
  }

  @override
  int get hashCode => Object.hash('AutocompleteQuery', raw);
}

class MentionAutocompleteQuery extends AutocompleteQuery {
  /// Whether the user wants a silent mention (@_query, vs. @query).
  final bool silent;

  MentionAutocompleteQuery(super.raw, {this.silent = false});

  bool testUser(User user, AutocompleteDataCache cache) {
    // TODO(#236) test email too, not just name
    if (!user.isActive) return false;

    return _testContainsQueryWords(cache.nameWordsForUser(user));
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

class AutocompleteResult {}

sealed class MentionAutocompleteResult extends AutocompleteResult {}

class UserMentionAutocompleteResult extends MentionAutocompleteResult {
  UserMentionAutocompleteResult({required this.userId});

  final int userId;
}

// TODO(#233): // class UserGroupMentionAutocompleteResult extends MentionAutocompleteResult {

// TODO(#234): // class WildcardMentionAutocompleteResult extends MentionAutocompleteResult {
