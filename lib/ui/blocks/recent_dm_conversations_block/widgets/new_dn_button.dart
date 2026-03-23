import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../values/icons.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/new_dm_sheet.dart';
import '../recent_dm_conversations.dart';

class NewDmButton extends StatefulWidget {
  const NewDmButton({super.key, required this.onDmSelect});

  final OnDmSelectCallback onDmSelect;

  @override
  State<NewDmButton> createState() => _NewDmButtonState();
}

class _NewDmButtonState extends State<NewDmButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final fabBgColor = _pressed
        ? designVariables.fabBgPressed
        : designVariables.fabBg;
    final fabLabelColor = _pressed
        ? designVariables.fabLabelPressed
        : designVariables.fabLabel;

    return GestureDetector(
      onTap: () => showNewDmSheet(context, widget.onDmSelect),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 20, 12),
        decoration: BoxDecoration(
          color: fabBgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: designVariables.fabShadow,
              blurRadius: _pressed ? 12 : 16,
              offset: _pressed ? const Offset(0, 2) : const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ZulipIcons.plus, size: 24, color: fabLabelColor),
            const SizedBox(width: 8),
            Text(
              zulipLocalizations.newDmFabButtonLabel,
              style: TextStyle(
                fontSize: 20,
                height: 24 / 20,
                color: fabLabelColor,
              ).merge(weightVariableTextStyle(context, wght: 500)),
            ),
          ],
        ),
      ),
    );
  }
}
