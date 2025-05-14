import 'dart:ui';

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

/// The mapping, of the locales we offer, to their display name in their own
/// locale a.k.a. selfname.
///
/// [ZulipLocalizations.supportedLocales] can include languages that only have
/// a few strings translated.  This map should only inlcude sufficiently
/// translated locales from [ZulipLocalizations.supportedLocales].
///
/// The map should be sorted by selfname, to help users find their
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
///   * [ZulipLocalizations.localeDisplayName], similar helper that looks up the
///     localized display name of a locale in an instance of ZulipLocalizations.
final kSelfnamesByLocale = <Locale, String>{
  Locale('en'): 'English',
  Locale('pl'): 'Polski',
  Locale('ru'): 'Русский',
  Locale('uk'): 'Українська',
};

extension ZulipLocalizationsHelper on ZulipLocalizations {
  /// Look up the localized display name of [locale].
  ///
  /// [locale] must be present in [kSelfnamesByLocale].
  String localeDisplayName(Locale locale) {
    assert(kSelfnamesByLocale.containsKey(locale), 'Locale not found: $locale');
    switch (locale.toLanguageTag()) {
      // When adding a new case, keep this sorted to match the order in
      // [kSelfnamesByLocale].

      case 'en':
        return languageEn;
      case 'pl':
        return languagePl;
      case 'ru':
        return languageRu;
      case 'uk':
        return languageUk;
      default:
        throw ArgumentError.value(locale, 'locale');
    }
  }
}
