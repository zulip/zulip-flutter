import 'package:checks/checks.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/user.dart';
import 'dart:io';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import 'test_app.dart';

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    throw const SocketException('test error');
  }
}

void main() {
  TestZulipBinding.ensureInitialized();

  group('AvatarImage', () {
    late PerAccountStore store;

    Future<Uri?> actualUrl(WidgetTester tester, String avatarUrl, [double? size]) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(avatarUrl: avatarUrl);
      await store.addUser(user);

      prepareBoringImageHttpClient();
      await tester.pumpWidget(GlobalStoreWidget(
        child: PerAccountStoreWidget(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: size ?? 30))));
      await tester.pump();
      await tester.pump();
      tester.widget(find.byType(AvatarImage));
      final widgets = tester.widgetList<RealmContentNetworkImage>(
        find.byType(RealmContentNetworkImage));
      return widgets.firstOrNull?.src;
    }

    testWidgets('smoke with absolute URL', (tester) async {
      const avatarUrl = 'https://example/avatar.png';
      check(await actualUrl(tester, avatarUrl)).isNotNull()
        .asString.equals(avatarUrl);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke with relative URL', (tester) async {
      const avatarUrl = '/avatar.png';
      check(await actualUrl(tester, avatarUrl))
        .equals(store.tryResolveUrl(avatarUrl)!);
      debugNetworkImageHttpClientProvider = null;
    });

   testWidgets('absolute URL, larger size', (tester) async {
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetDevicePixelRatio);

      const avatarUrl = 'https://example/avatar.png';
      check(await actualUrl(tester, avatarUrl, 50)).isNotNull()
        .asString.equals(avatarUrl.replaceAll('.png', '-medium.png'));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('relative URL, larger size', (tester) async {
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetDevicePixelRatio);

      const avatarUrl = '/avatar.png';
      check(await actualUrl(tester, avatarUrl, 50))
        .equals(store.tryResolveUrl('/avatar-medium.png')!);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('smoke with invalid URL', (tester) async {
      const avatarUrl = '::not a URL::';
      check(await actualUrl(tester, avatarUrl)).isNull();
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('shows placeholder when image URL gives error', (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        addTearDown(testBinding.reset);
        await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
        final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
        final user = eg.user(avatarUrl: 'https://zulip.com/avatar.png');
        await store.addUser(user);

        await tester.pumpWidget(TestZulipApp(
          accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: 32)));
        await tester.pump(); // Image provider is created
        await tester.pump(); // Image fails to load
        expect(find.byIcon(ZulipIcons.person), findsOneWidget);

        expect(find.byType(DecoratedBox), findsOneWidget);

      }, createHttpClient: (context) => MockHttpClient());
    });
  });
}
