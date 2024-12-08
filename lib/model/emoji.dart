import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/realm.dart';
import 'autocomplete.dart';
import 'narrow.dart';
import 'store.dart';

/// An emoji, described by how to display it in the UI.
sealed class EmojiDisplay {
  /// The emoji's name, as in [Reaction.emojiName].
  final String emojiName;

  EmojiDisplay({required this.emojiName});

  EmojiDisplay resolve(UserSettings? userSettings) { // TODO(server-5)
    if (this is TextEmojiDisplay) return this;
    if (userSettings?.emojiset == Emojiset.text) {
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

  /// Additional Zulip "emoji name" values for this emoji,
  /// to show in the emoji picker UI.
  Iterable<String> get aliases => _aliases ?? const [];
  final List<String>? _aliases;

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
  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
  });

  Iterable<EmojiCandidate> allEmojiCandidates();

  // TODO cut debugServerEmojiData once we can query for lists of emoji;
  //   have tests make those queries end-to-end
  Map<String, List<String>>? get debugServerEmojiData;

  void setServerEmojiData(ServerEmojiData data);
}

/// The implementation of [EmojiStore] that does the work.
///
/// Generally the only code that should need this class is [PerAccountStore]
/// itself.  Other code accesses this functionality through [PerAccountStore],
/// or through the mixin [EmojiStore] which describes its interface.
class EmojiStoreImpl with EmojiStore {
  EmojiStoreImpl({
    required this.realmUrl,
    required this.allRealmEmoji,
  }) : _serverEmojiData = null; // TODO(#974) maybe start from a hard-coded baseline

  /// The same as [PerAccountStore.realmUrl].
  final Uri realmUrl;

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
    final source = Uri.tryParse(sourceUrl);
    if (source == null) return TextEmojiDisplay(emojiName: emojiName);

    Uri? still;
    if (stillUrl != null) {
      still = Uri.tryParse(stillUrl);
      if (still == null) return TextEmojiDisplay(emojiName: emojiName);
    }

    return ImageEmojiDisplay(
      emojiName: emojiName,
      resolvedUrl: realmUrl.resolveUri(source),
      resolvedStillUrl: still == null ? null : realmUrl.resolveUri(still),
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

  List<EmojiCandidate>? _allEmojiCandidates;

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
    // Compare `emoji_picker.rebuild_catalog` in Zulip web;
    // `composebox_typeahead.update_emoji_data` which receives its output;
    // and `emoji.update_emojis` which builds part of its input.
    //   https://github.com/zulip/zulip/blob/0f59e2e78/web/src/emoji_picker.ts#L132-L185
    //   https://github.com/zulip/zulip/blob/0f59e2e78/web/src/composebox_typeahead.ts#L138-L163
    //   https://github.com/zulip/zulip/blob/0f59e2e78/web/src/emoji.ts#L232-L278
    //
    // Behavior differences we might copy or change, TODO:
    //  * Web has a particular ordering of Unicode emoji;
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
    //    like we do after #1112; but in web, this order appears only in the
    //    emoji picker on an empty query, and is otherwise lost even when the
    //    emoji are taken out of their home categories and shown instead
    //    together at the front.
    //
    //    In web on an empty query, :+1: aka :like: comes first, and
    //    :heart: aka :love: comes later (fourth); but then on the query "l",
    //    the results begin with :love: and then :like:.  They've flipped order,
    //    even though they're equally good prefix matches to the query.

    final results = <EmojiCandidate>[];

    final namesOverridden = {
      for (final emoji in activeRealmEmoji) emoji.name,
      'zulip',
    };
    // TODO(log) if _serverEmojiData missing
    for (final entry in (_serverEmojiData ?? {}).entries) {
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

  @override
  Iterable<EmojiCandidate> allEmojiCandidates() {
    return _allEmojiCandidates ??= _generateAllCandidates();
  }

  @override
  void setServerEmojiData(ServerEmojiData data) {
    _serverEmojiData = data.codeToNames;
    _allEmojiCandidates = null;
  }

  void handleRealmEmojiUpdateEvent(RealmEmojiUpdateEvent event) {
    allRealmEmoji = event.realmEmoji;
    _allEmojiCandidates = null;
  }
}

class EmojiAutocompleteView extends AutocompleteView<EmojiAutocompleteQuery, EmojiAutocompleteResult> {
  EmojiAutocompleteView._({required super.store, required super.query});

  factory EmojiAutocompleteView.init({
    required PerAccountStore store,
    required EmojiAutocompleteQuery query,
  }) {
    final view = EmojiAutocompleteView._(store: store, query: query);
    store.autocompleteViewManager.registerEmojiAutocomplete(view);
    return view;
  }

  @override
  Future<List<EmojiAutocompleteResult>?> computeResults() async {
    // TODO(#1068): rank emoji results (popular, realm, other; exact match, prefix, other)
    final results = <EmojiAutocompleteResult>[];
    if (await filterCandidates(filter: _testCandidate,
          candidates: store.allEmojiCandidates(), results: results)) {
      return null;
    }
    return results;
  }

  static EmojiAutocompleteResult? _testCandidate(EmojiAutocompleteQuery query, EmojiCandidate candidate) {
    return query._testCandidate(candidate);
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

  static String _adjustQuery(String raw) {
    return raw.toLowerCase().replaceAll(' ', '_'); // TODO(#1067) remove diacritics too
  }

  @override
  EmojiAutocompleteView initViewModel(PerAccountStore store, Narrow narrow) {
    return EmojiAutocompleteView.init(store: store, query: this);
  }

  EmojiAutocompleteResult? _testCandidate(EmojiCandidate candidate) {
    return matches(candidate) ? EmojiAutocompleteResult(candidate) : null;
  }

  // Compare get_emoji_matcher in Zulip web:shared/src/typeahead.ts .
  @visibleForTesting
  bool matches(EmojiCandidate candidate) {
    if (_adjusted == '') return true;
    if (candidate.emojiDisplay case UnicodeEmojiDisplay(:var emojiUnicode)) {
      if (_adjusted == emojiUnicode) return true;
    }
    return _nameMatches(candidate.emojiName)
      || candidate.aliases.any((alias) => _nameMatches(alias));
  }

  // Compare query_matches_string_in_order in Zulip web:shared/src/typeahead.ts .
  bool _nameMatches(String emojiName) {
    // TODO(#1067) this assumes emojiName is already lower-case (and no diacritics)

    if (!_adjusted.contains(_separator)) {
      // If the query is a single token (doesn't contain a separator),
      // the match can be anywhere in the string.
      return emojiName.contains(_adjusted);
    }

    // If there is a separator in the query, then we
    // require the match to start at the start of a token.
    // (E.g. for 'ab_cd_ef', query could be 'ab_c' or 'cd_ef',
    // but not 'b_cd_ef'.)
    return emojiName.startsWith(_adjusted)
      || emojiName.contains(_sepAdjusted);
  }

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
