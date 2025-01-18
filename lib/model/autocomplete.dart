import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../widgets/compose_box.dart';
import 'emoji.dart';
import 'narrow.dart';
import 'store.dart';

extension ComposeContentAutocomplete on ComposeContentController {
  AutocompleteIntent<ComposeAutocompleteQuery>? autocompleteIntent() {
    if (!selection.isValid || !selection.isNormalized) {
      // We don't require [isCollapsed] to be true because we've seen that
      // autocorrect and even backspace involve programmatically expanding the
      // selection to the left. Once we know where the syntax starts, we can at
      // least require that the selection doesn't extend leftward past that;
      // see below.
      return null;
    }

    // To avoid spending a lot of time searching for autocomplete intents
    // in long messages, we bound how far back we look for the intent's start.
    final earliest = max(0, selection.end - 30);

    if (selection.start < earliest) {
      // The selection extends to before any position we'd consider
      // for the start of the intent.  So there can't be a match.
      return null;
    }

    final textUntilCursor = text.substring(0, selection.end);
    int pos;
    for (pos = selection.end - 1; pos > selection.start; pos--) {
      final charAtPos = textUntilCursor[pos];
      if (charAtPos == '@') {
        final match = _mentionIntentRegex.matchAsPrefix(textUntilCursor, pos);
        if (match == null) continue;
      } else if (charAtPos == ':') {
        final match = _emojiIntentRegex.matchAsPrefix(textUntilCursor, pos);
        if (match == null) continue;
      } else {
        continue;
      }
      // See comment about [TextSelection.isCollapsed] above.
      return null;
    }

    for (; pos >= earliest; pos--) {
      final charAtPos = textUntilCursor[pos];
      final ComposeAutocompleteQuery query;
      if (charAtPos == '@') {
        final match = _mentionIntentRegex.matchAsPrefix(textUntilCursor, pos);
        if (match == null) continue;
        query = MentionAutocompleteQuery(match[2]!, silent: match[1]! == '_');
      } else if (charAtPos == ':') {
        final match = _emojiIntentRegex.matchAsPrefix(textUntilCursor, pos);
        if (match == null) continue;
        query = EmojiAutocompleteQuery(match[1]!);
      } else {
        continue;
      }
      return AutocompleteIntent(syntaxStart: pos, textEditingValue: value,
        query: query);
    }

    return null;
  }
}

extension ComposeTopicAutocomplete on ComposeTopicController {
  AutocompleteIntent<TopicAutocompleteQuery>? autocompleteIntent() {
    return AutocompleteIntent(
      syntaxStart: 0,
      query: TopicAutocompleteQuery(value.text),
      textEditingValue: value);
  }
}

