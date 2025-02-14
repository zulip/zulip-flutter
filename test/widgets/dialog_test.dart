import 'package:flutter/material.dart';
import 'package:zulip/widgets/dialog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../model/binding.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late BuildContext context;

  Future<void> prepare(WidgetTester tester) async {
    addTearDown(testBinding.reset);

    await tester.pumpWidget(const TestZulipApp(
      child: Scaffold(body: Placeholder())));
    await tester.pump();
    context = tester.element(find.byType(Placeholder));
  }

  group('showErrorDialog', () {
    testWidgets('show error dialog', (tester) async {
      await prepare(tester);
      
      String title = "Dialog Title";
      String message = "Dialog message.";

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();
      checkErrorDialog(tester, expectedTitle: title, expectedMessage: message);

    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  group('showSuggestedActionDialog', () {
    testWidgets('show suggested action dialog', (tester) async {
      await prepare(tester);

      String title = "Dialog Title";
      String message = "Dialog message.";
      String actionButtonText = "Action";
      
      showSuggestedActionDialog(context: context, title: title, message: message,
        actionButtonText: actionButtonText, onActionButtonPress: () {});
      await tester.pump();
      checkSuggestedActionDialog(tester, expectedTitle: title, expectedMessage: message,
        expectedActionButtonText: actionButtonText);
      
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });
}
