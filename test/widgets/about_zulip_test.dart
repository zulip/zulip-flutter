import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/about_zulip.dart';

import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../test_clipboard.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  /// Sets up the page; a null [version] means the startup prefetch failed.
  Future<void> prepare(WidgetTester tester, {String? version = '30.0.273'}) async {
    addTearDown(testBinding.reset);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        SystemChannels.platform, MockClipboard().handleMethodCall);
    testBinding.packageInfoResult =
      version == null ? null : eg.packageInfo(version: version);

    await tester.pumpWidget(TestZulipApp(child: const AboutZulipPage()));
    await tester.pump(); // global store loads
  }

  testWidgets('tap app version copies it to the clipboard', (tester) async {
    await prepare(tester, version: '30.0.273');
    check(find.text('30.0.273')).findsOne();

    await tester.tap(find.widgetWithText(ListTile, 'App version'));
    await tester.pump(); // onPressed runs in a post-frame callback
    await tester.pump(Duration.zero);
    check((await Clipboard.getData('text/plain'))!).text.equals('30.0.273');
  });

  testWidgets('banner in place of the app version, when the version is unknown', (tester) async {
    await prepare(tester, version: null);
    check(find.text('App version')).findsNothing();
    check(find.text('The app’s version information was not found.')).findsOne();
  });
}
