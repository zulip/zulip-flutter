import 'package:flutter/material.dart';

import '../../../../api/model/model.dart';
import '../../../../api/route/settings.dart';
import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../log.dart';
import '../../../utils/remote_settings.dart';
import '../../../utils/store.dart';
import '../../../widgets/button.dart';

class InvisibleModeToggle extends StatelessWidget {
  const InvisibleModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);

    // `value: true` means invisible mode is on,
    // i.e., that presenceEnabled is false.
    return RemoteSettingBuilder<bool>(
      findValueInStore: (store) => !store.userSettings.presenceEnabled,
      sendValueToServer: (value) => updateSettings(
        store.connection,
        newSettings: {UserSettingName.presenceEnabled: !value},
      ),
      // TODO(#741) interpret API errors for user
      onError: (e, requestedValue) => reportErrorToUserBriefly(
        requestedValue
            ? zulipLocalizations.turnOnInvisibleModeErrorTitle
            : zulipLocalizations.turnOffInvisibleModeErrorTitle,
      ),
      builder: (value, handleRequestNewValue) => ZulipMenuItemButton(
        style: ZulipMenuItemButtonStyle.list,
        label: zulipLocalizations.invisibleMode,
        onPressed: () => handleRequestNewValue(!value),
        toggle: Toggle(value: value, onChanged: handleRequestNewValue),
      ),
    );
  }
}
