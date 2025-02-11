import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/dialog.dart';

/// In a widget test, check that showErrorDialog was called with the right text.
///
/// Checks for an error dialog matching an expected title
/// and, optionally, matching an expected message. Fails if none is found.
///
/// On success, returns the widget's "OK" button.
/// Dismiss the dialog by calling `tester.tap(find.byWidget(okButton))`.
Widget checkErrorDialog(WidgetTester tester, {
  required String expectedTitle,
  String? expectedMessage,
}) {
  final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
  tester.widget(find.descendant(matchRoot: true,
    of: find.byWidget(dialog.title!), matching: find.text(expectedTitle)));
  if (expectedMessage != null) {
    tester.widget(find.descendant(matchRoot: true,
      of: find.byWidget(dialog.content!), matching: find.text(expectedMessage)));
  }

  // TODO check "Learn more" button?

  return tester.widget(
    find.descendant(of: find.byWidget(dialog),
      matching: find.widgetWithText(TextButton, 'OK')));
}

// TODO(#996) update this to check for per-platform flavors of alert dialog
/// Checks that there is no dialog.
/// Fails if one is found.
void checkNoDialog(WidgetTester tester) {
  check(find.byType(AlertDialog)).findsNothing();
}

/// In a widget test, check that [showSuggestedActionDialog] was called
/// with the right text.
///
/// Checks for a suggested-action dialog matching an expected title and message.
/// Fails if none is found.
///
/// On success, returns a Record with the widget's action button first
/// and its cancel button second.
/// Tap the action button by calling `tester.tap(find.byWidget(actionButton))`.
(Widget, Widget) checkSuggestedActionDialog(WidgetTester tester, {
  required String expectedTitle,
  required String expectedMessage,
  String? expectedActionButtonText,
}) {
  final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
  tester.widget(find.descendant(matchRoot: true,
    of: find.byWidget(dialog.title!), matching: find.text(expectedTitle)));
  tester.widget(find.descendant(matchRoot: true,
    of: find.byWidget(dialog.content!), matching: find.text(expectedMessage)));

  final actionButton = tester.widget(
    find.descendant(of: find.byWidget(dialog),
      matching: find.widgetWithText(TextButton, expectedActionButtonText ?? 'Continue')));

  final cancelButton = tester.widget(
    find.descendant(of: find.byWidget(dialog),
      matching: find.widgetWithText(TextButton, 'Cancel')));

  return (actionButton, cancelButton);
}
