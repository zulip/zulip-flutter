import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/initial_snapshot.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/basic.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/widgets/button.dart';
import 'package:zulip/widgets/content.dart';
import 'package:zulip/widgets/icons.dart';
import 'package:zulip/widgets/message_list.dart';
import 'package:zulip/widgets/page.dart';
import 'package:zulip/widgets/remote_settings.dart';
import 'package:zulip/widgets/profile.dart';
import 'package:zulip/widgets/user.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../model/binding.dart';
import '../model/test_store.dart';
import '../stdlib_checks.dart';
import '../test_images.dart';
import '../test_navigation.dart';
import 'checks.dart';
import 'finders.dart';
import 'test_app.dart';

late PerAccountStore store;
late FakeApiConnection connection;

Future<void> setupPage(WidgetTester tester, {
  required int pageUserId,
  List<User>? users,
  List<int>? mutedUserIds,
  List<CustomProfileField>? customProfileFields,
  Map<String, RealmDefaultExternalAccount>? realmDefaultExternalAccounts,
  bool realmPresenceDisabled = false,
  NavigatorObserver? navigatorObserver,
}) async {
  addTearDown(testBinding.reset);

  final initialSnapshot = eg.initialSnapshot(
    customProfileFields: customProfileFields,
    realmDefaultExternalAccounts: realmDefaultExternalAccounts,
    realmPresenceDisabled: realmPresenceDisabled);
  await testBinding.globalStore.add(eg.selfAccount, initialSnapshot);
  store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
  connection = store.connection as FakeApiConnection;

  await store.addUser(eg.selfUser);
  if (users != null) {
    await store.addUsers(users);
  }
  if (mutedUserIds != null) {
    await store.setMutedUsers(mutedUserIds);
  }

  await tester.pumpWidget(TestZulipApp(
    accountId: eg.selfAccount.id,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
    child: ProfilePage(userId: pageUserId)));

  // global store, per-account store, and page get loaded
  await tester.pumpAndSettle();
}

