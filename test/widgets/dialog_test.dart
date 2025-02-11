import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/dialog.dart';

import '../model/binding.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late BuildContext context;

  const title = "Dialog Title";
  const message = "Dialog message.";

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

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();
      checkErrorDialog(tester, expectedTitle: title, expectedMessage: message);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('user closes error dialog', (tester) async {
      await prepare(tester);

      showErrorDialog(context: context, title: title, message: message);
      await tester.pump();

      final button = checkErrorDialog(tester, expectedTitle: title);
      await tester.tap(find.byWidget(button));
      await tester.pump();
      checkNoDialog(tester);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  group('showSuggestedActionDialog', () {
    const actionButtonText = "Action";

    testWidgets('show suggested action dialog', (tester) async {
      await prepare(tester);

      showSuggestedActionDialog(context: context, title: title, message: message,
        actionButtonText: actionButtonText, onActionButtonPress: () {});
      await tester.pump();

      checkSuggestedActionDialog(tester, expectedTitle: title, expectedMessage: message,
        expectedActionButtonText: actionButtonText);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('user presses action button', (tester) async {
      await prepare(tester);

      var wasPressed = false;
      void onActionButtonPress() {
        wasPressed = true;
      }
      showSuggestedActionDialog(context: context, title: title, message: message,
        actionButtonText: actionButtonText, onActionButtonPress: onActionButtonPress);
      await tester.pump();

      final (actionButton, _) = checkSuggestedActionDialog(tester, expectedTitle: title, 
        expectedMessage: message, expectedActionButtonText: actionButtonText);
      await tester.tap(find.byWidget(actionButton));
      await tester.pump();
      checkNoDialog(tester);
      check(wasPressed).isTrue();
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

    testWidgets('user cancels', (tester) async {
      await prepare(tester);

      var wasPressed = false;
      void onActionButtonPress() {
        wasPressed = true;
      }
      showSuggestedActionDialog(context: context, title: title, message: message,
        actionButtonText: actionButtonText, onActionButtonPress: onActionButtonPress);
      await tester.pump();

      final (_, cancelButton) = checkSuggestedActionDialog(tester, expectedTitle: title,
        expectedMessage: message, expectedActionButtonText: actionButtonText);
      await tester.tap(find.byWidget(cancelButton));
      await tester.pump();
      checkNoDialog(tester);
      check(wasPressed).isFalse();
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });
}
