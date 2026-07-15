import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/image.dart';
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
    late User user;

    final findPlaceholder = find.descendant(
      of: find.byType(AvatarImage),
      matching: find.byIcon(ZulipIcons.person),
    );

    Future<Uri?> actualUrl(WidgetTester tester, String? avatarUrl, [double? size]) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      user = eg.user(avatarUrl: avatarUrl);
      await store.addUser(user);

      prepareBoringImageHttpClient();
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: size ?? 30)));
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

    testWidgets('shows placeholder when user is not found', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      const nonExistentUserId = 9999999;
      check(store.getUser(nonExistentUserId)).isNull();

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: nonExistentUserId, size: 30)));
      await tester.pump();
      check(findPlaceholder).findsOne();
    });

    testWidgets('fallback URL when avatarUrl is missing', (tester) async {
      check(await actualUrl(tester, null))
        .equals(store.realmUrl.resolve('/avatar/${user.userId}'));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('fallback URL when avatarUrl is missing, larger size', (tester) async {
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetDevicePixelRatio);

      check(await actualUrl(tester, null, 50))
        .equals(store.realmUrl.resolve('/avatar/${user.userId}/medium'));
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('shows placeholder when image fails to load', (tester) async {
      final httpClient = FakeImageHttpClient();
      debugNetworkImageHttpClientProvider = () => httpClient;
      httpClient.request.response
        ..statusCode = HttpStatus.notFound
        ..content = <int>[];

      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final badUser = eg.user(avatarUrl: 'https://zulip.com/avatarinvalid.png');
      await store.addUser(badUser);

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: badUser.userId, size: 30)));
      await tester.pump();
      await tester.pump();
      check(findPlaceholder).findsOne();

      debugNetworkImageHttpClientProvider = null;
    });

  });

  group('DeactivatedUserIcon', () {
    Future<void> pumpIcon(WidgetTester tester, {
      DeactivatedUserIconStyle style = DeactivatedUserIconStyle.avatarOverlay,
      Color? backgroundColor,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: DeactivatedUserIcon(size: 16,
            style: style, backgroundColor: backgroundColor)));
      await tester.pump();
    }

    final findBlockIcon = find.descendant(
      of: find.byType(DeactivatedUserIcon),
      matching: find.byIcon(Icons.block));
    final findDecoratedBox = find.descendant(
      of: find.byType(DeactivatedUserIcon),
      matching: find.byType(DecoratedBox));

    testWidgets('renders a block icon', (tester) async {
      await pumpIcon(tester);
      check(findBlockIcon).findsOne();
    });

    testWidgets('avatarOverlay: icon on a filled circle of backgroundColor', (tester) async {
      await pumpIcon(tester, backgroundColor: const Color(0xFF112233));
      check(findBlockIcon).findsOne();
      final decoratedBox = tester.widget<DecoratedBox>(findDecoratedBox);
      final decoration = decoratedBox.decoration as BoxDecoration;
      check(decoration.color).equals(const Color(0xFF112233));
      check(decoration.shape).equals(BoxShape.circle);
    });

    testWidgets('avatarOverlay, no backgroundColor: circle filled with default background', (tester) async {
      await pumpIcon(tester);
      final decoratedBox = tester.widget<DecoratedBox>(findDecoratedBox);
      final decoration = decoratedBox.decoration as BoxDecoration;
      check(decoration.color).equals(
        DesignVariables.of(tester.element(findBlockIcon)).mainBackground);
      check(decoration.shape).equals(BoxShape.circle);
    });

    testWidgets('inlineText: just the icon, no DecoratedBox', (tester) async {
      await pumpIcon(tester, style: DeactivatedUserIconStyle.inlineText);
      check(findBlockIcon).findsOne();
      check(findDecoratedBox).findsNothing();
    });
  });
}
