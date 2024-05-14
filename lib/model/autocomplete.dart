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
  MentionAutocompleteView._({
    required this.store,
    required this.narrow,
    required this.sortedUsers,
  });

  factory MentionAutocompleteView.init({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    final view = MentionAutocompleteView._(
      store: store,
      narrow: narrow,
      sortedUsers: _usersByRelevance(store: store, narrow: narrow),
    );
    store.autocompleteViewManager.registerMentionAutocomplete(view);
    return view;
  }

  static List<User> _usersByRelevance({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    return store.users.values.toList()
      ..sort(_comparator(store: store, narrow: narrow));
  }

  /// Compare the users the same way they would be sorted as
  /// autocomplete candidates.
  ///
  /// This behaves the same as the comparator used for sorting in
  /// [_usersByRelevance], but calling this for each comparison would be a bit
  /// less efficient because some of the logic is independent of the users and
  /// can be precomputed.
  ///
  /// This is useful for tests in order to distinguish "A comes before B"
  /// from "A ranks equal to B, and the sort happened to put A before B",
  /// particularly because [List.sort] makes no guarantees about the order
  /// of items that compare equal.
  int debugCompareUsers(User userA, User userB) {
    return _comparator(store: store, narrow: narrow)(userA, userB);
  }

  static int Function(User, User) _comparator({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    int? streamId;
    String? topic;
    switch (narrow) {
      case ChannelNarrow():
        streamId = narrow.streamId;
      case TopicNarrow():
        streamId = narrow.streamId;
        topic = narrow.topic;
      case DmNarrow():
        break;
      case CombinedFeedNarrow():
      case MentionsNarrow():
        assert(false, 'No compose box, thus no autocomplete is available in ${narrow.runtimeType}.');
    }
    return (userA, userB) => _compareByRelevance(userA, userB,
      streamId: streamId, topic: topic,
      store: store);
  }

  static int _compareByRelevance(User userA, User userB, {
    required int? streamId,
    required String? topic,
    required PerAccountStore store,
  }) {
    // TODO(#234): give preference to "all", "everyone" or "stream"

    // TODO(#618): give preference to subscribed users first

    if (streamId != null) {
      final recencyResult = compareByRecency(userA, userB,
        streamId: streamId,
        topic: topic,
        store: store);
      if (recencyResult != 0) return recencyResult;
    }
    final dmsResult = compareByDms(userA, userB, store: store);
    if (dmsResult != 0) return dmsResult;

    final botStatusResult = compareByBotStatus(userA, userB);
    if (botStatusResult != 0) return botStatusResult;

    return compareByAlphabeticalOrder(userA, userB, store: store);
  }

  /// Determines which of the two users has more recent activity (messages sent
  /// recently) in the topic/stream.
  ///
  /// First checks for the activity in [topic] if provided.
  ///
  /// If no [topic] is provided, or there is no activity in the topic at all,
  /// then checks for the activity in the stream with [streamId].
  ///
  /// Returns a negative number if [userA] has more recent activity than [userB],
  /// returns a positive number if [userB] has more recent activity than [userA],
  /// and returns `0` if both [userA] and [userB] have no activity at all.
  @visibleForTesting
  static int compareByRecency(User userA, User userB, {
    required int streamId,
    required String? topic,
    required PerAccountStore store,
  }) {
    final recentSenders = store.recentSenders;
    if (topic != null) {
      final result = -compareRecentMessageIds(
        recentSenders.latestMessageIdOfSenderInTopic(
          streamId: streamId, topic: topic, senderId: userA.userId),
        recentSenders.latestMessageIdOfSenderInTopic(
          streamId: streamId, topic: topic, senderId: userB.userId));
      if (result != 0) return result;
    }

    return -compareRecentMessageIds(
      recentSenders.latestMessageIdOfSenderInStream(
        streamId: streamId, senderId: userA.userId),
      recentSenders.latestMessageIdOfSenderInStream(
        streamId: streamId, senderId: userB.userId));
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

    return -compareRecentMessageIds(aLatestMessageId, bLatestMessageId);
  }

  /// Compares [a] to [b], with null less than all integers.
  ///
  /// The values should represent the most recent message ID in each of two
  /// sets of messages, with null meaning the set is empty.
  ///
  /// Return values are as with [Comparable.compareTo].
  @visibleForTesting
  static int compareRecentMessageIds(int? a, int? b) {
    return switch ((a, b)) {
      (int a, int b) => a.compareTo(b),
      (int(),     _) => 1,
      (_,     int()) => -1,
      _              => 0,
    };
  }

  /// Compares the bot status of two users and returns an integer indicating their order.
  ///
  /// Returns `-1` if `userA` is human and `userB` is bot, returns `1` if `userA`
  /// is bot and `userB` is human, and returns `0` if both users have the same
  /// bot status.
  @visibleForTesting
  static int compareByBotStatus(User userA, User userB) {
    return switch ((userA.isBot, userB.isBot)) {
      (false, true) => -1,
      (true, false) => 1,
      _             => 0,
    };
  }

  /// Compares the two users by [User.fullName] case-insensitively.
  ///
  /// Returns a negative number if `userA`'s `fullName` comes first alphabetically,
  /// returns a positive number if `userB`'s `fullName` comes first alphabetically,
  /// and returns `0` if both users have identical `fullName`.
  @visibleForTesting
  static int compareByAlphabeticalOrder(User userA, User userB,
      {required PerAccountStore store}) {
    final userAName = store.autocompleteViewManager.autocompleteDataCache
      .normalizedNameForUser(userA);
    final userBName = store.autocompleteViewManager.autocompleteDataCache
      .normalizedNameForUser(userB);
    return userAName.compareTo(userBName); // TODO(i18n): add locale-aware sorting
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
  final List<User> sortedUsers;

  MentionAutocompleteQuery? get query => _query;
  MentionAutocompleteQuery? _query;
  set query(MentionAutocompleteQuery? query) {
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

  Iterable<MentionAutocompleteResult> get results => _results;
  List<MentionAutocompleteResult> _results = [];

  Future<void> _startSearch(MentionAutocompleteQuery query) async {
    final newResults = await _computeResults(query);
    if (newResults == null) {
      // Query was old; new search is in progress. Or, no listeners to notify.
      return;
    }

    _results = newResults;
    notifyListeners();
  }

  Future<List<MentionAutocompleteResult>?> _computeResults(MentionAutocompleteQuery query) async {
    final List<MentionAutocompleteResult> results = [];
    final iterator = sortedUsers.iterator;
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
  MentionAutocompleteQuery(this.raw, {this.silent = false})
    : _lowercaseWords = raw.toLowerCase().split(' ');

  final String raw;

  /// Whether the user wants a silent mention (@_query, vs. @query).
  final bool silent;

  final List<String> _lowercaseWords;

  bool testUser(User user, AutocompleteDataCache cache) {
    // TODO(#236) test email too, not just name

    if (!user.isActive) return false;

    return _testName(user, cache);
  }

  bool _testName(User user, AutocompleteDataCache cache) {
    // TODO(#237) test with diacritics stripped, where appropriate

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
  final Map<int, String> _normalizedNamesByUser = {};

  /// The lowercase `fullName` of [user].
  String normalizedNameForUser(User user) {
    return _normalizedNamesByUser[user.userId] ??= user.fullName.toLowerCase();
  }

  final Map<int, List<String>> _nameWordsByUser = {};

  List<String> nameWordsForUser(User user) {
    return _nameWordsByUser[user.userId] ??= normalizedNameForUser(user).split(' ');
  }

  void invalidateUser(int userId) {
    _normalizedNamesByUser.remove(userId);
    _nameWordsByUser.remove(userId);
  }
}

sealed class MentionAutocompleteResult {}

class UserMentionAutocompleteResult extends MentionAutocompleteResult {
  UserMentionAutocompleteResult({required this.userId});

  final int userId;
}

// TODO(#233): // class UserGroupMentionAutocompleteResult extends MentionAutocompleteResult {

// TODO(#234): // class WildcardMentionAutocompleteResult extends MentionAutocompleteResult {
