import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/widgets/snackbar.dart';




// void main() {
//   testWidgets('showSnackBar displays correct SnackBar based on connectivity', (WidgetTester tester) async {
//     // Create a test widget
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Builder(
//           builder: (BuildContext context) {
//             return const SnackBarPage();
//           },
//         ),
//       ),
//     );
//
//
//     final snackBarPageState = tester.state<SnackBarPageState>(find.byType(SnackBarPage));
//
//     // Show SnackBar for connectivity result
//     snackBarPageState.showSnackBar(ConnectivityResult.wifi);
//     await tester.pump();
//
//
//     expect(find.text('Connecting'), findsOneWidget);
//     //expect(find.text('No Internet Connection'), findsOneWidget); // Assuming  no internet connection for wifi
//
//     //  Hide the SnackBar
//     ScaffoldMessenger.of(tester.element(find.byType(SnackBarPage))).hideCurrentSnackBar();
//
//     //  SnackBar for no internet connection
//     snackBarPageState.showSnackBar(ConnectivityResult.none); // Call showSnackBar with no internet connection
//     await tester.pump(); // Rebuild widget tree
//
//
// //    expect(find.text('Connecting'), findsNothing); // SnackBar for connecting should be hidden
//     expect(find.text('No Internet Connection'), findsOneWidget);
//
//     // Hide the SnackBar
//     ScaffoldMessenger.of(tester.element(find.byType(SnackBarPage))).hideCurrentSnackBar();
//   });
// }
//
//
//


void main() {
  testWidgets('showSnackBar displays correct SnackBar based on connectivity', (WidgetTester tester) async {
    // Create a test widget
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return const SnackBarPage();
          },
        ),
      ),
    );

    // Wait for initialization of SnackBarPageState
    await tester.pump(Duration.zero);

    final snackBarPageState = tester.state<SnackBarPageState>(find.byType(SnackBarPage));

    // Show SnackBar for connectivity result
    snackBarPageState.showSnackBar(ConnectivityResult.wifi);
    await tester.pump();

    // Check visibility of the SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Connecting'), findsOneWidget);

    // Hide the SnackBar
    snackBarPageState.hideSnackBar();
    await tester.pump();

    // Check visibility of the SnackBar after hiding
    expect(find.byType(SnackBar), findsNothing);

    // SnackBar for no internet connection
    snackBarPageState.showSnackBar(ConnectivityResult.none); // Call showSnackBar with no internet connection
    await tester.pump(); // Rebuild widget tree

    // Check visibility of the SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('No Internet Connection'), findsOneWidget);

    // Hide the SnackBar
    snackBarPageState.hideSnackBar();
    await tester.pump();

    // Check visibility of the SnackBar after hiding
    expect(find.byType(SnackBar), findsNothing);
  });
}




