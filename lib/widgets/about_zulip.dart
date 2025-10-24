import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/binding.dart';
import 'page.dart';

class AboutZulipPage extends StatefulWidget {
  const AboutZulipPage({super.key});

  static Route<void> buildRoute(BuildContext context) {
    return MaterialWidgetRoute(page: const AboutZulipPage());
  }

  @override
  State<AboutZulipPage> createState() => _AboutZulipPageState();
}

class _AboutZulipPageState extends State<AboutZulipPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    (() async {
      final result = await ZulipBinding.instance.packageInfo;
      setState(() {
        _packageInfo = result;
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.aboutPageTitle)),
      body: SingleChildScrollView(
        child: SafeArea(
          minimum: const EdgeInsets.all(8), // ListView pads vertical
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ListTile(
                  title: Text(zulipLocalizations.aboutPageAppVersion),
                  subtitle: Text(_packageInfo?.version
                    ?? zulipLocalizations.appVersionUnknownPlaceholder)),
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
