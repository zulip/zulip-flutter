import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

abstract final class GlobalLocalizations {
  static ZulipLocalizations zulipLocalizations =
    lookupZulipLocalizations(ZulipLocalizations.supportedLocales.first);
}
