import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      final result = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = result;
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Zulip")),
      body: SingleChildScrollView(
        child: SafeArea(
          minimum: const EdgeInsets.all(8), // ListView pads vertical
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ListTile(
                  title: const Text('App version'),
                  subtitle: Text(_packageInfo?.version ?? '(…)')),
                ListTile(
                  title: const Text('Open-source licenses'),
                  subtitle: const Text('Tap to view'),
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
