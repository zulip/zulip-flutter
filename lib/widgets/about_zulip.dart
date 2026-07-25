import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import 'actions.dart';
import 'banner.dart';
import 'page.dart';

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
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // The version is null if the prefetch at startup failed.
                if (version == null)
                  FloatingBanner(
                    intent: .warning,
                    label: zulipLocalizations.aboutPageAppVersionUnknown)
                else
                  ListTile(
                    title: Text(zulipLocalizations.aboutPageAppVersion),
                    subtitle: Text(version),
                    onTap: () => PlatformActions.copyWithPopup(context: context,
                      data: ClipboardData(text: version),
                      successContent: Text(zulipLocalizations.successAppVersionCopied))),
                ListTile(
                  title: Text(zulipLocalizations.aboutPageOpenSourceLicenses),
                  subtitle: Text(zulipLocalizations.aboutPageTapToView),
                  onTap: () {
                    // TODO(upstream?): This route and its child routes (pushed
                    //   when you tap a package to view its licenses) can't be
                    //   popped on iOS with the swipe-away gesture; you have to
                    //   tap the "Back" button. Debug/fix.
                    showLicensePage(context: context);
                  }),
              ])))),
      ));
  }
}
