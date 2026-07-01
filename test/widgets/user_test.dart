import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/image.dart';
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

    final findPlaceholder = find.descendant(
      of: find.byType(AvatarImage),
      matching: find.byIcon(ZulipIcons.person),
    );

    Future<Uri?> actualUrl(WidgetTester tester, String avatarUrl, [double? size]) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(avatarUrl: avatarUrl);
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

    testWidgets('shows placeholder when user avatarUrl is null', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

      final userWithNoUrl = eg.user(avatarUrl: null);
      await store.addUser(userWithNoUrl);

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: userWithNoUrl.userId, size: 30)));
      await tester.pump();
      check(findPlaceholder).findsOne();
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

    testWidgets('deactivated user with placeholder: wrapped in Opacity 0.5', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(avatarUrl: null, isActive: false);
      await store.addUser(user);

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: 30)));
      await tester.pump();
      final opacity = tester.widget<Opacity>(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(Opacity)));
      check(opacity.opacity).equals(AvatarImage.deactivatedOpacity);
    });

    testWidgets('deactivated user with network image: wrapped in Opacity 0.5', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(
        avatarUrl: 'https://example/avatar.png', isActive: false);
      await store.addUser(user);

      prepareBoringImageHttpClient();
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: 30)));
      await tester.pump();
      // The network image branch is also wrapped in Opacity.
      check(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(RealmContentNetworkImage))).findsOne();
      final opacity = tester.widget<Opacity>(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(Opacity)));
      check(opacity.opacity).equals(AvatarImage.deactivatedOpacity);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('active user: no Opacity wrapper', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(avatarUrl: null, isActive: true);
      await store.addUser(user);

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: 30)));
      await tester.pump();
      check(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(Opacity),
      )).findsNothing();
    });

    testWidgets('muted + deactivated user: deactivated takes priority over muted', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(
        avatarUrl: 'https://example/avatar.png', isActive: false);
      await store.addUser(user);
      await store.setMutedUsers([user.userId]);

      prepareBoringImageHttpClient();
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: 30)));
      await tester.pump();
      // Deactivated wins: the real avatar is shown faded, rather than being
      // replaced with the muted placeholder.
      check(findPlaceholder).findsNothing();
      check(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(RealmContentNetworkImage))).findsOne();
      final opacity = tester.widget<Opacity>(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(Opacity)));
      check(opacity.opacity).equals(AvatarImage.deactivatedOpacity);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('markIfDeactivated: false suppresses Opacity on deactivated user', (tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      final user = eg.user(avatarUrl: null, isActive: false);
      await store.addUser(user);

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: 30,
            markIfDeactivated: false)));
      await tester.pump();
      check(find.descendant(
        of: find.byType(AvatarImage),
        matching: find.byType(Opacity),
      )).findsNothing();
    });
  });

  group('Avatar deactivated handling', () {
    final findBlockIcon = find.descendant(
      of: find.byType(Avatar),
      matching: find.byIcon(Icons.block));
    final findOpacity = find.descendant(
      of: find.byType(Avatar),
      matching: find.byType(Opacity));
    final findPresenceCircle = find.descendant(
      of: find.byType(Avatar),
      matching: find.byType(PresenceCircle));

    void checkDeactivatedOpacity(WidgetTester tester) {
      final opacity = tester.widget<Opacity>(findOpacity);
      check(opacity.opacity).equals(AvatarImage.deactivatedOpacity);
    }

    Future<void> pumpAvatar(WidgetTester tester, User user, {
      bool showPresence = true,
      bool markIfDeactivated = true,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUser(user);
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: Avatar(userId: user.userId, size: 30, borderRadius: 4,
            showPresence: showPresence,
            markIfDeactivated: markIfDeactivated)));
      await tester.pump();
    }

    testWidgets('active user: no block icon, no Opacity, presence shown', (tester) async {
      await pumpAvatar(tester, eg.user(isActive: true));
      check(findBlockIcon).findsNothing();
      check(findOpacity).findsNothing();
      check(findPresenceCircle).findsOne();
    });

    testWidgets('deactivated user: block icon, opacity 0.5, no presence', (tester) async {
      await pumpAvatar(tester, eg.user(isActive: false));
      check(findBlockIcon).findsOne();
      check(findOpacity).findsOne();
      checkDeactivatedOpacity(tester);
      check(findPresenceCircle).findsNothing();
    });

    testWidgets('deleted user: same treatment as deactivated', (tester) async {
      await pumpAvatar(tester, eg.user(isActive: false, isDeleted: true));
      check(findBlockIcon).findsOne();
      check(findOpacity).findsOne();
      checkDeactivatedOpacity(tester);
      check(findPresenceCircle).findsNothing();
    });

    testWidgets('badge still appears when showPresence: false', (tester) async {
      // The message list passes showPresence: false; the deactivated badge
      // and opacity should still appear there.
      await pumpAvatar(tester, eg.user(isActive: false), showPresence: false);
      check(findBlockIcon).findsOne();
      check(findOpacity).findsOne();
      checkDeactivatedOpacity(tester);
      check(findPresenceCircle).findsNothing();
    });

    testWidgets('markIfDeactivated: false suppresses badge and Opacity', (tester) async {
      // The profile page header passes markIfDeactivated: false because it
      // shows the indicator next to the user's name instead.
      await pumpAvatar(tester, eg.user(isActive: false),
        markIfDeactivated: false);
      check(findBlockIcon).findsNothing();
      check(findOpacity).findsNothing();
    });
  });

  group('AvatarShape', () {
    final findBlockIcon = find.descendant(
      of: find.byType(AvatarShape),
      matching: find.byIcon(Icons.block));

    Future<void> pumpShape(WidgetTester tester, {
      int? userIdForPresence,
      bool showDeactivatedBadge = false,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarShape(size: 30, borderRadius: 4,
            userIdForPresence: userIdForPresence,
            showDeactivatedBadge: showDeactivatedBadge,
            child: const SizedBox.shrink())));
      await tester.pump();
    }

    testWidgets('showDeactivatedBadge: false paints presence, no badge', (tester) async {
      await pumpShape(tester, userIdForPresence: eg.selfUser.userId);
      check(find.byType(PresenceCircle)).findsOne();
      check(findBlockIcon).findsNothing();
    });

    testWidgets('showDeactivatedBadge: true paints badge, suppresses presence', (tester) async {
      await pumpShape(tester,
        userIdForPresence: eg.selfUser.userId, showDeactivatedBadge: true);
      check(findBlockIcon).findsOne();
      check(find.byType(PresenceCircle)).findsNothing();
    });

    testWidgets('no overlay when neither presence nor badge requested', (tester) async {
      await pumpShape(tester);
      check(find.byType(PresenceCircle)).findsNothing();
      check(findBlockIcon).findsNothing();
    });
  });

  group('DeactivatedUserIcon', () {
    Future<void> pumpIcon(WidgetTester tester, {Color? backgroundColor}) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: DeactivatedUserIcon(size: 16, backgroundColor: backgroundColor)));
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

    testWidgets('no backgroundColor: bare icon, no DecoratedBox', (tester) async {
      await pumpIcon(tester);
      check(findDecoratedBox).findsNothing();
    });

    testWidgets('backgroundColor: icon on a filled circle', (tester) async {
      await pumpIcon(tester, backgroundColor: const Color(0xFF112233));
      check(findBlockIcon).findsOne();
      final decoratedBox = tester.widget<DecoratedBox>(findDecoratedBox);
      final decoration = decoratedBox.decoration as BoxDecoration;
      check(decoration.color).equals(const Color(0xFF112233));
      check(decoration.shape).equals(BoxShape.circle);
    });
  });
}
