import '../generated/l10n/zulip_localizations.dart';

abstract final class GlobalLocalizations {
  static ZulipLocalizations zulipLocalizations =
    lookupZulipLocalizations(ZulipLocalizations.supportedLocales.first);
}
