import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class SnackBarPage extends StatefulWidget {
  const SnackBarPage({Key? key}) : super(key: key);

  @override
  _SnackBarPageState createState() => _SnackBarPageState();
}

class _SnackBarPageState extends State<SnackBarPage> {
  late ConnectivityResult _connectivityResult;

  @override
  void initState() {
    super.initState();
    // Initialize connectivity status
    _initConnectivity();
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
      });
      // Show or dismiss snackbar based on connectivity changes
      _showSnackBar(result);
    });
  }

  Future<void> _initConnectivity() async {
    final ConnectivityResult connectivityResult =
    await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = connectivityResult;
    });
    // Show initial snackbar based on connectivity status
    _showSnackBar(connectivityResult);
  }

  void _showSnackBar(ConnectivityResult connectivityResult) {
    final bool isConnected = connectivityResult != ConnectivityResult.none;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (isConnected) {
      // If connected, show a green snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.sync,
                color: Colors.white,
              ),
              SizedBox(width: 2),
              Text(
                'Connecting',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // If not connected, show a red snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.signal_wifi_off,
                color: Colors.white,
              ),
              SizedBox(width: 2),
              Text(
                'No Internet Connection',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      body: Center(
        child: Text(''),
      ),
    );
  }
}
