import 'package:flutter/material.dart';

import '../../values/theme.dart';

class InboxIconMarker extends StatelessWidget {
  const InboxIconMarker({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    // Design for icon markers based on Figma screen:
    //   https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?type=design&node-id=224-16386&mode=design&t=JsNndFQ8fKFH0SjS-0
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      // This color comes from the Figma screen for the "@" marker, but not
      // the topic visibility markers.
      child: Icon(icon, size: 14, color: designVariables.inboxItemIconMarker),
    );
  }
}
