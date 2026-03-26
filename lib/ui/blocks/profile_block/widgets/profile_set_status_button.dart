import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/store_service.dart';
import '../../../values/icons.dart';
import '../../../widgets/button.dart';
import '../../../widgets/image.dart';
import '../../../widgets/set_status.dart';
import '../../../widgets/user.dart';

class ProfileSetStatusButton extends StatelessWidget {
  const ProfileSetStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = requirePerAccountStore();
    final userStatus = store.getUserStatus(store.selfUserId);

    return ZulipMenuItemButton(
      style: ZulipMenuItemButtonStyle.list,
      label: userStatus == UserStatus.zero
          ? zulipLocalizations.statusButtonLabelStatusUnset
          : zulipLocalizations.statusButtonLabelStatusSet,
      subLabel: userStatus == UserStatus.zero
          ? null
          : TextSpan(
              children: [
                UserStatusEmoji.asWidgetSpan(
                  userId: store.selfUserId,
                  fontSize: 16,
                  textScaler: MediaQuery.textScalerOf(context),
                  position: StatusEmojiPosition.before,
                  animationMode: ImageAnimationMode.animateConditionally,
                ),
                userStatus.text == null
                    ? TextSpan(
                        text: zulipLocalizations.noStatusText,
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    : TextSpan(text: userStatus.text),
              ],
            ),
      icon: ZulipIcons.chevron_right,
      onPressed: () {
        Navigator.push(
          context,
          SetStatusPage.buildRoute(context: context, oldStatus: userStatus),
        );
      },
    );
  }
}
