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
