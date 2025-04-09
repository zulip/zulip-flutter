import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/widgets/dialog.dart';

import '../model/binding.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('showErrorDialog', () {
    testWidgets('tap "Learn more" button', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      showErrorDialog(context: element, title: 'hello',
        learnMoreButtonUrl: Uri.parse('https://foo.example'));
      await tester.pump();
      await tester.tap(find.text('Learn more'));
      check(testBinding.takeLaunchUrlCalls()).single.equals((
        url: Uri.parse('https://foo.example'),
        mode: LaunchMode.inAppBrowserView));
    });
  });

  group('showSuggestedActionDialog', () {
    testWidgets('tap action button', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      final dialog = showSuggestedActionDialog(context: element,
        title: 'Continue?',
        message: 'Do the thing?',
        actionButtonText: 'Sure');
      await tester.pump();
      await tester.tap(find.text('Sure'));
      await check(dialog.result).completes((it) => it.equals(true));
    });

    testWidgets('tap cancel', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      final dialog = showSuggestedActionDialog(context: element,
        title: 'Continue?',
        message: 'Do the thing?',
        actionButtonText: 'Sure');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await check(dialog.result).completes((it) => it.equals(null));
    });

    testWidgets('tap outside dialog area', (tester) async {
      addTearDown(testBinding.reset);
      await tester.pumpWidget(TestZulipApp());
      await tester.pump();
      final element = tester.element(find.byType(Placeholder));

      final dialog = showSuggestedActionDialog(context: element,
        title: 'Continue?',
        message: 'Do the thing?',
        actionButtonText: 'Sure');
      await tester.pump();
      await tester.tapAt(tester.getTopLeft(find.byType(TestZulipApp)));
      await check(dialog.result).completes((it) => it.equals(null));
    });
  });
}
