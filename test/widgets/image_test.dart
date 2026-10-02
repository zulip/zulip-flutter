import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/core.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/model/binding.dart';
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

  final authHeaders = authHeader(email: eg.selfAccount.email, apiKey: eg.selfAccount.apiKey);

  group('RealmContentNetworkImage', () {
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

  group('dart:io HttpClient auth headers on redirect', () {
    // These tests exercise no code of ours; they pin dart:io HttpClient
    // behavior we rely on for security.
    // An on-realm request carries the user's API key in the
    // Authorization header (RealmContentNetworkImage tests above),
    // and the response can be a redirect pointing off-realm:
    // for example, the /avatar/{user_id} fallback (see [FallbackAvatarUrl])
    // redirects to Gravatar or S3-style storage.
    // The API key must not be forwarded there.
    //
    // The behavior is deliberate on Dart's part: dropping sensitive
    // headers on cross-origin redirects was the fix for CVE-2022-0451,
    // in Dart 2.16:
    //   https://github.com/dart-lang/sdk/security/advisories/GHSA-c8mh-jj22-xg5h
    // These tests are a tripwire in case that ever regresses upstream,
    // which matters because we track Flutter's main channel.

    final authHeaderValue = authHeaders['Authorization']!;

    /// The Authorization header received at the redirect's destination.
    Future<String?> authHeaderAfterRedirect({required bool sameOrigin}) async {
      String? result;
      Future<void> handleDestination(HttpRequest request) async {
        result = request.headers.value('authorization');
        await request.response.close();
      }

      final destServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final redirectServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      Uri urlOf(HttpServer server, String path) => Uri(
        scheme: 'http',
        host: server.address.address, port: server.port, path: path);

      destServer.listen(handleDestination);
      redirectServer.listen((request) async {
        if (request.uri.path == '/redirect') {
          // A cross-origin URL differs in port, hence in origin.
          final destination = urlOf(sameOrigin ? redirectServer : destServer,
            '/destination');
          request.response
            ..statusCode = HttpStatus.found
            ..headers.set('location', destination.toString());
          await request.response.close();
        } else {
          await handleDestination(request);
        }
      });

      // Escape flutter_test's global [HttpOverrides], which stubs out
      // all HTTP; the [HttpOverrides] base class creates real clients.
      final client = HttpOverrides.runWithHttpOverrides(
        () => HttpClient(), _RealHttpOverrides());
      try {
        final request = await client.getUrl(urlOf(redirectServer, '/redirect'));
        request.headers.set('authorization', authHeaderValue);
        final response = await request.close();
        await response.drain<void>();
        // If the client didn't follow the redirect, this would be
        // the 302 itself; guard against a null `result` meaning
        // the destination was never contacted at all.
        check(response.statusCode).equals(HttpStatus.ok);
      } finally {
        client.close(force: true);
        await destServer.close(force: true);
        await redirectServer.close(force: true);
      }
      return result;
    }

    test('forward auth header on same-origin redirect', () async {
      check(await authHeaderAfterRedirect(sameOrigin: true))
        .equals(authHeaderValue);
    });

    test('no forward auth header on cross-origin redirect', () async {
      check(await authHeaderAfterRedirect(sameOrigin: false))
        .isNull();
    });
  });

  group('ImageThumbnailLocator.resolve', () {
    late PerAccountStore store;

    Future<void> prepare(WidgetTester tester, {List<ThumbnailFormat>? formats}) async {
      addTearDown(testBinding.reset);

      formats ??= [
        ThumbnailFormat(name: '840x560.webp',
          maxWidth: 840, maxHeight: 560, animated: false, format: 'webp'),
        ThumbnailFormat(name: '840x560-anim.webp',
          maxWidth: 840, maxHeight: 560, animated: true, format: 'webp'),
        ThumbnailFormat(name: '500x850.jpg',
          maxWidth: 500, maxHeight: 850, animated: false, format: 'jpg'),
        ThumbnailFormat(name: '500x850-anim.jpg',
          maxWidth: 500, maxHeight: 850, animated: true, format: 'jpg'),
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
        serverThumbnailFormats: formats,
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
      bool animateIfSupported,
      String expected, {
      required bool animated,
    }) {
      final locator = ImageThumbnailLocator(
        defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp'),
        animated: animated,
      );

      final context = tester.element(find.byType(Placeholder));
      final result = locator.resolve(context,
        width: width, height: height,
        animationMode: animateIfSupported
          ? ImageAnimationMode.animateAlways
          : ImageAnimationMode.animateNever);
      check(result.toString()).equals(expected);
    }

    testWidgets('animated version does not exist', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await prepare(tester);

      // Use the smallest format that's big enough.
      doCheck(tester, 200, 200, false, animated: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x850.jpg');
      doCheck(tester, 250, 425, false, animated: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x850.jpg');
      // The format sizes are in physical pixels.
      // This test set devicePixelRatio to 2, so 500 is too small for 300px.
      doCheck(tester, 300, 250, false, animated: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp');
      // When no format is big enough, use the largest format.
      doCheck(tester, 750, 1000, false, animated: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/1000x2000.png');

      // Given the image lacks an animated version, animationMode is ignored.
      doCheck(tester, 250, 425, true, animated: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x850.jpg');
      doCheck(tester, 300, 250, true, animated: false,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp');
    });

    testWidgets('animated version exists', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await prepare(tester);

      // Use the smallest format that's big enough, but animated.
      doCheck(tester, 250, 425, true, animated: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x850-anim.jpg');

      // When animationMode says not to animate, though,
      // the image's animated version is ignored.
      doCheck(tester, 200, 200, false, animated: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x850.jpg');
      doCheck(tester, 250, 425, false, animated: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/500x850.jpg');
      doCheck(tester, 750, 1000, false, animated: true,
        'https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/1000x2000.png');
    });

    testWidgets('query and fragment preserved', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await prepare(tester);

      final locator = ImageThumbnailLocator(
        defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp?x=y#abc'),
        animated: false);

      final context = tester.element(find.byType(Placeholder));
      final result = locator.resolve(context,
        width: 500, height: 500,
        animationMode: ImageAnimationMode.animateNever);
      check(result.toString())
        .equals('https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/1000x1000.webp?x=y#abc');
    });

    testWidgets('query and fragment preserved, in fallback to default src (store.serverThumbnailFormats empty)', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await prepare(tester, formats: []);

      final locator = ImageThumbnailLocator(
        defaultFormatSrc: Uri.parse('/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp?x=y#abc'),
        animated: false);

      final context = tester.element(find.byType(Placeholder));
      final result = locator.resolve(context,
        width: 500, height: 500,
        animationMode: ImageAnimationMode.animateNever);
      check(result.toString())
        .equals('https://chat.example/user_uploads/thumbnail/1/2/a/pic.jpg/840x560.webp?x=y#abc');
    });
  });

  group('ImageAnimationMode.shouldAnimate', () {
    Future<void> doCheck(WidgetTester tester, {
      required TargetPlatform platform,
      BaseDeviceInfo? deviceInfo,
      bool mediaQueryDisableAnimations = false,
      bool reduceMotion = false,
      bool autoPlayAnimatedImages = true,
      required ImageAnimationMode mode,
      required bool expected,
    }) async {
      addTearDown(testBinding.reset);
      if (deviceInfo != null) testBinding.deviceInfoResult = deviceInfo;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(
          reduceMotion: reduceMotion,
          autoPlayAnimatedImages: autoPlayAnimatedImages);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(disableAnimations: mediaQueryDisableAnimations),
          child: const Placeholder()));
        final context = tester.element(find.byType(Placeholder));
        check(mode.shouldAnimate(context)).equals(expected);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    testWidgets('animateAlways gives true regardless of device settings', (tester) async {
      await doCheck(tester, mode: ImageAnimationMode.animateAlways, expected: true,
        platform: .iOS,
        deviceInfo: const IosDeviceInfo(systemVersion: '18.0'),
        mediaQueryDisableAnimations: true, reduceMotion: true,
        autoPlayAnimatedImages: false);
    });

    testWidgets('animateNever gives false regardless of device settings', (tester) async {
      await doCheck(tester, mode: ImageAnimationMode.animateNever, expected: false,
        platform: .iOS);
    });

    group('animateConditionally', () {
      const mode = ImageAnimationMode.animateConditionally;

      testWidgets('MediaQuery.disableAnimations suppresses animation', (tester) async {
        await doCheck(tester, mode: mode, expected: false,
          platform: .android,
          mediaQueryDisableAnimations: true);
      });

      testWidgets('Android ignores reduceMotion and autoPlayAnimatedImages', (tester) async {
        await doCheck(tester, mode: mode, expected: true,
          platform: .android,
          reduceMotion: true, autoPlayAnimatedImages: false);
      });

      group('iOS 18+ (Flutter reports Auto-Play Animated Images)', () {
        const ios18 = IosDeviceInfo(systemVersion: '18.0');

        testWidgets('animate when auto-play on and reduce-motion off', (tester) async {
          await doCheck(tester, mode: mode, expected: true,
            platform: .iOS, deviceInfo: ios18,
            reduceMotion: false, autoPlayAnimatedImages: true);
        });

        testWidgets('no animate when auto-play off', (tester) async {
          await doCheck(tester, mode: mode, expected: false,
            platform: .iOS, deviceInfo: ios18,
            reduceMotion: false, autoPlayAnimatedImages: false);
        });

        testWidgets('animate when auto-play on even if reduce-motion on', (tester) async {
          // On iOS 18+, [autoPlayAnimatedImages] reflects the user's explicit
          // choice; respect it over the broader [reduceMotion] preference.
          await doCheck(tester, mode: mode, expected: true,
            platform: .iOS, deviceInfo: ios18,
            reduceMotion: true, autoPlayAnimatedImages: true);
        });
      });

      group('iOS <18 (Flutter cannot read Auto-Play Animated Images)', () {
        // Flutter always reports autoPlayAnimatedImages as true on iOS <18,
        // regardless of the OS setting.

        testWidgets('iOS 17: no animate when reduce-motion on', (tester) async {
          await doCheck(tester, mode: mode, expected: false,
            platform: .iOS,
            deviceInfo: const IosDeviceInfo(systemVersion: '17.5'),
            reduceMotion: true, autoPlayAnimatedImages: true);
        });

        testWidgets('iOS 17: animate when reduce-motion off', (tester) async {
          await doCheck(tester, mode: mode, expected: true,
            platform: .iOS,
            deviceInfo: const IosDeviceInfo(systemVersion: '17.5'),
            reduceMotion: false, autoPlayAnimatedImages: true);
        });

        testWidgets('unparseable systemVersion: fall back to reduce-motion', (tester) async {
          await doCheck(tester, mode: mode, expected: false,
            platform: .iOS,
            deviceInfo: const IosDeviceInfo(systemVersion: 'garbage'),
            reduceMotion: true, autoPlayAnimatedImages: true);
        });
      });
    });
  });
}

/// Real networking, via the [HttpOverrides] base class's real [HttpClient].
class _RealHttpOverrides extends HttpOverrides {}
