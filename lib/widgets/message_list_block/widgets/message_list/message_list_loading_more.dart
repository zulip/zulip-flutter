import 'package:flutter/material.dart';

class MessageListLoadingMore extends StatelessWidget {
  const MessageListLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: CircularProgressIndicator(),
      ),
    ); // TODO perhaps a different indicator
  }
}
