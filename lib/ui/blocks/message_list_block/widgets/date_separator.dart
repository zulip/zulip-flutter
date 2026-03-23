import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../values/theme.dart';
import 'date_text.dart';

class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.message});

  final MessageBase message;

  @override
  Widget build(BuildContext context) {
    // This makes the small-caps text vertically centered,
    // to align with the vertically centered divider lines.
    const textBottomPadding = 2.0;

    final designVariables = DesignVariables.of(context);

    final line = BorderSide(width: 0, color: designVariables.foreground);

    // TODO(#681) use different color for DM messages
    return ColoredBox(
      color: designVariables.bgMessageRegular,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border(bottom: line)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, textBottomPadding),
              child: DateText(
                fontSize: 16,
                height: (16 / 16),
                timestamp: message.timestamp,
              ),
            ),
            SizedBox(
              height: 0,
              width: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border(bottom: line)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
