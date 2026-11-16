import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_checks/legacy_checks.dart';
import 'package:material_ui/material_ui.dart';
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

    final findNetworkImage = find.descendant(
      of: find.byType(AvatarImage),
      matching: find.byType(RealmContentNetworkImage));
    final findPlaceholder = find.descendant(
      of: find.byType(AvatarImage),
      matching: find.byIcon(ZulipIcons.person),
    );
    final findOpacity = find.descendant(
      of: find.byType(AvatarImage),
      matching: find.byType(Opacity));

    Future<void> pumpImage(WidgetTester tester, User user, {
      double size = 30,
      bool muted = false,
      bool fadeIfDeactivated = true,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      await store.addUser(user);
      if (muted) await store.setMutedUsers([user.userId]);

      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarImage(userId: user.userId, size: size,
            fadeIfDeactivated: fadeIfDeactivated)));
      await tester.pump();
    }

    Future<Uri?> actualUrl(WidgetTester tester, String? avatarUrl, [double? size]) async {
      user = eg.user(avatarUrl: avatarUrl);
      prepareBoringImageHttpClient();
      await pumpImage(tester, user, size: size ?? 30);
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

      await pumpImage(tester,
        eg.user(avatarUrl: 'https://zulip.com/avatarinvalid.png'));
      await tester.pump();
      check(findPlaceholder).findsOne();

      debugNetworkImageHttpClientProvider = null;
    });

    void checkDeactivatedOpacity(WidgetTester tester) {
      final opacity = tester.widget<Opacity>(findOpacity);
      check(opacity.opacity).equals(AvatarImage.deactivatedOpacity);
    }

    testWidgets('deactivated user with placeholder: faded', (tester) async {
      await pumpImage(tester, eg.user(avatarUrl: null, isActive: false));
      checkDeactivatedOpacity(tester);
    });

    testWidgets('deactivated user with network image: faded', (tester) async {
      prepareBoringImageHttpClient();
      await pumpImage(tester,
        eg.user(avatarUrl: 'https://example/avatar.png', isActive: false));
      check(findNetworkImage).findsOne();
      checkDeactivatedOpacity(tester);
      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('active user: not faded', (tester) async {
      await pumpImage(tester, eg.user(avatarUrl: null, isActive: true));
      check(findOpacity).findsNothing();
    });

    testWidgets('muted + deactivated user: muted placeholder, faded', (tester) async {
      await pumpImage(tester,
        eg.user(avatarUrl: 'https://example/avatar.png', isActive: false),
        muted: true);
      check(findNetworkImage).findsNothing();
      check(findPlaceholder).findsOne();
      checkDeactivatedOpacity(tester);
    });

    testWidgets('fadeIfDeactivated: false: deactivated user not faded', (tester) async {
      await pumpImage(tester, eg.user(avatarUrl: null, isActive: false),
        fadeIfDeactivated: false);
      check(findOpacity).findsNothing();
    });
  });

  group('Avatar', () {
    final findDeactivatedIcon = find.descendant(
      of: find.byType(Avatar),
      matching: find.byType(DeactivatedUserIcon));
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

    testWidgets('active user: no badge, not faded, presence shown', (tester) async {
      await pumpAvatar(tester, eg.user(isActive: true));
      check(findDeactivatedIcon).findsNothing();
      check(findOpacity).findsNothing();
      check(findPresenceCircle).findsOne();
    });

    testWidgets('deactivated user: badge, faded, no presence', (tester) async {
      await pumpAvatar(tester, eg.user(isActive: false));
      check(findDeactivatedIcon).findsOne();
      checkDeactivatedOpacity(tester);
      check(findPresenceCircle).findsNothing();
    });

    testWidgets('badge still appears when showPresence: false', (tester) async {
      // The message list passes showPresence: false; the deactivated badge
      // and fade should still appear there.
      await pumpAvatar(tester, eg.user(isActive: false), showPresence: false);
      check(findDeactivatedIcon).findsOne();
      checkDeactivatedOpacity(tester);
      check(findPresenceCircle).findsNothing();
    });

    testWidgets('markIfDeactivated: false suppresses badge and fade', (tester) async {
      // The profile page header passes markIfDeactivated: false because it
      // shows the indicator next to the user's name instead.
      await pumpAvatar(tester, eg.user(isActive: false),
        markIfDeactivated: false);
      check(findDeactivatedIcon).findsNothing();
      check(findOpacity).findsNothing();
    });
  });

  group('AvatarShape', () {
    final findDeactivatedIcon = find.descendant(
      of: find.byType(AvatarShape),
      matching: find.byType(DeactivatedUserIcon));

    Future<void> pumpShape(WidgetTester tester, {
      User? user,
      bool showPresence = true,
      bool markIfDeactivated = true,
    }) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());
      final store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      if (user != null) await store.addUser(user);
      await tester.pumpWidget(
        TestZulipApp(accountId: eg.selfAccount.id,
          child: AvatarShape(size: 30, borderRadius: 4,
            userId: user?.userId,
            showPresence: showPresence,
            markIfDeactivated: markIfDeactivated,
            child: const SizedBox.shrink())));
      await tester.pump();
    }

    testWidgets('active user: paints presence, no badge', (tester) async {
      await pumpShape(tester, user: eg.user(isActive: true));
      check(find.byType(PresenceCircle)).findsOne();
      check(findDeactivatedIcon).findsNothing();
    });

    testWidgets('deactivated user: paints badge, suppresses presence', (tester) async {
      await pumpShape(tester, user: eg.user(isActive: false));
      check(findDeactivatedIcon).findsOne();
      check(find.byType(PresenceCircle)).findsNothing();
    });

    testWidgets('markIfDeactivated: false: no badge for deactivated user', (tester) async {
      await pumpShape(tester, user: eg.user(isActive: false),
        markIfDeactivated: false);
      check(findDeactivatedIcon).findsNothing();
      check(find.byType(PresenceCircle)).findsOne();
    });

    testWidgets('no userId: no overlay', (tester) async {
      await pumpShape(tester);
      check(find.byType(PresenceCircle)).findsNothing();
      check(findDeactivatedIcon).findsNothing();
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

    final findIcon = find.descendant(
      of: find.byType(DeactivatedUserIcon),
      matching: find.byIcon(Icons.block));

    RenderBox renderBox(WidgetTester tester) =>
      tester.renderObject<RenderBox>(find.byType(DeactivatedUserIcon));

    testWidgets('smoke', (tester) async {
      await pumpIcon(tester);
      check(findIcon).findsOne();
    });

    testWidgets('avatarOverlay: icon on a filled circle of backgroundColor', (tester) async {
      await pumpIcon(tester, backgroundColor: const Color(0xFF112233));
      check(findIcon).findsOne();
      check(renderBox(tester)).legacyMatcher(
        // `paints` isn't a [Matcher] so we wrap it with `equals`;
        // awkward but it works
        equals(paints..circle(color: const Color(0xFF112233))));
    });

    testWidgets('avatarOverlay, no backgroundColor: circle filled with default background', (tester) async {
      await pumpIcon(tester);
      final designVariables = DesignVariables.of(tester.element(findIcon));
      check(renderBox(tester)).legacyMatcher(
        equals(paints..circle(color: designVariables.mainBackground)));
    });

    testWidgets('inlineText: just the icon, no circle', (tester) async {
      await pumpIcon(tester, style: DeactivatedUserIconStyle.inlineText);
      check(findIcon).findsOne();
      check(renderBox(tester)).legacyMatcher(isNot(paints..circle()));
    });
  });
}
