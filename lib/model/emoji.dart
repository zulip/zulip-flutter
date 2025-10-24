import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/realm.dart';
import '../generated/l10n/zulip_localizations.dart';
import 'algorithms.dart';
import 'autocomplete.dart';
import 'narrow.dart';
import 'store.dart';

/// An emoji, described by how to display it in the UI.
sealed class EmojiDisplay {
  /// The emoji's name, as in [Reaction.emojiName].
  final String emojiName;

  EmojiDisplay({required this.emojiName});

  EmojiDisplay resolve(UserSettings userSettings) {
    if (this is TextEmojiDisplay) return this;
    if (userSettings.emojiset == Emojiset.text) {
      return TextEmojiDisplay(emojiName: emojiName);
    }
    return this;
  }
}

/// An emoji to display as Unicode text, relying on an emoji font.
class UnicodeEmojiDisplay extends EmojiDisplay {
  /// The actual Unicode text representing this emoji; for example, "🙂".
  final String emojiUnicode;

  UnicodeEmojiDisplay({required super.emojiName, required this.emojiUnicode});
}

/// An emoji to display as an image.
class ImageEmojiDisplay extends EmojiDisplay {
  /// An absolute URL for the emoji's image file.
  final Uri resolvedUrl;

  /// An absolute URL for a still version of the emoji's image file;
  /// compare [RealmEmojiItem.stillUrl].
  final Uri? resolvedStillUrl;

  ImageEmojiDisplay({
    required super.emojiName,
    required this.resolvedUrl,
    required this.resolvedStillUrl,
  });
}

/// An emoji to display as its name, in plain text.
///
/// We do this based on a user preference,
/// and as a fallback when the Unicode or image approaches fail.
class TextEmojiDisplay extends EmojiDisplay {
  TextEmojiDisplay({required super.emojiName});
}

/// An emoji that might be offered in an emoji picker UI.
final class EmojiCandidate {
  /// The Zulip "emoji type" for this emoji.
  final ReactionType emojiType;

  /// The Zulip "emoji code" for this emoji.
  ///
  /// This is the value that would appear in [Reaction.emojiCode].
  final String emojiCode;

  /// The Zulip "emoji name" to use for this emoji.
  ///
  /// This might not be the only name this emoji has; see [aliases].
  final String emojiName;

  /// [emojiName], but via [AutocompleteQuery.lowercaseAndStripDiacritics]
  /// to support fuzzy matching.
  String get normalizedEmojiName => _normalizedEmojiName
    ??= AutocompleteQuery.lowercaseAndStripDiacritics(emojiName);
  String? _normalizedEmojiName;

  /// Additional Zulip "emoji name" values for this emoji,
  /// to show in the emoji picker UI.
  Iterable<String> get aliases => _aliases ?? const [];
  final List<String>? _aliases;

  /// [aliases], but via [AutocompleteQuery.lowercaseAndStripDiacritics]
  /// to support fuzzy matching.
  Iterable<String> get normalizedAliases => _normalizedAliases
    ??= aliases.map((alias) => AutocompleteQuery.lowercaseAndStripDiacritics(alias));
  Iterable<String>? _normalizedAliases;

  final EmojiDisplay emojiDisplay;

  EmojiCandidate({
    required this.emojiType,
    required this.emojiCode,
    required this.emojiName,
    required List<String>? aliases,
    required this.emojiDisplay,
  }) : _aliases = aliases;

  /// Used for implementing [toString] and [EmojiAutocompleteResult.toString].
  String description() {
    final typeLabel = emojiType.name.replaceFirst(RegExp(r'Emoji$'), '');
    return '$typeLabel $emojiCode $emojiName'
      '${aliases.isNotEmpty ? ' $aliases' : ''}';
  }

  @override
  String toString() {
    return 'EmojiCandidate(${description()})';
  }
}

