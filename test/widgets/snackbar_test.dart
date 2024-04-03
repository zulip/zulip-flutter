//@formatter:off
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/snackbar.dart';

void main() {
  testWidgets('SnackBarPage displays correct SnackBar based on connectivity', (WidgetTester tester) async {
    //  connection restored with isStale = true
    await tester.pumpWidget(
      MaterialApp(
          home: Builder(
              builder: (BuildContext context) {
                return const SnackBarPage(isStale: true);
              })),
    );

    //  state of SnackBarPage
    final snackBarPageState = tester.state<SnackBarPageState>(find.byType(SnackBarPage));
    snackBarPageState.showSnackBar(ConnectivityResult.wifi);
    await tester.pump();
    expect(find.text('Connecting'), findsOneWidget);
    //  showSnackBar with ConnectivityResult.none
    snackBarPageState.showSnackBar(ConnectivityResult.none);
    // Wait for the widget to rebuild with the new SnackBar
    await tester.pump();
    // Verify that the 'Connecting' SnackBar is shown
    expect(find.text('No Internet Connection'), findsOneWidget);
  });
} //@formatter:off