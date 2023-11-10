import 'dart:ui';

import 'package:flutter/material.dart';

import 'text.dart';

/// A widget to display a given number of unreads in a conversation.
///
/// Implements the design for these in Figma:
///   <https://www.figma.com/file/1JTNtYo9memgW7vV6d0ygq/Zulip-Mobile?node-id=341%3A12387&mode=dev>
class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({
    super.key,
    required this.count,
    this.bold = false,
  });

  final int count;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color.fromRGBO(102, 102, 153, 0.15),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 1),
        child: Text(
          style: const TextStyle(
            fontFamily: 'Source Sans 3',
            fontSize: 16,
            height: (18 / 16),
            fontFeatures: [FontFeature.enable('smcp')], // small caps
            color: Color(0xFF222222),
          ).merge(bold
            ? weightVariableTextStyle(context, wght: 600, wghtIfPlatformRequestsBold: 900)
            : weightVariableTextStyle(context)),
          count.toString())));
  }
}
