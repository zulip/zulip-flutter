import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/realm.dart';

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

/// The portion of [PerAccountStore] describing what emoji exist.
mixin EmojiStore {
  /// The realm's custom emoji (for [ReactionType.realmEmoji],
  /// indexed by [Reaction.emojiCode].
  Map<String, RealmEmojiItem> get realmEmoji;

  EmojiDisplay emojiDisplayFor({
    required ReactionType emojiType,
    required String emojiCode,
    required String emojiName,
  });

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
    required this.realmEmoji,
  }) : _serverEmojiData = null; // TODO(#974) maybe start from a hard-coded baseline

  /// The same as [PerAccountStore.realmUrl].
  final Uri realmUrl;

  @override
  Map<String, RealmEmojiItem> realmEmoji;

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
        final item = realmEmoji[emojiCode];
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

  @override
  void setServerEmojiData(ServerEmojiData data) {
    _serverEmojiData = data.codeToNames;
  }

  void handleRealmEmojiUpdateEvent(RealmEmojiUpdateEvent event) {
    realmEmoji = event.realmEmoji;
  }
}
