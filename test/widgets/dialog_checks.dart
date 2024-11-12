import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows: {
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      tester.widget(find.widgetWithText(Dialog, expectedTitle));
      if (expectedMessage != null) {
        tester.widget(find.widgetWithText(Dialog, expectedMessage));
      }
      return tester.widget(
        find.descendant(of: find.byWidget(dialog),
          matching: find.widgetWithText(TextButton, 'OK')));
    }
    case TargetPlatform.iOS:
    case TargetPlatform.macOS: {
      final dialog = tester.widget<CupertinoAlertDialog>(
        find.byType(CupertinoAlertDialog));
      tester.widget(find.descendant(matchRoot: true,
        of: find.byWidget(dialog.title!), matching: find.text(expectedTitle)));
      if (expectedMessage != null) {
        tester.widget(find.descendant(matchRoot: true,
          of: find.byWidget(dialog.content!), matching: find.text(expectedMessage)));
      }
      return tester.widget(find.descendant(of: find.byWidget(dialog),
        matching: find.widgetWithText(CupertinoDialogAction, 'OK')));
    }
  }
}