/// The portion of [PerAccountStore] describing what emoji exist.
mixin EmojiStore {
  /// An [EmojiDisplay] for the specified emoji.
  ///
  /// Use [EmojiDisplay.resolve] on the result to apply the user's [Emojiset]
  /// setting.
  ///
  /// May be a [TextEmojiDisplay] even if the emojiset is not [Emojiset.text];
  /// this happens when we can't understand the data that describes the emoji
  /// (e.g. when an image emoji's URL doesn't parse)..
  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
  });

  /// Zulip's list of "popular" emoji, to be given precedence in
  /// offering to users.
  ///
  /// See description in the web code:
  ///   https://github.com/zulip/zulip/blob/83a121c7e/web/shared/src/typeahead.ts#L3-L21
  Iterable<EmojiCandidate> popularEmojiCandidates();

  Iterable<EmojiCandidate> allEmojiCandidates();

  String? getUnicodeEmojiNameByCode(String emojiCode);

  // TODO cut debugServerEmojiData once we can query for lists of emoji;
  //   have tests make those queries end-to-end
  Map<String, List<String>>? get debugServerEmojiData;
}

mixin ProxyEmojiStore on EmojiStore {
  @protected
  EmojiStore get emojiStore;

  @override
  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName
  }) {
    return emojiStore.emojiDisplayFor(
      emojiType: emojiType, emojiCode: emojiCode, emojiName: emojiName);
  }

  @override
  Iterable<EmojiCandidate> popularEmojiCandidates() => emojiStore.popularEmojiCandidates();

  @override
  Iterable<EmojiCandidate> allEmojiCandidates() => emojiStore.allEmojiCandidates();

  @override
  String? getUnicodeEmojiNameByCode(String emojiCode) =>
    emojiStore.getUnicodeEmojiNameByCode(emojiCode);

  @override
  Map<String, List<String>>? get debugServerEmojiData => emojiStore.debugServerEmojiData;
}

/// The implementation of [EmojiStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [EmojiStore] which describes its interface.
class EmojiStoreImpl extends PerAccountStoreBase with EmojiStore {
  EmojiStoreImpl({
    required super.core,
    required this.allRealmEmoji,
  }) : _serverEmojiData = null; // TODO(#974) maybe start from a hard-coded baseline

  /// The realm's custom emoji, indexed by their [RealmEmojiItem.emojiCode],
  /// including deactivated emoji not available for new uses.
  ///
  /// These are the emoji that can have [ReactionType.realmEmoji].
  ///
  /// For emoji available to be newly used, see [activeRealmEmoji].
  Map<String, RealmEmojiItem> allRealmEmoji;

  /// The realm's custom emoji that are available for new uses
  /// in messages and reactions.
  Iterable<RealmEmojiItem> get activeRealmEmoji {
    return allRealmEmoji.values.where((emoji) => !emoji.deactivated);
  }

  /// The realm-relative URL of the unique "Zulip extra emoji", :zulip:.
  static const kZulipEmojiUrl = '/static/generated/emoji/images/emoji/unicode/zulip.png';

