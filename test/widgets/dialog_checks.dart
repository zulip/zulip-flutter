import 'package:checks/checks.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/dialog.dart';

/// In a widget test, check that [showErrorDialog] was called with the right text.
///
/// Checks for an error dialog matching an expected title
/// and, optionally, matching an expected message. Fails if none is found.
///
/// On success, returns the widget's "OK" button.
/// Dismiss the dialog by calling `tester.tap(find.byWidget(okButton))`.
///
/// See also:
///  - [checkNoDialog]
Widget checkErrorDialog(WidgetTester tester, {
  required String expectedTitle,
  String? expectedMessage,
}) {
  // TODO if a dialog was found but it doesn't match expectations,
  //   show its details; see checkNoDialog for how to do that
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      final dialog = tester.widget<AlertDialog>(find.bySubtype<AlertDialog>());
      tester.widget(find.descendant(matchRoot: true,
        of: find.byWidget(dialog.title!), matching: find.text(expectedTitle)));
      if (expectedMessage != null) {
        tester.widget(find.descendant(matchRoot: true,
          of: find.byWidget(dialog.content!), matching: find.text(expectedMessage)));
      }
      return tester.widget(find.descendant(of: find.byWidget(dialog),
        matching: find.widgetWithText(TextButton, 'OK')));

    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      final dialog = tester.widget<CupertinoAlertDialog>(find.byType(CupertinoAlertDialog));
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


/// In a widget test, check that there aren't any alert dialogs.
///
/// See also:
///  - [checkErrorDialog]
void checkNoDialog(WidgetTester tester) {
  final List<Widget> alertDialogs = [
    ...tester.widgetList(find.bySubtype<AlertDialog>()),
    ...tester.widgetList(find.byType(CupertinoAlertDialog)),
  ];

  if (alertDialogs.isNotEmpty) {
    final message = StringBuffer()..write('Found dialog(s) when none were expected:\n');
    for (final alertDialog in alertDialogs) {
      final (title, content) = switch (alertDialog) {
        AlertDialog()          => (alertDialog.title, alertDialog.content),
        CupertinoAlertDialog() => (alertDialog.title, alertDialog.content),
        _ => throw UnimplementedError(),
      };

      message.write('Dialog:\n'
                 '  title: ${title is Text ? title.data : title.toString()}\n');

      if (content != null) {
        final contentTexts = tester.widgetList<Text>(find.descendant(
          matchRoot: true,
          of: find.byWidget(content),
          matching: find.byType(Text)));
        message.write('  content: ');
        if (contentTexts.isNotEmpty) {
          message.write(contentTexts.map((t) => t.data).join('\n    '));
        } else {
          // (Could show more detail here as necessary.)
          message.write(content.toString());
        }
      }
    }
    throw TestFailure(message.toString());
  }

  check(find.byType(Dialog)).findsNothing();
}

/// In a widget test, check that [showSuggestedActionDialog] was called
/// with the right text.
///
/// Checks for a suggested-action dialog matching an expected title and message.
/// Fails if none is found.
///
/// Use [expectDestructiveActionButton] to check whether
/// the button is "destructive" (see [showSuggestedActionDialog]).
/// This has no effect on Android because the "destructive" style is iOS-only.
///
/// On success, returns a Record with the widget's action button first
/// and its cancel button second.
/// Tap the action button by calling `tester.tap(find.byWidget(actionButton))`.
(Widget, Widget) checkSuggestedActionDialog(WidgetTester tester, {
  required String expectedTitle,
  String? expectedMessage,
  String? expectedActionButtonText,
  bool expectDestructiveActionButton = false,
}) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      final dialog = tester.widget<AlertDialog>(find.bySubtype<AlertDialog>());
      tester.widget(find.descendant(matchRoot: true,
        of: find.byWidget(dialog.title!), matching: find.text(expectedTitle)));
      if (expectedMessage != null) {
        tester.widget(find.descendant(matchRoot: true,
          of: find.byWidget(dialog.content!), matching: find.text(expectedMessage)));
      }

      final actionButton = tester.widget(find.descendant(of: find.byWidget(dialog),
        matching: find.widgetWithText(TextButton, expectedActionButtonText ?? 'Continue')));
      final cancelButton = tester.widget(find.descendant(of: find.byWidget(dialog),
        matching: find.widgetWithText(TextButton, 'Cancel')));
      return (actionButton, cancelButton);

    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      final dialog = tester.widget<CupertinoAlertDialog>(find.byType(CupertinoAlertDialog));
      tester.widget(find.descendant(matchRoot: true,
        of: find.byWidget(dialog.title!), matching: find.text(expectedTitle)));
      if (expectedMessage != null) {
        tester.widget(find.descendant(matchRoot: true,
          of: find.byWidget(dialog.content!), matching: find.text(expectedMessage)));
      }

      final actionButton = tester.widget<CupertinoDialogAction>(
        find.descendant(
          of: find.byWidget(dialog),
          matching: find.widgetWithText(
            CupertinoDialogAction,
            expectedActionButtonText ?? 'Continue')));
      check(actionButton.isDestructiveAction).equals(expectDestructiveActionButton);
      final cancelButton = tester.widget(find.descendant(of: find.byWidget(dialog),
        matching: find.widgetWithText(CupertinoDialogAction, 'Cancel')));
      return (actionButton, cancelButton);
  }
}
