// @formatter:off
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SnackBarPage extends StatefulWidget {
  final bool isStale;
  const SnackBarPage({super.key, required this.isStale});
  @override
  SnackBarPageState createState() => SnackBarPageState();
}

class SnackBarPageState extends State<SnackBarPage> {
  late ConnectivityResult _connectivityResult; // ignore: unused_field
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _connectivityResult = result;
      });
      showSnackBar(result);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = connectivityResult;
    });
    showSnackBar(connectivityResult);
  }

  void showSnackBar(ConnectivityResult connectivityResult) {
    final bool isConnected = connectivityResult != ConnectivityResult.none;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                    'No Internet Connection',
                    style: TextStyle(color: Colors.white)),],),
            duration: Duration(days: 365),
          ));
    }
    else if (widget.isStale) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                  )]),
            duration: Duration(seconds: 20),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Text(''),
        ));
  }
} // @formatter:off