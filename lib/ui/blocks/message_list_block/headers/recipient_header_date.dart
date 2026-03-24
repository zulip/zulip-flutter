import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../widgets/date_text.dart';

class RecipientHeaderDate extends StatelessWidget {
  const RecipientHeaderDate({super.key, required this.message});

  final MessageBase message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 16, 0),
      child: DateText(
        fontSize: 16,
        // In Figma this has a line-height of 19, but using 18
        // here to match the stream/topic text widgets helps
        // to align all the text to the same baseline.
        height: (18 / 16),
        timestamp: message.timestamp,
      ),
    );
  }
}
