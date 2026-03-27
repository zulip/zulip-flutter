import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../generated/l10n/zulip_localizations.dart';
import '../../model/binding.dart';
import '../utils/page.dart';

class _AboutZulipController extends GetxController {
  final Rx<PackageInfo?> packageInfo = Rx<PackageInfo?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    packageInfo.value = await ZulipBinding.instance.packageInfo;
  }
}

class AboutZulipPage extends StatelessWidget {
  const AboutZulipPage({super.key});

  static Route<void> buildRoute(BuildContext context) {
    return MaterialWidgetRoute(page: const AboutZulipPage());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_AboutZulipController());
    final zulipLocalizations = ZulipLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(zulipLocalizations.aboutPageTitle)),
      body: SingleChildScrollView(
        child: SafeArea(
          minimum: const EdgeInsets.all(8), // ListView pads vertical
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListTile(
                      title: Text(zulipLocalizations.aboutPageAppVersion),
                      subtitle: Text(
                        controller.packageInfo.value?.version ??
                            zulipLocalizations.appVersionUnknownPlaceholder,
                      ),
                    ),
                    ListTile(
                      title: Text(
                        zulipLocalizations.aboutPageOpenSourceLicenses,
                      ),
                      subtitle: Text(zulipLocalizations.aboutPageTapToView),
                      onTap: () {
                        // TODO(upstream?): This route and its child routes (pushed
                        //   when you tap a package to view its licenses) can't be
                        //   popped on iOS with the swipe-away gesture; you have to
                        //   tap the "Back" button. Debug/fix.
                        showLicensePage(context: context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