  @override
  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
  }) {
    switch (emojiType) {
      case ReactionType.unicodeEmoji:
        final parsed = tryParseEmojiCodeToUnicode(emojiCode);
        if (parsed == null) break;
        return UnicodeEmojiDisplay(emojiName: emojiName, emojiUnicode: parsed);

      case ReactionType.realmEmoji:
        final item = allRealmEmoji[emojiCode];
        if (item == null) break;
        // TODO we don't check emojiName matches the known realm emoji; is that right?
        return _tryImageEmojiDisplay(
          sourceUrl: item.sourceUrl, stillUrl: item.stillUrl,
          emojiName: emojiName);

      case ReactionType.zulipExtraEmoji:
        return _tryImageEmojiDisplay(
          sourceUrl: kZulipEmojiUrl, stillUrl: null, emojiName: emojiName);
    }
    return TextEmojiDisplay(emojiName: emojiName);
  }

  EmojiDisplay _tryImageEmojiDisplay({
    required String sourceUrl,
    required String? stillUrl,
    required String emojiName,
  }) {
    final resolvedUrl = this.tryResolveUrl(sourceUrl);
    if (resolvedUrl == null) return TextEmojiDisplay(emojiName: emojiName);

    Uri? resolvedStillUrl;
    if (stillUrl != null) {
      resolvedStillUrl = this.tryResolveUrl(stillUrl);
      if (resolvedStillUrl == null) return TextEmojiDisplay(emojiName: emojiName);
    }

    return ImageEmojiDisplay(
      emojiName: emojiName,
      resolvedUrl: resolvedUrl,
      resolvedStillUrl: resolvedStillUrl,
    );
  }

  @override
  Map<String, List<String>>? get debugServerEmojiData => _serverEmojiData;

  /// The server's list of Unicode emoji and names for them,
  /// from [ServerEmojiData].
  ///
  /// This is null until [UpdateMachine.fetchEmojiData] finishes
  /// retrieving the data.
  Map<String, List<String>>? _serverEmojiData;

  List<EmojiCandidate>? _popularCandidates;

  @override
  Iterable<EmojiCandidate> popularEmojiCandidates() {
    return _popularCandidates ??= _generatePopularCandidates();
  }

  List<EmojiCandidate> _generatePopularCandidates() {
    EmojiCandidate candidate(String emojiCode, List<String> names) {
      final [emojiName, ...aliases] = names;
      final emojiUnicode = tryParseEmojiCodeToUnicode(emojiCode)!;
      return EmojiCandidate(emojiType: ReactionType.unicodeEmoji,
        emojiCode: emojiCode, emojiName: emojiName, aliases: aliases,
        emojiDisplay: UnicodeEmojiDisplay(
          emojiName: emojiName, emojiUnicode: emojiUnicode));
    }
    if (_serverEmojiData == null) return [];

    final result = <EmojiCandidate>[];
    for (final emojiCode in _popularEmojiCodesList) {
      final names = _serverEmojiData![emojiCode];
      if (names == null) continue; // TODO(log)
      result.add(candidate(emojiCode, names));
    }
    return result;
  }

  /// Codes for the popular emoji, in order; all are Unicode emoji.
  // This list should match web:
  //   https://github.com/zulip/zulip/blob/9feba0f16/web/shared/src/typeahead.ts#L22-L29
  static final List<String> _popularEmojiCodesList = (() {
    String check(String emojiCode, String emojiUnicode) {
      assert(emojiUnicode == tryParseEmojiCodeToUnicode(emojiCode));
      return emojiCode;
    }
    return [
      check('1f44d', '👍'),
      check('1f389', '🎉'),
      check('1f642', '🙂'),
      check('2764', '❤'),
      check('1f6e0', '🛠'),
      check('1f419', '🐙'),
    ];
  })();

  static final Set<String> _popularEmojiCodes = Set.of(_popularEmojiCodesList);

  static bool _isPopularEmoji(EmojiCandidate candidate) {
    return candidate.emojiType == ReactionType.unicodeEmoji
      && _popularEmojiCodes.contains(candidate.emojiCode);
  }

  EmojiCandidate _emojiCandidateFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
    required List<String>? aliases,
  }) {
    return EmojiCandidate(
      emojiType: emojiType, emojiCode: emojiCode, emojiName: emojiName,
      aliases: aliases,
      emojiDisplay: emojiDisplayFor(
        emojiType: emojiType, emojiCode: emojiCode, emojiName: emojiName));
  }

  List<EmojiCandidate> _generateAllCandidates() {
    // See also [EmojiAutocompleteQuery._rankResult];
    // that ranking takes precedence over the order of this list.
    //
    // Compare `emoji_picker.rebuild_catalog` in Zulip web;
    // `composebox_typeahead.update_emoji_data` which receives its output;
    // and `emoji.update_emojis` which builds part of its input.
    //   https://github.com/zulip/zulip/blob/0f59e2e78/web/src/emoji_picker.ts#L132-L185
    //   https://github.com/zulip/zulip/blob/0f59e2e78/web/src/composebox_typeahead.ts#L138-L163
    //   https://github.com/zulip/zulip/blob/0f59e2e78/web/src/emoji.ts#L232-L278
    //
    // Behavior differences we might copy or change, TODO:
    //  * TODO(#1201) Web has a particular ordering of Unicode emoji;
    //    a data file groups them by category and orders within each of those,
    //    and the code has a list of categories.
    //    This seems useful; it'll call for expanding the server emoji data API.
    //  * Both here and in web, the realm emoji appear in whatever order the
    //    server returned them in; and that order appears to be random,
    //    presumably the iteration order of some Python dict,
    //    and to vary over time.
    //
    // Behavior differences that web should probably fix, TODO(web):
    //  * Web ranks the realm's custom emoji (and the Zulip extra emoji) at the
    //    end of the base list, as seen in the emoji picker on an empty query;
    //    but then ranks them first, after only the six "popular" emoji,
    //    once there's a non-empty query.
    //  * Web gives the six "popular" emoji a set order amongst themselves,
    //    like we do here; but in web, this order appears only in the
    //    emoji picker on an empty query, and is otherwise lost even when the
    //    emoji are taken out of their home categories and shown instead
    //    together at the front.
    //
    //    In web on an empty query, :+1: aka :like: comes first, and
    //    :heart: aka :love: comes later (fourth); but then on the query "l",
    //    the results begin with :love: and then :like:.  They've flipped order,
    //    even though they're equally good prefix matches to the query.

    final results = <EmojiCandidate>[];

    // Include the "popular" emoji, in their canonical order
    // relative to each other.
    results.addAll(popularEmojiCandidates());

    final namesOverridden = {
      for (final emoji in activeRealmEmoji) emoji.name,
      'zulip',
    };
    // TODO(log) if _serverEmojiData missing
    for (final entry in (_serverEmojiData ?? {}).entries) {
      if (_popularEmojiCodes.contains(entry.key)) continue;

      final allNames = entry.value;
      final String emojiName;
      final List<String>? aliases;
      if (allNames.any(namesOverridden.contains)) {
        final names = allNames.whereNot(namesOverridden.contains).toList();
        if (names.isEmpty) continue;
        emojiName = names.removeAt(0);
        aliases = names;
      } else {
        // Most emoji aren't overridden, so avoid copying the list.
        emojiName = allNames.first;
        aliases = allNames.length > 1 ? allNames.sublist(1) : null;
      }
      results.add(_emojiCandidateFor(
        emojiType: ReactionType.unicodeEmoji,
        emojiCode: entry.key, emojiName: emojiName,
        aliases: aliases));
    }

    for (final emoji in activeRealmEmoji) {
      final emojiName = emoji.name;
      if (emojiName == 'zulip') {
        // :zulip: overrides realm emoji; compare web's `emoji.update_emojis`.
        continue;
      }
      results.add(_emojiCandidateFor(
        emojiType: ReactionType.realmEmoji,
        emojiCode: emoji.emojiCode, emojiName: emojiName,
        aliases: null));
    }

    results.add(_emojiCandidateFor(
      emojiType: ReactionType.zulipExtraEmoji,
      emojiCode: 'zulip', emojiName: 'zulip',
      aliases: null));

    return results;
  }

  List<EmojiCandidate>? _allEmojiCandidates;

  @override
  Iterable<EmojiCandidate> allEmojiCandidates() {
    return _allEmojiCandidates ??= _generateAllCandidates();
  }

  @override
  String? getUnicodeEmojiNameByCode(String emojiCode) =>
    _serverEmojiData?[emojiCode]?.first; // TODO(log) if null

  void setServerEmojiData(ServerEmojiData data) {
    _serverEmojiData = data.codeToNames;
    _popularCandidates = null;
    _allEmojiCandidates = null;
  }

  void handleRealmEmojiUpdateEvent(RealmEmojiUpdateEvent event) {
    allRealmEmoji = event.realmEmoji;
    _allEmojiCandidates = null;
  }
}

