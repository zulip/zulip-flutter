import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/settings.dart';
import 'package:zulip/widgets/settings.dart';

import '../model/binding.dart';
import 'test_app.dart';
import '../example_data.dart' as eg;

void main() {
  TestZulipBinding.ensureInitialized();

  testWidgets('Theme setting initial value', (tester) async {

  });

  testWidgets('Update theme setting', (tester) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
    await tester.pumpWidget(TestZulipApp(
      accountId: eg.selfAccount.id,
      child: const SettingsPage()));
    await tester.pump();
    await tester.pump();
    check(testBinding.globalStore.globalSettings.themeSetting).equals(ThemeSetting.unset);

    await tester.tap(find.text('Light'));
    check(testBinding.globalStore.globalSettings.themeSetting).equals(ThemeSetting.light);

    await tester.tap(find.text('Dark'));
    check(testBinding.globalStore.globalSettings.themeSetting).equals(ThemeSetting.dark);
  });
}
