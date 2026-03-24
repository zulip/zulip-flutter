import 'package:flutter/material.dart';

import '../../../values/text.dart';
import '../../../values/theme.dart';

class SubscriptionListHeader extends StatelessWidget {
  const SubscriptionListHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final line = Expanded(
      child: Divider(color: designVariables.subscriptionListHeaderLine),
    );

    return SliverToBoxAdapter(
      child: ColoredBox(
        // TODO(design) check if this is the right variable
        color: designVariables.background,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            line,
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: designVariables.subscriptionListHeaderText,
                  fontSize: 14,
                  letterSpacing: proportionalLetterSpacing(
                    context,
                    0.04,
                    baseFontSize: 14,
                  ),
                  height: (16 / 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            line,
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