/// The quality of an emoji's match to an autocomplete query.
enum EmojiMatchQuality {
  /// The query matches the whole emoji name (or the literal emoji itself).
  exact,

  /// The query matches a prefix of the emoji name, but not the whole name.
  prefix,

  /// The query matches starting at the start of a word in the emoji name,
  /// but not the start of the whole name.
  ///
  /// For example a name "ab_cd_ef" would match queries "c" or "cd_e"
  /// at this level, but not a query "b_cd_ef".
  wordAligned,

  /// The query matches somewhere in the emoji name,
  /// but not at the start of any word.
  other;

  /// The best possible quality of match.
  static const best = exact;

  /// The better of the two given qualities of match,
  /// where null represents no match at all.
  static EmojiMatchQuality? bestOf(EmojiMatchQuality? a, EmojiMatchQuality? b) {
    if (b == null) return a;
    if (a == null) return b;
    return compare(a, b) <= 0 ? a : b;
  }

  /// Comparator that puts better matches first.
  static int compare(EmojiMatchQuality a, EmojiMatchQuality b) {
    return Enum.compareByIndex(a, b);
  }
}

class EmojiAutocompleteView extends AutocompleteView<EmojiAutocompleteQuery, EmojiAutocompleteResult> {
  EmojiAutocompleteView._({required super.store, required super.query});

