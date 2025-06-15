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

  test('languages', () {
    final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
    for (final (locale, selfname, _) in zulipLocalizations.languages()) {
      check(ZulipLocalizations.supportedLocales).contains(locale);
      check(kSelfnamesByLocale)[locale].isNotNull().equals(selfname);
    }
  });
}
