import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/store.dart';
import 'package:zulip/widgets/theme.dart';
import 'package:zulip/widgets/user.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import 'test_app.dart';

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
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [
            DesignVariables.light,
          ]),
          home: GlobalStoreWidget(
            child: PerAccountStoreWidget(accountId: eg.selfAccount.id,
                child: AvatarImage(userId: user.userId, size: size ?? 30)),
          ),
        ),
      );
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
      addTearDown(testBinding.reset);
      prepareBoringImageHttpClient(success: false);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final badUser = eg.user(avatarUrl: 'https://zulip.com/avatarinvalid.png');
      await store.addUser(badUser);
      await tester.pumpWidget(
          MaterialApp(
              theme: ThemeData(extensions: [
                DesignVariables.light,
              ]),
              home: TestZulipApp(
          accountId: eg.selfAccount.id,
          child: AvatarImage(userId: badUser.userId, size: 30))));
      await tester.pumpAndSettle();
      check(
        find.descendant(
          of: find.byType(AvatarImage),
          matching: find.byIcon(ZulipIcons.person),
        ).evaluate().length
      ).equals(1);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('shows placeholder when user avatarUrl is null', (WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final userWithNoUrl = eg.user(avatarUrl: null);
      await store.addUser(userWithNoUrl);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [
            DesignVariables.light,
          ]),
          home: TestZulipApp(
            accountId: eg.selfAccount.id,
            child: AvatarImage(userId: userWithNoUrl.userId, size: 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(
          find.descendant(
            of: find.byType(AvatarImage),
            matching: find.byIcon(ZulipIcons.person),
          ).evaluate().length
      ).equals(1);
    });

    testWidgets('shows placeholder when user is not found', (WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      const nonExistentUserId = 9999999;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [
            DesignVariables.light,
          ]),
          home: TestZulipApp(
            accountId: eg.selfAccount.id,
            child: AvatarImage(userId: nonExistentUserId, size: 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(
          find.descendant(
            of: find.byType(AvatarImage),
            matching: find.byIcon(ZulipIcons.person),
          ).evaluate().length
      ).equals(1);
    });
  });
}
