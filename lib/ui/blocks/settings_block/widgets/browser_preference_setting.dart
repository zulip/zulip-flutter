import 'package:flutter/material.dart';

import '../../../../generated/l10n/zulip_localizations.dart';
import '../../../../get/services/global_service.dart';
import '../../../../model/settings.dart';

class BrowserPreferenceSetting extends StatelessWidget {
  const BrowserPreferenceSetting({super.key});

  void _handleChange(BuildContext context, bool newOpenLinksWithInAppBrowser) {
    final globalSettings = GlobalService.to.settingsStore;
    globalSettings?.setBrowserPreference(
      newOpenLinksWithInAppBrowser
          ? BrowserPreference.inApp
          : BrowserPreference.external,
    );
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final globalSettings = GlobalService.to.settingsStore;
    final openLinksWithInAppBrowser =
        globalSettings?.effectiveBrowserPreference == BrowserPreference.inApp;
    return SwitchListTile.adaptive(
      title: Text(zulipLocalizations.openLinksWithInAppBrowser),
      value: openLinksWithInAppBrowser,
      onChanged: (newValue) => _handleChange(context, newValue),
    );
  }
}