  factory EmojiAutocompleteView.init({
    required PerAccountStore store,
    required EmojiAutocompleteQuery query,
  }) {
    return EmojiAutocompleteView._(store: store, query: query);
  }

  @override
  Future<List<EmojiAutocompleteResult>?> computeResults() async {
    final unsorted = <EmojiAutocompleteResult>[];
    if (await filterCandidates(filter: _testCandidate,
          candidates: store.allEmojiCandidates(), results: unsorted)) {
      return null;
    }
    return bucketSort(unsorted,
      (r) => r.rank, numBuckets: EmojiAutocompleteQuery._numResultRanks);
  }

  static EmojiAutocompleteResult? _testCandidate(EmojiAutocompleteQuery query, EmojiCandidate candidate) {
    return query.testCandidate(candidate);
  }
}

class EmojiAutocompleteQuery extends ComposeAutocompleteQuery {
  factory EmojiAutocompleteQuery(String raw)
    => EmojiAutocompleteQuery._(raw, _adjustQuery(raw));

  EmojiAutocompleteQuery._(super.raw, String adjusted)
    : _adjusted = adjusted,
      _sepAdjusted = _separator + adjusted;

  /// The query string as adjusted for comparing to emoji names,
  /// via [_adjustQuery].
  final String _adjusted;

  /// The concatenation of [_separator] with [_adjusted].
  ///
  /// Useful for finding word-aligned matches in an emoji name.
  final String _sepAdjusted;

  static const _separator = '_';

  static String _adjustQuery(String raw) =>
    AutocompleteQuery.lowercaseAndStripDiacritics(raw.replaceAll(' ', '_'));

  @override
  EmojiAutocompleteView initViewModel({
    required PerAccountStore store,
    required ZulipLocalizations localizations,
    required Narrow narrow,
  }) {
    return EmojiAutocompleteView.init(store: store, query: this);
  }

  @visibleForTesting
  EmojiAutocompleteResult? testCandidate(EmojiCandidate candidate) {
    final matchQuality = match(candidate);
    if (matchQuality == null) return null;
    return EmojiAutocompleteResult(candidate,
      _rankResult(matchQuality, candidate));
  }

  // Compare get_emoji_matcher in Zulip web:shared/src/typeahead.ts .
  @visibleForTesting
  EmojiMatchQuality? match(EmojiCandidate candidate) {
    if (_adjusted == '') return EmojiMatchQuality.prefix;

    if (candidate.emojiDisplay case UnicodeEmojiDisplay(:var emojiUnicode)) {
      if (_adjusted == emojiUnicode) {
        return EmojiMatchQuality.exact;
      }
    }

    EmojiMatchQuality? result = _matchName(candidate.normalizedEmojiName);
    for (final normalizedAlias in candidate.normalizedAliases) {
      if (result == EmojiMatchQuality.best) return result;
      result = EmojiMatchQuality.bestOf(result, _matchName(normalizedAlias));
    }
    return result;
  }

