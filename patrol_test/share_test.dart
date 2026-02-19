import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/share.dart';

import '../test/example_data.dart' as eg;
import '../test/test_images.dart';
import 'binding.dart';

void main() {
  SemiLiveZulipBinding.ensureInitialized();
  ShareService.start();

  Future<void> prepare(PatrolIntegrationTester $) async {
    addTearDown(semiLiveBinding.reset);
    await semiLiveBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    prepareBoringImageHttpClient();
    await $.pumpWidgetAndSettle(ZulipApp());
  }

  patrolTest('share to Zulip: Google Maps', ($) async {
    await prepare($);

    await $.platform.mobile.openPlatformApp(
      androidAppId: GoogleApp.maps,
    );

    // TODO(patrol): abstract these steps over iOS vs Android (though
    //    doesn't matter until we implement this feature-under-test for iOS, #54)
    final selector = AndroidSelector(text: 'Skip');
    if ((await $.platform.android.getNativeViews(selector)).roots.isNotEmpty) {
      await $.platform.tap(selector);
    }

    // (A bit of debugging to demonstrate how the selectors below were written.)
    // final tmp = (await $.platform.android.getNativeViews(
    //   AndroidSelector(className: 'android.widget.EditText'))).roots;
    // for (final r in tmp) print(r);

    // In Google Maps, open up some predictable place.
    await $.platform.tap(AndroidSelector(contentDescription: 'Search here'));
    await $.platform.android.enterText(
      AndroidSelector(text: 'Search here'), text: 'San Francisco, CA');
    await $.platform.android.tap(AndroidSelector(text: 'San Francisco'));

    // In the place's bottom sheet, tap the Share button, then pick Zulip.
    await $.platform.android.tap(AndroidSelector(text: 'Share'));
    await $.platform.android.tap(AndroidSelector(text: 'Zulip'));

    // Check the app opens and shows the share-to-Zulip sheet.
    await $.waitUntilVisible($(ShareSheet));

    // TODO(#1787): pick a destination and send, to check the shared data was received

    debugNetworkImageHttpClientProvider = null;
  },
    skip: defaultTargetPlatform != TargetPlatform.android, // TODO(#54) feature not yet implemented on iOS
  );

  patrolTest('share to Zulip: Chrome', ($) async {
    await prepare($);

    await $.platform.mobile.openPlatformApp(
      androidAppId: GoogleApp.chrome,
    );

    final selector = AndroidSelector(text: 'Use without an account');
    if ((await $.platform.android.getNativeViews(selector)).roots.isNotEmpty) {
      await $.platform.tap(selector);
    }

    {
      final selector = AndroidSelector(text: 'Got it');
      if ((await $.platform.android.getNativeViews(selector)).roots.isNotEmpty) {
        await $.platform.tap(selector);
      }
    }

    {
      final selector = AndroidSelector(text: 'No thanks');
      if ((await $.platform.android.getNativeViews(selector)).roots.isNotEmpty) {
        await $.platform.tap(selector);
      }
    }

    await $.platform.android.enterText(
      AndroidSelector(text: 'Search or type URL'),
      text: 'google.com');
    await $.platform.tap(Selector(text: 'google.com'));

    // print((await $.platform.android.getNativeViews(null)).roots);

    // TODO write selector for the overflow menu in app bar;
    //   that in turn has a share option.
    // await $.platform.tap(Selector(contentDescription: ));

    debugNetworkImageHttpClientProvider = null;
  },
    skip: true, // This is a possible alternative to the Google Maps-based test;
                // only one of them is really needed.
  );
}
