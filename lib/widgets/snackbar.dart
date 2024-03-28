//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class SnackBarPage extends StatefulWidget {
//   const SnackBarPage({super.key});
//
//   @override
//   SnackBarPageState createState() => SnackBarPageState();
// }
//
// class SnackBarPageState extends State<SnackBarPage> {
//   late ConnectivityResult _connectivityResult; // ignore: unused_field
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize connectivity status
//     _initConnectivity();
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Subscribe to connectivity changes
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       setState(() {
//         _connectivityResult = result;
//       });
//       // Show or dismiss snackbar based on connectivity changes
//       showSnackBar(result);
//     });
//   }
//
//   @override
//   void dispose() {
//     _connectivitySubscription.cancel(); // Cancel subscription to avoid memory leaks
//     super.dispose();
//   }
//
//   Future<void> _initConnectivity() async {
//     final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
//     setState(() {
//       _connectivityResult = connectivityResult;
//     });
//     //  initial snackbar based on connectivity status
//     showSnackBar(connectivityResult);
//   }
//
//   void showSnackBar(ConnectivityResult connectivityResult) {
//     final bool isConnected = connectivityResult != ConnectivityResult.none;
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//
//     if (isConnected) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Row(
//             children: [
//               Icon(
//                 Icons.sync,
//                 color: Colors.white,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Connecting',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//           duration:  Duration(seconds: 3),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content:  Row(
//             children: [
//               Icon(
//                 Icons.error_outline,
//                 color: Colors.white,
//               ),
//               SizedBox(width: 2),
//               Text(
//                 'No Internet Connection',
//                 style:  TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//           duration:  Duration(seconds: 365),
//         ),
//       );
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body:  Center(
//         child:   Text(''),
//       ),
//     );
//   }
// }
//




import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SnackBarPage extends StatefulWidget {
  const SnackBarPage({super.key});

  @override
  SnackBarPageState createState() => SnackBarPageState();
}


class SnackBarPageState extends State<SnackBarPage> {
  late ConnectivityResult _connectivityResult; // ignore: unused_field
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  late ScaffoldMessengerState _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    // Initialize connectivity status
    _initConnectivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
      });
      // Show or dismiss snackbar based on connectivity changes
      showSnackBar(result);
    });
    // Get the ScaffoldMessengerState
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // Cancel subscription to avoid memory leaks
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = connectivityResult;
    });
    // Show initial snackbar based on connectivity status
    showSnackBar(connectivityResult);
  }

  void showSnackBar(ConnectivityResult connectivityResult) {
    final bool isConnected = connectivityResult != ConnectivityResult.none;
    _scaffoldMessengerState.hideCurrentSnackBar(); // Hide current snackbar

    if (isConnected) {
      _scaffoldMessengerState.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.sync,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Connecting',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      _scaffoldMessengerState.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              SizedBox(width: 2),
              Text(
                'No Internet Connection',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          duration: Duration(seconds: 365),
        ),
      );
    }
  }

  void hideSnackBar() {
    _scaffoldMessengerState.hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(''),
      ),
    );
  }
}