final RegExp _mentionIntentRegex = (() {
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

final RegExp _emojiIntentRegex = (() {
  // Similar reasoning as in _mentionIntentRegex.
  // Specifically forbid a preceding ":", though, to make "::" not a query.
  const before = r'(?<=^|\s|\p{Punctuation})(?<!:)';
  // TODO(dart-future): Regexps in ES 2024 have a /v aka unicodeSets flag;
  //   if Dart matches that, we could combine into one character class
  //   meaning "whitespace and punctuation, except not `:`":
  //     r'(?<=^|[[\s\p{Punctuation}]--[:]])'

  // What possible emoji queries do we want to anticipate?
  //
  // First, look only for queries aimed at emoji names (and aliases);
  // there's little point in searching by literal emoji here, because once the
  // user has entered a literal emoji they can simply leave it in.
  // (Searching by literal emoji is useful, by contrast, for adding a reaction.)
  //
  // Then, what are the possible names (including aliases)?
  // For custom emoji, the names the server allows are r'^[0-9a-z_-]*[0-9a-z]$';
  // see check_valid_emoji_name in zerver/lib/emoji.py.
  // So only ASCII lowercase alnum, underscore, and dash.
  // A few Unicode emoji have more general names in the server's list:
  // Latin letters with diacritics, a few kana and kanji, and the name "+1".
  // (And the only "Zulip extra emoji" has one name, "zulip".)
  // Details: https://github.com/zulip/zulip-flutter/pull/1069#discussion_r1855964953
  //
  // We generalize [0-9a-z] to "any letter or number".
  // That handles the existing names except "+1", plus a potential future
  // loosening of the constraints on custom emoji's names.
  //
  // Then "+1" we take as a special case, without generalizing,
  // in order to recognize that name without adding false positives.
  //
  // Even though there could be a custom emoji whose name begins with "-",
  // we reject queries that begin that way: ":-" is much more likely to be
  // the start of an emoticon.

  /// Characters that might be meant as part of (a query for) an emoji's name
  /// at any point in the query.
  const nameCharacters = r'_\p{Letter}\p{Number}';

  return RegExp(unicode: true,
    before
    + r':'
    + r'(|'
      // Recognize '+' only as part of '+1', the only emoji name that has it.
      + r'\+1?|'
      // Reject on whitespace right after ':'; interpret that
      // as the user choosing to get out of the emoji autocomplete.
      // Similarly reject starting with ':-', which is common for emoticons.
      + r'['    + nameCharacters + r']'
      + r'[-\s' + nameCharacters + r']*'
    + r')$');
})();

/// The text controller's recognition that the user might want autocomplete UI.
class AutocompleteIntent<QueryT extends AutocompleteQuery> {
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

  final QueryT query;

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
  final Set<TopicAutocompleteView> _topicAutocompleteViews = {};
  final Set<EmojiAutocompleteView> _emojiAutocompleteViews = {};

  AutocompleteDataCache autocompleteDataCache = AutocompleteDataCache();

  void registerMentionAutocomplete(MentionAutocompleteView view) {
    final added = _mentionAutocompleteViews.add(view);
    assert(added);
  }

  void unregisterMentionAutocomplete(MentionAutocompleteView view) {
    final removed = _mentionAutocompleteViews.remove(view);
    assert(removed);
  }

  void registerTopicAutocomplete(TopicAutocompleteView view) {
    final added = _topicAutocompleteViews.add(view);
    assert(added);
  }

  void unregisterTopicAutocomplete(TopicAutocompleteView view) {
    final removed = _topicAutocompleteViews.remove(view);
    assert(removed);
  }

  void registerEmojiAutocomplete(EmojiAutocompleteView view) {
    final added = _emojiAutocompleteViews.add(view);
    assert(added);
  }

  void unregisterEmojiAutocomplete(EmojiAutocompleteView view) {
    final removed = _emojiAutocompleteViews.remove(view);
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
  /// Calls [AutocompleteView.reassemble] for all that are registered.
  ///
  void reassemble() {
    for (final view in _mentionAutocompleteViews) {
      view.reassemble();
    }
    for (final view in _topicAutocompleteViews) {
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
/// Subclasses correspond to subclasses of [AutocompleteQuery],
/// i.e. different types of autocomplete interaction initiated by the user.
/// Each subclass specifies the corresponding [AutocompleteQuery] subclass
/// as `QueryT`,
/// and the [AutocompleteResult] subclass in `ResultT` describes the
/// possible results that the user might choose in the autocomplete interaction.
///
/// When an [AutocompleteView] is created, its constructor begins the search
/// for results corresponding to the initial [query].
/// The query may later be updated, causing a new search.
///
/// The owner of one of these objects must call [dispose] when the object
/// will no longer be used, in order to free resources on the [PerAccountStore].
///
/// Lifecycle:
///  * Create an instance of a concrete subtype, beginning a search
///  * Add listeners with [addListener].
///  * When the user edits the query, use the [query] setter to update the search.
///  * On reassemble, call [reassemble].
///  * When the object will no longer be used, call [dispose] to free
///    resources on the [PerAccountStore].
abstract class AutocompleteView<QueryT extends AutocompleteQuery, ResultT extends AutocompleteResult> extends ChangeNotifier {
  /// Construct a view-model for an autocomplete interaction,
  /// and begin the search for the initial query.
  AutocompleteView({required this.store, required QueryT query})
      : _query = query {
    _startSearch();
  }

  final PerAccountStore store;

  /// True just if this [AutocompleteView] is of the appropriate type
  /// to handle the given query.
  bool acceptsQuery(AutocompleteQuery query) => query is QueryT;

  /// The last query this [AutocompleteView] was asked to perform for the user.
  ///
  /// If this view-model is currently performing a search,
  /// the search is for this query.
  /// If not, then [results] reflect this query.
  ///
  /// When set, the existing query is aborted if still in progress,
  /// and a search for the new query is begun.
  /// Any existing value in [results] remains until the new query finishes.
  QueryT get query => _query;
  QueryT _query;
  set query(QueryT query) {
    _query = query;
    _startSearch();
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// This will redo the search from scratch for the current query, if any.
  void reassemble() {
    _startSearch();
  }

  /// The latest set of results available for any value of [query].
  ///
  /// When this changes, listeners will be notified with [notifyListeners].
  ///
  /// These results might not correspond to the current value of [query],
  /// if a search is still in progress.
  /// Before any search completes, [results] will be empty.
  Iterable<ResultT> get results => _results;
  List<ResultT> _results = [];

  Future<void> _startSearch() async {
    final newResults = await computeResults();
    if (newResults == null) {
      // Query was old; new search is in progress. Or, no listeners to notify.
      return;
    }

    _results = newResults;
    notifyListeners();
  }

  /// Compute the autocomplete results for the current query,
  /// returning null if the search aborts early.
  ///
  /// Implementations should call [shouldStop] at regular intervals,
  /// and abort if it completes with true.
  /// Consider using [filterCandidates].
  @protected
  Future<List<ResultT>?> computeResults();

  /// Completes in a later microtask, returning true if evaluation
  /// of the current query should stop and false if it should continue.
  ///
  /// The deferral to a later microtask allows other code in the app to run.
  /// A long CPU-intensive loop should call this regularly
  /// (e.g. every 1000 iterations) so that the UI remains responsive.
  @protected
  Future<bool> shouldStop() async {
    final query = _query;
    await Future(() {});

    // If the query has changed, stop work on the old query.
    if (query != _query) return true;

    // If there are no listeners to get the result, stop work.
    // This happens in particular if [dispose] was called.
    if (!hasListeners) return true;

    return false;
  }

  /// Examine the given candidates against `query`, adding matches to `results`.
  ///
  /// This function chunks its work for interruption using [shouldStop],
  /// and returns true if the search was aborted.
  @protected
  Future<bool> filterCandidates<T>({
    required ResultT? Function(QueryT query, T candidate) filter,
    required Iterable<T> candidates,
    required List<ResultT> results,
  }) async {
    final query = _query;

    final iterator = candidates.iterator;
    outer: while (true) {
      assert(_query == query);
      if (await shouldStop()) return true;
      assert(_query == query);

      for (int i = 0; i < 1000; i++) {
        if (!iterator.moveNext()) break outer;
        final item = iterator.current;
        final result = filter(query, item);
        if (result != null) results.add(result);
      }
    }
    return false;
  }
}

/// An [AutocompleteView] for an autocomplete interaction
/// in the compose box's content input.
typedef ComposeAutocompleteView = AutocompleteView<ComposeAutocompleteQuery, ComposeAutocompleteResult>;

/// An [AutocompleteView] for an @-mention autocomplete interaction,
/// an example of a [ComposeAutocompleteView].
class MentionAutocompleteView extends AutocompleteView<MentionAutocompleteQuery, MentionAutocompleteResult> {
  MentionAutocompleteView._({
    required super.store,
    required super.query,
    required this.narrow,
    required this.sortedUsers,
  });

  factory MentionAutocompleteView.init({
    required PerAccountStore store,
    required Narrow narrow,
    required MentionAutocompleteQuery query,
  }) {
    final view = MentionAutocompleteView._(
      store: store,
      query: query,
      narrow: narrow,
      sortedUsers: _usersByRelevance(store: store, narrow: narrow),
    );
    store.autocompleteViewManager.registerMentionAutocomplete(view);
    return view;
  }

  final Narrow narrow;
  final List<User> sortedUsers;

  @override
  Future<List<MentionAutocompleteResult>?> computeResults() async {
    final results = <MentionAutocompleteResult>[];
    if (await filterCandidates(filter: _testUser,
          candidates: sortedUsers, results: results)) {
      return null;
    }
    return results;
  }

  MentionAutocompleteResult? _testUser(MentionAutocompleteQuery query, User user) {
    if (query.testUser(user, store.autocompleteViewManager.autocompleteDataCache)) {
      return UserMentionAutocompleteResult(userId: user.userId);
    }
    return null;
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
    TopicName? topic;
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
      case StarredMessagesNarrow():
        assert(false, 'No compose box, thus no autocomplete is available in ${narrow.runtimeType}.');
    }
    return (userA, userB) => _compareByRelevance(userA, userB,
      streamId: streamId, topic: topic,
      store: store);
  }

  static int _compareByRelevance(User userA, User userB, {
    required int? streamId,
    required TopicName? topic,
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
    required TopicName? topic,
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

  /// Comparator that puts non-bots before bots.
  @visibleForTesting
  static int compareByBotStatus(User userA, User userB) {
    return switch ((userA.isBot, userB.isBot)) {
      (false, true) => -1,
      (true, false) => 1,
      _             => 0,
    };
  }

  /// Comparator that orders alphabetically by [User.fullName].
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
}

/// A query the user has entered into some form of autocomplete.
///
/// Subclasses correspond to different types of autocomplete interaction
/// initiated by the user:
/// for example typing `@` into a compose box's content input
/// to autocomplete an @-mention ([MentionAutocompleteQuery]),
/// or typing into a topic input
/// to autocomplete a topic name ([TopicAutocompleteQuery]).
/// Each subclass has a corresponding subclass of [AutocompleteView].
///
/// An [AutocompleteQuery] object stores the user's actual query string
/// as [raw].
/// It may also store processed forms of the query
/// (for example, converted to lowercase or split on whitespace)
/// to prepare for whatever particular form of searching will be done
/// for the given type of autocomplete interaction.
abstract class AutocompleteQuery {
  AutocompleteQuery(this.raw)
    : _lowercaseWords = raw.toLowerCase().split(' ');

  /// The actual string the user entered.
  final String raw;

  final List<String> _lowercaseWords;

  /// Whether all of this query's words have matches in [words] that appear in order.
  ///
  /// A "match" means the word in [words] starts with the query word.
  bool _testContainsQueryWords(List<String> words) {
    // TODO(#237) test with diacritics stripped, where appropriate
    int wordsIndex = 0;
    int queryWordsIndex = 0;
    while (true) {
      if (queryWordsIndex == _lowercaseWords.length) {
        return true;
      }
      if (wordsIndex == words.length) {
        return false;
      }

      if (words[wordsIndex].startsWith(_lowercaseWords[queryWordsIndex])) {
        queryWordsIndex++;
      }
      wordsIndex++;
    }
  }
}

/// Any autocomplete query in the compose box's content input.
abstract class ComposeAutocompleteQuery extends AutocompleteQuery {
  ComposeAutocompleteQuery(super.raw);

  /// Construct an [AutocompleteView] initialized with this query
  /// and ready to handle queries of the same type.
  ComposeAutocompleteView initViewModel(PerAccountStore store, Narrow narrow);
}

/// A @-mention autocomplete query, used by [MentionAutocompleteView].
class MentionAutocompleteQuery extends ComposeAutocompleteQuery {
  MentionAutocompleteQuery(super.raw, {this.silent = false});

  /// Whether the user wants a silent mention (@_query, vs. @query).
  final bool silent;

  @override
  MentionAutocompleteView initViewModel(PerAccountStore store, Narrow narrow) {
    return MentionAutocompleteView.init(store: store, narrow: narrow, query: this);
  }

  bool testUser(User user, AutocompleteDataCache cache) {
    // TODO(#236) test email too, not just name

    if (!user.isActive) return false;

    return _testName(user, cache);
  }

  bool _testName(User user, AutocompleteDataCache cache) {
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

/// Cached data that is used for autocomplete
/// but kept around in between autocomplete interactions.
///
/// An instance of this class is managed by [AutocompleteViewManager].
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

/// A result the user chose, or might choose, from an autocomplete interaction.
///
/// Different subclasses of [AutocompleteView],
/// representing different types of autocomplete interaction,
/// have corresponding subclasses of [AutocompleteResult] they might produce.
class AutocompleteResult {}

/// A result from some autocomplete interaction in
/// the compose box's content input, initiated by a [ComposeAutocompleteQuery]
/// and managed by some [ComposeAutocompleteView].
sealed class ComposeAutocompleteResult extends AutocompleteResult {}

/// An emoji chosen in an autocomplete interaction, via [EmojiAutocompleteView].
class EmojiAutocompleteResult extends ComposeAutocompleteResult {
  EmojiAutocompleteResult(this.candidate, this.rank);

  final EmojiCandidate candidate;

  /// A measure of the result's quality in the context of the query.
  ///
  /// Used internally by [EmojiAutocompleteView] for ranking the results.
  final int rank;

  @override
  String toString() {
    return 'EmojiAutocompleteResult(${candidate.description()})';
  }
}

/// A result from an @-mention autocomplete interaction,
/// managed by a [MentionAutocompleteView].
///
/// This is abstract because there are several kinds of result
/// that can all be offered in the same @-mention autocomplete interaction:
/// a user, a wildcard, or a user group.
sealed class MentionAutocompleteResult extends ComposeAutocompleteResult {}

/// An autocomplete result for an @-mention of an individual user.
class UserMentionAutocompleteResult extends MentionAutocompleteResult {
  UserMentionAutocompleteResult({required this.userId});

  final int userId;
}

// TODO(#233): // class UserGroupMentionAutocompleteResult extends MentionAutocompleteResult {

// TODO(#234): // class WildcardMentionAutocompleteResult extends MentionAutocompleteResult {

/// An autocomplete interaction for choosing a topic for a message.
class TopicAutocompleteView extends AutocompleteView<TopicAutocompleteQuery, TopicAutocompleteResult> {
  TopicAutocompleteView._({
    required super.store,
    required super.query,
    required this.streamId,
  });

  factory TopicAutocompleteView.init({
    required PerAccountStore store,
    required int streamId,
    required TopicAutocompleteQuery query,
  }) {
    final view = TopicAutocompleteView._(
      store: store, streamId: streamId, query: query);
    store.autocompleteViewManager.registerTopicAutocomplete(view);
    view._fetch();
    return view;
  }

  /// The channel/stream the eventual message will be sent to.
  final int streamId;

  Iterable<TopicName> _topics = [];
  bool _isFetching = false;

  /// Fetches topics of the current stream narrow, expected to fetch
  /// only once per lifecycle.
  ///
  /// Starts fetching once the stream narrow is active, then when results
  /// are fetched it restarts search to refresh UI showing the newly
  /// fetched topics.
  Future<void> _fetch() async {
     assert(!_isFetching);
    _isFetching = true;
    final result = await getStreamTopics(store.connection, streamId: streamId);
    _topics = result.topics.map((e) => e.name);
    _isFetching = false;
    return _startSearch();
  }

  @override
  Future<List<TopicAutocompleteResult>?> computeResults() async {
    final results = <TopicAutocompleteResult>[];
    if (await filterCandidates(filter: _testTopic,
          candidates: _topics, results: results)) {
      return null;
    }
    return results;
  }

  TopicAutocompleteResult? _testTopic(TopicAutocompleteQuery query, TopicName topic) {
    if (query.testTopic(topic)) {
      return TopicAutocompleteResult(topic: topic);
    }
    return null;
  }

  @override
  void dispose() {
    store.autocompleteViewManager.unregisterTopicAutocomplete(this);
    super.dispose();
  }
}

/// A query for autocompleting a topic to send to,
/// used by [TopicAutocompleteView].
class TopicAutocompleteQuery extends AutocompleteQuery {
  TopicAutocompleteQuery(super.raw);

  bool testTopic(TopicName topic) {
    // TODO(#881): Sort by match relevance, like web does.
    return topic.displayName != raw
      && topic.displayName.toLowerCase().contains(raw.toLowerCase());
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'TopicAutocompleteQuery')}(raw: $raw)';
  }

  @override
  bool operator ==(Object other) {
    return other is TopicAutocompleteQuery && other.raw == raw;
  }

  @override
  int get hashCode => Object.hash('TopicAutocompleteQuery', raw);
}

/// A topic chosen in an autocomplete interaction, via a [TopicAutocompleteView].
class TopicAutocompleteResult extends AutocompleteResult {
  final TopicName topic;

  TopicAutocompleteResult({required this.topic});
}
