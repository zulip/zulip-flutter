import 'dart:ui';

import 'package:collection/collection.dart';

import '../generated/l10n/zulip_localizations.dart';

abstract final class GlobalLocalizations {
  /// The [ZulipLocalizations] for the user's chosen language and locale.
  ///
  /// Where possible, the [ZulipLocalizations] should be acquired
  /// through [ZulipLocalizations.of] instead, using a [BuildContext].
  /// This static field is to be used where access to a [BuildContext]
  /// is impractical, such as in the API bindings
  /// (which use localizations when throwing exceptions).
  ///
  /// This gets set during app startup once we have the user's choice of locale.
  /// If accessed before that point, it uses the app's first supported locale,
  /// namely 'en'.
  static ZulipLocalizations zulipLocalizations =
    lookupZulipLocalizations(ZulipLocalizations.supportedLocales.first);
}

extension ZulipLocalizationsHelper on ZulipLocalizations {
  /// Returns a list of the locales we offer, with their display name in their
  /// own locale a.k.a. selfname, and the display name localized in this
  /// [ZulipLocalizations] instance.
  ///
  /// This list only includes some of [ZulipLocalizations.supportedLocales];
  /// it includes languages that have substantially complete translations.
  /// For what counts as substantially translated, see docs/translation.md.
  ///
  /// The list should be sorted by selfname, to help users find their
  /// language in the UI.  When in doubt how to sort (like between different
  /// scripts, or in scripts you don't know), try to match the order found in
  /// other UIs, like for choosing a language in your phone's system settings.
  ///
  /// For the values of selfname, consult Wikipedia:
  ///   https://meta.wikimedia.org/wiki/List_of_Wikipedias
  ///   https://en.wikipedia.org/wiki/Special:Preferences
  /// or better yet, Wikipedia's own mobile UIs.  Wikipedia is a very
  /// conscientiously international and intercultural project with a lot of
  /// effort going into it by speakers of many languages, which makes it a
  /// useful gold standard for this.
  ///
  /// This is adapted from:
  ///   https://github.com/zulip/zulip-mobile/blob/91f5c3289/src/settings/languages.js
  ///
  /// See also:
  ///   * [kSelfnamesByLocale], a map for looking up the selfname of a locale,
  ///     when its [ZulipLocalizations]-specific displayName is not needed.
  List<Language> languages() {
    return [
      (Locale('en'), 'English', languageEn),
      (Locale('pl'), 'Polski', languagePl),
      (Locale('ru'), 'Русский', languageRu),
      (Locale('uk'), 'Українська', languageUk),
    ];
  }
}

typedef Language = (Locale locale, String selfname, String displayName);

/// The map, of the locales we offer, to their display name in their own
/// locale a.k.a. selfname.
///
/// See also:
///   * [ZulipLocalizations.languages], similar helper that returns
///     a list of locales with their localized display name in that
///     [ZulipLocalizations] instance and their selfname.
final kSelfnamesByLocale = UnmodifiableMapView(_selfnamesByLocale);
final _selfnamesByLocale = {
  // While [ZulipLocalizations.languages]' result will be different depending
  // on the language setting, `locale` and `selfname` are the same for all
  // languages.  This makes it fine to generate this map from
  // [GlobalLocalizations.zulipLocalizations],
  // despite it being a mutable static field.
  for (final (locale, selfname, _)
       in GlobalLocalizations.zulipLocalizations.languages())
    locale: selfname,
};
