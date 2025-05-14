import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/generated/l10n/zulip_localizations.dart';
import 'package:zulip/model/localizations.dart';

void main() {
  test('kSelfnamesByLocale', () {
    for (final locale in kSelfnamesByLocale.keys) {
      check(ZulipLocalizations.supportedLocales).contains(locale);
    }
  });

  test('localeDisplayName only returns for all keys in kSelfnamesByLocale', () {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    for (final locale in ZulipLocalizations.supportedLocales) {
      kSelfnamesByLocale.containsKey(locale)
        ? check(() =>
            zulipLocalizations.localeDisplayName(locale)).returnsNormally()
        : check(() =>
            zulipLocalizations.localeDisplayName(locale)).throws<void>();
    }
  });
}
