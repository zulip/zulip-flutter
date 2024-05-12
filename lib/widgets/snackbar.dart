import 'package:flutter/material.dart';

class SnackBarPage extends StatefulWidget {
  final bool isStale;
  const SnackBarPage({super.key, required this.isStale});

  @override
  SnackBarPageState createState() => SnackBarPageState();
}

class SnackBarPageState extends State<SnackBarPage> {
  @override
  void initState() {
    super.initState();
    // Call showSnackBar() after the build process is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isStale) {
        showSnackBar();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SnackBarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if isStale changed to true
    if (widget.isStale && !oldWidget.isStale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnackBar();
      });
    }
  }

  void showSnackBar() {
    String snackBarText = 'Connecting';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.sync,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              snackBarText,
              style: const TextStyle(color: Colors.white),
            )]),
        duration: const Duration(seconds: 20),
      ));
    }

  @override
  Widget build(BuildContext context) {
    return Container(); // Return an empty container or another widget here
  }
}


