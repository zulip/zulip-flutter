import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import 'actions.dart';
import 'banner.dart';
import 'button.dart';
import 'icons.dart';
import 'page.dart';

Uri _releaseNotesUrl(String version) =>
  Uri.parse('https://github.com/zulip/zulip-flutter/releases/tag/v$version');

class AboutZulipPage extends StatelessWidget {
  const AboutZulipPage({super.key});

  static Route<void> buildRoute(BuildContext context) {
    return MaterialWidgetRoute(page: const AboutZulipPage());
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final version = ZulipBinding.instance.syncPackageInfo?.version;
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.aboutPageTitle)),
      body: SingleChildScrollView(
        child: SafeArea(
          minimum: const EdgeInsets.all(8), // ListView pads vertical
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: .center,
                crossAxisAlignment: .stretch,
                spacing: 8,
                children: [
                  // The version is null if the prefetch at startup failed.
                  if (version == null)
                    FloatingBanner(
                      intent: .warning,
                      label: zulipLocalizations.aboutPageAppVersionUnknown)
                  else
                    MenuButtonsShape(buttons: [
                      ZulipMenuItemButton(
                        style: .list,
                        label: zulipLocalizations.aboutPageAppVersion,
                        subLabel: TextSpan(text: version),
                        icon: ZulipIcons.copy,
                        onPressed: () => PlatformActions.copyWithPopup(context: context,
                          data: ClipboardData(text: version),
                          successContent: Text(zulipLocalizations.successAppVersionCopied))),
                      ZulipMenuItemButton(
                        style: .list,
                        label: zulipLocalizations.aboutPageReleaseNotes,
                        icon: ZulipIcons.external_link,
                        onPressed: () =>
                          PlatformActions.launchUrl(context, _releaseNotesUrl(version))),
                    ]),
                  MenuButtonsShape(buttons: [
                    ZulipMenuItemButton(
                      style: .list,
                      label: zulipLocalizations.aboutPageOpenSourceLicenses,
                      icon: ZulipIcons.chevron_right,
                      onPressed: () => showLicensePage(context: context)),
                  ]),
                ])))),
      ));
  }
}
