import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/model/content.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/image.dart';
import 'package:zulip/widgets/store.dart';

import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../test_images.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  group('RealmContentNetworkImage', () {
    final authHeaders = authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey);

    Future<Map<String, List<String>>> actualHeaders(WidgetTester tester, Uri src) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      final httpClient = prepareBoringImageHttpClient();

      await tester.pumpWidget(GlobalStoreWidget(
        child: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: RealmContentNetworkImage(src))));
      await tester.pump();
      await tester.pump();

      return httpClient.request.headers.values;
    }

    testWidgets('includes auth header if `src` on-realm', (tester) async {
      check(await actualHeaders(tester, Uri.parse('https://chat.example/image.png')))
        .deepEquals({
          'Authorization': [authHeaders['Authorization']!],
          'User-Agent': [userAgentHeader()['User-Agent']!],
        });
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('excludes auth header if `src` off-realm', (tester) async {
      check(await actualHeaders(tester, Uri.parse('https://other.example/image.png')))
        .deepEquals({'User-Agent': [userAgentHeader()['User-Agent']!]});
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('throws if no `PerAccountStoreWidget` ancestor', (tester) async {
      await tester.pumpWidget(
        RealmContentNetworkImage(Uri.parse('https://zulip.invalid/path/to/image.png'), filterQuality: FilterQuality.medium));
      check(tester.takeException()).isA<AssertionError>();
    });
  });

  group('ImageThumbnailLocator.resolve', () {
    late PerAccountStore store;

    Future<void> prepare(WidgetTester tester) async {
      addTearDown(testBinding.reset);

      final exampleFormats = [
        ThumbnailFormat(name: '840x560.webp',
          maxWidth: 840, maxHeight: 560, animated: false, format: 'webp'),
        ThumbnailFormat(name: '840x560-anim.webp',
          maxWidth: 840, maxHeight: 560, animated: true, format: 'webp'),
        ThumbnailFormat(name: '500x900.jpg',
          maxWidth: 500, maxHeight: 900, animated: false, format: 'jpg'),
        ThumbnailFormat(name: '500x900-anim.jpg',
          maxWidth: 500, maxHeight: 900, animated: true, format: 'jpg'),
        ThumbnailFormat(name: '1000x1000.webp',
          maxWidth: 1000, maxHeight: 1000, animated: false, format: 'webp'),
        ThumbnailFormat(name: '1000x2000-anim.png',
          maxWidth: 1000, maxHeight: 2000, animated: true, format: 'png'),
        ThumbnailFormat(name: '1000x1000-anim.webp',
          maxWidth: 1000, maxHeight: 1000, animated: true, format: 'webp'),
        ThumbnailFormat(name: '1000x2000.png',
          maxWidth: 1000, maxHeight: 2000, animated: false, format: 'png'),
      ];

      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot(
        serverThumbnailFormats: exampleFormats,
      ));

      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUser(eg.selfUser);

      await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id));
      await tester.pump();
    }

    void doCheck(
      WidgetTester tester,
      double width,
      double height,
      bool animatedIfSupported,
      String expected, {
      required bool hasAnimatedVersion,
    }) {
      final locator = ImageThumbnailLocator(
        urlPath: '/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp',
        hasAnimatedVersion: hasAnimatedVersion,
      );

      final context = tester.element(find.byType(Placeholder));
      final result = locator.resolve(context,
        width: width, height: height,
        animationMode: animatedIfSupported
          ? ImageAnimationMode.animateAlways
          : ImageAnimationMode.animateNever);
      check(result.toString()).equals(expected);
    }

    testWidgets('animated version exists', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await prepare(tester);

      doCheck(tester, 200, 200, false, hasAnimatedVersion: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x900.jpg');
      doCheck(tester, 250, 450, true, hasAnimatedVersion: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x900-anim.jpg');
      doCheck(tester, 250, 450, false, hasAnimatedVersion: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x900.jpg');
      doCheck(tester, 300, 250, true, hasAnimatedVersion: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560-anim.webp');
      doCheck(tester, 300, 250, false, hasAnimatedVersion: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp');
      doCheck(tester, 750, 1000, false, hasAnimatedVersion: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/1000x2000.png');
    });

    testWidgets('animated version does not exist', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await prepare(tester);

      doCheck(tester, 200, 200, false, hasAnimatedVersion: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x900.jpg');
      doCheck(tester, 250, 450, true, hasAnimatedVersion: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x900.jpg');
      doCheck(tester, 250, 450, false, hasAnimatedVersion: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x900.jpg');
      doCheck(tester, 300, 250, true, hasAnimatedVersion: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp');
      doCheck(tester, 300, 250, false, hasAnimatedVersion: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp');
      doCheck(tester, 750, 1000, false, hasAnimatedVersion: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/1000x2000.png');
    });
  });
}
