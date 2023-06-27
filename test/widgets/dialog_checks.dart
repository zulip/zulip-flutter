import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  return tester.widget(
    find.descendant(of: find.byWidget(dialog),
      matching: find.widgetWithText(TextButton, 'OK')));
}
