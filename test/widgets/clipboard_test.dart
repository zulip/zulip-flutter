import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/widgets/clipboard.dart';

import '../flutter_checks.dart';
import '../model/binding.dart';
import '../test_clipboard.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      MockClipboard().handleMethodCall,
    );
  });

  tearDown(() async {
    testBinding.reset();
  });

  group('copyWithPopup', () {
    Future<void> call(WidgetTester tester, {required String text}) async {
      await tester.pumpWidget(TestZulipApp(
        child: Scaffold(
          body: Builder(builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                copyWithPopup(context: context, successContent: const Text('Text copied'),
                  data: ClipboardData(text: text));
              },
              child: const Text('Copy')))))));
      await tester.pump();
      await tester.tap(find.text('Copy'));
      await tester.pump(); // copy
      await tester.pump(Duration.zero); // await platform info (awkwardly async)
    }

    Future<void> checkSnackBar(WidgetTester tester, {required bool expected}) async {
      if (!expected) {
        check(tester.widgetList(find.byType(SnackBar))).isEmpty();
        return;
      }
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      check(snackBar.behavior).equals(SnackBarBehavior.floating);
      tester.widget(find.descendant(matchRoot: true,
        of: find.byWidget(snackBar.content), matching: find.text('Text copied')));
    }

    Future<void> checkClipboardText(String expected) async {
      check(await Clipboard.getData('text/plain')).isNotNull().text.equals(expected);
    }

    testWidgets('iOS', (tester) async {
      testBinding.deviceInfoResult = const IosDeviceInfo(systemVersion: '16.0');
      await call(tester, text: 'asdf');
      await checkClipboardText('asdf');
      await checkSnackBar(tester, expected: true);
    });

    testWidgets('Android', (tester) async {
      testBinding.deviceInfoResult = const AndroidDeviceInfo(sdkInt: 33, release: '13');
      await call(tester, text: 'asdf');
      await checkClipboardText('asdf');
      await checkSnackBar(tester, expected: false);
    });

    testWidgets('Android <13', (tester) async {
      testBinding.deviceInfoResult = const AndroidDeviceInfo(sdkInt: 32, release: '12');
      await call(tester, text: 'asdf');
      await checkClipboardText('asdf');
      await checkSnackBar(tester, expected: true);
    });
  });
}
