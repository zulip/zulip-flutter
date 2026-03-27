import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../values/icons.dart';
import '../../../values/text.dart';
import '../../../values/theme.dart';
import '../../../widgets/new_dm_sheet.dart';
import '../recent_dm_conversations.dart';

class NewDmButton extends StatelessWidget {
  const NewDmButton({super.key, required this.onDmSelect});

  final OnDmSelectCallback onDmSelect;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_NewDmButtonController(), tag: 'new_dm_button');
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    return GestureDetector(
      onTap: () => showNewDmSheet(context, onDmSelect),
      onTapDown: (_) => controller.setPressed(true),
      onTapUp: (_) => controller.setPressed(false),
      onTapCancel: () => controller.setPressed(false),
      child: Obx(() {
        final pressed = controller.pressed.value;
        final fabBgColor = pressed
            ? designVariables.fabBgPressed
            : designVariables.fabBg;
        final fabLabelColor = pressed
            ? designVariables.fabLabelPressed
            : designVariables.fabLabel;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 20, 12),
          decoration: BoxDecoration(
            color: fabBgColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: designVariables.fabShadow,
                blurRadius: pressed ? 12 : 16,
                offset: pressed ? const Offset(0, 2) : const Offset(0, 4),
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
        );
      }),
    );
  }
}

class _NewDmButtonController extends GetxController {
  final RxBool pressed = false.obs;

  void setPressed(bool value) {
    pressed.value = value;
  }
}
