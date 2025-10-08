import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/channels.dart';
import '../generated/l10n/zulip_localizations.dart';
import '../widgets/compose_box.dart';
import 'algorithms.dart';
import 'channel.dart';
import 'compose.dart';
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
  final Set<AutocompleteView> _autocompleteViews = {};

  AutocompleteDataCache autocompleteDataCache = AutocompleteDataCache();

  void registerAutocomplete(AutocompleteView view) {
    final added = _autocompleteViews.add(view);
    assert(added);
  }

  void unregisterAutocomplete(AutocompleteView view) {
    final removed = _autocompleteViews.remove(view);
    assert(removed);
  }

  void handleRealmUserRemoveEvent(RealmUserRemoveEvent event) {
    autocompleteDataCache.invalidateUser(event.userId);
  }

  void handleRealmUserUpdateEvent(RealmUserUpdateEvent event) {
    autocompleteDataCache.invalidateUser(event.userId);
  }

  void handleUserGroupRemoveEvent(UserGroupRemoveEvent event) {
    autocompleteDataCache.invalidateUserGroup(event.groupId);
  }

  void handleUserGroupUpdateEvent(UserGroupUpdateEvent event) {
    autocompleteDataCache.invalidateUserGroup(event.groupId);
  }

  void handleChannelDeleteEvent(ChannelDeleteEvent event) {
    for (final channelId in event.channelIds) {
      autocompleteDataCache.invalidateChannel(channelId);
    }
  }

  void handleChannelUpdateEvent(ChannelUpdateEvent event) {
    autocompleteDataCache.invalidateChannel(event.streamId);
  }

  /// Called when the app is reassembled during debugging, e.g. for hot reload.
  ///
  /// Calls [AutocompleteView.reassemble] for all that are registered.
  ///
  void reassemble() {
    for (final view in _autocompleteViews) {
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
    store.autocompleteViewManager.registerAutocomplete(this);
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

  @override
  void dispose() {
    store.autocompleteViewManager.unregisterAutocomplete(this);
    // We cancel in-progress computations by checking [hasListeners] between tasks.
    // After [super.dispose] is called, [hasListeners] returns false.
    // TODO test that logic (may involve detecting an unhandled Future rejection; how?)
    super.dispose();
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
    required this.localizations,
    required this.narrow,
    required this.sortedUsers,
    required this.sortedUserGroups,
  });

  factory MentionAutocompleteView.init({
    required PerAccountStore store,
    required ZulipLocalizations localizations,
    required Narrow narrow,
    required MentionAutocompleteQuery query,
  }) {
    return MentionAutocompleteView._(
      store: store,
      query: query,
      localizations: localizations,
      narrow: narrow,
      sortedUsers: _usersByRelevance(store: store, narrow: narrow),
      sortedUserGroups: _userGroupsByRelevance(store: store),
    );
  }

  final Narrow narrow;
  final List<User> sortedUsers;
  final List<UserGroup> sortedUserGroups;
  final ZulipLocalizations localizations;

  static List<User> _usersByRelevance({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    return store.allUsers.toList()
      ..sort(_comparator(store: store, narrow: narrow));
  }

  /// Compare the users the same way they would be sorted as
  /// autocomplete candidates, given [query].
  ///
  /// The users must both match the query.
  ///
  /// This behaves the same as the comparator used for sorting in
  /// [_usersByRelevance], combined with the ranking applied at the end
  /// of [computeResults].
  ///
  /// This is useful for tests in order to distinguish "A comes before B"
  /// from "A ranks equal to B, and the sort happened to put A before B",
  /// particularly because [List.sort] makes no guarantees about the order
  /// of items that compare equal.
  int debugCompareUsers(User userA, User userB) {
    final rankA = query.testUser(userA, store)!.rank;
    final rankB = query.testUser(userB, store)!.rank;
    if (rankA != rankB) return rankA.compareTo(rankB);

    return _comparator(store: store, narrow: narrow)(userA, userB);
  }

  static int Function(User, User) _comparator({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    // See also [MentionAutocompleteQuery._rankUserResult];
    // that ranking takes precedence over this.

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
      case KeywordSearchNarrow():
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

  static List<UserGroup> _userGroupsByRelevance({required PerAccountStore store}) {
    return store.activeGroups
      // TODO(#1776) Follow new "Who can mention this group" setting instead
      .where((userGroup) => !userGroup.isSystemGroup)
      .toList()
      ..sort(_userGroupComparator(store: store));
  }

  static int Function(UserGroup, UserGroup) _userGroupComparator({
    required PerAccountStore store,
  }) {
    // See also [MentionAutocompleteQuery._rankUserGroupResult];
    // that ranking takes precedence over this.

    return (userGroupA, userGroupB) =>
      compareGroupsByAlphabeticalOrder(userGroupA, userGroupB, store: store);
  }

  static int compareGroupsByAlphabeticalOrder(UserGroup userGroupA, UserGroup userGroupB,
      {required PerAccountStore store}) {
    final groupAName = store.autocompleteViewManager.autocompleteDataCache
      .normalizedNameForUserGroup(userGroupA);
    final groupBName = store.autocompleteViewManager.autocompleteDataCache
      .normalizedNameForUserGroup(userGroupB);
    return groupAName.compareTo(groupBName); // TODO(i18n): add locale-aware sorting
  }

  void computeWildcardMentionResults({
    required List<MentionAutocompleteResult> results,
    required bool isComposingChannelMessage,
  }) {
    if (query.silent) return;

    bool tryOption(WildcardMentionOption option) {
      final result = query.testWildcardOption(option, localizations: localizations);
      if (result == null) return false;
      results.add(result);
      return true;
    }

    // Only one of the (all, everyone, channel, stream) channel wildcards are
    // shown.
    all: {
      if (tryOption(WildcardMentionOption.all)) break all;
      if (tryOption(WildcardMentionOption.everyone)) break all;
      if (isComposingChannelMessage) {
        final isChannelWildcardAvailable = store.zulipFeatureLevel >= 247; // TODO(server-9)
        if (isChannelWildcardAvailable && tryOption(WildcardMentionOption.channel)) break all;
        if (tryOption(WildcardMentionOption.stream)) break all;
      }
    }

    final isTopicWildcardAvailable = store.zulipFeatureLevel >= 224; // TODO(server-8)
    if (isComposingChannelMessage && isTopicWildcardAvailable) {
      tryOption(WildcardMentionOption.topic);
    }
  }

  @override
  Future<List<MentionAutocompleteResult>?> computeResults() async {
    final unsorted = <MentionAutocompleteResult>[];
    // Give priority to wildcard mentions.
    computeWildcardMentionResults(results: unsorted,
      isComposingChannelMessage: narrow is ChannelNarrow || narrow is TopicNarrow);

    if (await filterCandidates(filter: _testUser,
        candidates: sortedUsers, results: unsorted)) {
      return null;
    }

    if (await filterCandidates(filter: _testUserGroup,
        candidates: sortedUserGroups, results: unsorted)) {
      return null;
    }

    return bucketSort(unsorted,
      (r) => r.rank, numBuckets: MentionAutocompleteQuery._numResultRanks);
  }

  MentionAutocompleteResult? _testUser(MentionAutocompleteQuery query, User user) {
    return query.testUser(user, store);
  }

  MentionAutocompleteResult? _testUserGroup(MentionAutocompleteQuery query, UserGroup userGroup) {
    return query.testUserGroup(userGroup, store);
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
/// (for example, normalized by case and diacritics, or split on whitespace)
/// to prepare for whatever particular form of searching will be done
/// for the given type of autocomplete interaction.
abstract class AutocompleteQuery {
  AutocompleteQuery(this.raw) {
    _normalized = lowercaseAndStripDiacritics(raw);
    // TODO(#1805) split on space characters that the user is actually using
    //   (e.g. U+3000 IDEOGRAPHIC SPACE);
    //   could check active keyboard or just split on all kinds of spaces
    _normalizedWords = _normalized.split(' ');
  }

  /// The actual string the user entered.
  final String raw;

  late final String _normalized;

  late final List<String> _normalizedWords;

  static final RegExp _regExpStripMarkCharacters = RegExp(r'\p{M}', unicode: true);

  static String lowercaseAndStripDiacritics(String input) {
    // Anders reports that this is what web does; see discussion:
    //   https://chat.zulip.org/#narrow/channel/48-mobile/topic/deps.3A.20Add.20new.20package.20to.20handle.20diacritics/near/2244487
    final lowercase = input.toLowerCase();
    final compatibilityNormalized = unorm.nfkd(lowercase);
    return compatibilityNormalized.replaceAll(_regExpStripMarkCharacters, '');
  }

  NameMatchQuality? _matchName({
    required String normalizedName,
    required List<String> normalizedNameWords,
  }) {
    if (normalizedName.startsWith(_normalized)) {
      if (normalizedName.length == _normalized.length) {
        return NameMatchQuality.exact;
      } else {
        return NameMatchQuality.totalPrefix;
      }
    }

    if (_testContainsQueryWords(normalizedNameWords)) {
      return NameMatchQuality.wordPrefixes;
    }

    return null;
  }

  /// Whether all of this query's words have matches in [words],
  /// insensitively to case and diacritics, that appear in order.
  ///
  /// A "match" means the word in [words] starts with the query word.
  ///
  /// [words] must all have been passed through [lowercaseAndStripDiacritics].
  bool _testContainsQueryWords(List<String> words) {
    int wordsIndex = 0;
    int queryWordsIndex = 0;
    while (true) {
      if (queryWordsIndex == _normalizedWords.length) {
        return true;
      }
      if (wordsIndex == words.length) {
        return false;
      }

      if (words[wordsIndex].startsWith(_normalizedWords[queryWordsIndex])) {
        queryWordsIndex++;
      }
      wordsIndex++;
    }
  }
}

/// The match quality of some kind of name (e.g. [User.fullName])
/// to an autocomplete query.
///
/// All matches are case-insensitive.
enum NameMatchQuality {
  /// The query matches the whole name exactly.
  exact,

  /// The name starts with the query.
  totalPrefix,

  /// All of the query's words have matches in the words of the name
  /// that appear in order.
  ///
  /// A "match" means the word in the name starts with the query word.
  wordPrefixes,
}

/// Any autocomplete query in the compose box's content input.
abstract class ComposeAutocompleteQuery extends AutocompleteQuery {
  ComposeAutocompleteQuery(super.raw);

  /// Construct an [AutocompleteView] initialized with this query
  /// and ready to handle queries of the same type.
  ComposeAutocompleteView initViewModel({
    required PerAccountStore store,
    required ZulipLocalizations localizations,
    required Narrow narrow,
  });
}

/// A @-mention autocomplete query, used by [MentionAutocompleteView].
class MentionAutocompleteQuery extends ComposeAutocompleteQuery {
  MentionAutocompleteQuery(super.raw, {this.silent = false});

  /// Whether the user wants a silent mention (@_query, vs. @query).
  final bool silent;

  @override
  MentionAutocompleteView initViewModel({
    required PerAccountStore store,
    required ZulipLocalizations localizations,
    required Narrow narrow,
  }) {
    return MentionAutocompleteView.init(
      store: store, localizations: localizations, narrow: narrow, query: this);
  }

  WildcardMentionAutocompleteResult? testWildcardOption(WildcardMentionOption wildcardOption, {
      required ZulipLocalizations localizations}) {
    final localized = wildcardOption.localizedCanonicalString(localizations);
    final matches = wildcardOption.canonicalString.contains(_normalized)
      || AutocompleteQuery.lowercaseAndStripDiacritics(localized).contains(_normalized);
    if (!matches) return null;
    return WildcardMentionAutocompleteResult(
      wildcardOption: wildcardOption, rank: _rankWildcardResult);
  }

  MentionAutocompleteResult? testUser(User user, PerAccountStore store) {
    if (!user.isActive) return null;
    if (store.isUserMuted(user.userId)) return null;

    final cache = store.autocompleteViewManager.autocompleteDataCache;
    final nameMatchQuality = _matchName(
      normalizedName: cache.normalizedNameForUser(user),
      normalizedNameWords: cache.normalizedNameWordsForUser(user));
    bool? matchesEmail;
    if (nameMatchQuality == null) {
      matchesEmail = _matchEmail(user, cache);
      if (!matchesEmail) return null;
    }

    return UserMentionAutocompleteResult(
      userId: user.userId,
      rank: _rankUserResult(user,
        nameMatchQuality: nameMatchQuality, matchesEmail: matchesEmail));
  }

  bool _matchEmail(User user, AutocompleteDataCache cache) {
    final normalizedEmail = cache.normalizedEmailForUser(user);
    if (normalizedEmail == null) return false; // Email not known
    return normalizedEmail.startsWith(_normalized);
  }

  MentionAutocompleteResult? testUserGroup(UserGroup userGroup, PerAccountStore store) {
    final cache = store.autocompleteViewManager.autocompleteDataCache;

    final nameMatchQuality = _matchName(
      normalizedName: cache.normalizedNameForUserGroup(userGroup),
      normalizedNameWords: cache.normalizedNameWordsForUserGroup(userGroup));

    if (nameMatchQuality == null) return null;

    return UserGroupMentionAutocompleteResult(
      groupId: userGroup.id,
      rank: _rankUserGroupResult(userGroup, nameMatchQuality: nameMatchQuality));
  }

  /// A measure of a wildcard result's quality in the context of the query,
  /// from 0 (best) to one less than [_numResultRanks].
  ///
  /// See also [_rankUserResult] and [_rankUserGroupResult].
  static const _rankWildcardResult = 0;

  /// A measure of a user result's quality in the context of the query,
  /// from 0 (best) to one less than [_numResultRanks].
  ///
  /// When [nameMatchQuality] is non-null (the name matches),
  /// callers should skip computing [matchesEmail] and pass null for that.
  ///
  /// See also [_rankWildcardResult] and [_rankUserGroupResult].
  static int _rankUserResult(User user, {
    required NameMatchQuality? nameMatchQuality,
    required bool? matchesEmail,
  }) {
    if (nameMatchQuality != null) {
      assert(matchesEmail == null);
      return switch (nameMatchQuality) {
        NameMatchQuality.exact =>        1,
        NameMatchQuality.totalPrefix =>  2,
        NameMatchQuality.wordPrefixes => 3,
      };
    }
    assert(matchesEmail == true);
    return 7;
  }

  /// A measure of a user-group result's quality in the context of the query,
  /// from 0 (best) to one less than [_numResultRanks].
  ///
  /// See also [_rankWildcardResult] and [_rankUserResult].
  static int _rankUserGroupResult(UserGroup userGroup, {
    required NameMatchQuality nameMatchQuality,
  }) {
    return switch (nameMatchQuality) {
      NameMatchQuality.exact =>        4,
      NameMatchQuality.totalPrefix =>  5,
      NameMatchQuality.wordPrefixes => 6,
    };
  }

  /// The number of possible values returned by
  /// [_rankWildcardResult], [_rankUserResult], and [_rankUserGroupResult]..
  static const _numResultRanks = 8;

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

extension WildcardMentionOptionExtension on WildcardMentionOption {
  /// A translation of [canonicalString], from [localizations].
  String localizedCanonicalString(ZulipLocalizations localizations) {
    return switch (this) {
      WildcardMentionOption.all      => localizations.wildcardMentionAll,
      WildcardMentionOption.everyone => localizations.wildcardMentionEveryone,
      WildcardMentionOption.channel  => localizations.wildcardMentionChannel,
      WildcardMentionOption.stream   => localizations.wildcardMentionStream,
      WildcardMentionOption.topic    => localizations.wildcardMentionTopic,
    };
  }
}

/// Cached data that is used for autocomplete
/// but kept around in between autocomplete interactions.
///
/// An instance of this class is managed by [AutocompleteViewManager].
// TODO(#1805) when splitting words, split on space characters that are likely
//   to be used (e.g. U+3000 IDEOGRAPHIC SPACE);
//   could check server language or just split on all kinds of spaces
class AutocompleteDataCache {
  final Map<int, String> _normalizedNamesByUser = {};

  /// The normalized `fullName` of [user].
  String normalizedNameForUser(User user) {
    return _normalizedNamesByUser[user.userId]
      ??= AutocompleteQuery.lowercaseAndStripDiacritics(user.fullName);
  }

  final Map<int, List<String>> _normalizedNameWordsByUser = {};

  List<String> normalizedNameWordsForUser(User user) {
    return _normalizedNameWordsByUser[user.userId]
      ??= normalizedNameForUser(user).split(' ');
  }

  final Map<int, String?> _normalizedEmailsByUser = {};

  /// The normalized `deliveryEmail` of [user], or null if that's null.
  String? normalizedEmailForUser(User user) {
    return _normalizedEmailsByUser[user.userId]
      ??= (user.deliveryEmail != null
            ? AutocompleteQuery.lowercaseAndStripDiacritics(user.deliveryEmail!)
            : null);
  }

  final Map<int, String> _normalizedNamesByUserGroup = {};

  /// The normalized `name` of [userGroup].
  String normalizedNameForUserGroup(UserGroup userGroup) {
    return _normalizedNamesByUserGroup[userGroup.id]
      ??= AutocompleteQuery.lowercaseAndStripDiacritics(userGroup.name);
  }

  final Map<int, List<String>> _normalizedNameWordsByUserGroup = {};

  List<String> normalizedNameWordsForUserGroup(UserGroup userGroup) {
    return _normalizedNameWordsByUserGroup[userGroup.id]
      ??= normalizedNameForUserGroup(userGroup).split(' ');
  }

  final Map<int, String> _normalizedNamesByChannel = {};

  /// The normalized `name` of [channel].
  String normalizedNameForChannel(ZulipStream channel) {
    return _normalizedNamesByChannel[channel.streamId]
      ??= AutocompleteQuery.lowercaseAndStripDiacritics(channel.name);
  }

  final Map<int, List<String>> _normalizedNameWordsByChannel = {};

  List<String> normalizedNameWordsForChannel(ZulipStream channel) {
    return _normalizedNameWordsByChannel[channel.streamId]
      ?? normalizedNameForChannel(channel).split(' ');
  }

  void invalidateUser(int userId) {
    _normalizedNamesByUser.remove(userId);
    _normalizedNameWordsByUser.remove(userId);
    _normalizedEmailsByUser.remove(userId);
  }

  void invalidateUserGroup(int id) {
    _normalizedNamesByUserGroup.remove(id);
    _normalizedNameWordsByUserGroup.remove(id);
  }

  void invalidateChannel(int channelId) {
    _normalizedNamesByChannel.remove(channelId);
    _normalizedNameWordsByChannel.remove(channelId);
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
sealed class MentionAutocompleteResult extends ComposeAutocompleteResult {
  /// A measure of the result's quality in the context of the query.
  ///
  /// Used internally by [MentionAutocompleteView] for ranking the results.
  // See also [MentionAutocompleteView._usersByRelevance];
  // results with equal [rank] will appear in the order they were put in
  // by that method.
  //
  // Compare sort_recipients in Zulip web:
  //   https://github.com/zulip/zulip/blob/afdf20c67/web/src/typeahead_helper.ts#L472
  //
  // Behavior we have that web doesn't and might like to follow:
  // - A "word-prefixes" match quality on user and user-group names:
  //   see [NameMatchQuality.wordPrefixes], which we rank on.
  //
  // Behavior web has that seems undesired, which we don't plan to follow:
  // - Ranking humans above bots, even when the bots have higher relevance
  //   and better match quality. If there's a bot participating in the
  //   current conversation and I start typing its name, why wouldn't we want
  //   that as a top result? Issue: https://github.com/zulip/zulip/issues/35467
  // - A "word-boundary" match quality on user and user-group names:
  //   special rank when the whole query appears contiguously
  //   right after a word-boundary character.
  //   Our [NameMatchQuality.wordPrefixes] seems smarter.
  // - An "exact" match quality on emails: probably not worth its complexity.
  //   Emails are much more uniform in their endings than users' names are,
  //   so a prefix match should be adequate. (If I've typed "email@example.co",
  //   that'll probably be the only result. There might be an "email@example.com",
  //   and an "exact" match would downrank that, but still that's just two items
  //   to scan through.)
  // - A "word-boundary" match quality on user emails:
  //   "words" is a wrong abstraction when matching on emails.
  // - Ranking some case-sensitive matches differently from case-insensitive
  //   matches. Users will expect a lowercase query to be adequate.
  int get rank;
}

/// An autocomplete result for an @-mention of an individual user.
class UserMentionAutocompleteResult extends MentionAutocompleteResult {
  UserMentionAutocompleteResult({required this.userId, required this.rank});

  final int userId;

  @override
  final int rank;
}

/// An autocomplete result for an @-mention of all the users in a conversation.
class WildcardMentionAutocompleteResult extends MentionAutocompleteResult {
  WildcardMentionAutocompleteResult({required this.wildcardOption, required this.rank});

  final WildcardMentionOption wildcardOption;

  @override
  final int rank;
}

/// An autocomplete result for an @-mention of a user group.
class UserGroupMentionAutocompleteResult extends MentionAutocompleteResult {
  UserGroupMentionAutocompleteResult({required this.groupId, required this.rank});

  final int groupId;

  @override
  final int rank;
}

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
    return TopicAutocompleteView._(store: store, streamId: streamId, query: query)
      .._fetch();
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
    final result = await getStreamTopics(store.connection, streamId: streamId,
      allowEmptyTopicName: true,
    );
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
    if (query.testTopic(topic, store)) {
      return TopicAutocompleteResult(topic: topic);
    }
    return null;
  }
}

/// A query for autocompleting a topic to send to,
/// used by [TopicAutocompleteView].
class TopicAutocompleteQuery extends AutocompleteQuery {
  TopicAutocompleteQuery(super.raw);

  bool testTopic(TopicName topic, PerAccountStore store) {
    // TODO(#881): Sort by match relevance, like web does.

    if (topic.displayName == null) {
      return AutocompleteQuery.lowercaseAndStripDiacritics(store.realmEmptyTopicDisplayName)
        .contains(_normalized);
    }
    return topic.displayName != raw
      && AutocompleteQuery.lowercaseAndStripDiacritics(topic.displayName!).contains(_normalized);
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

/// An [AutocompleteView] for a #channel autocomplete interaction,
/// an example of a [ComposeAutocompleteView].
class ChannelLinkAutocompleteView extends AutocompleteView<ChannelLinkAutocompleteQuery, ChannelLinkAutocompleteResult> {
  ChannelLinkAutocompleteView._({
    required super.store,
    required super.query,
    required this.narrow,
    required this.sortedChannels,
  });

  factory ChannelLinkAutocompleteView.init({
    required PerAccountStore store,
    required Narrow narrow,
    required ChannelLinkAutocompleteQuery query,
  }) {
    return ChannelLinkAutocompleteView._(
      store: store,
      query: query,
      narrow: narrow,
      sortedChannels: _channelsByRelevance(store: store, narrow: narrow),
    );
  }

  final Narrow narrow;
  final List<ZulipStream> sortedChannels;

  static List<ZulipStream> _channelsByRelevance({
    required PerAccountStore store,
    required Narrow narrow,
  }) {
    return store.streams.values.sorted(_comparator(narrow: narrow));
  }

  /// Compare the channels the same way they would be sorted as
  /// autocomplete candidates, given [query].
  ///
  /// The channels must both match the query.
  ///
  /// This behaves the same as the comparator used for sorting in
  /// [_channelsByRelevance], combined with the ranking applied at the end
  /// of [computeResults].
  ///
  /// This is useful for tests in order to distinguish "A comes before B"
  /// from "A ranks equal to B, and the sort happened to put A before B",
  /// particularly because [List.sort] makes no guarantees about the order
  /// of items that compare equal.
  int debugCompareChannels(ZulipStream a, ZulipStream b) {
    final rankA = query.testChannel(a, store)!.rank;
    final rankB = query.testChannel(b, store)!.rank;
    if (rankA != rankB) return rankA.compareTo(rankB);

    return _comparator(narrow: narrow)(a, b);
  }

  static Comparator<ZulipStream> _comparator({required Narrow narrow}) {
    // See also [ChannelLinkAutocompleteQuery._rankResult];
    // that ranking takes precedence over this.

    int? channelId;
    switch (narrow) {
      case ChannelNarrow(:var streamId):
      case TopicNarrow(:var streamId):
        channelId = streamId;
      case DmNarrow():
        break;
      case CombinedFeedNarrow():
      case MentionsNarrow():
      case StarredMessagesNarrow():
      case KeywordSearchNarrow():
        assert(false, 'No compose box, thus no autocomplete is available in ${narrow.runtimeType}.');
    }
    return (a, b) => _compareByRelevance(a, b, composingToChannelId: channelId);
  }

  static int _compareByRelevance(ZulipStream a, ZulipStream b, {
    required int? composingToChannelId,
  }) {
    // Compare `typeahead_helper.compare_by_activity` in Zulip web;
    //   https://github.com/zulip/zulip/blob/c3fdee6ed/web/src/typeahead_helper.ts#L972-L988
    //
    // Behavior difference that Web should probably fix, TODO(Web):
    //  * Web compares "recent activity" only for subscribed channels,
    //    but we do it for unsubscribed ones too.
    //  * We exclude archived channels from autocomplete results,
    //    but Web doesn't.
    //    See: [ChannelLinkAutocompleteQuery.testChannel]

    if (composingToChannelId != null) {
      final composingToResult = compareByComposingTo(a, b,
        composingToChannelId: composingToChannelId);
      if (composingToResult != 0) return composingToResult;
    }

    final beingSubscribedResult = compareByBeingSubscribed(a, b);
    if (beingSubscribedResult != 0) return beingSubscribedResult;

    final recentActivityResult = compareByRecentActivity(a, b);
    if (recentActivityResult != 0) return recentActivityResult;

    final weeklyTrafficResult = compareByWeeklyTraffic(a, b);
    if (weeklyTrafficResult != 0) return weeklyTrafficResult;

    return ChannelStore.compareChannelsByName(a, b);
  }

  /// Comparator that puts the channel being composed to, before other ones.
  @visibleForTesting
  static int compareByComposingTo(ZulipStream a, ZulipStream b, {
    required int composingToChannelId,
  }) {
    final composingToA = composingToChannelId == a.streamId;
    final composingToB = composingToChannelId == b.streamId;
    return switch((composingToA, composingToB)) {
      (true,  false) => -1,
      (false,  true) =>  1,
      _              =>  0,
    };
  }

  /// Comparator that puts subscribed channels before unsubscribed ones.
  ///
  /// For subscribed channels, it puts them in the following order:
  ///   pinned unmuted > unpinned unmuted > pinned muted > unpinned muted
  @visibleForTesting
  static int compareByBeingSubscribed(ZulipStream a, ZulipStream b) {
    if (a is  Subscription && b is! Subscription) return -1;
    if (a is! Subscription && b is  Subscription) return  1;

    return switch((a, b)) {
      (Subscription(isMuted:  false), Subscription(isMuted:   true)) => -1,
      (Subscription(isMuted:   true), Subscription(isMuted:  false)) =>  1,
      (Subscription(pinToTop:  true), Subscription(pinToTop: false)) => -1,
      (Subscription(pinToTop: false), Subscription(pinToTop:  true)) =>  1,
      _                                                              =>  0,
    };
  }

  /// Comparator that puts recently-active channels before inactive ones.
  ///
  /// Being recently-active is determined by [ZulipStream.isRecentlyActive].
  @visibleForTesting
  static int compareByRecentActivity(ZulipStream a, ZulipStream b) {
    // Compare `stream_list_sort.has_recent_activity` in Zulip web:
    //   https://github.com/zulip/zulip/blob/925ae0f9b/web/src/stream_list_sort.ts#L84-L96
    //
    // There are a few other criteria that Web considers for a channel being
    // recently-active, for which we don't have all the data at the moment:
    //  * If the user don't want to filter out inactive streams to the
    //    bottom, then every channel is considered as recently-active.
    //  * A channel pinned to the top is also considered as recently-active,
    //    but we already favor that criterion before even reaching to this one.
    //  * If the channel is newly subscribed, then it's considered as
    //    recently-active.

    return switch((a.isRecentlyActive, b.isRecentlyActive)) {
      (true, false) => -1,
      (false, true) =>  1,
      // The combination of `null` and `bool` is not possible as they're both
      // either `null` or `bool`, before or after server-10, respectively.
      // TODO(server-10): remove the preceding comment
      _             =>  0,
    };
  }

  /// Comparator that puts channels with more [ZulipStream.streamWeeklyTraffic] first.
  ///
  /// A channel with undefined weekly traffic (`null`) is put after
  /// the channel with weekly traffic defined, but zero and `null`
  /// traffic are considered the same.
  @visibleForTesting
  static int compareByWeeklyTraffic(ZulipStream a, ZulipStream b) {
    return -(a.streamWeeklyTraffic ?? 0).compareTo(b.streamWeeklyTraffic ?? 0);
  }

  @override
  Future<List<ChannelLinkAutocompleteResult>?> computeResults() async {
    final unsorted = <ChannelLinkAutocompleteResult>[];
    if (await filterCandidates(filter: _testChannel,
          candidates: sortedChannels, results: unsorted)) {
      return null;
    }

    return bucketSort(unsorted,
      (r) => r.rank, numBuckets: ChannelLinkAutocompleteQuery._numResultRanks);
  }

  ChannelLinkAutocompleteResult? _testChannel(ChannelLinkAutocompleteQuery query, ZulipStream channel) {
    return query.testChannel(channel, store);
  }
}

/// A #channel autocomplete query, used by [ChannelLinkAutocompleteView].
class ChannelLinkAutocompleteQuery extends ComposeAutocompleteQuery {
  ChannelLinkAutocompleteQuery(super.raw);

  @override
  ChannelLinkAutocompleteView initViewModel({
    required PerAccountStore store,
    required ZulipLocalizations localizations,
    required Narrow narrow,
  }) {
    return ChannelLinkAutocompleteView.init(store: store, query: this, narrow: narrow);
  }

  ChannelLinkAutocompleteResult? testChannel(ZulipStream channel, PerAccountStore store) {
    if (channel.isArchived) return null;

    final cache = store.autocompleteViewManager.autocompleteDataCache;
    final matchQuality = _matchName(
      normalizedName: cache.normalizedNameForChannel(channel),
      normalizedNameWords: cache.normalizedNameWordsForChannel(channel));
    if (matchQuality == null) return null;
    return ChannelLinkAutocompleteResult(
      channelId: channel.streamId, rank: _rankResult(matchQuality));
  }

  /// A measure of a channel result's quality in the context of the query,
  /// from 0 (best) to one less than [_numResultRanks].
  static int _rankResult(NameMatchQuality matchQuality) {
    return switch(matchQuality) {
      NameMatchQuality.exact        => 0,
      NameMatchQuality.totalPrefix  => 1,
      NameMatchQuality.wordPrefixes => 2,
    };
  }

  /// The number of possible values returned by [_rankResult].
  static const _numResultRanks = 3;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'ChannelLinkAutocompleteQuery')}($raw)';
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelLinkAutocompleteQuery && other.raw == raw;
  }

  @override
  int get hashCode => Object.hash('ChannelLinkAutocompleteQuery', raw);
}

/// An autocomplete result for a #channel.
class ChannelLinkAutocompleteResult extends ComposeAutocompleteResult {
  ChannelLinkAutocompleteResult({required this.channelId, required this.rank});

  final int channelId;

  /// A measure of the result's quality in the context of the query.
  ///
  /// Used internally by [ChannelLinkAutocompleteView] for ranking the results.
  // See also [ChannelLinkAutocompleteView._channelsByRelevance];
  // results with equal [rank] will appear in the order they were put in
  // by that method.
  //
  // Compare sort_streams in Zulip web:
  //   https://github.com/zulip/zulip/blob/a5d25826b/web/src/typeahead_helper.ts#L998-L1008
  //
  // Behavior we have that web doesn't and might like to follow:
  // - A "word-prefixes" match quality on channel names:
  //   see [NameMatchQuality.wordPrefixes], which we rank on.
  //
  // Behavior web has that seems undesired, which we don't plan to follow:
  // - A "word-boundary" match quality on channel names:
  //   special rank when the whole query appears contiguously
  //   right after a word-boundary character.
  //   Our [NameMatchQuality.wordPrefixes] seems smarter.
  // - Ranking some case-sensitive matches differently from case-insensitive
  //   matches. Users will expect a lowercase query to be adequate.
  // - Matching and ranking on channel descriptions but only when the query
  //   is present (but not an exact match, total-prefix, or word-boundary match)
  //   in the channel name. This doesn't seem to be helpful in most cases,
  //   because it is hard for a query to be present in the name (the way
  //   mentioned before) and also present in the description.
  final int rank;
}
