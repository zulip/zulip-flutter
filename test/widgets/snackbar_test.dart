import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/snackbar.dart';

void main() {
  testWidgets('Test SnackBarPage', (WidgetTester tester) async {
    /// SnackBarPage widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SnackBarPage(isStale: false),
        ),
      ),
    );

    ///  noSnackBar is shown
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);

    /// Change isStale to true
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SnackBarPage(isStale: true),
        ),
      ),
    );

    ///  SnackBar is shown
    await tester.pump();
    expect(find.text('Connecting'), findsOneWidget);
  });
}