  EmojiMatchQuality? _matchName(String normalizedName) {
    // Compare query_matches_string_in_order in Zulip web:shared/src/typeahead.ts
    // for a Boolean version of this logic (match vs. no match),
    // and triage_raw in the same file web:shared/src/typeahead.ts
    // for the finer distinctions.
    // See also commentary in [_rankResult].

    if (normalizedName == _adjusted)           return EmojiMatchQuality.exact;
    if (normalizedName.startsWith(_adjusted))  return EmojiMatchQuality.prefix;
    if (normalizedName.contains(_sepAdjusted)) return EmojiMatchQuality.wordAligned;
    if (!_adjusted.contains(_separator)) {
      // If the query is a single token (doesn't contain a separator),
      // allow a match anywhere in the string, too.
      if (normalizedName.contains(_adjusted))  return EmojiMatchQuality.other;
    } else {
      // Otherwise, require at least a word-aligned match.
    }
    return null;
  }

  /// A measure of the result's quality in the context of the query,
  /// ranked from 0 (best) to one less than [_numResultRanks].
  static int _rankResult(EmojiMatchQuality matchQuality, EmojiCandidate candidate) {
    // See also [EmojiStoreImpl._generateAllCandidates];
    // emoji which this function ranks equally
    // will appear in the order they were put in by that method.
    //
    // Compare sort_emojis in Zulip web:
    //   https://github.com/zulip/zulip/blob/83a121c7e/web/shared/src/typeahead.ts#L322-L382
    //
    // Behavior differences we might copy, TODO:
    //  * Web ranks each name of a Unicode emoji separately.
    //  * Web recognizes a word-aligned match starting after [ /-] as well as [_].
    //
    // Behavior differences that web should probably fix, TODO(web):
    //  * Among popular emoji with non-exact matches,
    //    web doesn't prioritize prefix over word-aligned; we do.
    //    (This affects just one case: for query "o",
    //    we put :octopus: before :working_on_it:.)
    //  * Web only counts an emoji as "popular" for ranking if the query
    //    is a prefix of a single word in the name; so "thumbs_" or "working_on_i"
    //    lose the ranking boost for :thumbs_up: and :working_on_it: respectively.
    //  * Web starts with only case-sensitive exact matches ("perfect matches"),
    //    and puts case-insensitive exact matches just ahead of prefix matches;
    //    it also distinguishes prefix matches by case-sensitive vs. not.
    //    We use case-insensitive matches throughout;
    //    case seems unhelpful for emoji search.
    //  * Web suppresses Unicode emoji names shadowed by a realm emoji
    //    only if the latter is also a match for the query.  That mostly works,
    //    because emoji with the same name will mostly both match or both not;
    //    but it breaks if the Unicode emoji was a literal match.

    final isPopular = EmojiStoreImpl._isPopularEmoji(candidate);
    final isCustomEmoji = switch (candidate.emojiType) {
      // The web implementation calls this condition `is_realm_emoji`,
      // but its actual semantics is it's true for the Zulip extra emoji too.
      // See `zulip_emoji` in web:src/emoji.ts .
      ReactionType.realmEmoji || ReactionType.zulipExtraEmoji => true,
      ReactionType.unicodeEmoji => false,
    };
    return switch (matchQuality) {
      EmojiMatchQuality.exact       => 0,
      EmojiMatchQuality.prefix      => isPopular ? 1 : isCustomEmoji ? 3 : 5,
      EmojiMatchQuality.wordAligned => isPopular ? 2 : isCustomEmoji ? 4 : 6,
      EmojiMatchQuality.other       =>                 isCustomEmoji ? 7 : 8,
    };
  }

  /// The number of possible values returned by [_rankResult].
  static const _numResultRanks = 9;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'EmojiAutocompleteQuery')}($raw)';
  }

  @override
  bool operator ==(Object other) {
    return other is EmojiAutocompleteQuery && other.raw == raw;
  }

  @override
  int get hashCode => Object.hash('EmojiAutocompleteQuery', raw);
}
