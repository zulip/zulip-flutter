import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/about_zulip.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  /// Sets up the page; a null [version] means the startup prefetch failed.
  Future<void> prepare(WidgetTester tester, {String? version = '30.0.273'}) async {
    addTearDown(testBinding.reset);
    testBinding.packageInfoResult =
      version == null ? null : eg.packageInfo(version: version);

    await tester.pumpWidget(TestZulipApp(child: const AboutZulipPage()));
    await tester.pump(); // global store loads
  }

  testWidgets('banner in place of the app version, when the version is unknown', (tester) async {
    await prepare(tester, version: null);
    check(find.text('App version')).findsNothing();
    check(find.text('The app’s version information was not found.')).findsOne();
  });
}