void main() {
  TestZulipBinding.ensureInitialized();

  testWidgets('page builds; profile page renders', (tester) async {
    final user = eg.user(userId: 1, fullName: 'test user',
      deliveryEmail: 'testuser@example.com');

    await setupPage(tester, users: [user], pageUserId: user.userId);

    check(because: 'find user avatar', find.byType(Avatar).evaluate()).length.equals(1);
    check(because: 'find user name', find.text('test user').evaluate()).isNotEmpty();
    // Tests for user status are in their own test group.
    check(because: 'find user delivery email', find.text('testuser@example.com').evaluate()).isNotEmpty();
  });

  testWidgets('page builds; error page shows up if data is missing', (tester) async {
    await setupPage(tester, pageUserId: eg.selfUser.userId + 1989);
    check(because: 'find no user avatar', find.byType(Avatar).evaluate()).isEmpty();
    check(because: 'find error icon', find.byIcon(Icons.error).evaluate()).isNotEmpty();
  });

  testWidgets('page builds; dm links to correct narrow', (tester) async {
    final pushedRoutes = <Route<dynamic>>[];
    final testNavObserver = TestNavigatorObserver()
      ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

    await setupPage(tester,
      users: [eg.user(userId: 1)],
      pageUserId: 1,
      navigatorObserver: testNavObserver,
    );

    final targetWidget = find.byIcon(Icons.email);
    await tester.ensureVisible(targetWidget);
    await tester.tap(targetWidget);
    check(pushedRoutes).last.isA<WidgetRoute>().page
      .isA<MessageListPage>()
      .initNarrow.equals(DmNarrow.withUser(1, selfUserId: eg.selfUser.userId));
  });

  testWidgets('page builds; ensure long name does not overflow', (tester) async {
    final longString = 'X' * 400;
    final user = eg.user(userId: 1, fullName: longString);
    await setupPage(tester, users: [user], pageUserId: user.userId);
    check(find.text(longString).evaluate()).isNotEmpty();
  });

  group('custom profile fields', () {
    testWidgets('page builds; profile page renders with profileData', (tester) async {
      await setupPage(tester,
        users: [
          eg.user(userId: 1, profileData: {
            0: ProfileFieldUserData(value: 'shortTextValue'),
            1: ProfileFieldUserData(value: 'longTextValue'),
            2: ProfileFieldUserData(value: 'x'),
            3: ProfileFieldUserData(value: 'dateValue'),
            4: ProfileFieldUserData(value: 'http://example/linkValue'),
            5: ProfileFieldUserData(value: '[2]'),
            6: ProfileFieldUserData(value: 'externalValue'),
            7: ProfileFieldUserData(value: 'pronounsValue'),
          }),
          eg.user(userId: 2, fullName: 'userValue'),
        ],
        pageUserId: 1,
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.shortText),
          eg.customProfileField(1, CustomProfileFieldType.longText),
          eg.customProfileField(2, CustomProfileFieldType.choice,
            fieldData: '{"x": {"text": "choiceValue", "order": "1"}}'),
          eg.customProfileField(3, CustomProfileFieldType.date),
          eg.customProfileField(4, CustomProfileFieldType.link),
          eg.customProfileField(5, CustomProfileFieldType.user),
          eg.customProfileField(6, CustomProfileFieldType.externalAccount,
            fieldData: '{"subtype": "external1"}'),
          eg.customProfileField(7, CustomProfileFieldType.pronouns),
        ], realmDefaultExternalAccounts: {
          'external1': RealmDefaultExternalAccount(
            name: 'external1',
            text: '',
            hint: '',
            urlPattern: 'https://example/%(username)s')});

      final testCases = [
        (find.text('field0'), find.text('shortTextValue'), CustomProfileFieldType.shortText),
        (find.text('field1'), find.text('longTextValue'), CustomProfileFieldType.longText),
        (find.text('field2'), find.text('choiceValue'), CustomProfileFieldType.choice),
        (find.text('field3'), find.text('dateValue'), CustomProfileFieldType.date),
        (find.text('field4'), find.text('http://example/linkValue'), CustomProfileFieldType.link),
        (find.text('field5'), find.text('userValue'), CustomProfileFieldType.user),
        (find.text('field6'), find.text('externalValue'), CustomProfileFieldType.externalAccount),
        (find.text('field7'), find.text('pronounsValue'), CustomProfileFieldType.pronouns),
      ];
      for (final testCase in testCases) {
        Finder labelFinder = testCase.$1;
        Finder fieldFinder = testCase.$2;
        CustomProfileFieldType testCaseType = testCase.$3;
        check(
          because: 'find label for $testCaseType',
          labelFinder.evaluate().length
        ).equals(1);
        check(
          because: 'find field for $testCaseType',
          fieldFinder.evaluate().length
        ).equals(1);
      }
      final avatars = tester.widgetList<Avatar>(find.byType(Avatar));
      check(avatars.map((w) => w.userId).toList())
        .deepEquals([1, 2]);
    });

    testWidgets('page builds; link type will navigate', (tester) async {
      const testUrl = 'http://example/url';
      final user = eg.user(userId: 1, profileData: {
        0: ProfileFieldUserData(value: testUrl),
      });

      await setupPage(tester,
        users: [user],
        pageUserId: user.userId,
        customProfileFields: [eg.customProfileField(0, CustomProfileFieldType.link)],
      );

      await tester.tap(find.text(testUrl));
      check(testBinding.takeLaunchUrlCalls()).single.equals((
        url: Uri.parse(testUrl),
        mode: LaunchMode.inAppBrowserView,
      ));
    });

    testWidgets('page builds; external link type navigates away', (tester) async {
      final user = eg.user(userId: 1, profileData: {
        0: ProfileFieldUserData(value: 'externalValue'),
      });

      await setupPage(tester,
        users: [user],
        pageUserId: user.userId,
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.externalAccount,
            fieldData: '{"subtype": "external1"}')
        ],
        realmDefaultExternalAccounts: {
          'external1': RealmDefaultExternalAccount(
            name: 'external1',
            text: '',
            hint: '',
            urlPattern: 'http://example/%(username)s')},
      );

      await tester.tap(find.text('externalValue'));
      check(testBinding.takeLaunchUrlCalls()).single.equals((
        url: Uri.parse('http://example/externalValue'),
        mode: LaunchMode.inAppBrowserView,
      ));
    });

    testWidgets('page builds; user links to profile', (tester) async {
      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2]'),
        }),
        eg.user(userId: 2, fullName: 'test user'),
      ];
      final pushedRoutes = <Route<dynamic>>[];
      final testNavObserver = TestNavigatorObserver()
        ..onPushed = (route, prevRoute) => pushedRoutes.add(route);

      await setupPage(tester,
        users: users,
        pageUserId: 1,
        customProfileFields: [eg.customProfileField(0, CustomProfileFieldType.user)],
        navigatorObserver: testNavObserver,
      );

      final textFinder = find.text('test user');
      check(textFinder.evaluate()).length.equals(1);
      final fieldContainer = find.ancestor(of: textFinder, matching: find.byType(Column)).first;
      final targetWidget = find.descendant(of: fieldContainer, matching:find.byType(Avatar));
      await tester.tap(targetWidget, warnIfMissed: false);
      check(pushedRoutes).last.isA<WidgetRoute>().page.isA<ProfilePage>().userId.equals(2);
    });

    testWidgets('page builds; user field with unknown user', (tester) async {
      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2]'),
        }),
      ];
      await setupPage(tester,
        users: users,
        pageUserId: 1,
        customProfileFields: [eg.customProfileField(0, CustomProfileFieldType.user)],
      );

      final textFinder = find.text('(unknown user)');
      check(textFinder.evaluate()).length.equals(1);
    });

    testWidgets('page builds; user field with muted user', (tester) async {
      prepareBoringImageHttpClient();

      Finder avatarFinder(int userId) => find.byWidgetPredicate(
        (widget) => widget is Avatar && widget.userId == userId);
      Finder mutedAvatarFinder(int userId) => find.descendant(
        of: avatarFinder(userId),
        matching: find.byIcon(ZulipIcons.person));
      Finder nonmutedAvatarFinder(int userId) => find.descendant(
        of: avatarFinder(userId),
        matching: find.byType(RealmContentNetworkImage));

      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2,3]'),
        }),
        eg.user(userId: 2, fullName: 'test user2', avatarUrl: '/foo.png'),
        eg.user(userId: 3, fullName: 'test user3', avatarUrl: '/bar.png'),
      ];

      await setupPage(tester,
        users: users,
        mutedUserIds: [2],
        pageUserId: 1,
        customProfileFields: [eg.customProfileField(0, CustomProfileFieldType.user)]);

      check(find.text('Muted user')).findsOne();
      check(mutedAvatarFinder(2)).findsOne();
      check(nonmutedAvatarFinder(2)).findsNothing();

      check(find.text('test user3')).findsOne();
      check(mutedAvatarFinder(3)).findsNothing();
      check(nonmutedAvatarFinder(3)).findsOne();

      debugNetworkImageHttpClientProvider = null;
    });

    testWidgets('page builds; user links render multiple avatars', (tester) async {
      final users = [
        eg.user(userId: 1, profileData: {
          0: ProfileFieldUserData(value: '[2,3]'),
        }),
        eg.user(userId: 2, fullName: 'test user2'),
        eg.user(userId: 3, fullName: 'test user3'),
      ];

      await setupPage(tester,
        users: users,
        pageUserId: 1,
        customProfileFields: [eg.customProfileField(0, CustomProfileFieldType.user)],
      );

      final avatars = tester.widgetList<Avatar>(find.byType(Avatar));
      check(avatars.map((w) => w.userId).toList())
        .deepEquals([1, 2, 3]);
    });

    testWidgets('page builds; ensure long customProfileFields do not overflow', (tester) async {
      final longString = 'X' * 400;
      final user = eg.user(userId: 1, fullName: 'fullName', profileData: {
        0: ProfileFieldUserData(value: longString),
        1: ProfileFieldUserData(value: longString),
        2: ProfileFieldUserData(value: 'x'),
        3: ProfileFieldUserData(value: 'http://example/$longString'),
        4: ProfileFieldUserData(value: '[2]'),
        5: ProfileFieldUserData(value: longString),
        6: ProfileFieldUserData(value: longString),
      });
      final user2 = eg.user(userId: 2, fullName: longString);

      await setupPage(tester, users: [user, user2], pageUserId: user.userId,
        customProfileFields: [
          eg.customProfileField(0, CustomProfileFieldType.shortText),
          eg.customProfileField(1, CustomProfileFieldType.longText),
          eg.customProfileField(2, CustomProfileFieldType.choice,
            fieldData: '{"x": {"text": "$longString", "order": "1"}}'),
          // no [CustomProfileFieldType.date] because those can't be made long
          eg.customProfileField(3, CustomProfileFieldType.link),
          eg.customProfileField(4, CustomProfileFieldType.user),
          eg.customProfileField(5, CustomProfileFieldType.externalAccount,
            fieldData: '{"subtype": "external1"}'),
          eg.customProfileField(6, CustomProfileFieldType.pronouns),
        ], realmDefaultExternalAccounts: {
          'external1': RealmDefaultExternalAccount(
            name: 'external1',
            text: '',
            hint: '',
            urlPattern: 'https://example/%(username)s')});

      check(find.textContaining(longString).evaluate()).length.equals(7);
    });
  });

  group('user status', () {
    testWidgets('non-self profile, status set: status info appears', (tester) async {
      await setupPage(tester, users: [eg.otherUser], pageUserId: eg.otherUser.userId);
      await store.changeUserStatus(eg.otherUser.userId, UserStatusChange(
        text: OptionSome('Busy'),
        emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
          emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
      await tester.pump();

      final statusEmojiFinder = find.ancestor(of: find.text('\u{1f6e0}'),
        matching: find.byType(UserStatusEmoji));
      check(statusEmojiFinder).findsOne();
      check(tester.widget<UserStatusEmoji>(statusEmojiFinder)
        .neverAnimate).isFalse();
      check(find.text('Busy')).findsOne();
    });

    testWidgets('self-profile, status set: status info appears', (tester) async {
      await setupPage(tester, users: [eg.selfUser], pageUserId: eg.selfUser.userId);
      await store.changeUserStatus(eg.selfUser.userId, UserStatusChange(
        text: OptionSome('Busy'),
        emoji: OptionSome(StatusEmoji(emojiName: 'working_on_it',
          emojiCode: '1f6e0', reactionType: ReactionType.unicodeEmoji))));
      await tester.pump();

      final statusEmojiFinder = find.ancestor(of: find.text('\u{1f6e0}'),
        matching: find.byType(UserStatusEmoji));
      check(statusEmojiFinder).findsOne();
      check(tester.widget<UserStatusEmoji>(statusEmojiFinder)
        .neverAnimate).isFalse();
      check(findText(includePlaceholders: false, 'Busy')).findsOne();
    });
  });

  group('invisible mode', () {
    final findRow = find.widgetWithText(ZulipMenuItemButton, 'Invisible mode');
    final findToggle = find.descendant(of: findRow, matching: find.byType(Toggle));

    void checkDoesNotAppear(WidgetTester tester) {
      check(findRow).findsNothing();
      check(findToggle).findsNothing();
    }

    void checkAppears(WidgetTester tester) {
      check(findRow).findsOne();
      check(findToggle).findsOne();
    }

    bool getValue(WidgetTester tester) => tester.widget<Toggle>(findToggle).value;

    void checkAppearsActive(WidgetTester tester, bool expected) {
      check(getValue(tester)).equals(expected);

      check(tester.semantics.find(findRow)).matchesSemantics(
        label: 'Invisible mode',
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasToggledState: true,
        isToggled: expected);
    }

    void prepareRequestSuccess([Duration delay = Duration.zero]) {
      connection.prepare(json: {}, delay: delay);
    }

    void prepareRequestError([Duration delay = Duration.zero]) {
      connection.prepare(httpException: SocketException('failed'), delay: delay);
    }

    void scheduleEventAfter(Duration duration, bool newInvisibleModeValue) async {
      await Future<void>.delayed(duration);
      await store.handleEvent(UserSettingsUpdateEvent(id: 1,
        property: UserSettingName.presenceEnabled, value: !newInvisibleModeValue));
    }

    void checkRequest(bool requestedInvisibleModeValue) {
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('PATCH')
        ..url.path.equals('/api/v1/settings')
        ..bodyFields.deepEquals({
          'presence_enabled': requestedInvisibleModeValue ? 'false' : 'true',
        });
    }

    final toggleInteractionModeVariant = ValueVariant<_InvisibleModeToggleInteractionMode>(
      _InvisibleModeToggleInteractionMode.values.toSet());

    Future<void> doToggle(WidgetTester tester, _InvisibleModeToggleInteractionMode mode) async {
      switch (mode) {
        case _InvisibleModeToggleInteractionMode.tapRow:
          await tester.tap(findRow);
        case _InvisibleModeToggleInteractionMode.tapToggle:
          await tester.tap(findToggle);
        case _InvisibleModeToggleInteractionMode.dragToggleThumb:
          final textDirection = Directionality.of(tester.element(findToggle));
          final dragDx = switch ((getValue(tester), textDirection)) {
            (true,  TextDirection.ltr) => -40.0,
            (false, TextDirection.ltr) =>  40.0,
            (true,  TextDirection.rtl) =>  40.0,
            (false, TextDirection.rtl) => -40.0,
          };
          await tester.drag(findToggle, Offset(dragDx, 0.0));
      }
    }

    testWidgets('self-profile: appears', (tester) async {
      await setupPage(tester, pageUserId: eg.selfUser.userId);
      checkAppears(tester);
    });

    testWidgets('self-profile, but presence disabled in realm: does not appear', (tester) async {
      await setupPage(tester, pageUserId: eg.selfUser.userId, realmPresenceDisabled: true);
      checkDoesNotAppear(tester);
    });

    testWidgets('non-self profile: does not appear', (tester) async {
      await setupPage(tester, pageUserId: eg.otherUser.userId, users: [eg.otherUser]);
      checkDoesNotAppear(tester);
    });

    testWidgets('without recent interaction, event causes immediate update, which sticks', (tester) async {
      await setupPage(tester, pageUserId: eg.selfUser.userId);
      check(store.userSettings.presenceEnabled).isTrue();
      checkAppearsActive(tester, false);

      await store.handleEvent(UserSettingsUpdateEvent(id: 1,
        property: UserSettingName.presenceEnabled, value: false));
      await tester.pump();
      checkAppearsActive(tester, true);

      await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout * 2);
      checkAppearsActive(tester, true);
    });

    testWidgets('smoke, turn on', (tester) async {
      final toggleInteractionMode = toggleInteractionModeVariant.currentValue!;

      await setupPage(tester, pageUserId: eg.selfUser.userId);
      check(store.userSettings.presenceEnabled).isTrue();
      checkAppearsActive(tester, false);

      // The appearance changes and the request is sent, immediately.
      prepareRequestSuccess(Duration(milliseconds: 100));
      scheduleEventAfter(Duration(milliseconds: 150), true);
      await doToggle(tester, toggleInteractionMode);
      await tester.pump();
      await tester.pump();
      checkAppearsActive(tester, true);
      checkRequest(true);

      // Wait a while, idly: no change, no extra requests
      await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout * 2);
      check(connection.takeRequests()).isEmpty();
      checkAppearsActive(tester, true);
    }, variant: toggleInteractionModeVariant);

    testWidgets('smoke, turn off', (tester) async {
      final toggleInteractionMode = toggleInteractionModeVariant.currentValue!;

      await setupPage(tester, pageUserId: eg.selfUser.userId);
      await store.handleEvent(UserSettingsUpdateEvent(id: 1,
        property: UserSettingName.presenceEnabled, value: false));
      await tester.pump();
      checkAppearsActive(tester, true);

      // The appearance changes and the request is sent, immediately.
      prepareRequestSuccess(Duration(milliseconds: 100));
      scheduleEventAfter(Duration(milliseconds: 150), false);
      await doToggle(tester, toggleInteractionMode);
      await tester.pump();
      await tester.pump();
      checkAppearsActive(tester, false);
      checkRequest(false);

      // Wait a while, idly: no change, no extra requests
      await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout * 2);
      check(connection.takeRequests()).isEmpty();
      checkAppearsActive(tester, false);
    }, variant: toggleInteractionModeVariant);

    testWidgets('event arrives after local-echo timeout', (tester) async {
      final toggleInteractionMode = toggleInteractionModeVariant.currentValue!;

      await setupPage(tester, pageUserId: eg.selfUser.userId);
      check(store.userSettings.presenceEnabled).isTrue();
      checkAppearsActive(tester, false);

      // The appearance changes and the request is sent, immediately.
      prepareRequestSuccess(Duration(milliseconds: 100));
      scheduleEventAfter(Duration(seconds: 10), true);
      await doToggle(tester, toggleInteractionMode);
      await tester.pump();
      await tester.pump();
      checkAppearsActive(tester, true);
      checkRequest(true);

      // Local-echo timeout passes and event hasn't come; change back.
      await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout);
      await tester.pump();
      checkAppearsActive(tester, false);

      // The event comes after a while; update for the new value.
      await tester.pump(Duration(seconds: 10));
      check(connection.takeRequests()).isEmpty();
      checkAppearsActive(tester, true);
    }, variant: toggleInteractionModeVariant);

    testWidgets('request has an error', (tester) async {
      final toggleInteractionMode = toggleInteractionModeVariant.currentValue!;

      await setupPage(tester, pageUserId: eg.selfUser.userId);
      check(store.userSettings.presenceEnabled).isTrue();
      checkAppearsActive(tester, false);

      // The appearance changes and the request is sent, immediately.
      final requestDuration = Duration(milliseconds: 100);
      prepareRequestError(requestDuration);
      await doToggle(tester, toggleInteractionMode);
      await tester.pump();
      await tester.pump();
      checkAppearsActive(tester, true);
      checkRequest(true);

      // The appearance doesn't change as soon as the request errors,
      // if it errored quickly…
      await tester.pump(requestDuration);
      checkAppearsActive(tester, true);

      // Try waiting a bit longer; it still hasn't changed…
      //   (https://github.com/zulip/zulip-flutter/pull/1631#discussion_r2191301085 )
      final epsilon = Duration(milliseconds: 50);
      await tester.pump(epsilon);
      checkAppearsActive(tester, true);

      // …it changes when [RemoteSettingBuilder.localEchoMinimum]
      // has passed since the interaction.
      await tester.pump(
        RemoteSettingBuilder.localEchoMinimum - requestDuration - epsilon);
      await tester.pump();
      checkAppearsActive(tester, false);

      // Wait a while, idly: no change, no extra requests
      await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout * 2);
      check(connection.takeRequests()).isEmpty();
      checkAppearsActive(tester, false);
    }, variant: toggleInteractionModeVariant);

    testWidgets('spam-tapping', (tester) async {
      final toggleInteractionMode = toggleInteractionModeVariant.currentValue!;

      await setupPage(tester, pageUserId: eg.selfUser.userId);
      check(store.userSettings.presenceEnabled).isTrue();
      checkAppearsActive(tester, false);

      Future<void> doSpamTap({required bool expectedCurrentValue}) async {
        checkAppearsActive(tester, expectedCurrentValue);
        final newValue = !expectedCurrentValue;
        // The appearance changes and the request is sent, immediately.
        prepareRequestSuccess(Duration(milliseconds: 100));
        scheduleEventAfter(Duration(milliseconds: 150), newValue);
        await doToggle(tester, toggleInteractionMode);
        await tester.pump();
        await tester.pump();
        checkAppearsActive(tester, newValue);
        checkRequest(newValue);
      }

      // Events will be coming in, but those don't control the switch;
      // only the user interaction does, until there have been no interactions
      // for [RemoteSettingBuilder.localEchoMinimum].
      await doSpamTap(expectedCurrentValue: false);
      await tester.pump(Duration(milliseconds: 90));
      await doSpamTap(expectedCurrentValue: true);
      await tester.pump(Duration(milliseconds: 30));
      await doSpamTap(expectedCurrentValue: false);
      await tester.pump(Duration(milliseconds: 60));
      await doSpamTap(expectedCurrentValue: true);
      await tester.pump(Duration(milliseconds: 120));
      await doSpamTap(expectedCurrentValue: false);
      await tester.pump(Duration(milliseconds: 120));
      await doSpamTap(expectedCurrentValue: true);
      await tester.pump(Duration(milliseconds: 120));
      await doSpamTap(expectedCurrentValue: false);
      await tester.pump(Duration(milliseconds: 300));
      await doSpamTap(expectedCurrentValue: true);
      await tester.pump(Duration(milliseconds: 45));
      await doSpamTap(expectedCurrentValue: false);
      await tester.pump(Duration(milliseconds: 600));
      await doSpamTap(expectedCurrentValue: true);
      await tester.pump(Duration(milliseconds: 5));
      await doSpamTap(expectedCurrentValue: false);
      check(getValue(tester)).equals(true);

      await tester.pump(RemoteSettingBuilder.localEchoMinimum - Duration(milliseconds: 1));
      check(getValue(tester)).equals(true);
      await tester.pump(Duration(milliseconds: 2));
      check(getValue(tester)).equals(true);

      // Wait a while, idly: no change, no extra requests
      await tester.pump(RemoteSettingBuilder.localEchoIdleTimeout * 2);
      check(connection.takeRequests()).isEmpty();
      checkAppearsActive(tester, true);
    }, variant: toggleInteractionModeVariant);
  });
}

enum _InvisibleModeToggleInteractionMode {
  tapRow,
  tapToggle,
  dragToggleThumb,
  // TODO(a11y) is there something separate to test?
}
